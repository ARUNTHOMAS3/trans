import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' show max;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart' hide Skeleton;
import 'package:zerpai_erp/core/services/api_client.dart';

import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import '../../models/purchases_purchase_receives_model.dart';
import '../../providers/purchase_receives_provider.dart';
import '../../../vendors/providers/vendor_provider.dart';
import '../../../purchase_orders/providers/purchases_purchase_orders_provider.dart'
    hide warehousesProvider;
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';

import 'package:zerpai_erp/shared/widgets/inputs/radio_group.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';

import 'package:zerpai_erp/shared/providers/lookup_providers.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/advanced_vendor_search_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/edit_quantity_dialog.dart';
import 'package:zerpai_erp/modules/purchases/vendors/repositories/vendor_repository_impl.dart';
import 'package:zerpai_erp/shared/widgets/inputs/vendor_sidebar.dart';

const _bgWhite = Color(0xFFFFFFFF);
const _borderCol = Color(0xFFE8E8E8);
const _fieldBorder = Color(0xFFE0E0E0);
const _focusBorder = Color(0xFF0088FF);
const _labelColor = Color(0xFF444444);
const _requiredLabel = Color(0xFFD32F2F);
const _hintColor = Color(0xFF999999);
const _textPrimary = Color(0xFF333333);
const _linkBlue = Color(0xFF2A95BF);
const _greenBtn = Color(0xFF19A05E);
const _dangerRed = Color(0xFFD32F2F);
const _infoBannerBg = Color(0xFFFFF3E0);
const _infoBannerBorder = Color(0xFFFFCC80);
const _infoBannerText = Color(0xFFE65100);

// ── Row controller for items table ──────────────────────────────────────────
class _ReceiveItemRowController {
  final TextEditingController qtyCtrl = TextEditingController();

  void dispose() {
    qtyCtrl.dispose();
  }
}

// ── Controller for batch entry rows in the dialog ───────────────────────────
class _BatchItemRowController {
  final TextEditingController batchNoCtrl = TextEditingController();
  final TextEditingController unitPackCtrl = TextEditingController();
  final TextEditingController mrpCtrl = TextEditingController();
  final TextEditingController ptrCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController focCtrl = TextEditingController();
  final TextEditingController mfgBatchCtrl = TextEditingController();
  final TextEditingController mfgDateCtrl = TextEditingController();
  final TextEditingController expDateCtrl = TextEditingController();
  final TextEditingController damageCtrl = TextEditingController();
  final GlobalKey mfgKey = GlobalKey();
  final GlobalKey expKey = GlobalKey();
  DateTime? mfgDate;
  DateTime? expDate;
  bool isDamaged = false;
  bool isAutoLoaded = false;
  String? binId;
  String? binLabel;

  _BatchItemRowController({BatchInfo? initial}) {
    if (initial != null) {
      batchNoCtrl.text = initial.batchNo;
      unitPackCtrl.text = initial.unitPack;
      mrpCtrl.text = initial.mrp.toString();
      ptrCtrl.text = initial.ptr.toString();
      qtyCtrl.text = initial.quantity.toString();
      focCtrl.text = initial.foc == 0 ? '' : initial.foc.toString();
      mfgBatchCtrl.text = initial.manufactureBatch;
      mfgDate = initial.manufactureDate;
      expDate = initial.expiryDate;
      if (mfgDate != null)
        mfgDateCtrl.text = DateFormat('dd-MM-yyyy').format(mfgDate!);
      if (expDate != null)
        expDateCtrl.text = DateFormat('dd-MM-yyyy').format(expDate!);
      binId = initial.binId;
      binLabel = initial.binLabel;
    }
  }

  void dispose() {
    batchNoCtrl.dispose();
    unitPackCtrl.dispose();
    mrpCtrl.dispose();
    ptrCtrl.dispose();
    qtyCtrl.dispose();
    focCtrl.dispose();
    mfgBatchCtrl.dispose();
    mfgDateCtrl.dispose();
    expDateCtrl.dispose();
    damageCtrl.dispose();
  }

  BatchInfo toBatchInfo() {
    return BatchInfo(
      batchNo: batchNoCtrl.text,
      unitPack: unitPackCtrl.text,
      mrp: double.tryParse(mrpCtrl.text) ?? 0,
      ptr: double.tryParse(ptrCtrl.text) ?? 0,
      quantity: double.tryParse(qtyCtrl.text) ?? 0,
      foc: double.tryParse(focCtrl.text) ?? 0,
      manufactureBatch: mfgBatchCtrl.text,
      manufactureDate: mfgDate,
      expiryDate: expDate,
      binId: binId,
      binLabel: binLabel,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MAIN WIDGET
// ═════════════════════════════════════════════════════════════════════════════
class PurchasesPurchaseReceivesCreateScreen extends ConsumerStatefulWidget {
  final String? initialPoId;
  final String? initialReceiveId;
  const PurchasesPurchaseReceivesCreateScreen({
    super.key,
    this.initialPoId,
    this.initialReceiveId,
  });

  @override
  ConsumerState<PurchasesPurchaseReceivesCreateScreen> createState() =>
      _PRCreateState();
}

class _PRCreateState
    extends ConsumerState<PurchasesPurchaseReceivesCreateScreen> {
  bool _isLoadingData = false;
  bool get _isEditMode =>
      widget.initialReceiveId != null && widget.initialReceiveId!.isNotEmpty;

  final _receiveNumberCtrl = TextEditingController();
  final _receivedDateCtrl = TextEditingController();
  final _billNoCtrl = TextEditingController();
  final _billDateCtrl = TextEditingController();
  final _invoiceTotalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Form state
  final GlobalKey _dateFieldKey = GlobalKey();
  final GlobalKey _billDateFieldKey = GlobalKey();
  String? _selectedVendorName;
  String? _selectedVendorId;
  List<PurchaseOrder> _selectedPOs = [];
  PurchaseOrder? _selectedPO;
  String? _selectedPONumber;
  String? _selectedPOId;
  String? _selectedWarehouseId;

  bool _receiveBilledItems = false;
  bool _isFullyBilled = false;
  bool _hasBills = false;
  List<Map<String, dynamic>> _associatedBills = [];
  final Set<String> _expandedBillIds = <String>{};
  final Map<String, TextEditingController> _billedQtyControllers = {};

  List<PurchaseOrder> _vendorPOs = [];
  final Map<String, double> _receivedQuantities = {};
  bool _isLoadingPOs = false;
  bool _isSaving = false;
  bool _isReceiveAutoGenerate = true;
  String _receiveNumberPrefix = 'PR-';
  int _receiveNextNumber = 1;
  bool _isManualMode = false;
  bool _isDamageEnabled = false;
  final List<String?> _preferredBins = [];
  final List<TextEditingController> _damageControllers = [];
  final Set<String> _hoveredQtyFields = <String>{};
  final Set<String> _focusedQtyFields = <String>{};
  final Set<String> _hoveredFormFields = <String>{};
  final Set<String> _focusedFormFields = <String>{};
  bool _showSearchItemDetails = false;
  String _itemDetailsSearchQuery = '';
  final _itemDetailsSearchCtrl = TextEditingController();

  final Set<int> _hiddenManualIndices = <int>{};
  String _binMode = 'item'; // 'transaction' or 'item'
  int? _hoveredRowIndex;
  final ScrollController _attachmentListScrollController = ScrollController();
  final LayerLink _uploadLink = LayerLink();
  final LayerLink _attachmentBadgeLink = LayerLink();
  OverlayEntry? _uploadOverlay;
  OverlayEntry? _attachmentListOverlay;
  OverlayEntry? _topErrorOverlayEntry;
  OverlayEntry? _vendorSidebarOverlay;
  OverlayEntry? _valueTooltipOverlay;
  bool _isVendorSidebarLoading = false;
  bool _isUploadButtonHovered = false;
  Timer? _topErrorTimer;
  String? _selectedTransactionBin;
  String? _selectedTransactionBinId;
  static const int _maxUploadFiles = 5;
  static const int _maxUploadFileSizeBytes = 10 * 1024 * 1024;
  final List<PlatformFile> _uploadedFiles = [];

  final List<PurchaseReceiveItem> _items = [];
  final List<_ReceiveItemRowController> _rowControllers = [];
  final Map<int, String> _rowSelectedWarehouses = {};
  final Map<int, String> _rowSelectedViews = {};

  double _dynamicQtyToReceiveColumnWidth() {
    final maxBatches = _items.isEmpty
        ? 0
        : _items.map((i) => i.batches.length).fold<int>(0, (m, e) => max(m, e));
    const baseWidth = 140.0;
    const extraPerBatch = 102.0;
    if (maxBatches > 0) {
      return (132.0 + (maxBatches * extraPerBatch)).clamp(baseWidth, 700.0);
    }
    return baseWidth;
  }

  double _dynamicBilledQtyToReceiveColumnWidth() {
    int maxBatches = 0;
    for (final bill in _associatedBills) {
      final items = bill['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final batches =
            (item['batches'] as List<dynamic>?)?.cast<BatchInfo>() ?? [];
        if (batches.length > maxBatches) {
          maxBatches = batches.length;
        }
      }
    }
    const baseWidth = 140.0;
    const extraPerBatch = 102.0;
    if (maxBatches > 0) {
      return (132.0 + (maxBatches * extraPerBatch)).clamp(baseWidth, 700.0);
    }
    return baseWidth;
  }

  double _sumBatchQuantity(List<BatchInfo> batches) {
    return batches.fold<double>(0, (sum, batch) => sum + batch.quantity);
  }

  double _sumBatchFoc(List<BatchInfo> batches) {
    return batches.fold<double>(0, (sum, batch) => sum + batch.foc);
  }

  String _fmtPcs(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(warehousesProvider);
      ref.invalidate(vendorProvider);
    });
    if (!_isEditMode) {
      _receiveNumberCtrl.text = _generateReceiveNumber();
      _receivedDateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    } else {
      _isLoadingData = true;
      _receiveNumberCtrl.text = 'PR-XXXXX';
      _billNoCtrl.text = 'BILL-XXXXX';
      _invoiceTotalCtrl.text = '0.00';
      _receivedDateCtrl.text = '01-01-2026';
      _billDateCtrl.text = '01-01-2026';
      _selectedVendorName = 'Loading Vendor Name...';
      _selectedPONumber = 'PO-XXXXX';
      _items.addAll([
        PurchaseReceiveItem(
          itemId: 'dummy1',
          itemName: 'Loading item name and description...',
          ordered: 10,
          received: 0,
          inTransit: 0,
          cancelled: 0,
          quantityToReceive: 10,
        ),
        PurchaseReceiveItem(
          itemId: 'dummy2',
          itemName: 'Loading item name and description...',
          ordered: 5,
          received: 0,
          inTransit: 0,
          cancelled: 0,
          quantityToReceive: 5,
        ),
      ]);
      _rowControllers.addAll([
        _ReceiveItemRowController()..qtyCtrl.text = '10',
        _ReceiveItemRowController()..qtyCtrl.text = '5',
      ]);
      _preferredBins.addAll([null, null]);
      _damageControllers.addAll([
        TextEditingController(),
        TextEditingController(),
      ]);
    }

    // Load vendors and next number when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(vendorProvider.notifier).loadVendors();
      if (!_isEditMode) {
        await _fetchNextNumber();
      }

      if (_isEditMode && mounted) {
        await _loadReceiveData(widget.initialReceiveId!);
      } else if (widget.initialPoId != null && mounted) {
        try {
          setState(() {
            _isLoadingPOs = true;
          });
          // 1. Fetch the Purchase Order detail
          final po = await ref.read(
            purchaseOrderProvider(widget.initialPoId!).future,
          );
          if (po != null && mounted) {
            // 2. Set vendor details from the PO
            setState(() {
              _selectedVendorId = po.vendorId;
              _selectedVendorName = po.vendorName;
            });
            // 3. Fetch POs for that vendor so the dropdown gets populated
            if (po.vendorId.isNotEmpty) {
              await _fetchPOsForVendor(po.vendorId);
            }
            // 4. Select the PO and populate its items
            await _onPOsSelected([po]);
          }
        } catch (e) {
          AppLogger.error(
            'Failed to load initial purchase order for receive',
            error: e,
            module: 'purchases',
          );
        } finally {
          if (mounted) {
            setState(() {
              _isLoadingPOs = false;
            });
          }
        }
      }
    });
  }

  Future<void> _loadReceiveData(String receiveId) async {
    setState(() => _isLoadingData = true);
    try {
      final repository = ref.read(purchaseReceiveRepositoryProvider);
      final receive = await repository.getPurchaseReceive(receiveId);

      if (receive == null) {
        if (mounted) {
          ZerpaiToast.error(context, 'Purchase Receive not found');
          context.pop();
        }
        return;
      }

      await _loadAttachmentsForReceive(receiveId);

      if (!mounted) return;

      // Extract unique PO IDs from the receive items
      final uniquePOIds = receive.items
          .map((i) => i.purchaseOrderId)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      if (uniquePOIds.isEmpty &&
          receive.purchaseOrderId != null &&
          receive.purchaseOrderId!.isNotEmpty) {
        uniquePOIds.add(receive.purchaseOrderId!);
      }

      // Load actual PurchaseOrder objects
      final loadedPOs = <PurchaseOrder>[];
      for (final poId in uniquePOIds) {
        try {
          final po = await ref.read(purchaseOrderProvider(poId).future);
          if (po != null) loadedPOs.add(po);
        } catch (e) {
          AppLogger.warning(
            'Could not load PO $poId for edit flow',
            error: e,
            module: 'purchases',
          );
        }
      }

      if (!mounted) return;

      final poNumbers = loadedPOs.map((p) => p.orderNumber).toList();
      final List<Map<String, dynamic>> loadedBills = [];
      double totalBilledQty = 0.0;
      double totalOrderedQty = 0.0;

      for (final po in loadedPOs) {
        for (final poItem in po.items) {
          totalOrderedQty += poItem.quantity;
        }
      }

      if (poNumbers.isNotEmpty) {
        try {
          final supabase = Supabase.instance.client;
          final orFilter = poNumbers
              .map((poNum) => "order_number.ilike.%${poNum.trim()}%")
              .join(',');
          final response = await supabase
              .from('bills')
              .select(
                'id, bill_number, order_number, status, bill_items(id, product_id, quantity, description, rate, products(id, product_name, image_urls, hsn_code:hsn_sac_code, track_batches, track_serial_number, track_bin_location), bill_item_batches(*, batch:batch_master(*)))',
              )
              .or(orFilter)
              .neq('status', 'void');

          final normalizedPoNumbers = poNumbers
              .map((p) => p.trim().toLowerCase())
              .toSet();

          for (final b in response) {
            final billData = Map<String, dynamic>.from(b as Map);
            final orderNumStr = (billData['order_number'] ?? '')
                .toString()
                .toLowerCase();
            final billPoNumbers = orderNumStr
                .split(',')
                .map((p) => p.trim())
                .toList();
            final hasMatch = billPoNumbers.any(
              (num) => normalizedPoNumbers.contains(num),
            );
            if (!hasMatch) continue;

            final itemsList = billData['bill_items'] as List<dynamic>? ?? [];
            final List<Map<String, dynamic>> billItemsList = [];

            for (final bi in itemsList) {
              final biMap = Map<String, dynamic>.from(bi as Map);
              final productId = biMap['product_id']?.toString() ?? '';
              final qty =
                  double.tryParse(biMap['quantity']?.toString() ?? '0.0') ??
                  0.0;
              totalBilledQty += qty;

              double initialQtyToReceive = qty;
              List<BatchInfo> initialItemBatches = [];
              String? initialBinId;
              String? initialBinLabel;

              double orderedVal = 0.0;
              double receivedVal = 0.0;
              double cancelledVal = 0.0;
              String name =
                  biMap['products']?['product_name'] ??
                  biMap['product']?['product_name'] ??
                  biMap['product']?['name'] ??
                  biMap['product_name'] ??
                  biMap['item_name'] ??
                  '';
              String desc = biMap['description'] ?? '';

              PurchaseOrder? matchedPoForBi;
              PurchaseOrderItem? poItem;
              for (final po in loadedPOs) {
                poItem = po.items
                    .where(
                      (it) =>
                          !it.isHeader &&
                          it.productId == productId &&
                          (it.description ?? '').trim() == desc.trim(),
                    )
                    .firstOrNull;
                if (poItem != null) {
                  matchedPoForBi = po;
                  break;
                }
              }
              if (poItem == null) {
                poItem = loadedPOs.isNotEmpty
                    ? loadedPOs.first.items
                          .where(
                            (it) => !it.isHeader && it.productId == productId,
                          )
                          .firstOrNull
                    : null;
                matchedPoForBi = loadedPOs.isNotEmpty ? loadedPOs.first : null;
              }

              if (poItem != null) {
                orderedVal = poItem.quantity;
                cancelledVal = poItem.cancelledQuantity;
                if (name.isEmpty)
                  name = poItem.productName ?? poItem.itemCode ?? '';
                if (desc.isEmpty) desc = poItem.description ?? '';
              }

              final matchedReceiveItem =
                  receive.items
                      .where(
                        (ri) =>
                            ri.itemId == productId &&
                            (ri.description ?? '').trim() == desc.trim() &&
                            (ri.ordered - orderedVal).abs() < 0.001,
                      )
                      .firstOrNull ??
                  receive.items
                      .where(
                        (ri) =>
                            ri.itemId == productId &&
                            (ri.description ?? '').trim() == desc.trim(),
                      )
                      .firstOrNull ??
                  receive.items.firstWhere(
                    (ri) => ri.itemId == productId,
                    orElse: () => PurchaseReceiveItem(itemId: ''),
                  );

              if (matchedReceiveItem.itemId != null &&
                  matchedReceiveItem.itemId!.isNotEmpty) {
                initialQtyToReceive = matchedReceiveItem.quantityToReceive;
                initialItemBatches = matchedReceiveItem.batches;
                initialBinId = matchedReceiveItem.binId;
                initialBinLabel = matchedReceiveItem.binLabel;
              }

              billItemsList.add({
                'itemId': productId,
                'itemName': name,
                'description': desc,
                'quantityToReceive': initialQtyToReceive,
                'ordered': orderedVal,
                'received': receivedVal,
                'cancelled': cancelledVal,
                'batches': initialItemBatches,
                'purchaseOrderId':
                    matchedPoForBi?.id ??
                    (loadedPOs.isNotEmpty
                        ? loadedPOs.first.id
                        : receive.purchaseOrderId),
                'purchaseOrderNumber':
                    matchedPoForBi?.orderNumber ??
                    (loadedPOs.isNotEmpty
                        ? loadedPOs.first.orderNumber
                        : receive.purchaseOrderNumber),
                'binId': initialBinId,
                'binLabel': initialBinLabel,
              });
            }

            loadedBills.add({
              'id': billData['id']?.toString() ?? '',
              'bill_number': billData['bill_number']?.toString() ?? '',
              'items': billItemsList,
            });
          }
        } catch (billErr) {
          AppLogger.error(
            'Failed to load bills for edit flow',
            error: billErr,
            module: 'purchases',
          );
        }
      }

      setState(() {
        _receiveNumberCtrl.text = receive.purchaseReceiveNumber;
        _receivedDateCtrl.text = receive.receivedDate != null
            ? DateFormat('dd-MM-yyyy').format(receive.receivedDate!)
            : '';
        _billNoCtrl.text = receive.billNo ?? '';
        _billDateCtrl.text = receive.billDate != null
            ? DateFormat('dd-MM-yyyy').format(receive.billDate!)
            : '';
        _invoiceTotalCtrl.text = receive.invoiceTotal.toString();
        _notesCtrl.text = receive.notes ?? '';

        _selectedVendorId = receive.vendorId;
        if ((_selectedVendorId == null || _selectedVendorId!.isEmpty) &&
            loadedPOs.isNotEmpty) {
          _selectedVendorId = loadedPOs.first.vendorId;
        }
        _selectedVendorName = receive.vendorName;
        if ((_selectedVendorName == null || _selectedVendorName!.isEmpty) &&
            loadedPOs.isNotEmpty) {
          _selectedVendorName = loadedPOs.first.vendorName;
        }

        if (loadedPOs.isNotEmpty) {
          _selectedPOs = loadedPOs;
          _selectedPO = loadedPOs.first;
          _selectedPONumber = _selectedPOs.map((p) => p.orderNumber).join(', ');
          _selectedPOId = _selectedPO?.id;
          _vendorPOs = loadedPOs;
        } else if (receive.purchaseOrderId != null &&
            receive.purchaseOrderId!.isNotEmpty) {
          final po = PurchaseOrder(
            id: receive.purchaseOrderId,
            orderNumber: receive.purchaseOrderNumber ?? '',
            orderDate: DateTime.now(),
            vendorId: receive.vendorId ?? '',
            vendorName: receive.vendorName,
          );
          _selectedPOs = [po];
          _selectedPO = po;
          _selectedPONumber = po.orderNumber;
          _selectedPOId = po.id;
          _vendorPOs = [po];
        }

        _binMode = receive.transactionBinLabel != null ? 'transaction' : 'item';
        _selectedTransactionBin = receive.transactionBinLabel;
        _selectedTransactionBinId = receive.transactionBinId;

        // Populate items
        _items.clear();
        _rowControllers.clear();
        _preferredBins.clear();
        _damageControllers.clear();

        for (final item in receive.items) {
          _items.add(item);
          final ctrl = _ReceiveItemRowController();
          final qty = item.batches.isNotEmpty
              ? _sumBatchQuantity(item.batches)
              : item.quantityToReceive;
          final foc = _sumBatchFoc(item.batches);
          ctrl.qtyCtrl.text = _fmtPcs(qty + foc);
          _rowControllers.add(ctrl);
          _preferredBins.add(item.binLabel);
          _damageControllers.add(TextEditingController());
        }

        _associatedBills = loadedBills;
        _hasBills = loadedBills.isNotEmpty;
        _isFullyBilled =
            totalBilledQty >= totalOrderedQty && totalOrderedQty > 0;
        _receiveBilledItems = false;

        for (final bill in loadedBills) {
          final bId = bill['id']?.toString();
          if (bId != null) _expandedBillIds.add(bId);
        }

        _isLoadingData = false;
      });
    } catch (e, st) {
      AppLogger.error(
        'Failed to load purchase receive',
        error: e,
        stackTrace: st,
        module: 'purchases',
      );
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to load purchase receive data');
        context.pop();
      }
    }
  }

  String _generateReceiveNumber() {
    return '$_receiveNumberPrefix${_receiveNextNumber.toString().padLeft(5, '0')}';
  }

  Future<void> _fetchNextNumber() async {
    try {
      final repo = ref.read(purchaseReceiveRepositoryProvider);
      final data = await repo.getNextPurchaseReceiveNumber(
        prefix: _receiveNumberPrefix,
      );
      if (mounted) {
        setState(() {
          _receiveNextNumber = data['nextNumber'] as int? ?? 1;
          _receiveNumberPrefix = data['prefix'] as String? ?? 'PR-';
          if (_isReceiveAutoGenerate) {
            _receiveNumberCtrl.text = data['formatted'] as String? ?? '';
          }
        });
      }
    } catch (e) {
      AppLogger.error(
        'Failed to fetch next receive number',
        error: e,
        module: 'purchases',
      );
    }
  }

  void _showTopError(String message) {
    _dismissTopError();
    final overlay = Overlay.of(context, rootOverlay: true);
    _topErrorOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 14,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEA),
                    border: Border.all(color: const Color(0xFFF5C2C7)),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _dangerRed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          LucideIcons.alertTriangle,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: _dangerRed,
                            fontSize: 13,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _dismissTopError,
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: _dangerRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_topErrorOverlayEntry!);
    _topErrorTimer = Timer(const Duration(seconds: 4), _dismissTopError);
  }

  void _dismissTopError() {
    _topErrorTimer?.cancel();
    _topErrorTimer = null;
    _topErrorOverlayEntry?.remove();
    _topErrorOverlayEntry = null;
  }

  void _showTopSuccess(String message) {
    _dismissTopError();
    final overlay = Overlay.of(context, rootOverlay: true);
    _topErrorOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 14,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    border: Border.all(color: const Color(0xFFCEEAD6)),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22A95E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Color(0xFF137333),
                            fontSize: 13,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _dismissTopError,
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF137333),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_topErrorOverlayEntry!);
    _topErrorTimer = Timer(const Duration(seconds: 4), _dismissTopError);
  }

  void _showPurchaseReceivePreferencesDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _PurchaseReceivePreferencesDialog(
        initialAutoGenerate: _isReceiveAutoGenerate,
        initialPrefix: _receiveNumberPrefix,
        initialNextNumber: _receiveNextNumber,
        onSave: (isAuto, prefix, nextNum) {
          setState(() {
            _isReceiveAutoGenerate = isAuto;
            _receiveNumberPrefix = prefix;
            _receiveNextNumber = nextNum;
            if (_isReceiveAutoGenerate) {
              _receiveNumberCtrl.text = _generateReceiveNumber();
            } else {
              _receiveNumberCtrl.clear();
            }
          });
        },
      ),
    );
  }

  void _removeItem(int index, {bool isFromManual = false}) {
    if (index >= _items.length) return;

    if (isFromManual) {
      final visibleCount = _items
          .asMap()
          .entries
          .where((e) => !_hiddenManualIndices.contains(e.key))
          .length;

      // Enforce: at least one row should be there in both tables
      if (visibleCount <= 1) return;

      final item = _items[index];
      // If it's a PO item (not purely manual), just hide it from the manual view
      if ((item.itemId ?? '').isNotEmpty &&
          index < (_selectedPO?.items.length ?? 0)) {
        setState(() {
          _hiddenManualIndices.add(index);
        });
        return;
      }
    }

    if (_items.length <= 1) return;
    setState(() {
      _items.removeAt(index);
      if (index < _rowControllers.length) {
        _rowControllers[index].dispose();
        _rowControllers.removeAt(index);
        if (index < _preferredBins.length) {
          _preferredBins.removeAt(index);
        }
        if (index < _damageControllers.length) {
          _damageControllers[index].dispose();
          _damageControllers.removeAt(index);
        }
      }
    });
  }

  void _clearAllRows() {
    for (final c in _rowControllers) {
      c.dispose();
    }
    _items.clear();
    _rowControllers.clear();
    _preferredBins.clear();
    for (final c in _damageControllers) {
      c.dispose();
    }
    _damageControllers.clear();
    _billedQtyControllers.forEach((k, c) => c.dispose());
    _billedQtyControllers.clear();
    _rowSelectedWarehouses.clear();
    _rowSelectedViews.clear();
  }

  void _insertManualRow() {
    setState(() {
      _items.add(PurchaseReceiveItem());
      _rowControllers.add(_ReceiveItemRowController());
      _preferredBins.add(null);
      _damageControllers.add(TextEditingController());
    });
  }

  Future<void> _pickFiles() async {
    if (_uploadedFiles.length >= _maxUploadFiles) {
      _showTopError('You can upload only a maximum of 5 files');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final files = result.files;

    if (_uploadedFiles.length + files.length > _maxUploadFiles) {
      _showTopError('You can upload only a maximum of 5 files');
      return;
    }

    for (final file in files) {
      if (file.size > _maxUploadFileSizeBytes) {
        _showTopError('File exceeds 10MB');
        return;
      }
    }
    setState(() {
      _uploadedFiles.addAll(files);
    });

    AppLogger.info(
      'Files attached to purchase receive',
      module: 'purchases',
      data: {'count': _uploadedFiles.length},
    );
  }

  Future<void> _saveAttachments(String receiveId) async {
    try {
      final supabase = Supabase.instance.client;
      final apiClient = ApiClient();

      for (var file in _uploadedFiles) {
        if (file.bytes == null) {
          AppLogger.info(
            'Skipping file ${file.name} because bytes are null (already uploaded)',
            module: 'purchases',
          );
          continue;
        }

        final base64Data = base64Encode(file.bytes!);

        // Upload to Cloudflare R2 via backend
        final response = await apiClient.post(
          '/lookups/uploads',
          data: {
            'fileName': file.name,
            'fileData': base64Data,
            'mimeType': 'application/octet-stream',
            'prefix': 'purchase_receives',
          },
        );

        final fileKey =
            response.data['fileKey'] ?? 'purchase_receives/${file.name}';

        final double sizeInKb = file.size / 1024;
        final String formattedSize = sizeInKb >= 1024
            ? '${(sizeInKb / 1024).toStringAsFixed(2)} MB'
            : '${sizeInKb.toStringAsFixed(2)} KB';

        await supabase.from('purchase_receive_attachments').insert({
          'purchase_receive_id': receiveId,
          'file_name': file.name,
          'file_path': fileKey,
          'file_size': formattedSize,
          'file_type': file.extension,
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error saving attachments',
        error: e,
        module: 'purchases',
      );
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to save attachments: $e');
      }
    }
  }

  Future<void> _loadAttachmentsForReceive(String receiveId) async {
    try {
      final supabase = Supabase.instance.client;
      final attachmentsData = await supabase
          .from('purchase_receive_attachments')
          .select()
          .eq('purchase_receive_id', receiveId);

      if (mounted) {
        setState(() {
          _uploadedFiles.clear();
          _uploadedFiles.addAll(
            (attachmentsData as List).map<PlatformFile>((row) {
              final sizeVal = row['file_size'];
              int parsedSize = 0;
              if (sizeVal is int) {
                parsedSize = sizeVal;
              } else if (sizeVal is String) {
                parsedSize =
                    int.tryParse(sizeVal.replaceAll(RegExp(r'[^0-9]'), '')) ??
                    0;
              }
              return PlatformFile(
                name: row['file_name'] ?? '',
                size: parsedSize,
              );
            }),
          );
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error loading attachments',
        error: e,
        module: 'purchases',
      );
    }
  }

  Future<void> _deleteAttachmentFromDb(String fileName) async {
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('purchase_receive_attachments')
          .select('id, file_path')
          .eq('purchase_receive_id', widget.initialReceiveId!)
          .eq('file_name', fileName)
          .maybeSingle();

      if (res != null) {
        final id = res['id'];
        final filePath = res['file_path']?.toString();

        if (filePath != null) {
          final apiClient = ApiClient();
          await apiClient.delete(
            '/lookups/uploads',
            data: {'fileKey': filePath},
          );
        }

        await supabase
            .from('purchase_receive_attachments')
            .delete()
            .eq('id', id);

        AppLogger.info(
          'Attachment $fileName deleted from database',
          module: 'purchases',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Failed to delete attachment from db',
        error: e,
        module: 'purchases',
      );
    }
  }

  @override
  void dispose() {
    _closeVendorSidebar();
    _dismissTopError();
    _uploadOverlay?.remove();
    _uploadOverlay = null;
    _attachmentListOverlay?.remove();
    _attachmentListOverlay = null;
    _attachmentListScrollController.dispose();
    _receiveNumberCtrl.dispose();
    _receivedDateCtrl.dispose();
    _billNoCtrl.dispose();
    _billDateCtrl.dispose();
    _invoiceTotalCtrl.dispose();
    _notesCtrl.dispose();
    _itemDetailsSearchCtrl.dispose();
    for (final c in _damageControllers) {
      c.dispose();
    }
    for (var c in _rowControllers) {
      c.dispose();
    }
    _billedQtyControllers.forEach((k, c) => c.dispose());
    _billedQtyControllers.clear();
    _valueTooltipOverlay?.remove();
    _valueTooltipOverlay = null;
    super.dispose();
  }

  Future<void> _openEditQuantityDialog(int index) async {
    final item = _items[index];
    final poId = item.purchaseOrderId ?? _selectedPOId;
    final poNum = item.purchaseOrderNumber ?? _selectedPONumber ?? '';

    Map<String, dynamic>? initialBill;
    Map<String, dynamic>? initialBillItem;
    for (final bill in _associatedBills) {
      final billItems = bill['items'] as List<dynamic>? ?? [];
      final itemInBill = billItems
          .where((bi) => bi['itemId'] == item.itemId)
          .firstOrNull;
      if (itemInBill != null) {
        final qty =
            double.tryParse(
              itemInBill['quantityToReceive']?.toString() ?? '0.0',
            ) ??
            0.0;
        if (qty > 0) {
          initialBill = bill;
          initialBillItem = itemInBill;
          break;
        }
      }
    }
    if (initialBill == null) {
      for (final bill in _associatedBills) {
        final billItems = bill['items'] as List<dynamic>? ?? [];
        final itemInBill = billItems
            .where((bi) => bi['itemId'] == item.itemId)
            .firstOrNull;
        if (itemInBill != null) {
          initialBill = bill;
          initialBillItem = itemInBill;
          break;
        }
      }
    }

    final result = await showDialog<QuantitySplitResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return EditQuantityDialog(
          itemName: item.itemName,
          productId: item.itemId ?? '',
          currentUnreceivedAllocated: item.quantityToReceive,
          isReceiveMode: true,
          poId: poId,
          poNum: poNum,
          vendorId: _selectedVendorId,
          billId: widget.initialReceiveId,
          initialPurchaseReceiveId: initialBill?['id']?.toString(),
          initialPurchaseReceiveNumber: initialBill?['bill_number']?.toString(),
          initialPurchaseReceiveQty:
              double.tryParse(
                initialBillItem?['quantityToReceive']?.toString() ?? '0.0',
              ) ??
              0.0,
          initialPurchaseReceiveItemId: initialBillItem?['id']?.toString(),
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        item.quantityToReceive = result.unreceivedQuantity;
        _rowControllers[index].qtyCtrl.text = result.unreceivedQuantity % 1 == 0
            ? result.unreceivedQuantity.toInt().toString()
            : result.unreceivedQuantity.toString();

        for (final split in result.receiveSplits) {
          final billMap = split.receive;
          final billId = billMap['id']?.toString();
          if (billId == null) continue;

          final associatedBillIndex = _associatedBills.indexWhere(
            (b) => b['id']?.toString() == billId,
          );
          if (associatedBillIndex != -1) {
            final associatedBill = _associatedBills[associatedBillIndex];
            final billItems = associatedBill['items'] as List<dynamic>? ?? [];
            final itemInBillIndex = billItems.indexWhere(
              (bi) => bi['itemId'] == item.itemId,
            );
            if (itemInBillIndex != -1) {
              final itemInBill = Map<String, dynamic>.from(
                billItems[itemInBillIndex],
              );
              itemInBill['quantityToReceive'] = split.quantity;
              billItems[itemInBillIndex] = itemInBill;

              final ctrlKey = "${billId}_${item.itemId}";
              if (_billedQtyControllers.containsKey(ctrlKey)) {
                _billedQtyControllers[ctrlKey]!.text = split.quantity % 1 == 0
                    ? split.quantity.toInt().toString()
                    : split.quantity.toString();
              } else {
                _billedQtyControllers[ctrlKey] = TextEditingController(
                  text: split.quantity % 1 == 0
                      ? split.quantity.toInt().toString()
                      : split.quantity.toString(),
                );
              }
            }
          }
        }
        _receiveBilledItems = true;
      });
    }
  }

  Future<void> _openEditQuantityDialogFromBilled(
    int billIndex,
    int itemIndex,
  ) async {
    final bill = _associatedBills[billIndex];
    final itemMap = Map<String, dynamic>.from(bill['items'][itemIndex]);
    final productId = itemMap['itemId']?.toString() ?? '';
    final itemName = itemMap['itemName']?.toString() ?? '';

    int normalItemIndex = _items.indexWhere((it) => it.itemId == productId);
    double currentUnbilled = 0.0;
    if (normalItemIndex != -1) {
      currentUnbilled = _items[normalItemIndex].quantityToReceive;
    }

    final result = await showDialog<QuantitySplitResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return EditQuantityDialog(
          itemName: itemName,
          productId: productId,
          currentUnreceivedAllocated: currentUnbilled,
          isReceiveMode: true,
          poId: itemMap['purchaseOrderId'] ?? _selectedPOId,
          poNum: itemMap['purchaseOrderNumber'] ?? _selectedPONumber ?? '',
          vendorId: _selectedVendorId,
          billId: widget.initialReceiveId,
          initialPurchaseReceiveId: bill['id']?.toString(),
          initialPurchaseReceiveNumber: bill['bill_number']?.toString(),
          initialPurchaseReceiveQty:
              double.tryParse(
                itemMap['quantityToReceive']?.toString() ?? '0.0',
              ) ??
              0.0,
          initialPurchaseReceiveItemId: itemMap['id']?.toString(),
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        if (normalItemIndex != -1) {
          _items[normalItemIndex].quantityToReceive = result.unreceivedQuantity;
          _rowControllers[normalItemIndex].qtyCtrl.text =
              result.unreceivedQuantity % 1 == 0
              ? result.unreceivedQuantity.toInt().toString()
              : result.unreceivedQuantity.toString();
        }

        for (var b in _associatedBills) {
          final itemsList = b['items'] as List<dynamic>? ?? [];
          for (int i = 0; i < itemsList.length; i++) {
            final bi = Map<String, dynamic>.from(itemsList[i]);
            if (bi['itemId'] == productId) {
              bi['quantityToReceive'] = 0.0;
              itemsList[i] = bi;
              final ctrlKey = "${b['id']}_$productId";
              if (_billedQtyControllers.containsKey(ctrlKey)) {
                _billedQtyControllers[ctrlKey]!.text = '0';
              }
            }
          }
        }

        for (final split in result.receiveSplits) {
          final billMap = split.receive;
          final billId = billMap['id']?.toString();
          if (billId == null) continue;

          final associatedBillIndex = _associatedBills.indexWhere(
            (b) => b['id']?.toString() == billId,
          );
          if (associatedBillIndex != -1) {
            final associatedBill = _associatedBills[associatedBillIndex];
            final billItems = associatedBill['items'] as List<dynamic>? ?? [];
            final itemInBillIndex = billItems.indexWhere(
              (bi) => bi['itemId'] == productId,
            );
            if (itemInBillIndex != -1) {
              final itemInBill = Map<String, dynamic>.from(
                billItems[itemInBillIndex],
              );
              itemInBill['quantityToReceive'] = split.quantity;
              billItems[itemInBillIndex] = itemInBill;

              final ctrlKey = "${billId}_$productId";
              if (_billedQtyControllers.containsKey(ctrlKey)) {
                _billedQtyControllers[ctrlKey]!.text = split.quantity % 1 == 0
                    ? split.quantity.toInt().toString()
                    : split.quantity.toString();
              }
            }
          }
        }
      });
    }
  }

  void _switchToManualMode() {
    final nextIsManual = !_isManualMode;

    final hasPersistedRows = _items.any(
      (item) =>
          (item.itemId?.isNotEmpty ?? false) ||
          item.itemName.isNotEmpty ||
          item.batches.isNotEmpty ||
          item.ordered > 0 ||
          item.quantityToReceive > 0,
    );

    setState(() {
      _isManualMode = nextIsManual;

      if (_isManualMode) {
        // Preserve existing rows (including batches) when switching to manual.
        if (_items.isEmpty) {
          _items.add(PurchaseReceiveItem());
          _rowControllers.add(_ReceiveItemRowController());
          _preferredBins.add(null);
          _damageControllers.add(TextEditingController());
        }
      }
    });

    // Switching back to PO mode should keep existing rows/batches.
    // Only repopulate from PO when there is nothing meaningful to show.
    if (!nextIsManual && !hasPersistedRows && _selectedPOs.isNotEmpty) {
      _onPOsSelected(_selectedPOs);
    }
  }

  void _addAllItemsFromPO() {
    if (_selectedPOs.isEmpty) {
      _showTopError("Please select a Purchase Order first.");
      return;
    }
    setState(() {
      _clearAllRows();
      for (final po in _selectedPOs) {
        _populateRowsFromPO(po);
      }
    });
  }

  bool get _hasValidSelection =>
      _isEditMode ||
      (_selectedVendorName != null &&
          _selectedVendorName!.isNotEmpty &&
          _selectedPOs.isNotEmpty);

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: true,
      useHorizontalPadding: false,
      useTopPadding: false,
      footer: _buildStickyFooter(),
      child: Skeletonizer(
        enabled: _isLoadingData,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Close Button ──
            _buildHeader(),
            const SizedBox(height: 8),
            // ── Vendor/PO (left) + Detail fields (right) ──
            _buildFormSection(),
            const SizedBox(height: 20),
            // ── Dependent Sections (Disabled without PO) ──
            Opacity(
              opacity: (_isLoadingData || _hasValidSelection) ? 1.0 : 0.5,
              child: IgnorePointer(
                ignoring: _isLoadingData || !_hasValidSelection,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildReceiveModeRadioButtons(),
                    if (!_receiveBilledItems) ...[
                      _buildInfoBanner(),
                      const SizedBox(height: 20),
                      _buildBinSelectionSection(),
                      const SizedBox(height: 24),
                    ] else ...[
                      const SizedBox(height: 8),
                    ],
                    // ── Items Table ──
                    _buildItemsTable(),
                    const SizedBox(height: 32),
                    // ── Notes & Upload ──
                    _buildNotesAndUploadSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER (Title + Close)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          const Icon(LucideIcons.package, size: 22, color: _textPrimary),
          const SizedBox(width: 10),
          Text(
            _isEditMode ? 'Edit Purchase Receive' : 'New Purchase Receive',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              if (widget.initialPoId != null &&
                  widget.initialPoId!.isNotEmpty) {
                context.go('/purchases/purchase-orders/${widget.initialPoId}');
              } else {
                context.go('/purchases/purchase-receives');
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 20, color: _hintColor),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SELECTION DIALOGS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _fetchPOsForVendor(String vendorId) async {
    setState(() {
      _isLoadingPOs = true;
      _vendorPOs.clear();
      _selectedPOs.clear();
      _selectedPO = null;
      _selectedPONumber = null;
      _selectedPOId = null;

      _clearAllRows();
    });

    try {
      final pos = await ref.read(
        purchaseOrdersProvider(
          PurchaseOrderFilter(limit: 500, vendorId: vendorId),
        ).future,
      );

      final filtered = pos
          .where(
            (po) =>
                po.vendorId == vendorId &&
                (po.receiveStatus ?? '').toLowerCase() != 'full' &&
                po.status.toLowerCase() != 'draft' &&
                po.status.toLowerCase() != 'drft',
          )
          .toList();
      if (mounted) {
        setState(() {
          _vendorPOs = filtered;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Failed to load purchase orders',
        error: e,
        module: 'purchases',
      );
    } finally {
      if (mounted) setState(() => _isLoadingPOs = false);
    }
  }

  Future<void> _onPOsSelected(List<PurchaseOrder> pos) async {
    setState(() {
      _selectedPOs = pos;
      _selectedPO = pos.isNotEmpty ? pos.first : null;
      _selectedPONumber = pos.map((p) => p.orderNumber).join(', ');
      _selectedPOId = pos.isNotEmpty ? pos.first.id : null;
      _isManualMode = false;
      _isLoadingPOs = true;
    });

    try {
      final Map<String, double> tempReceived = {};
      final List<PurchaseReceiveItem> newItems = [];
      final List<_ReceiveItemRowController> newRowControllers = [];
      final List<String?> newPreferredBins = [];
      final List<TextEditingController> newDamageControllers = [];
      double totalOrderedQty = 0.0;
      final List<PurchaseOrder> detailedPOs = [];

      for (final po in pos) {
        final poId = po.id?.trim();
        final isValidPoId =
            poId != null &&
            RegExp(
              r'^[0-9a-fA-F]{8}-'
              r'[0-9a-fA-F]{4}-'
              r'[0-9a-fA-F]{4}-'
              r'[0-9a-fA-F]{4}-'
              r'[0-9a-fA-F]{12}$',
            ).hasMatch(poId);

        final shouldFetchDetails = isValidPoId && po.items.isEmpty;
        final fullPO = shouldFetchDetails
            ? await ref.read(purchaseOrderProvider(poId).future)
            : po;

        if (isValidPoId) {
          try {
            final supabase = Supabase.instance.client;
            final response = await supabase
                .from('purchase_receives')
                .select(
                  'id, status, purchase_receive_items(item_id, received, quantity_to_receive, ordered, description, purchase_receive_item_batches(quantity))',
                )
                .eq('purchase_order_id', poId)
                .eq('is_delete', false)
                .eq('status', 'received');

            for (final r in response) {
              final itemsList =
                  r['purchase_receive_items'] as List<dynamic>? ?? [];
              for (final recItem in itemsList) {
                final productId = recItem['item_id']?.toString() ?? '';
                if (productId.isEmpty) continue;

                double itemRecQty = 0.0;
                final batches =
                    recItem['purchase_receive_item_batches']
                        as List<dynamic>? ??
                    [];
                if (batches.isNotEmpty) {
                  for (final b in batches) {
                    itemRecQty +=
                        double.tryParse(b['quantity']?.toString() ?? '0.0') ??
                        0.0;
                  }
                } else {
                  itemRecQty +=
                      double.tryParse(
                        recItem['quantity_to_receive']?.toString() ??
                            recItem['received']?.toString() ??
                            '0.0',
                      ) ??
                      0.0;
                }
                final double ordered =
                    double.tryParse(recItem['ordered']?.toString() ?? '0.0') ??
                    0.0;
                final String desc = recItem['description']?.toString() ?? '';
                final String compositeKey =
                    '${productId}_${ordered.toStringAsFixed(4)}_${desc.trim()}';
                tempReceived[compositeKey] =
                    (tempReceived[compositeKey] ?? 0.0) + itemRecQty;
                tempReceived[productId] =
                    (tempReceived[productId] ?? 0.0) + itemRecQty;
              }
            }
          } catch (dbErr) {
            AppLogger.error(
              'Failed to load existing purchase receives for received quantities mapping',
              error: dbErr,
              module: 'purchases',
            );
          }
        }

        final activePO = fullPO ?? po;
        detailedPOs.add(activePO);
        for (final poItem in activePO.items) {
          totalOrderedQty += poItem.quantity;
          final String compositeKey =
              '${poItem.productId}_${poItem.quantity.toStringAsFixed(4)}_${(poItem.description ?? '').trim()}';
          final recQty =
              tempReceived[compositeKey] ??
              tempReceived[poItem.productId] ??
              0.0;
          newItems.add(
            PurchaseReceiveItem(
              itemId: poItem.productId,
              itemName: poItem.productName ?? poItem.itemCode ?? "",
              description: poItem.description,
              ordered: poItem.quantity,
              received: recQty,
              inTransit: 0,
              cancelled: poItem.cancelledQuantity,
              quantityToReceive: 0,
              purchaseOrderId: po.id,
              purchaseOrderNumber: po.orderNumber,
            ),
          );
          final controller = _ReceiveItemRowController();
          controller.qtyCtrl.text = '0';
          newRowControllers.add(controller);
          newPreferredBins.add(null);
          newDamageControllers.add(TextEditingController());
        }
      }

      final poNumbers = pos.map((po) => po.orderNumber).toList();
      final List<Map<String, dynamic>> loadedBills = [];
      double totalBilledQty = 0.0;

      if (poNumbers.isNotEmpty) {
        try {
          final targetWarehouseId =
              pos.first.warehouseId?.trim() ??
              pos.first.deliveryWarehouseId?.trim();
          List<Map<String, dynamic>> binsList = [];
          if (targetWarehouseId != null && targetWarehouseId.isNotEmpty) {
            try {
              final rawBins = await ref.read(
                binsLookupProvider(targetWarehouseId).future,
              );
              binsList = rawBins
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
            } catch (_) {}
          }

          final supabase = Supabase.instance.client;
          final orFilter = poNumbers
              .map((poNum) => "order_number.ilike.%${poNum.trim()}%")
              .join(',');
          final response = await supabase
              .from('bills')
              .select(
                'id, bill_number, order_number, status, bill_items(id, product_id, quantity, description, rate, products(id, product_name, image_urls, hsn_code:hsn_sac_code, track_batches, track_serial_number, track_bin_location), bill_item_batches(*, batch:batch_master(*)))',
              )
              .or(orFilter)
              .neq('status', 'void');

          final normalizedPoNumbers = poNumbers
              .map((p) => p.trim().toLowerCase())
              .toSet();

          for (final b in response) {
            final billData = Map<String, dynamic>.from(b as Map);
            final orderNumStr = (billData['order_number'] ?? '')
                .toString()
                .toLowerCase();
            final billPoNumbers = orderNumStr
                .split(',')
                .map((p) => p.trim())
                .toList();
            final hasMatch = billPoNumbers.any(
              (num) => normalizedPoNumbers.contains(num),
            );
            if (!hasMatch) continue;

            final itemsList = billData['bill_items'] as List<dynamic>? ?? [];
            final List<Map<String, dynamic>> billItemsList = [];

            PurchaseOrder? matchingPo;
            for (final p in pos) {
              final normOrderNum = p.orderNumber.trim().toLowerCase();
              if (billPoNumbers.contains(normOrderNum)) {
                matchingPo = p;
                break;
              }
            }
            final String? matchedPoId =
                matchingPo?.id ?? (pos.isNotEmpty ? pos.first.id : null);
            final String matchedPoNumber =
                matchingPo?.orderNumber ??
                (pos.isNotEmpty
                    ? pos.first.orderNumber
                    : (billData['order_number']?.toString() ?? ''));

            for (final bi in itemsList) {
              final biMap = Map<String, dynamic>.from(bi as Map);
              final productId = biMap['product_id']?.toString() ?? '';
              final qty =
                  double.tryParse(biMap['quantity']?.toString() ?? '0.0') ??
                  0.0;
              totalBilledQty += qty;

              double orderedVal = 0.0;
              double receivedVal = 0.0;
              double cancelledVal = 0.0;
              String name =
                  biMap['products']?['product_name'] ??
                  biMap['product']?['product_name'] ??
                  biMap['product']?['name'] ??
                  biMap['product_name'] ??
                  biMap['item_name'] ??
                  '';
              String desc = biMap['description'] ?? '';

              final targetPo =
                  matchingPo ?? (pos.isNotEmpty ? pos.first : null);
              if (targetPo != null) {
                PurchaseOrderItem? poItem = targetPo.items
                    .where(
                      (it) =>
                          !it.isHeader &&
                          it.productId == productId &&
                          (it.description ?? '').trim() == desc.trim(),
                    )
                    .firstOrNull;
                poItem ??= targetPo.items.firstWhere(
                  (it) => !it.isHeader && it.productId == productId,
                  orElse: () => PurchaseOrderItem(
                    productId: '',
                    quantity: 0.0,
                    rate: 0.0,
                    amount: 0.0,
                  ),
                );

                if (poItem.productId.isNotEmpty) {
                  orderedVal = poItem.quantity;
                  final String compositeKey =
                      '${poItem.productId}_${poItem.quantity.toStringAsFixed(4)}_${(poItem.description ?? '').trim()}';
                  receivedVal =
                      tempReceived[compositeKey] ??
                      tempReceived[productId] ??
                      0.0;
                  cancelledVal = poItem.cancelledQuantity;
                  if (name.isEmpty)
                    name = poItem.productName ?? poItem.itemCode ?? '';
                  if (desc.isEmpty) desc = poItem.description ?? '';
                }
              }

              final List<BatchInfo> itemBatches = [];
              final bibList =
                  biMap['bill_item_batches'] as List<dynamic>? ?? [];
              for (final bib in bibList) {
                final bibMap = Map<String, dynamic>.from(bib as Map);
                final batchMap = bibMap['batch'] != null
                    ? Map<String, dynamic>.from(bibMap['batch'] as Map)
                    : null;
                final String batchNo =
                    batchMap?['batch_no']?.toString() ??
                    bibMap['manufacture_batch_no']?.toString() ??
                    '';
                final double qtyVal =
                    double.tryParse(bibMap['quantity']?.toString() ?? '0.0') ??
                    0.0;
                final double focVal =
                    double.tryParse(
                      bibMap['foc_quantity']?.toString() ?? '0.0',
                    ) ??
                    0.0;
                final double mrpVal =
                    double.tryParse(bibMap['mrp']?.toString() ?? '0.0') ?? 0.0;
                final double ptrVal =
                    double.tryParse(
                      bibMap['purchase_rate']?.toString() ?? '0.0',
                    ) ??
                    0.0;
                final String mfgBatch =
                    bibMap['manufacture_batch_no']?.toString() ?? '';
                final String? binIdVal = bibMap['bin_id']?.toString();

                DateTime? mfgD;
                if (bibMap['manufacture_date'] != null) {
                  mfgD = DateTime.tryParse(
                    bibMap['manufacture_date'].toString(),
                  );
                }
                DateTime? expD;
                if (bibMap['expiry_date'] != null) {
                  expD = DateTime.tryParse(bibMap['expiry_date'].toString());
                }

                final matchedBin = binsList.firstWhere(
                  (b) => b['id'] == binIdVal,
                  orElse: () => <String, dynamic>{},
                );
                final String? binLabelVal = matchedBin.isNotEmpty
                    ? matchedBin['bin_code']?.toString()
                    : null;

                itemBatches.add(
                  BatchInfo(
                    batchNo: batchNo,
                    unitPack: bibMap['unit_pack']?.toString() ?? '',
                    mrp: mrpVal,
                    ptr: ptrVal,
                    quantity: qtyVal,
                    foc: focVal,
                    manufactureBatch: mfgBatch,
                    manufactureDate: mfgD,
                    expiryDate: expD,
                    binId: binIdVal,
                    binLabel: binLabelVal,
                  ),
                );
              }

              billItemsList.add({
                'itemId': productId,
                'itemName': name,
                'description': desc,
                'quantityToReceive': qty,
                'ordered': orderedVal,
                'received': receivedVal,
                'cancelled': cancelledVal,
                'batches': itemBatches,
                'purchaseOrderId': matchedPoId,
                'purchaseOrderNumber': matchedPoNumber,
                'binId': null,
                'binLabel': null,
              });
            }

            loadedBills.add({
              'id': billData['id']?.toString() ?? '',
              'bill_number': billData['bill_number']?.toString() ?? '',
              'items': billItemsList,
            });
          }
        } catch (billErr) {
          AppLogger.error(
            'Failed to load bills for selected POs',
            error: billErr,
            module: 'purchases',
          );
        }
      }

      setState(() {
        _selectedPOs = detailedPOs;
        _selectedPO = detailedPOs.isNotEmpty ? detailedPOs.first : null;
        _selectedPOId = _selectedPO?.id;
        _receivedQuantities.clear();
        _receivedQuantities.addAll(tempReceived);
        _isLoadingPOs = false;
        _clearAllRows();
        _items.addAll(newItems);
        _rowControllers.addAll(newRowControllers);
        _preferredBins.addAll(newPreferredBins);
        _damageControllers.addAll(newDamageControllers);

        _associatedBills = loadedBills;
        _hasBills = loadedBills.isNotEmpty;
        if (_hasBills) {
          _isFullyBilled =
              totalBilledQty >= totalOrderedQty && totalOrderedQty > 0;
          if (_isFullyBilled) {
            _receiveBilledItems = true;
          } else {
            _receiveBilledItems =
                false; // Toggleable, defaults to unbilled normal table
          }
        } else {
          _isFullyBilled = false;
          _receiveBilledItems = false;
        }
      });
    } catch (e) {
      AppLogger.error(
        "Failed to load purchase order details",
        error: e,
        module: "purchases",
      );
      if (mounted) {
        setState(() {
          _isLoadingPOs = false;
          _clearAllRows();
          for (final po in pos) {
            _populateRowsFromPO(po);
          }
        });
      }
    }
  }

  void _populateRowsFromPO(PurchaseOrder? po) {
    if (po == null || po.items.isEmpty) return;
    for (final poItem in po.items) {
      final String compositeKey =
          '${poItem.productId}_${poItem.quantity.toStringAsFixed(4)}_${(poItem.description ?? '').trim()}';
      final recQty =
          _receivedQuantities[compositeKey] ??
          _receivedQuantities[poItem.productId] ??
          0.0;
      _items.add(
        PurchaseReceiveItem(
          itemId: poItem.productId,
          itemName: poItem.productName ?? poItem.itemCode ?? "",
          description: poItem.description,
          ordered: poItem.quantity,
          received: recQty,
          inTransit: 0,
          cancelled: poItem.cancelledQuantity,
          quantityToReceive: 0,
          purchaseOrderId: po.id,
          purchaseOrderNumber: po.orderNumber,
        ),
      );
      final controller = _ReceiveItemRowController();
      controller.qtyCtrl.text = '0';
      _rowControllers.add(controller);
      _preferredBins.add(null);
      _damageControllers.add(TextEditingController());
    }
  }

  Widget _buildFormSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    var selectedVendor = ref
                        .watch(vendorProvider)
                        .vendors
                        .firstWhere(
                          (v) => v.id == _selectedVendorId,
                          orElse: () => Vendor(id: '', displayName: ''),
                        );
                    if (selectedVendor.id.isEmpty &&
                        _selectedVendorName != null &&
                        _selectedVendorName!.isNotEmpty) {
                      final matched = ref
                          .watch(vendorProvider)
                          .vendors
                          .firstWhere(
                            (v) =>
                                v.displayName.toLowerCase() ==
                                _selectedVendorName!.toLowerCase(),
                            orElse: () => Vendor(id: '', displayName: ''),
                          );
                      if (matched.id.isNotEmpty) {
                        selectedVendor = matched;
                      } else {
                        selectedVendor = Vendor(
                          id: _selectedVendorId ?? '',
                          displayName: _selectedVendorName!,
                        );
                      }
                    }
                    final hasVendor = selectedVendor.id.isNotEmpty;
                    final hasDisplayName =
                        selectedVendor.displayName.isNotEmpty;
                    return _buildFormRow(
                      label: "Vendor Name",
                      isRequired: true,
                      child: Expanded(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 450,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: FormDropdown<Vendor>(
                                      height: 32,
                                      itemHeight: 56.0,
                                      enabled: !_isEditMode,
                                      fillColor: _isEditMode
                                          ? const Color(0xFFF1F5F9)
                                          : Colors.white,
                                      value: hasDisplayName ? selectedVendor : null,
                                      textStyle: TextStyle(
                                        fontSize: 13,
                                        fontWeight: hasDisplayName
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: hasDisplayName
                                            ? _textPrimary
                                            : _hintColor,
                                      ),
                                      items: ref.watch(vendorProvider).vendors,
                                      hint: "Select or type to search",
                                      showSearch: true,
                                      allowClear: hasDisplayName && !_isEditMode,
                                      menuWidth: 450,
                                      onChanged: (vendor) {
                                        if (vendor != null) {
                                          setState(() {
                                            _selectedVendorId = vendor.id;
                                            _selectedVendorName = vendor.displayName;
                                          });
                                          _fetchPOsForVendor(vendor.id);
                                        } else {
                                          setState(() {
                                            _selectedVendorId = null;
                                            _selectedVendorName = null;
                                          });
                                        }
                                      },
                                      showSettings: false,
                                      displayStringForValue: (v) => v.displayName,
                                      itemBuilder: (v, isSelected, isHovered) =>
                                          _buildVendorDropdownItem(
                                            v,
                                            isSelected,
                                            isHovered,
                                          ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        bottomLeft: Radius.circular(4),
                                      ),
                                      showRightBorder: true,
                                      border: Border.all(color: _fieldBorder),
                                    ),
                                  ),
                                  Container(
                                    height: 32,
                                    width: 32,
                                    decoration: BoxDecoration(
                                      color: _isEditMode
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF10B981),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(4),
                                        bottomRight: Radius.circular(4),
                                      ),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        LucideIcons.search,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      onPressed: () => _showAdvancedSearch(
                                        ref.read(vendorProvider).vendors,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasVendor) ...[
                              const Spacer(),
                              // Vendor card button on the right
                              GestureDetector(
                                onTap: () => _showVendorSidebar(selectedVendor),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF475569),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        selectedVendor.displayName.length > 20
                                            ? '${selectedVendor.displayName.substring(0, 20)}...'
                                            : selectedVendor.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildFormRow(
                  label: "Purchase Order#",
                  labelColor: _dangerRed,
                  child: SizedBox(
                    width: 450,
                    child: FormDropdown<PurchaseOrder>(
                      height: 32,
                      enabled: !_isEditMode,
                      fillColor: _isEditMode
                          ? const Color(0xFFF1F5F9)
                          : Colors.white,
                      menuWidth: 450,
                      itemHeight: 60.0,
                      multiSelect: true,
                      selectedValues: _selectedPOs,
                      hideSelectedItemsInMultiSelect: true,
                      value: null,
                      items: _vendorPOs,
                      hint: _selectedVendorId == null
                          ? "Select a vendor first"
                          : (_vendorPOs.isEmpty && !_isLoadingPOs
                                ? "No POs found"
                                : "Select Purchase Orders"),
                      showSearch: true,
                      isLoading: _isLoadingPOs,
                      displayStringForValue: (po) => po.orderNumber,
                      searchStringForValue: (po) =>
                          "${po.orderNumber} ${DateFormat("dd-MM-yyyy").format(po.orderDate)}",
                      itemBuilder: (po, isSelected, isHovered) {
                        final showHover = isHovered;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          constraints: const BoxConstraints(minHeight: 60),
                          decoration: BoxDecoration(
                            color: showHover
                                ? const Color(0xFF3B82F6)
                                : (isSelected
                                      ? const Color(0xFFF3F4F6)
                                      : Colors.white),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      po.orderNumber,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: "Inter",
                                        fontWeight: FontWeight.w500,
                                        color: showHover
                                            ? Colors.white
                                            : _textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Date: ${DateFormat("dd-MM-yyyy").format(po.orderDate)} | Total: ₹${po.total.toStringAsFixed(2)}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFamily: "Inter",
                                        color: showHover
                                            ? const Color(0xFFEAF2FF)
                                            : _hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  LucideIcons.check,
                                  size: 16,
                                  color: showHover ? Colors.white : _linkBlue,
                                ),
                            ],
                          ),
                        );
                      },
                      onChanged: (_) {},
                      onSelectedValuesChanged: (pos) {
                        _onPOsSelected(pos);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Opacity(
                  opacity: _hasValidSelection ? 1.0 : 0.5,
                  child: IgnorePointer(
                    ignoring: !_hasValidSelection,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormRow(
                              label: "Bill no#",
                              isRequired: true,
                              child: SizedBox(
                                width: 180,
                                child: SizedBox(
                                  height: 32,
                                  child: MouseRegion(
                                    onEnter: (_) => setState(
                                      () => _hoveredFormFields.add('billNo'),
                                    ),
                                    onExit: (_) => setState(
                                      () => _hoveredFormFields.remove('billNo'),
                                    ),
                                    child: Focus(
                                      onFocusChange: (focus) => setState(() {
                                        if (focus) {
                                          _focusedFormFields.add('billNo');
                                        } else {
                                          _focusedFormFields.remove('billNo');
                                        }
                                      }),
                                      child: TextField(
                                        controller: _billNoCtrl,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r"[a-zA-Z0-9]"),
                                          ),
                                        ],
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: _textPrimary,
                                          fontFamily: "Inter",
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          filled: true,
                                          fillColor: _hasValidSelection
                                              ? _bgWhite
                                              : const Color(0xFFF5F5F5),
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                10,
                                                8,
                                                10,
                                                8,
                                              ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  (_hoveredFormFields.contains(
                                                        'billNo',
                                                      ) ||
                                                      _focusedFormFields
                                                          .contains('billNo'))
                                                  ? const Color(0xFF3B82F6)
                                                  : _fieldBorder,
                                              width:
                                                  (_hoveredFormFields.contains(
                                                        'billNo',
                                                      ) ||
                                                      _focusedFormFields
                                                          .contains('billNo'))
                                                  ? 1.5
                                                  : 1.0,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFF3B82F6),
                                              width: 1.5,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildFormRow(
                              label: "Bill date",
                              isRequired: true,
                              child: SizedBox(
                                width: 180,
                                child: SizedBox(
                                  height: 32,
                                  child: MouseRegion(
                                    onEnter: (_) => setState(
                                      () => _hoveredFormFields.add('billDate'),
                                    ),
                                    onExit: (_) => setState(
                                      () =>
                                          _hoveredFormFields.remove('billDate'),
                                    ),
                                    child: Focus(
                                      onFocusChange: (focus) => setState(() {
                                        if (focus) {
                                          _focusedFormFields.add('billDate');
                                        } else {
                                          _focusedFormFields.remove('billDate');
                                        }
                                      }),
                                      child: TextField(
                                        controller: _billDateCtrl,
                                        key: _billDateFieldKey,
                                        readOnly: true,
                                        onTap: () async {
                                          final picked =
                                              await ZerpaiDatePicker.show(
                                                context,
                                                initialDate: DateTime.now(),
                                                targetKey: _billDateFieldKey,
                                              );
                                          if (picked != null && mounted) {
                                            setState(() {
                                              _billDateCtrl.text = DateFormat(
                                                "dd-MM-yyyy",
                                              ).format(picked);
                                            });
                                          }
                                        },
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: _textPrimary,
                                          fontFamily: "Inter",
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          filled: true,
                                          fillColor: _hasValidSelection
                                              ? _bgWhite
                                              : const Color(0xFFF5F5F5),
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                10,
                                                8,
                                                10,
                                                8,
                                              ),
                                          hintText: "dd-MM-yyyy",
                                          hintStyle: const TextStyle(
                                            fontSize: 13,
                                            color: _hintColor,
                                            fontFamily: "Inter",
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  (_hoveredFormFields.contains(
                                                        'billDate',
                                                      ) ||
                                                      _focusedFormFields
                                                          .contains('billDate'))
                                                  ? const Color(0xFF3B82F6)
                                                  : _fieldBorder,
                                              width:
                                                  (_hoveredFormFields.contains(
                                                        'billDate',
                                                      ) ||
                                                      _focusedFormFields
                                                          .contains('billDate'))
                                                  ? 1.5
                                                  : 1.0,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFF3B82F6),
                                              width: 1.5,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          suffixIcon: const Icon(
                                            LucideIcons.calendar,
                                            size: 16,
                                            color: _hintColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildFormRow(
                              label: "Bill invoice total",
                              isRequired: true,
                              child: SizedBox(
                                width: 180,
                                child: SizedBox(
                                  height: 32,
                                  child: MouseRegion(
                                    onEnter: (_) => setState(
                                      () => _hoveredFormFields.add(
                                        'invoiceTotal',
                                      ),
                                    ),
                                    onExit: (_) => setState(
                                      () => _hoveredFormFields.remove(
                                        'invoiceTotal',
                                      ),
                                    ),
                                    child: Focus(
                                      onFocusChange: (focus) => setState(() {
                                        if (focus) {
                                          _focusedFormFields.add(
                                            'invoiceTotal',
                                          );
                                        } else {
                                          _focusedFormFields.remove(
                                            'invoiceTotal',
                                          );
                                        }
                                      }),
                                      child: TextField(
                                        controller: _invoiceTotalCtrl,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          TextInputFormatter.withFunction((
                                            oldValue,
                                            newValue,
                                          ) {
                                            if (newValue.text.isEmpty ||
                                                RegExp(
                                                  r"^\d*\.?\d*$",
                                                ).hasMatch(newValue.text)) {
                                              return newValue;
                                            }
                                            return oldValue;
                                          }),
                                        ],
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: _textPrimary,
                                          fontFamily: "Inter",
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          filled: true,
                                          fillColor: _hasValidSelection
                                              ? _bgWhite
                                              : const Color(0xFFF5F5F5),
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                10,
                                                8,
                                                10,
                                                8,
                                              ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color:
                                                  (_hoveredFormFields.contains(
                                                        'invoiceTotal',
                                                      ) ||
                                                      _focusedFormFields
                                                          .contains(
                                                            'invoiceTotal',
                                                          ))
                                                  ? const Color(0xFF3B82F6)
                                                  : _fieldBorder,
                                              width:
                                                  (_hoveredFormFields.contains(
                                                        'invoiceTotal',
                                                      ) ||
                                                      _focusedFormFields
                                                          .contains(
                                                            'invoiceTotal',
                                                          ))
                                                  ? 1.5
                                                  : 1.0,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Color(0xFF3B82F6),
                                              width: 1.5,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 40),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormRow(
                              label: "Purchase receive#",
                              isRequired: true,
                              child: SizedBox(
                                width: 180,
                                height: 32,
                                child: MouseRegion(
                                  onEnter: (_) => setState(
                                    () =>
                                        _hoveredFormFields.add('receiveNumber'),
                                  ),
                                  onExit: (_) => setState(
                                    () => _hoveredFormFields.remove(
                                      'receiveNumber',
                                    ),
                                  ),
                                  child: Focus(
                                    onFocusChange: (focus) => setState(() {
                                      if (focus) {
                                        _focusedFormFields.add('receiveNumber');
                                      } else {
                                        _focusedFormFields.remove(
                                          'receiveNumber',
                                        );
                                      }
                                    }),
                                    child: TextField(
                                      controller: _receiveNumberCtrl,
                                      readOnly: _isReceiveAutoGenerate,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _textPrimary,
                                        fontFamily: "Inter",
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        filled: true,
                                        fillColor: _hasValidSelection
                                            ? _bgWhite
                                            : const Color(0xFFF5F5F5),
                                        contentPadding:
                                            const EdgeInsets.fromLTRB(
                                              10,
                                              8,
                                              10,
                                              8,
                                            ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color:
                                                (_hoveredFormFields.contains(
                                                      'receiveNumber',
                                                    ) ||
                                                    _focusedFormFields.contains(
                                                      'receiveNumber',
                                                    ))
                                                ? const Color(0xFF3B82F6)
                                                : _fieldBorder,
                                            width:
                                                (_hoveredFormFields.contains(
                                                      'receiveNumber',
                                                    ) ||
                                                    _focusedFormFields.contains(
                                                      'receiveNumber',
                                                    ))
                                                ? 1.5
                                                : 1.0,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: Color(0xFF3B82F6),
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        suffixIcon: ZTooltip(
                                          message:
                                              "Click here to enable or disable autogeneration of Purchase Receive numbers.",
                                          child: InkWell(
                                            onTap:
                                                _showPurchaseReceivePreferencesDialog,
                                            child: const Icon(
                                              LucideIcons.settings,
                                              size: 16,
                                              color: _hintColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildFormRow(
                              label: "Received date",
                              isRequired: true,
                              child: SizedBox(
                                width: 180,
                                height: 32,
                                child: MouseRegion(
                                  onEnter: (_) => setState(
                                    () =>
                                        _hoveredFormFields.add('receivedDate'),
                                  ),
                                  onExit: (_) => setState(
                                    () => _hoveredFormFields.remove(
                                      'receivedDate',
                                    ),
                                  ),
                                  child: Focus(
                                    onFocusChange: (focus) => setState(() {
                                      if (focus) {
                                        _focusedFormFields.add('receivedDate');
                                      } else {
                                        _focusedFormFields.remove(
                                          'receivedDate',
                                        );
                                      }
                                    }),
                                    child: TextField(
                                      controller: _receivedDateCtrl,
                                      readOnly: true,
                                      key: _dateFieldKey,
                                      onTap: () async {
                                        final picked =
                                            await ZerpaiDatePicker.show(
                                              context,
                                              initialDate: DateTime.now(),
                                              targetKey: _dateFieldKey,
                                            );
                                        if (picked != null && mounted) {
                                          setState(() {
                                            _receivedDateCtrl.text = DateFormat(
                                              "dd-MM-yyyy",
                                            ).format(picked);
                                          });
                                        }
                                      },
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _textPrimary,
                                        fontFamily: "Inter",
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        filled: true,
                                        fillColor: _hasValidSelection
                                            ? _bgWhite
                                            : const Color(0xFFF5F5F5),
                                        contentPadding:
                                            const EdgeInsets.fromLTRB(
                                              10,
                                              8,
                                              10,
                                              8,
                                            ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color:
                                                (_hoveredFormFields.contains(
                                                      'receivedDate',
                                                    ) ||
                                                    _focusedFormFields.contains(
                                                      'receivedDate',
                                                    ))
                                                ? const Color(0xFF3B82F6)
                                                : _fieldBorder,
                                            width:
                                                (_hoveredFormFields.contains(
                                                      'receivedDate',
                                                    ) ||
                                                    _focusedFormFields.contains(
                                                      'receivedDate',
                                                    ))
                                                ? 1.5
                                                : 1.0,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: Color(0xFF3B82F6),
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        suffixIcon: const Icon(
                                          LucideIcons.calendar,
                                          size: 16,
                                          color: _hintColor,
                                        ),
                                      ),
                                    ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INFO BANNER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInfoBanner() {
    final actionLabel = _isManualMode ? 'Add Manually' : 'Select or Scan Items';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _infoBannerBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _infoBannerBorder),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.info, size: 16, color: _infoBannerText),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: _infoBannerText,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(
                      text: _isManualMode
                          ? 'You can also add all items from the purchase order and manually adjust their quantities.  '
                          : 'You can also select or scan the items to be included from the purchase order.  ',
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: InkWell(
                        onTap: _switchToManualMode,
                        child: Text(
                          actionLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _linkBlue,
                            fontFamily: 'Inter',
                            decoration: TextDecoration.none,
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
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BIN SELECTION SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBinSelectionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          const Text(
            'Bin',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 200,
            child: FormDropdown<String>(
              height: 32,
              value: _binMode,
              items: const ['transaction', 'item'],
              itemBuilder: (item, isSelected, isHovered) {
                return _buildDropdownOverlayItem(
                  item == 'transaction' ? 'Transaction Level' : 'Item Level',
                  isSelected,
                  isHovered,
                );
              },
              displayStringForValue: (v) =>
                  v == 'transaction' ? 'Transaction Level' : 'Item Level',
              searchStringForValue: (v) =>
                  v == 'transaction' ? 'Transaction Level' : 'Item Level',
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _binMode = val;
                  if (_binMode == 'transaction') {
                    _preferredBins.clear();
                  } else if (_binMode == 'item') {
                    while (_preferredBins.length < _items.length) {
                      _preferredBins.add(null);
                    }
                    for (int i = 0; i < _items.length; i++) {
                      if (_selectedTransactionBin != null) {
                        _preferredBins[i] = _selectedTransactionBin;
                        _items[i] = _items[i].copyWith(
                          binId: _selectedTransactionBinId,
                          binLabel: _selectedTransactionBin,
                        );
                      }
                    }
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 20),
          if (_binMode == 'transaction')
            SizedBox(
              width: 220,
              child: Consumer(
                builder: (context, ref, _) {
                  final targetWarehouseId =
                      _selectedPO?.warehouseId ??
                      _selectedPO?.deliveryWarehouseId;
                  final binsAsync = ref.watch(
                    binsLookupProvider(targetWarehouseId),
                  );
                  final binsList = binsAsync.asData?.value ?? [];
                  final bins = binsList.map((b) => b['bin_code']!).toList();
                  final dropdown = FormDropdown<String>(
                    height: 32,
                    value: _selectedTransactionBin,
                    items: bins,
                    hint: 'Select Bin',
                    showSearch: true,
                    itemBuilder: (item, isSelected, isHovered) =>
                        _buildDropdownOverlayItem(item, isSelected, isHovered),
                    onChanged: (val) => setState(() {
                      _selectedTransactionBin = val;
                      if (val != null) {
                        final matched = binsList.firstWhere(
                          (b) => b['bin_code'] == val,
                          orElse: () => <String, String>{},
                        );
                        _selectedTransactionBinId = matched['id'];
                        while (_preferredBins.length < _items.length) {
                          _preferredBins.add(null);
                        }
                        for (int i = 0; i < _items.length; i++) {
                          _preferredBins[i] = val;
                          _items[i] = _items[i].copyWith(
                            binId: _selectedTransactionBinId,
                            binLabel: val,
                          );
                        }
                      } else {
                        _selectedTransactionBinId = null;
                      }
                    }),
                  );
                  return Skeletonizer(
                    enabled: binsAsync.isLoading,
                    child:
                        _selectedTransactionBin != null &&
                            _selectedTransactionBin!.isNotEmpty
                        ? _HoverOverlayWrapper(
                            text: _selectedTransactionBin,
                            child: dropdown,
                          )
                        : dropdown,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ITEMS TABLE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildItemsTable() {
    if (_receiveBilledItems) {
      return _buildBilledItemsTable();
    } else if (_isManualMode) {
      return _buildManualItemsTable(); // ✅ Manual table
    } else {
      return _buildItemsTableNormal(); // ✅ PO table (default)
    }
  }

  Widget _buildReceiveModeRadioButtons() {
    if (!_hasBills || _isFullyBilled) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 32, bottom: 20),
      child: RadioScope<bool>(
        value: _receiveBilledItems,
        onChanged: (val) {
          setState(() {
            _receiveBilledItems = val;
          });
        },
        child: Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioGroupItem<bool>(
                  value: false,
                  activeColor: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Receive Unbilled items',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioGroupItem<bool>(
                  value: true,
                  activeColor: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Receive Billed items',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBilledItemsTable() {
    final double tableWidth = 620.0 + _dynamicBilledQtyToReceiveColumnWidth() + 2.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: tableWidth,
                decoration: const BoxDecoration(
                  border: Border.fromBorderSide(BorderSide(color: _borderCol)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Table Header
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        border: Border(
                          bottom: BorderSide(color: _borderCol, width: 0.8),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _tableHeaderCell(
                            "ITEMS & DESCRIPTION",
                            fixedWidth: 620,
                          ),
                          _tableHeaderCell(
                            "QUANTITY TO RECEIVE",
                            fixedWidth: _dynamicBilledQtyToReceiveColumnWidth(),
                            align: TextAlign.right,
                            isLastColumn: true,
                          ),
                        ],
                      ),
                    ),
                    // Table Body (Grouped by Bill)
                    if (_associatedBills.isEmpty)
                      _buildEmptyBilledRow()
                    else
                      ..._associatedBills.asMap().entries.expand((entry) {
                        final billIndex = entry.key;
                        final bill = entry.value;
                        final billId = bill['id']?.toString() ?? '';
                        final billNo = bill['bill_number']?.toString() ?? '';
                        final itemsList = bill['items'] as List<dynamic>? ?? [];
                        final isExpanded = _expandedBillIds.contains(billId);

                        return [
                          _buildBilledGroupHeader(
                            billIndex,
                            billId,
                            billNo,
                            itemsList.length,
                            isExpanded,
                          ),
                          if (isExpanded)
                            ...itemsList.asMap().entries.map((itemEntry) {
                              final itemIndex = itemEntry.key;
                              final item = itemEntry.value;
                              return _buildBilledItemRow(
                                billIndex,
                                itemIndex,
                                item,
                              );
                            }),
                        ];
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBilledRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderCol)),
      ),
      child: const Text(
        'No bills associated with this Purchase Order',
        style: TextStyle(fontSize: 13, color: _hintColor, fontFamily: 'Inter'),
      ),
    );
  }

  Widget _buildBilledGroupHeader(
    int billIndex,
    String billId,
    String billNo,
    int itemCount,
    bool isExpanded,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: _borderCol, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              color: const Color(0xFF2A95BF),
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                if (isExpanded) {
                  _expandedBillIds.remove(billId);
                } else {
                  _expandedBillIds.add(billId);
                }
              });
            },
          ),
          const SizedBox(width: 8),
          Text(
            'Bill# - $billNo ( $itemCount Items )',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _associatedBills.removeAt(billIndex);
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Remove Bill',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF2A95BF),
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBilledItemRow(int billIndex, int itemIndex, dynamic item) {
    final bill = _associatedBills[billIndex];
    final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
    final String name = itemMap['itemName'] ?? '';
    final String desc = itemMap['description'] ?? '';
    final double qtyToReceive = itemMap['quantityToReceive'] ?? 0.0;
    final List<BatchInfo> batches =
        (itemMap['batches'] as List<dynamic>?)?.cast<BatchInfo>() ?? [];
    final hasBatches = batches.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderCol, width: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ITEMS & DESCRIPTION
          SizedBox(
            width: 620,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: _borderCol, width: 0.8),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _borderCol),
                    ),
                    child: const Icon(
                      LucideIcons.image,
                      size: 16,
                      color: _hintColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: _textPrimary,
                            fontFamily: "Inter",
                          ),
                        ),
                        if (desc.isNotEmpty)
                          Text(
                            desc,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _hintColor,
                              fontFamily: "Inter",
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // QUANTITY TO RECEIVE
          SizedBox(
            width: _dynamicBilledQtyToReceiveColumnWidth(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              alignment: Alignment.topRight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQtyInputField(
                          fieldKey: "billed-qty-$billIndex-$itemIndex",
                          controller: _billedQtyControllers.putIfAbsent(
                            "${bill['id']}_${itemMap['itemId']}",
                            () => TextEditingController(
                              text: qtyToReceive % 1 == 0
                                  ? qtyToReceive.toInt().toString()
                                  : qtyToReceive.toString(),
                            ),
                          ),
                          onChanged: (val) =>
                              _onBilledRowQtyChanged(billIndex, itemIndex, val),
                          height: 32,
                          isNumeric: true,
                        ),
                        const SizedBox(height: 4),
                        if (!hasBatches) ...[
                          const SizedBox(height: 4),
                          _buildBilledItemAddBatchesLinkButton(
                            billIndex,
                            itemIndex,
                            itemMap,
                          ),
                          if (_hasBills && _isEditMode) ...[
                            const SizedBox(height: 4),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _openEditQuantityDialogFromBilled(
                                  billIndex,
                                  itemIndex,
                                ),
                                child: const Icon(
                                  LucideIcons.fileEdit,
                                  size: 14,
                                  color: Color(0xFF2A95BF),
                                ),
                              ),
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (_hasBills && _isEditMode) ...[
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _openEditQuantityDialogFromBilled(
                                          billIndex,
                                          itemIndex,
                                        ),
                                    child: const Icon(
                                      LucideIcons.fileEdit,
                                      size: 14,
                                      color: Color(0xFF2A95BF),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              GestureDetector(
                                onTap: () => _showSelectBilledItemBatchDialog(
                                  billIndex,
                                  itemIndex,
                                ),
                                child: Text(
                                  _sumBatchFoc(batches) > 0
                                      ? '${_fmtPcs(_sumBatchQuantity(batches))}pcs + ${_fmtPcs(_sumBatchFoc(batches))}foc'
                                      : '${_fmtPcs(_sumBatchQuantity(batches))}pcs',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _linkBlue,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (hasBatches)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: batches.map((batch) {
                            return GestureDetector(
                              onTap: () => _showSelectBilledItemBatchDialog(
                                billIndex,
                                itemIndex,
                              ),
                              child: Container(
                                width: 94,
                                margin: const EdgeInsets.only(right: 2),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F9F5),
                                  border: Border.all(
                                    color: const Color(0xFFCFE9D8),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _batchText('Batch: ${batch.batchNo}'),
                                    _batchText(
                                      'Qty: ${_fmtPcs(batch.quantity)} pcs',
                                    ),
                                    if (batch.foc > 0)
                                      _batchText(
                                        'FOC: ${_fmtPcs(batch.foc)} pcs',
                                      ),
                                    _batchText('Pack: ${batch.unitPack}'),
                                    _batchText('MRP: ${batch.mrp}'),
                                    _batchText('P Rate: ${batch.ptr}'),
                                    _batchText(
                                      'Exp: ${batch.expiryDate != null ? DateFormat('dd-MM-yyyy').format(batch.expiryDate!) : ''}',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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

  Widget _buildBilledItemAddBatchesLinkButton(
    int billIndex,
    int itemIndex,
    Map<String, dynamic> itemMap,
  ) {
    return InkWell(
      onTap: () => _showSelectBilledItemBatchDialog(billIndex, itemIndex),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertTriangle, size: 12, color: _dangerRed),
          SizedBox(width: 4),
          Text(
            'Add Batches',
            style: TextStyle(
              fontSize: 11,
              color: _linkBlue,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSelectBilledItemBatchDialog(
    int billIndex,
    int itemIndex,
  ) async {
    final bill = _associatedBills[billIndex];
    final itemsList = bill['items'] as List<dynamic>;
    final itemMap = Map<String, dynamic>.from(itemsList[itemIndex]);

    final String itemId = itemMap['itemId'] ?? '';
    final String name = itemMap['itemName'] ?? '';
    final double qtyToReceive = itemMap['quantityToReceive'] ?? 0.0;
    final List<BatchInfo> initialBatches =
        (itemMap['batches'] as List<dynamic>?)?.cast<BatchInfo>() ?? [];

    final remaining = qtyToReceive;

    final batchOptions = <String>{
      ...initialBatches.map((b) => b.batchNo.trim()).where((v) => v.isNotEmpty),
    };

    final batchDetails = <Map<String, dynamic>>[];
    if (itemId.isNotEmpty) {
      try {
        final dbBatches = await ref.read(batchLookupProvider(itemId).future);
        final dbBatchNumbers = dbBatches
            .map((b) => b['batch_no']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        batchOptions.addAll(dbBatchNumbers);
        batchDetails.addAll(dbBatches);
      } catch (_) {}
    }

    final warehousesAsync = ref.read(allWarehousesProvider);
    final warehouses = warehousesAsync.asData?.value ?? [];
    final warehouseName = _resolveWarehouseName();
    final warehouse = warehouses.firstWhere(
      (w) => w['name'] == warehouseName,
      orElse: () => <String, dynamic>{},
    );
    final warehouseId = warehouse['id']?.toString();
    final targetWarehouseId =
        _selectedPO?.warehouseId?.trim() ??
        _selectedPO?.deliveryWarehouseId?.trim() ??
        warehouseId;

    List<Map<String, dynamic>> bins = [];
    if (targetWarehouseId != null && targetWarehouseId.isNotEmpty) {
      try {
        final binsList = await ref.read(
          binsLookupProvider(targetWarehouseId).future,
        );
        bins = binsList.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SelectBatchDialog(
        itemName: name,
        productId: itemId,
        batchOptions: batchOptions.toList()..sort(),
        batchDetails: batchDetails,
        initialBatches: initialBatches,
        bins: bins,
        ordered: qtyToReceive,
        maxQuantity: remaining,
        warehouseName: _resolveWarehouseName(),
        initialDamageEnabled: _isDamageEnabled,
        onDamageChanged: (enabled) {
          setState(() {
            _isDamageEnabled = enabled;
          });
        },
        onTopError: _showTopError,
        onSave: (newBatches) {
          setState(() {
            final combinedQty = newBatches.fold<double>(
              0,
              (sum, batch) => sum + batch.quantity,
            );

            final updatedItem = Map<String, dynamic>.from(itemMap);
            updatedItem['batches'] = newBatches;
            updatedItem['quantityToReceive'] = combinedQty;

            itemsList[itemIndex] = updatedItem;
            _associatedBills[billIndex] = {...bill, 'items': itemsList};

            final controllerKey = "${bill['id']}_$itemId";
            final controller = _billedQtyControllers[controllerKey];
            if (controller != null) {
              final totalFoc = _sumBatchFoc(newBatches);
              final displayQty = combinedQty + totalFoc;
              controller.text = displayQty % 1 == 0
                  ? displayQty.toInt().toString()
                  : displayQty.toString();
            }
          });
        },
      ),
    );
  }

  Widget _buildInsertRowButton() {
    return TextButton(
      onPressed: _insertManualRow,
      style: TextButton.styleFrom(
        foregroundColor: _linkBlue,
        padding: const EdgeInsets.symmetric(horizontal: 0),
      ),
      child: const Text(
        '+ Insert New Row',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildItemsTableNormal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final parentWidth = constraints.maxWidth;
          final qtyWidth = _dynamicQtyToReceiveColumnWidth();
          final double firstColWidth = (parentWidth - (438.0 + qtyWidth) - 2.0).clamp(240.0, 400.0);
          final double tableWidth = firstColWidth + 438.0 + qtyWidth + 2.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: tableWidth,
                  decoration: const BoxDecoration(
                    border: Border.fromBorderSide(BorderSide(color: _borderCol)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Table Header
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          border: Border(
                            bottom: BorderSide(color: _borderCol, width: 0.8),
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _tableHeaderCell(
                                "",
                                fixedWidth: firstColWidth,
                                child: _buildHeaderSearchField(
                                  label: "ITEMS & DESCRIPTION",
                                  controller: _itemDetailsSearchCtrl,
                                  hintText: "Search items...",
                                  onChanged: (val) {
                                    setState(() => _itemDetailsSearchQuery = val);
                                  },
                                  isSearchVisible: _showSearchItemDetails,
                                  onToggle: () {
                                    setState(() {
                                      _showSearchItemDetails =
                                          !_showSearchItemDetails;
                                      if (!_showSearchItemDetails) {
                                        _itemDetailsSearchCtrl.clear();
                                        _itemDetailsSearchQuery = '';
                                      }
                                    });
                                  },
                                ),
                              ),
                              _tableHeaderCell(
                                "ORDERED",
                                fixedWidth: 100,
                                align: TextAlign.right,
                              ),
                              _tableHeaderCell(
                                "RECEIVED",
                                fixedWidth: 100,
                                align: TextAlign.right,
                              ),
                              _tableHeaderCell(
                                "IN TRANSIT",
                                fixedWidth: 110,
                                align: TextAlign.right,
                              ),
                              _tableHeaderCell(
                                "CANCELLED",
                                fixedWidth: 100,
                                align: TextAlign.right,
                              ),
                              _buildQtyHeaderCell(
                                fixedWidth: qtyWidth,
                              ),
                              _tableHeaderCell(
                                "",
                                fixedWidth: 28,
                                isLastColumn: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Table Body
                      if (_isLoadingPOs)
                        _buildLoadingRow()
                      else
                        ...(() {
                          final Map<String, double> itemBilledQty = {};
                          for (final bill in _associatedBills) {
                            final itemsList =
                                bill['items'] as List<dynamic>? ?? [];
                            for (final bi in itemsList) {
                              final biMap = Map<String, dynamic>.from(bi as Map);
                              final productId = biMap['itemId']?.toString() ?? '';
                              final poId =
                                  biMap['purchaseOrderId']?.toString() ?? '';
                              final qty =
                                  double.tryParse(
                                        biMap['quantityToReceive']?.toString() ?? '',
                                      ) ??
                                      0.0;
                              final key = "$poId-$productId";
                              itemBilledQty[key] =
                                  (itemBilledQty[key] ?? 0.0) + qty;
                            }
                          }

                          var visibleItems = _items.asMap().entries.where((
                            entry,
                          ) {
                            final item = entry.value;
                            final key = "${item.purchaseOrderId}-${item.itemId}";
                            final billedQty = itemBilledQty[key] ?? 0.0;
                            final maxQty =
                                (item.ordered - item.received - item.cancelled)
                                    .clamp(0.0, double.infinity);
                            return billedQty < maxQty;
                          }).toList();

                          if (_itemDetailsSearchQuery.isNotEmpty) {
                            final query = _itemDetailsSearchQuery.toLowerCase();
                            visibleItems = visibleItems.where((entry) {
                              return entry.value.itemName.toLowerCase().contains(
                                query,
                              );
                            }).toList();
                          }

                          if (visibleItems.isEmpty) {
                            return [_buildEmptyRow()];
                          }

                          return visibleItems
                              .map(
                                (entry) => _buildItemRow(entry.key, entry.value, firstColWidth),
                              )
                              .toList();
                        })(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildManualItemsTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final parentWidth = constraints.maxWidth;
          final qtyWidth = _dynamicQtyToReceiveColumnWidth();
          final double firstColWidth = (parentWidth - (438.0 + qtyWidth) - 2.0).clamp(240.0, 400.0);
          final double tableWidth = firstColWidth + 438.0 + qtyWidth + 2.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: tableWidth,
                  decoration: const BoxDecoration(
                    border: Border.fromBorderSide(BorderSide(color: _borderCol)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Table Header
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          border: Border(
                            bottom: BorderSide(color: _borderCol, width: 0.8),
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _tableHeaderCell(
                                "",
                                fixedWidth: firstColWidth,
                                child: _buildHeaderSearchField(
                                  label: "ITEMS & DESCRIPTION",
                                  controller: _itemDetailsSearchCtrl,
                                  hintText: "Search items...",
                                  onChanged: (val) {
                                    setState(() => _itemDetailsSearchQuery = val);
                                  },
                                  isSearchVisible: _showSearchItemDetails,
                                  onToggle: () {
                                    setState(() {
                                      _showSearchItemDetails =
                                          !_showSearchItemDetails;
                                      if (!_showSearchItemDetails) {
                                        _itemDetailsSearchCtrl.clear();
                                        _itemDetailsSearchQuery = '';
                                      }
                                    });
                                  },
                                  subtitleWidget: InkWell(
                                    onTap: _addAllItemsFromPO,
                                    child: const Text(
                                      "add all items",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _linkBlue,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              _tableHeaderCell(
                                "ORDERED",
                                fixedWidth: 100,
                                align: TextAlign.right,
                              ),
                              _tableHeaderCell(
                                "RECEIVED",
                                fixedWidth: 100,
                                align: TextAlign.right,
                              ),
                              _tableHeaderCell(
                                "IN TRANSIT",
                                fixedWidth: 110,
                                align: TextAlign.right,
                              ),
                              _tableHeaderCell(
                                "CANCELLED",
                                fixedWidth: 100,
                                align: TextAlign.right,
                              ),
                              _buildQtyHeaderCell(
                                fixedWidth: qtyWidth,
                              ),
                              _tableHeaderCell(
                                "",
                                fixedWidth: 28,
                                isLastColumn: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Table Rows
                      if (_items.isEmpty)
                        KeyedSubtree(
                          key: const ValueKey('ephemeral-row'),
                          child: _buildManualRow(
                            0,
                            PurchaseReceiveItem(),
                            firstColWidth,
                            isEphemeral: true,
                          ),
                        )
                      else
                        ...(() {
                          var visibleManualItems = _items
                              .asMap()
                              .entries
                              .toList();
                          if (_itemDetailsSearchQuery.isNotEmpty) {
                            final query = _itemDetailsSearchQuery.toLowerCase();
                            visibleManualItems = visibleManualItems.where((
                              entry,
                            ) {
                              return entry.value.itemName.toLowerCase().contains(
                                query,
                              );
                            }).toList();
                          }
                          return visibleManualItems.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final ctrlKey = _rowControllers.length > index
                                ? _rowControllers[index].hashCode
                                : index;
                            return KeyedSubtree(
                              key: ValueKey('row-$ctrlKey'),
                              child: _buildManualRow(index, item, firstColWidth),
                            );
                          }).toList();
                        })(),
                      // Bottom border
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: _borderCol,
                      ),
                    ],
                  ),
                ),
              ),
              // Insert New Row Button
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: _buildInsertRowButton(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tableHeaderCell(
    String text, {
    int flex = 1,
    double? fixedWidth,
    TextAlign? align,
    bool isLastColumn = false,
    Widget? child,
  }) {
    final content = Container(
      alignment: align == TextAlign.right
          ? Alignment.centerRight
          : Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          right: isLastColumn
              ? BorderSide.none
              : const BorderSide(color: _borderCol, width: 0.8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child:
          child ??
          Text(
            text,
            textAlign: align,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              fontFamily: 'Inter',
              letterSpacing: 0.3,
            ),
          ),
    );

    if (fixedWidth != null) {
      return SizedBox(width: fixedWidth, child: content);
    }

    return Expanded(flex: flex, child: content);
  }

  Widget _buildHeaderSearchField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onChanged,
    required bool isSearchVisible,
    required VoidCallback onToggle,
    TextAlign textAlign = TextAlign.start,
    Widget? subtitleWidget,
  }) {
    if (!isSearchVisible) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: textAlign == TextAlign.center
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Inter',
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onToggle,
                child: const Icon(
                  LucideIcons.search,
                  size: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          if (subtitleWidget != null) ...[
            const SizedBox(height: 2),
            subtitleWidget,
          ],
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
            child: const Icon(
              LucideIcons.x,
              size: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyHeaderCell({required double fixedWidth}) {
    return SizedBox(
      width: fixedWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QUANTITY TO RECEIVE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                fontFamily: 'Inter',
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            InkWell(
              onTap: _fillAllUnreceivedQuantities,
              child: const Text(
                'Add all Unreceived',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _linkBlue,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyInputField({
    required String fieldKey,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    double height = 36,
    bool isNumeric = true,
  }) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hoveredQtyFields.add(fieldKey);
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredQtyFields.remove(fieldKey);
        });
      },
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 100,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF3B82F6), width: 1.0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 13,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
              hintText: '0',
              hintStyle: TextStyle(
                color: _hintColor,
                fontFamily: 'Inter',
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _adjustRowQuantity(int index, {required int delta}) {
    if (index >= _items.length || index >= _rowControllers.length) return;
    final ctrl = _rowControllers[index];
    final item = _items[index];
    final totalFoc = _sumBatchFoc(item.batches);
    final currentSum =
        double.tryParse(ctrl.qtyCtrl.text.isEmpty ? '0' : ctrl.qtyCtrl.text) ??
        0;
    final nextSum = (currentSum + delta).clamp(0.0, double.infinity).toDouble();
    final nextQty = (nextSum - totalFoc).clamp(0.0, double.infinity);
    final display = nextSum == nextSum.roundToDouble()
        ? nextSum.toInt().toString()
        : nextSum.toStringAsFixed(2);

    setState(() {
      ctrl.qtyCtrl.text = display;
      _items[index] = _items[index].copyWith(quantityToReceive: nextQty);
    });
  }

  void _onRowQtyChanged(int index, String value) {
    if (index >= _items.length) return;
    final parsed = double.tryParse(value.isEmpty ? '0' : value) ?? 0;
    final item = _items[index];
    final totalFoc = _sumBatchFoc(item.batches);
    final qty = (parsed - totalFoc).clamp(0.0, double.infinity);
    setState(() {
      _items[index] = _items[index].copyWith(quantityToReceive: qty);
    });
  }

  void _onBilledRowQtyChanged(int billIndex, int itemIndex, String value) {
    if (billIndex >= _associatedBills.length) return;
    final bill = _associatedBills[billIndex];
    final itemsList = bill['items'] as List<dynamic>;
    if (itemIndex >= itemsList.length) return;
    final itemMap = Map<String, dynamic>.from(itemsList[itemIndex]);

    final double parsed = double.tryParse(value.isEmpty ? '0' : value) ?? 0.0;
    final List<BatchInfo> batches =
        (itemMap['batches'] as List<dynamic>?)?.cast<BatchInfo>() ?? [];
    final totalFoc = _sumBatchFoc(batches);
    final qty = (parsed - totalFoc).clamp(0.0, double.infinity);

    setState(() {
      final updatedItem = Map<String, dynamic>.from(itemMap);
      updatedItem['quantityToReceive'] = qty;
      itemsList[itemIndex] = updatedItem;

      _associatedBills[billIndex] = {...bill, 'items': itemsList};
    });
  }

  void _fillAllUnreceivedQuantities() {
    if (_items.isEmpty) return;
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        if (i >= _rowControllers.length) continue;
        if (_items[i].batches.isNotEmpty) continue;
        final maxQty =
            (_items[i].ordered - _items[i].received - _items[i].cancelled)
                .clamp(0.0, double.infinity);
        final display = maxQty == maxQty.roundToDouble()
            ? maxQty.toInt().toString()
            : maxQty.toStringAsFixed(2);
        _rowControllers[i].qtyCtrl.text = display;
        _items[i] = _items[i].copyWith(quantityToReceive: maxQty);
      }
    });
  }

  Widget _buildAddBatchesLinkButton(int index) {
    return InkWell(
      onTap: () => _showSelectBatchDialog(index),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertTriangle, size: 12, color: _dangerRed),
          SizedBox(width: 4),
          Text(
            'Add Batches',
            style: TextStyle(
              fontSize: 11,
              color: _linkBlue,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyAndFocBreakdown(PurchaseReceiveItem item) {
    if (item.batches.isEmpty) {
      return const SizedBox.shrink();
    }
    final qty = _sumBatchQuantity(item.batches);
    final foc = _sumBatchFoc(item.batches);
    return Text(
      foc > 0
          ? '${_fmtPcs(qty)}pcs + ${_fmtPcs(foc)}foc'
          : '${_fmtPcs(qty)}pcs',
      style: const TextStyle(
        fontSize: 10,
        color: _hintColor,
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _batchText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        height: 1.35,
        color: _textPrimary,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _buildEmptyRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderCol)),
      ),
      child: const Text(
        'Select a purchase order to populate items',
        style: TextStyle(fontSize: 13, color: _hintColor, fontFamily: 'Inter'),
      ),
    );
  }

  Widget _buildLoadingRow() {
    final qtyWidth = _dynamicQtyToReceiveColumnWidth();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderCol)),
      ),
      child: SizedBox(
        height: 180,
        child: Column(
          children: List.generate(3, (_) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 170, child: Skeleton(height: 14)),
                  const SizedBox(width: 300, child: Skeleton(height: 14)),
                  const SizedBox(width: 100, child: Skeleton(height: 14)),
                  const SizedBox(width: 100, child: Skeleton(height: 14)),
                  const SizedBox(width: 110, child: Skeleton(height: 14)),
                  SizedBox(width: qtyWidth, child: const Skeleton(height: 14)),
                  const SizedBox(width: 12),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _tableBodyCell({
    int flex = 1,
    double? fixedWidth,
    required Widget child,
    bool isLastColumn = false,
    bool hideRightBorder = false,
    double? height,
  }) {
    Widget content = Container(
      height: height,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(
        vertical: height != null
            ? (height >= 140.0 ? 12.0 : (height > 60.0 ? 6.0 : 4.0))
            : 12.0,
      ),
      decoration: BoxDecoration(
        border: Border(
          right: (isLastColumn || hideRightBorder)
              ? BorderSide.none
              : const BorderSide(color: _borderCol, width: 0.8),
        ),
      ),
      child: child,
    );

    if (fixedWidth != null) {
      return SizedBox(width: fixedWidth, child: content);
    }
    return Expanded(flex: flex, child: content);
  }

  Widget _buildQtyControl({
    required String fieldKey,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    final isActive =
        _hoveredQtyFields.contains(fieldKey) ||
        _focusedQtyFields.contains(fieldKey);

    return SizedBox(
      height: 32,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: InkWell(
              onTap: onDecrement,
              child: Center(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      width: 10,
                      height: 2.2,
                      color: _focusBorder,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredQtyFields.add(fieldKey)),
              onExit: (_) => setState(() => _hoveredQtyFields.remove(fieldKey)),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _bgWhite,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isActive ? _focusBorder : Colors.transparent,
                    width: isActive ? 1.2 : 1,
                  ),
                ),
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
                    controller: controller,
                    onChanged: onChanged,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: _hintColor,
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 24,
            child: InkWell(
              onTap: onIncrement,
              child: Center(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 2.2,
                            color: _focusBorder,
                          ),
                          Container(
                            width: 2.2,
                            height: 10,
                            color: _focusBorder,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownOverlayItem(
    String text,
    bool isSelected,
    bool isHovered,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHovered
            ? const Color(0xFF3B82F6)
            : (isSelected ? const Color(0xFFF3F4F6) : Colors.white),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isHovered ? Colors.white : _textPrimary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  void _showAdvancedSearch(List<Vendor> vendors) {
    showDialog(
      context: context,
      builder: (ctx) => AdvancedVendorSearchDialog(
        vendors: vendors,
        onSelect: (v) {
          setState(() {
            _selectedVendorId = v.id;
            _selectedVendorName = v.displayName;
          });
          _fetchPOsForVendor(v.id);
        },
      ),
    );
  }

  void _closeVendorSidebar() {
    _vendorSidebarOverlay?.remove();
    _vendorSidebarOverlay = null;
  }

  void _showVendorSidebar(Vendor vendor) async {
    if (_isVendorSidebarLoading) return;
    if (_vendorSidebarOverlay != null) return;

    setState(() {
      _isVendorSidebarLoading = true;
    });

    Vendor displayVendor = vendor;
    try {
      final repo = ref.read(vendorRepositoryProvider);
      final fetched = await repo.getVendorById(vendor.id);
      if (fetched != null) {
        displayVendor = fetched;
      }
    } catch (e) {
      debugPrint('Error fetching full vendor details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isVendorSidebarLoading = false;
        });
      }
    }

    if (!mounted) return;

    final overlay = Overlay.of(context);
    _vendorSidebarOverlay = OverlayEntry(
      builder: (ctx) => VendorSidebar(
        vendor: displayVendor,
        onClose: _closeVendorSidebar,
        paymentTermsList: const [],
      ),
    );
    overlay.insert(_vendorSidebarOverlay!);
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
    final primaryTextColor = isHovered ? Colors.white : _textPrimary;
    final secondaryTextColor = isHovered
        ? Colors.white.withValues(alpha: 0.85)
        : _hintColor;

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

  Widget _buildManualRow(
    int index,
    PurchaseReceiveItem item,
    double firstColWidth, {
    bool isEphemeral = false,
  }) {
    if (!_rowSelectedWarehouses.containsKey(index)) {
      _rowSelectedWarehouses[index] = _resolveWarehouseName();
    }
    if (!_rowSelectedViews.containsKey(index)) {
      _rowSelectedViews[index] = 'Accounting';
    }
    final ctrl = index < _rowControllers.length
        ? _rowControllers[index]
        : _ReceiveItemRowController();
    final poItems = _selectedPOs.expand((po) => po.items).toList();
    final poItemKeyCounts = <String, int>{};
    for (final poItem in poItems) {
      if (poItem.isHeader) continue;
      final key =
          '${poItem.productId}_${poItem.quantity.toStringAsFixed(4)}_${(poItem.description ?? '').trim()}';
      poItemKeyCounts[key] = (poItemKeyCounts[key] ?? 0) + 1;
    }

    final selectedPoItemKeyCounts = <String, int>{};
    for (int i = 0; i < _items.length; i++) {
      if (i != index && !_hiddenManualIndices.contains(i)) {
        final it = _items[i];
        if (it.itemId != null && it.itemId!.isNotEmpty) {
          final key =
              '${it.itemId}_${it.ordered.toStringAsFixed(4)}_${(it.description ?? '').trim()}';
          selectedPoItemKeyCounts[key] =
              (selectedPoItemKeyCounts[key] ?? 0) + 1;
        }
      }
    }

    final availablePoItems = poItems.where((poItem) {
      if (poItem.isHeader) return false;
      final key =
          '${poItem.productId}_${poItem.quantity.toStringAsFixed(4)}_${(poItem.description ?? '').trim()}';
      final allowedCount = poItemKeyCounts[key] ?? 0;
      final selectedCount = selectedPoItemKeyCounts[key] ?? 0;
      return selectedCount < allowedCount || poItem.productId == item.itemId;
    }).toList();

    final selectedItem =
        poItems
            .where(
              (it) =>
                  !it.isHeader &&
                  it.productId == item.itemId &&
                  (it.quantity - item.ordered).abs() < 0.001 &&
                  (it.description ?? '').trim() ==
                      (item.description ?? '').trim(),
            )
            .firstOrNull ??
        (item.itemId != null && item.itemId!.isNotEmpty
            ? poItems
                  .where((it) => !it.isHeader && it.productId == item.itemId)
                  .firstOrNull
            : null);
    final hasBatches = !isEphemeral && item.batches.isNotEmpty;
    final bool needsAddBatchesLink = !isEphemeral && !hasBatches && item.quantityToReceive > 0;
    final double rowHeight = hasBatches ? 140.0 : (needsAddBatchesLink ? 84.0 : 60.0);

    if (ctrl.qtyCtrl.text == '0') {
      ctrl.qtyCtrl.text = '';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = index),
      onExit: (_) => setState(() {
        if (_hoveredRowIndex == index) {
          _hoveredRowIndex = null;
        }
      }),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _borderCol, width: 0.8)),
        ),
        child: Row(
          children: [
            _tableBodyCell(
              fixedWidth: firstColWidth,
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FormDropdown<PurchaseOrderItem>(
                  value: selectedItem,
                  items: availablePoItems,
                  hint: 'Type or click to select an item',
                  showSearch: true,
                  displayStringForValue: (poItem) {
                    final qtyStr =
                        poItem.quantity == poItem.quantity.roundToDouble()
                        ? poItem.quantity.round().toString()
                        : poItem.quantity.toStringAsFixed(2);
                    final descStr =
                        poItem.description != null &&
                            poItem.description!.isNotEmpty
                        ? ' - ${poItem.description}'
                        : '';
                    return '${poItem.productName ?? poItem.itemCode ?? 'Unnamed item'} (Qty: $qtyStr$descStr)';
                  },
                  searchStringForValue: (poItem) =>
                      '${poItem.productName ?? ''} ${poItem.itemCode ?? ''}',
                  itemBuilder: (poItem, isSelected, isHovered) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? const Color(0xFF3B82F6)
                            : (isSelected
                                  ? const Color(0xFFF3F4F6)
                                  : Colors.white),
                        borderRadius: BorderRadius.circular(4),
                        border: Border(
                          bottom: BorderSide(
                            color: isHovered || isSelected
                                ? Colors.transparent
                                : const Color(0xFFE5E7EB),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${poItem.productName ?? 'Unnamed item'} (Qty: ${poItem.quantity == poItem.quantity.roundToDouble() ? poItem.quantity.round().toString() : poItem.quantity.toStringAsFixed(2)}${poItem.description != null && poItem.description!.isNotEmpty ? ' - ${poItem.description}' : ''})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: isHovered ? Colors.white : _textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                          if (poItem.itemCode != null)
                            Text(
                              poItem.itemCode!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isHovered
                                    ? const Color(0xFFEAF2FF)
                                    : _hintColor,
                                fontFamily: 'Inter',
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  onChanged: (poItem) {
                    if (poItem == null) return;
                    setState(() {
                      final matchingPo = _selectedPOs.firstWhere(
                        (po) => po.items.any(
                          (it) =>
                              (poItem.id != null && it.id == poItem.id) ||
                              (poItem.id == null &&
                                  it.productId == poItem.productId &&
                                  it.quantity == poItem.quantity &&
                                  (it.description ?? '') ==
                                      (poItem.description ?? '')),
                        ),
                        orElse: () => _selectedPOs.isNotEmpty
                            ? _selectedPOs.first
                            : PurchaseOrder(
                                id: '',
                                orderNumber: '',
                                orderDate: DateTime.now(),
                                vendorId: '',
                              ),
                      );
                      if (isEphemeral) {
                        final String compositeKey =
                            '${poItem.productId}_${poItem.quantity.toStringAsFixed(4)}_${(poItem.description ?? '').trim()}';
                        final recQty =
                            _receivedQuantities[compositeKey] ??
                            _receivedQuantities[poItem.productId] ??
                            0.0;
                        _items.add(
                          poItem.productId.isNotEmpty
                              ? PurchaseReceiveItem(
                                  itemId: poItem.productId,
                                  itemName: poItem.productName ?? '',
                                  description: poItem.description,
                                  ordered: poItem.quantity,
                                  received: recQty,
                                  inTransit: 0,
                                  cancelled: poItem.cancelledQuantity,
                                  purchaseOrderId: matchingPo.id,
                                  purchaseOrderNumber: matchingPo.orderNumber,
                                )
                              : PurchaseReceiveItem(),
                        );
                        _rowControllers.add(_ReceiveItemRowController());
                        _preferredBins.add(null);
                        _damageControllers.add(TextEditingController());
                        _items.add(PurchaseReceiveItem());
                        _rowControllers.add(_ReceiveItemRowController());
                        _preferredBins.add(null);
                        _damageControllers.add(TextEditingController());
                      } else {
                        if (index < _items.length) {
                          final String compositeKey =
                              '${poItem.productId}_${poItem.quantity.toStringAsFixed(4)}_${(poItem.description ?? '').trim()}';
                          final recQty =
                              _receivedQuantities[compositeKey] ??
                              _receivedQuantities[poItem.productId] ??
                              0.0;
                          _items[index] = _items[index].copyWith(
                            itemId: poItem.productId,
                            itemName: poItem.productName ?? '',
                            description: poItem.description,
                            ordered: poItem.quantity,
                            received: recQty,
                            inTransit: 0,
                            cancelled: poItem.cancelledQuantity,
                            purchaseOrderId: matchingPo.id,
                            purchaseOrderNumber: matchingPo.orderNumber,
                          );
                          if (index == _items.length - 1) {
                            _items.add(PurchaseReceiveItem());
                            _rowControllers.add(_ReceiveItemRowController());
                            _preferredBins.add(null);
                            _damageControllers.add(TextEditingController());
                          }
                        }
                      }
                    });
                  },
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: 100,
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  item.ordered > 0
                      ? item.ordered.toStringAsFixed(
                          item.ordered == item.ordered.roundToDouble() ? 0 : 2,
                        )
                      : "",
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
                    fontFamily: "Inter",
                  ),
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: 100,
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  item.ordered > 0
                      ? item.received.toStringAsFixed(
                          item.received == item.received.roundToDouble()
                              ? 0
                              : 2,
                        )
                      : "",
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
                    fontFamily: "Inter",
                  ),
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: 110,
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  item.inTransit.toStringAsFixed(
                    item.inTransit == item.inTransit.roundToDouble() ? 0 : 2,
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
                    fontFamily: "Inter",
                  ),
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: 100,
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  item.ordered > 0
                      ? item.cancelled.toStringAsFixed(
                          item.cancelled == item.cancelled.roundToDouble()
                              ? 0
                              : 2,
                        )
                      : "",
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
                    fontFamily: "Inter",
                  ),
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: _dynamicQtyToReceiveColumnWidth(),
              hideRightBorder: true,
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQtyControl(
                            fieldKey: 'manual-$index',
                            controller: ctrl.qtyCtrl,
                            onChanged: (val) {
                              if (isEphemeral) return;
                              _onRowQtyChanged(index, val);
                            },
                            onIncrement: () {
                              if (isEphemeral) return;
                              _adjustRowQuantity(index, delta: 1);
                            },
                            onDecrement: () {
                              if (isEphemeral) return;
                              _adjustRowQuantity(index, delta: -1);
                            },
                          ),
                          Row(
                            children: [
                              if (!isEphemeral &&
                                  !hasBatches &&
                                  item.quantityToReceive > 0)
                                _buildAddBatchesLinkButton(index),
                            ],
                          ),
                          if (!isEphemeral)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: _buildQtyAndFocBreakdown(item),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (hasBatches)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: item.batches.map((batch) {
                              return GestureDetector(
                                onTap: () => _showSelectBatchDialog(index),
                                child: Container(
                                  width: 94,
                                  margin: const EdgeInsets.only(right: 2),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F9F5),
                                    border: Border.all(
                                      color: const Color(0xFFCFE9D8),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _batchText('Batch: ${batch.batchNo}'),
                                      _batchText(
                                        'Qty: ${_fmtPcs(batch.quantity)} pcs',
                                      ),
                                      if (batch.foc > 0)
                                        _batchText(
                                          'FOC: ${_fmtPcs(batch.foc)} pcs',
                                        ),
                                      _batchText('Pack: ${batch.unitPack}'),
                                      _batchText('MRP: ${batch.mrp}'),
                                      _batchText('P Rate: ${batch.ptr}'),
                                      _batchText(
                                        'Exp: ${batch.expiryDate != null ? DateFormat('dd-MM-yyyy').format(batch.expiryDate!) : ''}',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: 28,
              isLastColumn: true,
              height: rowHeight,
              child: isEphemeral
                  ? const SizedBox()
                  : (_hoveredRowIndex == index
                        ? Center(
                            child: InkWell(
                              onTap: () => _removeItem(index),
                              borderRadius: BorderRadius.circular(4),
                              child: const Icon(
                                LucideIcons.x,
                                size: 12,
                                color: _dangerRed,
                              ),
                            ),
                          )
                        : const SizedBox()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, PurchaseReceiveItem item, double firstColWidth) {
    final ctrl = index < _rowControllers.length
        ? _rowControllers[index]
        : _ReceiveItemRowController();
    final hasBatches = item.batches.isNotEmpty;
    final bool needsAddBatchesLink = !hasBatches && item.quantityToReceive > 0;
    final double rowHeight = hasBatches ? 140.0 : (needsAddBatchesLink ? 84.0 : 60.0);

    if (ctrl.qtyCtrl.text == '0') {
      ctrl.qtyCtrl.text = '';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = index),
      onExit: (_) => setState(() {
        if (_hoveredRowIndex == index) {
          _hoveredRowIndex = null;
        }
      }),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _borderCol, width: 0.8)),
        ),
        child: Row(
          children: [
            _tableBodyCell(
              fixedWidth: firstColWidth,
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _borderCol),
                      ),
                      child: const Icon(
                        LucideIcons.image,
                        size: 16,
                        color: _hintColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName.isNotEmpty
                                ? item.itemName
                                : "Select an item",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: item.itemName.isNotEmpty
                                  ? _textPrimary
                                  : _hintColor,
                              fontFamily: "Inter",
                            ),
                          ),
                          if (item.description != null &&
                              item.description!.isNotEmpty)
                            Text(
                              item.description!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _hintColor,
                                fontFamily: "Inter",
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: 100,
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  item.ordered.toStringAsFixed(
                    item.ordered == item.ordered.roundToDouble() ? 0 : 2,
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
                    fontFamily: "Inter",
                  ),
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: 100,
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  item.received.toStringAsFixed(
                    item.received == item.received.roundToDouble() ? 0 : 2,
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
                    fontFamily: "Inter",
                  ),
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: 110,
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  item.inTransit.toStringAsFixed(
                    item.inTransit == item.inTransit.roundToDouble() ? 0 : 2,
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
                    fontFamily: "Inter",
                  ),
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: 100,
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  item.cancelled.toStringAsFixed(
                    item.cancelled == item.cancelled.roundToDouble() ? 0 : 2,
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
                    fontFamily: "Inter",
                  ),
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: _dynamicQtyToReceiveColumnWidth(),
              hideRightBorder: true,
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQtyInputField(
                            fieldKey: "item-$index",
                            controller: ctrl.qtyCtrl,
                            onChanged: (val) => _onRowQtyChanged(index, val),
                            height: 32,
                          ),
                          if (!hasBatches && item.quantityToReceive > 0) ...[
                            const SizedBox(height: 4),
                            _buildAddBatchesLinkButton(index),
                          ],
                          if (_hasBills || item.batches.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (_hasBills && _isEditMode) ...[
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _openEditQuantityDialog(index),
                                        child: const Icon(
                                          LucideIcons.fileEdit,
                                          size: 14,
                                          color: Color(0xFF2A95BF),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  _buildQtyAndFocBreakdown(item),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (hasBatches)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: item.batches.map((batch) {
                              return GestureDetector(
                                onTap: () => _showSelectBatchDialog(index),
                                child: Container(
                                  width: 94,
                                  margin: const EdgeInsets.only(right: 2),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F9F5),
                                    border: Border.all(
                                      color: const Color(0xFFCFE9D8),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _batchText('Batch: ${batch.batchNo}'),
                                      _batchText(
                                        'Qty: ${_fmtPcs(batch.quantity)} pcs',
                                      ),
                                      if (batch.foc > 0)
                                        _batchText(
                                          'FOC: ${_fmtPcs(batch.foc)} pcs',
                                        ),
                                      _batchText('Pack: ${batch.unitPack}'),
                                      _batchText('MRP: ${batch.mrp}'),
                                      _batchText('P Rate: ${batch.ptr}'),
                                      _batchText(
                                        'Exp: ${batch.expiryDate != null ? DateFormat('dd-MM-yyyy').format(batch.expiryDate!) : ''}',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: 28,
              isLastColumn: true,
              height: rowHeight,
              child: _hoveredRowIndex == index
                  ? Center(
                      child: InkWell(
                        onTap: () => _removeItem(index),
                        borderRadius: BorderRadius.circular(4),
                        child: const Icon(
                          LucideIcons.x,
                          size: 12,
                          color: _dangerRed,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTES AND UPLOAD SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNotesAndUploadSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(top: BorderSide(color: _borderCol)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes (For Internal Use)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _labelColor,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 800,
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredFormFields.add('notes')),
              onExit: (_) => setState(() => _hoveredFormFields.remove('notes')),
              child: Focus(
                onFocusChange: (focus) => setState(() {
                  if (focus) {
                    _focusedFormFields.add('notes');
                  } else {
                    _focusedFormFields.remove('notes');
                  }
                }),
                child: TextField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _bgWhite,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            (_hoveredFormFields.contains('notes') ||
                                _focusedFormFields.contains('notes'))
                            ? const Color(0xFF3B82F6)
                            : _fieldBorder,
                        width:
                            (_hoveredFormFields.contains('notes') ||
                                _focusedFormFields.contains('notes'))
                            ? 1.5
                            : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFF3B82F6),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Attach File(s) to Purchase Receive',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _labelColor,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          _buildFileUploadSection(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STICKY FOOTER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStickyFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: const BoxDecoration(
        color: _bgWhite,
        border: Border(top: BorderSide(color: _borderCol)),
      ),
      child: Row(
        children: [
          // Save as Draft
          OutlinedButton(
            onPressed: _isSaving || _isLoadingData || !_hasValidSelection
                ? null
                : () => _handleSave('draft'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textPrimary,
              side: const BorderSide(color: _fieldBorder),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Save as Draft',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Save as Received (primary green)
          ElevatedButton(
            onPressed: _isSaving || _isLoadingData || !_hasValidSelection
                ? null
                : () => _handleSave('received'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _greenBtn,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Save as Received',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Cancel
          TextButton(
            onPressed: () {
              if (widget.initialPoId != null &&
                  widget.initialPoId!.isNotEmpty) {
                context.go('/purchases/purchase-orders/${widget.initialPoId}');
              } else {
                context.pop();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: _textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
              ),
            ),
          ),

          if (_isSaving) ...[
            const SizedBox(width: 16),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED FORM BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFormRow({
    required String label,
    required Widget child,
    bool isRequired = false,
    Color? labelColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      labelColor ?? (isRequired ? _requiredLabel : _labelColor),
                  fontFamily: 'Inter',
                ),
                children: [
                  TextSpan(text: label),
                  if (isRequired)
                    const TextSpan(
                      text: '*',
                      style: TextStyle(color: _requiredLabel),
                    ),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  // Removed _buildDropdownField as it was replaced by FormDropdown
  // SAVE HANDLER
  // ═══════════════════════════════════════════════════════════════════════════
  void _handleSave(String status) async {
    // STEP 1: Validate required fields FIRST
    List<String> missingFields = [];

    if (_selectedVendorName == null || _selectedVendorName!.isEmpty) {
      missingFields.add('Vendor');
    }

    if (_selectedPONumber == null || _selectedPONumber!.isEmpty) {
      missingFields.add('Purchase Order');
    }

    if (_billNoCtrl.text.trim().isEmpty) {
      _showTopError('Bill No is required');
      return;
    }

    if (_billDateCtrl.text.trim().isEmpty) {
      _showTopError('Bill Date is required');
      return;
    }

    if (_invoiceTotalCtrl.text.trim().isEmpty) {
      _showTopError('Invoice Total is required');
      return;
    }

    final List<dynamic> validationItems = [];
    if (_receiveBilledItems) {
      for (final bill in _associatedBills) {
        validationItems.addAll(bill['items']);
      }
    } else {
      validationItems.addAll(_items);
    }

    if (validationItems.isEmpty) {
      missingFields.add('Item');
    } else {
      for (int i = 0; i < validationItems.length; i++) {
        final item = validationItems[i];
        final itemId = _receiveBilledItems ? item['itemId'] : item.itemId;
        final qty = _receiveBilledItems
            ? item['quantityToReceive']
            : item.quantityToReceive;
        if (itemId == null || itemId.isEmpty) {
          missingFields.add('Item in row ${i + 1}');
        }
        if (qty <= 0) {
          missingFields.add('Quantity in row ${i + 1}');
        }
      }
    }

    // If missing fields → SHOW SPECIFIC MESSAGE
    if (missingFields.isNotEmpty) {
      final message =
          'Please fill required fields: ${missingFields.join(', ')}';
      _showTopError(message);
      return;
    }

    // STEP 2: Check quantity mismatch ONLY if required fields are valid
    bool hasMismatch = false;
    if (_receiveBilledItems) {
      for (final bill in _associatedBills) {
        final items = bill['items'] as List<dynamic>;
        for (final item in items) {
          final batches =
              (item['batches'] as List<dynamic>?)?.cast<BatchInfo>() ?? [];
          final double qtyToReceive = item['quantityToReceive'] ?? 0.0;
          if (batches.isNotEmpty) {
            final totalBatchQty = batches.fold<double>(
              0,
              (sum, b) => sum + b.quantity,
            );
            if (totalBatchQty != qtyToReceive) {
              hasMismatch = true;
              break;
            }
          }
        }
        if (hasMismatch) break;
      }
    } else {
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        final totalBatchQty = item.batches.fold<double>(
          0,
          (sum, b) => sum + b.quantity,
        );
        if (item.batches.isNotEmpty &&
            totalBatchQty != item.quantityToReceive) {
          hasMismatch = true;
          break;
        }
      }
    }

    if (hasMismatch) {
      _showTopError(
        "There's a mismatch between the quantity entered in the line item and the total quantity across all batches.",
      );
      return;
    }

    setState(() => _isSaving = true);

    final targetWarehouseId =
        _selectedWarehouseId ??
        _selectedPO?.warehouseId ??
        _selectedPO?.deliveryWarehouseId;
    final List<PurchaseReceiveItem> finalItems = _receiveBilledItems
        ? _associatedBills.expand((bill) {
            final itemsList = bill['items'] as List<dynamic>;
            return itemsList.map((item) {
              final Map<String, dynamic> itemMap = Map<String, dynamic>.from(
                item,
              );
              final preferredBin = _binMode == 'transaction'
                  ? _selectedTransactionBin
                  : itemMap['binLabel'];
              return PurchaseReceiveItem(
                itemId: itemMap['itemId'],
                itemName: itemMap['itemName'],
                description: itemMap['description'],
                ordered: itemMap['ordered'] ?? 0.0,
                received: itemMap['received'] ?? 0.0,
                inTransit: itemMap['inTransit'] ?? 0.0,
                cancelled: itemMap['cancelled'] ?? 0.0,
                quantityToReceive: itemMap['quantityToReceive'] ?? 0.0,
                batches: (itemMap['batches'] as List<dynamic>?)
                    ?.cast<BatchInfo>(),
                purchaseOrderId: itemMap['purchaseOrderId'],
                purchaseOrderNumber: itemMap['purchaseOrderNumber'],
                binId: itemMap['binId'],
                binLabel: preferredBin,
                billed: true,
              );
            });
          }).toList()
        : _items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final preferredBin = _binMode == 'transaction'
                ? _selectedTransactionBin
                : (i < _preferredBins.length ? _preferredBins[i] : null);
            return item.copyWith(binLabel: preferredBin);
          }).toList();

    final totalReceiveQty = finalItems.fold<double>(0.0, (sum, item) {
      if (item.batches.isNotEmpty) {
        return sum +
            item.batches.fold<double>(0.0, (s, b) => s + b.quantity + b.foc);
      } else {
        return sum + item.quantityToReceive;
      }
    });

    final receive = PurchaseReceive(
      id: widget.initialReceiveId,
      purchaseReceiveNumber: _receiveNumberCtrl.text.trim(),
      receivedDate: DateFormat(
        'dd-MM-yyyy',
      ).parse(_receivedDateCtrl.text.trim()),
      vendorId: _selectedVendorId,
      vendorName: _selectedVendorName,
      purchaseOrderId: _selectedPOId,
      purchaseOrderNumber: _selectedPONumber,
      warehouseId: targetWarehouseId,
      status: status,
      notes: _notesCtrl.text.trim(),
      billNo: _billNoCtrl.text.trim(),
      billDate: _billDateCtrl.text.trim().isNotEmpty
          ? DateFormat('dd-MM-yyyy').parse(_billDateCtrl.text.trim())
          : null,
      invoiceTotal: double.tryParse(_invoiceTotalCtrl.text.trim()) ?? 0,
      transactionBinId: _binMode == 'transaction'
          ? _selectedTransactionBinId
          : null,
      transactionBinLabel: _binMode == 'transaction'
          ? _selectedTransactionBin
          : null,
      quantity: totalReceiveQty,
      items: finalItems,
    );

    AppLogger.info(
      'Saving Purchase Receive...',
      data: {'status': status, 'receiveNumber': receive.purchaseReceiveNumber},
      module: 'purchases',
    );

    String? errorMsg;
    PurchaseReceive? savedReceive;
    final repository = ref.read(purchaseReceiveRepositoryProvider);

    try {
      if (_isEditMode) {
        savedReceive = await repository.updatePurchaseReceive(
          widget.initialReceiveId!,
          receive,
        );
        if (savedReceive == null) {
          errorMsg = 'Failed to update purchase receive';
        }
      } else {
        savedReceive = await repository.createPurchaseReceive(receive);
      }
    } catch (e) {
      errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring('Exception: '.length);
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (errorMsg == null && savedReceive != null) {
      if (_uploadedFiles.isNotEmpty) {
        await _saveAttachments(savedReceive.id!);
      }

      final uniquePOIds = _items
          .map((e) => e.purchaseOrderId)
          .whereType<String>()
          .toSet();
      for (final poId in uniquePOIds) {
        ref.invalidate(purchaseOrderProvider(poId));
      }
      ref.read(apiClientProvider).clearCache('purchase-orders');
      ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
      ref.read(purchaseReceivesProvider.notifier).fetchReceives();
      if (_isEditMode) {
        ref.invalidate(purchaseReceiveByIdProvider(widget.initialReceiveId!));
      }

      _showTopSuccess(
        _isEditMode
            ? 'Purchase receive updated successfully'
            : (status == 'received'
                  ? 'Purchase receive saved successfully'
                  : 'Purchase receive saved as draft'),
      );
      if (status == 'received') {
        context.go('/purchases/purchase-receives?id=${savedReceive.id}');
      } else if (widget.initialPoId != null && widget.initialPoId!.isNotEmpty) {
        context.go('/purchases/purchase-orders/${widget.initialPoId}');
      } else {
        context.go('/purchases/purchase-receives');
      }
    } else {
      _showTopError(errorMsg ?? 'Failed to save purchase receive');
    }
  }

  Future<void> _showSelectBatchDialog(int itemIndex) async {
    final item = _items[itemIndex];
    final remaining = (item.ordered - item.received - item.cancelled).clamp(
      0.0,
      double.infinity,
    );

    final batchOptions = <String>{
      ...item.batches.map((b) => b.batchNo.trim()).where((v) => v.isNotEmpty),
    };

    final itemId = item.itemId?.trim();
    final batchDetails = <Map<String, dynamic>>[];
    if (itemId != null && itemId.isNotEmpty) {
      try {
        final dbBatches = await ref.read(batchLookupProvider(itemId).future);
        final dbBatchNumbers = dbBatches
            .map((b) => b['batch_no']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        batchOptions.addAll(dbBatchNumbers);
        batchDetails.addAll(dbBatches);
      } catch (_) {
        // keep existing local options if remote lookup fails
      }
    }

    final warehousesAsync = ref.read(allWarehousesProvider);
    final warehouses = warehousesAsync.asData?.value ?? [];
    final warehouseName =
        _rowSelectedWarehouses[itemIndex] ?? _resolveWarehouseName();
    final warehouse = warehouses.firstWhere(
      (w) => w['name'] == warehouseName,
      orElse: () => <String, dynamic>{},
    );
    final warehouseId = warehouse['id']?.toString();
    final targetWarehouseId =
        _selectedPO?.warehouseId?.trim() ??
        _selectedPO?.deliveryWarehouseId?.trim() ??
        warehouseId;

    List<Map<String, dynamic>> bins = [];
    if (targetWarehouseId != null && targetWarehouseId.isNotEmpty) {
      try {
        final binsList = await ref.read(
          binsLookupProvider(targetWarehouseId).future,
        );
        bins = binsList.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }

    final defaultBinId = _binMode == 'transaction'
        ? _selectedTransactionBinId
        : item.binId;
    final defaultBinLabel = _binMode == 'transaction'
        ? _selectedTransactionBin
        : item.binLabel;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SelectBatchDialog(
        itemName: item.itemName,
        productId: itemId,
        batchOptions: batchOptions.toList()..sort(),
        batchDetails: batchDetails,
        initialBatches: item.batches,
        bins: bins,
        defaultBinId: defaultBinId,
        defaultBinLabel: defaultBinLabel,
        // Total in batch dialog must follow Quantity to receive in line item.
        ordered: item.quantityToReceive,
        maxQuantity: remaining,
        warehouseName:
            _rowSelectedWarehouses[itemIndex] ?? _resolveWarehouseName(),
        initialDamageEnabled: _isDamageEnabled,
        onDamageChanged: (enabled) {
          setState(() {
            _isDamageEnabled = enabled;
          });
        },
        onTopError: _showTopError,
        onSave: (newBatches) {
          setState(() {
            final combinedQty = newBatches.fold<double>(
              0,
              (sum, batch) => sum + batch.quantity,
            );
            final combinedFoc = newBatches.fold<double>(
              0,
              (sum, batch) => sum + batch.foc,
            );

            _items[itemIndex] = item.copyWith(
              batches: newBatches,
              quantityToReceive: combinedQty,
            );
            _rowControllers[itemIndex].qtyCtrl.text = _fmtPcs(
              combinedQty + combinedFoc,
            );
          });
        },
      ),
    );
  }

  String _resolveWarehouseName() {
    final warehouseName = _selectedPO?.warehouseName?.trim();
    if (warehouseName != null && warehouseName.isNotEmpty) {
      return warehouseName;
    }

    final idToLookup =
        _selectedPO?.warehouseId?.trim() ??
        _selectedPO?.deliveryWarehouseId?.trim();
    final whAsync = ref.read(warehousesProvider);
    if (idToLookup != null && idToLookup.isNotEmpty) {
      if (whAsync.hasValue && whAsync.value != null) {
        try {
          final wh = whAsync.value!.firstWhere((w) => w.id == idToLookup);
          return wh.name;
        } catch (_) {
          // Fallback if not found
        }
      }
    }

    if (whAsync.hasValue &&
        whAsync.value != null &&
        whAsync.value!.isNotEmpty) {
      return whAsync.value!.first.name;
    }

    return '';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILE UPLOAD — Split-button with dashed border (matches PO create)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CompositedTransformTarget(
              link: _uploadLink,
              child: MouseRegion(
                onEnter: (_) => setState(() => _isUploadButtonHovered = true),
                onExit: (_) => setState(() => _isUploadButtonHovered = false),
                child: CustomPaint(
                  foregroundPainter: _PRDashedBorderPainter(
                    color: (_isUploadButtonHovered || _uploadOverlay != null)
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFD1D5DB),
                  ),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: _pickFiles,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.upload,
                                  size: 14,
                                  color: Color(0xFF6B7280),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Upload File',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                    fontFamily: 'Inter',
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
                        InkWell(
                          onTap: _toggleUploadOverlay,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              _uploadOverlay != null
                                  ? LucideIcons.chevronUp
                                  : LucideIcons.chevronDown,
                              size: 16,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_uploadedFiles.isNotEmpty) _buildAttachmentBadge(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'You can upload a maximum of $_maxUploadFiles files, ${_maxUploadFileSizeBytes ~/ (1024 * 1024)}MB each',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentBadge() {
    return CompositedTransformTarget(
      link: _attachmentBadgeLink,
      child: InkWell(
        onTap: _toggleAttachmentListOverlay,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.paperclip, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '${_uploadedFiles.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleAttachmentListOverlay() {
    if (_attachmentListOverlay != null) {
      _attachmentListOverlay?.remove();
      _attachmentListOverlay = null;
      setState(() {});
      return;
    }

    _attachmentListOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _attachmentListOverlay?.remove();
                _attachmentListOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _attachmentBadgeLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _uploadedFiles
                          .map((file) => _buildAttachmentListItem(file))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_attachmentListOverlay!);
    setState(() {});
  }

  Widget _buildAttachmentListItem(PlatformFile file) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setItemState) {
        return MouseRegion(
          onEnter: (_) => setItemState(() => isHovered = true),
          onExit: (_) => setItemState(() => isHovered = false),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.file,
                  size: 16,
                  color: isHovered ? Colors.white : const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: isHovered
                              ? Colors.white
                              : const Color(0xFF374151),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'File Size: ${(file.size / 1024).toStringAsFixed(2)} KB',
                        style: TextStyle(
                          fontSize: 11,
                          color: isHovered
                              ? Colors.white.withValues(alpha: 0.8)
                              : const Color(0xFF6B7280),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                if (isHovered)
                  InkWell(
                    onTap: () {
                      if (file.bytes == null && _isEditMode) {
                        _deleteAttachmentFromDb(file.name);
                      }
                      setState(() {
                        _uploadedFiles.remove(file);
                        if (_uploadedFiles.isEmpty) {
                          _attachmentListOverlay?.remove();
                          _attachmentListOverlay = null;
                        }
                      });
                      _attachmentListOverlay?.markNeedsBuild();
                    },
                    child: const Icon(
                      LucideIcons.trash,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleUploadOverlay() {
    if (_uploadOverlay != null) {
      _uploadOverlay?.remove();
      _uploadOverlay = null;
      if (mounted) setState(() {});
      return;
    }

    _uploadOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _uploadOverlay?.remove();
                _uploadOverlay = null;
                if (mounted) setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _uploadLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.bottomLeft,
            offset: const Offset(0, -8),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    _buildUploadItem('Attach From Desktop'),
                    _buildUploadItem('Attach From Documents'),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_uploadOverlay!);
    if (mounted) setState(() {});
  }

  Widget _buildUploadItem(String label) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setOverlayState) {
        return MouseRegion(
          onEnter: (_) => setOverlayState(() => isHovered = true),
          onExit: (_) => setOverlayState(() => isHovered = false),
          child: GestureDetector(
            onTap: () async {
              _uploadOverlay?.remove();
              _uploadOverlay = null;
              if (mounted) setState(() {});
              await _pickFiles();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isHovered ? FontWeight.w600 : FontWeight.w500,
                  color: isHovered ? Colors.white : const Color(0xFF374151),
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SelectBatchDialog extends StatefulWidget {
  final String itemName;
  final String warehouseName;
  final double ordered;
  final double maxQuantity;
  final List<String> batchOptions;
  final List<Map<String, dynamic>> batchDetails;
  final List<BatchInfo> initialBatches;
  final bool initialDamageEnabled;
  final ValueChanged<bool>? onDamageChanged;
  final void Function(String message)? onTopError;
  final Function(List<BatchInfo>) onSave;
  final String? productId;
  final List<Map<String, dynamic>> bins;
  final String? defaultBinId;
  final String? defaultBinLabel;
  final bool readOnly;

  SelectBatchDialog({
    required this.itemName,
    required this.warehouseName,
    required this.ordered,
    required this.maxQuantity,
    required this.batchOptions,
    required this.batchDetails,
    required this.initialBatches,
    this.initialDamageEnabled = false,
    this.onDamageChanged,
    this.onTopError,
    required this.onSave,
    this.productId,
    this.bins = const [],
    this.defaultBinId,
    this.defaultBinLabel,
    this.readOnly = false,
  });

  @override
  State<SelectBatchDialog> createState() => _SelectBatchDialogState();
}

class _PurchaseReceivePreferencesDialog extends StatefulWidget {
  final bool initialAutoGenerate;
  final String initialPrefix;
  final int initialNextNumber;
  final void Function(bool isAuto, String prefix, int nextNum) onSave;

  const _PurchaseReceivePreferencesDialog({
    required this.initialAutoGenerate,
    required this.initialPrefix,
    required this.initialNextNumber,
    required this.onSave,
  });

  @override
  State<_PurchaseReceivePreferencesDialog> createState() =>
      _PurchaseReceivePreferencesDialogState();
}

class _PurchaseReceivePreferencesDialogState
    extends State<_PurchaseReceivePreferencesDialog> {
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
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);
    const borderCol = Color(0xFFE5E7EB);
    const greenBtn = Color(0xFF22A95E);

    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 600,
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
                    'Configure Purchase Receive# Preferences',
                    style: TextStyle(
                      fontSize: 32 / 2,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: borderCol),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your purchase receive numbers are set on auto-generate mode to save',
                    style: TextStyle(
                      fontSize: 27 / 2,
                      color: textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'your time. Are you sure about changing this setting?',
                    style: TextStyle(
                      fontSize: 27 / 2,
                      color: textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 16),
                  RadioGroup<bool>(
                    groupValue: _isAuto,
                    onChanged: (val) => setState(() => _isAuto = val!),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => setState(() => _isAuto = true),
                          child: Row(
                            children: [
                              Radio<bool>(
                                value: true,
                                activeColor: const Color(0xFF3B82F6),
                              ),
                              const Text(
                                'Continue auto-generating purchase receive numbers',
                                style: TextStyle(
                                  fontSize: 25 / 2,
                                  color: textPrimary,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(width: 6),
                              const ZTooltip(
                                message:
                                    'The edited prefix and next number will be updated in the transaction number series associated with your purchase receive.',
                                child: Icon(
                                  LucideIcons.helpCircle,
                                  size: 14,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isAuto) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 46,
                              top: 6,
                              right: 8,
                            ),
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
                                          color: textSecondary,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: _prefixCtrl,
                                        style: const TextStyle(
                                          fontSize: 22 / 2,
                                          color: textPrimary,
                                          fontFamily: 'Inter',
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 12,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            borderSide: const BorderSide(
                                              color: borderCol,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            borderSide: const BorderSide(
                                              color: borderCol,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            borderSide: const BorderSide(
                                              color: _focusBorder,
                                              width: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 30),
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
                                          color: textSecondary,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: _numberCtrl,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        style: const TextStyle(
                                          fontSize: 22 / 2,
                                          color: textPrimary,
                                          fontFamily: 'Inter',
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 12,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            borderSide: const BorderSide(
                                              color: borderCol,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            borderSide: const BorderSide(
                                              color: borderCol,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            borderSide: const BorderSide(
                                              color: _focusBorder,
                                              width: 1.2,
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
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () => setState(() => _isAuto = false),
                          child: Row(
                            children: [
                              Radio<bool>(
                                value: false,
                                activeColor: const Color(0xFF3B82F6),
                              ),
                              const Text(
                                'Enter purchase receive numbers manually',
                                style: TextStyle(
                                  fontSize: 25 / 2,
                                  color: textPrimary,
                                  fontFamily: 'Inter',
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
            ),
            const Divider(height: 1, color: borderCol),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              child: Row(
                children: [
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        final nextNum =
                            int.tryParse(_numberCtrl.text) ??
                            widget.initialNextNumber;
                        widget.onSave(_isAuto, _prefixCtrl.text, nextNum);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenBtn,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 22 / 2,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        backgroundColor: const Color(0xFFEEEEEE),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 22 / 2,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
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
    );
  }
}

class _SelectBatchDialogState extends State<SelectBatchDialog> {
  final Map<String, Set<String>> _batchIdsByBinId = {};
  final Map<String, Set<String>> _batchIdsByBin = {};

  Future<void> _fetchStockLayerBins() async {
    if (widget.productId == null || widget.productId!.isEmpty) return;
    try {
      _batchIdsByBinId.clear();
      _batchIdsByBin.clear();
      final supabase = Supabase.instance.client;
      final binCodeMap = <String, String>{};
      final batchNoById = <String, String>{};

      for (final binObj in widget.bins) {
        final bId = (binObj['id'] ?? binObj['binId'])?.toString().trim();
        final bCode = (binObj['bin_code'] ?? binObj['binCode'])?.toString().trim();
        if (bId != null && bId.isNotEmpty && bCode != null && bCode.isNotEmpty) {
          binCodeMap[bId] = bCode;
        }
      }

      for (final b in widget.batchDetails) {
        final id = (b['id'] ?? b['batchId'] ?? b['batch_id'])?.toString().trim();
        final no = (b['batch_no'] ?? b['batchNo'])?.toString().trim();
        if (id != null && id.isNotEmpty && no != null && no.isNotEmpty) {
          batchNoById[id] = no;
        }
      }

      try {
        final binRes = await supabase.from('bin_master').select('id, bin_code');
        for (final b in binRes as List) {
          final id = b['id']?.toString().trim();
          final code = b['bin_code']?.toString().trim();
          if (id != null && id.isNotEmpty && code != null && code.isNotEmpty) {
            binCodeMap[id] = code;
          }
        }
      } catch (_) {}

      void addBinBatchMapping(String? binId, String? batchId) {
        if (binId == null || binId.isEmpty || batchId == null || batchId.isEmpty) return;
        final bNo = batchNoById[batchId];
        final binCode = binCodeMap[binId];

        final setById = _batchIdsByBinId.putIfAbsent(binId, () => <String>{});
        setById.add(batchId);
        if (bNo != null && bNo.isNotEmpty) setById.add(bNo.toLowerCase());

        if (binCode != null && binCode.isNotEmpty) {
          final setByCode = _batchIdsByBin.putIfAbsent(binCode.toLowerCase(), () => <String>{});
          setByCode.add(batchId);
          if (bNo != null && bNo.isNotEmpty) setByCode.add(bNo.toLowerCase());
        }
      }

      try {
        final batchRes = await supabase
            .from('batch_master')
            .select('id, batch_no, bin_id')
            .eq('product_id', widget.productId!);
        if (mounted) {
          for (final item in batchRes as List) {
            final bId = item['id']?.toString().trim();
            final bNo = item['batch_no']?.toString().trim();
            final binId = item['bin_id']?.toString().trim();

            if (bId != null && bId.isNotEmpty) {
              if (bNo != null && bNo.isNotEmpty) batchNoById[bId] = bNo;
              addBinBatchMapping(binId, bId);
            }
          }
        }
      } catch (_) {}

      try {
        final stockRes = await supabase
            .from('batch_stock_layers')
            .select('batch_id, bin_id')
            .eq('product_id', widget.productId!)
            .not('bin_id', 'is', null);
        if (mounted) {
          for (final item in stockRes as List) {
            final bId = item['batch_id']?.toString().trim();
            final binId = item['bin_id']?.toString().trim();
            addBinBatchMapping(binId, bId);
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }
  final List<_BatchItemRowController> _rows = [];
  final Map<_BatchItemRowController, TextEditingController>
  _batchInputControllers = {};
  final Map<_BatchItemRowController, FocusNode> _batchInputFocusNodes = {};
  bool _showMfgDetails = false;
  bool _showFoc = false;
  bool _showDamage = false;
  bool _overwriteLineItem = false;
  String? _dialogErrorMessage;
  static const String _qtyOrFocMessage =
      'Either Quantity or FOC must be entered';
  final TextInputFormatter _numericInputFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text;
        if (text.isEmpty || RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
          return newValue;
        }
        return oldValue;
      });

  String? _productUnitPackId;

  Future<void> _fetchProductUnitPack() async {
    if (widget.productId == null || widget.productId!.isEmpty) return;
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('products')
          .select('unit_pack_id')
          .eq('id', widget.productId!)
          .maybeSingle();
      if (response != null && mounted) {
        final unitPackId = response['unit_pack_id']?.toString();
        if (unitPackId != null && unitPackId.isNotEmpty) {
          final packResponse = await supabase
              .from('product_pack_sizes')
              .select('pack_name')
              .eq('id', unitPackId)
              .maybeSingle();
          if (packResponse != null && mounted) {
            setState(() {
              _productUnitPackId = packResponse['pack_name']?.toString() ?? '';
              for (var row in _rows) {
                if (row.unitPackCtrl.text.isEmpty) {
                  row.unitPackCtrl.text = _productUnitPackId!;
                }
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _showDamage = widget.initialDamageEnabled;
    _fetchProductUnitPack();
    _fetchStockLayerBins();
    if (widget.initialBatches.isEmpty) {
      final firstRow = _BatchItemRowController();
      firstRow.qtyCtrl.text = widget.ordered.toString();
      firstRow.binId = widget.defaultBinId;
      firstRow.binLabel = widget.defaultBinLabel;
      _rows.add(firstRow);
    } else {
      for (var b in widget.initialBatches) {
        final row = _BatchItemRowController(initial: b);
        if (row.binId == null || row.binId!.isEmpty) {
          row.binId = widget.defaultBinId;
          row.binLabel = widget.defaultBinLabel;
        }
        if ((row.binLabel == null || row.binLabel!.isEmpty) &&
            row.binId != null &&
            widget.bins.isNotEmpty) {
          final matchedBin = widget.bins.firstWhere(
            (bin) => bin['id']?.toString() == row.binId,
            orElse: () => <String, dynamic>{},
          );
          if (matchedBin.isNotEmpty) {
            row.binLabel = matchedBin['bin_code']?.toString();
          }
        }
        _rows.add(row);
        if (b.manufactureDate != null ||
            b.expiryDate != null ||
            b.manufactureBatch.isNotEmpty) {
          _showMfgDetails = true;
        }
        if (b.foc > 0) {
          _showFoc = true;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _batchInputControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _batchInputFocusNodes.values) {
      focusNode.dispose();
    }
    for (var r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      final newRow = _BatchItemRowController();
      if (_productUnitPackId != null && _productUnitPackId!.isNotEmpty) {
        newRow.unitPackCtrl.text = _productUnitPackId!;
      }
      newRow.binId = widget.defaultBinId;
      newRow.binLabel = widget.defaultBinLabel;
      _rows.add(newRow);
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1 || index < 0 || index >= _rows.length) {
      return;
    }
    setState(() {
      _disposeBatchInputResources(_rows[index]);
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  void _disposeBatchInputResources(_BatchItemRowController row) {
    _batchInputControllers.remove(row)?.dispose();
    _batchInputFocusNodes.remove(row)?.dispose();
  }

  double get _totalQuantityOut => _rows.fold<double>(
    0,
    (sum, row) =>
        sum +
        (double.tryParse(row.qtyCtrl.text.trim()) ?? 0) +
        (double.tryParse(row.focCtrl.text.trim()) ?? 0),
  );

  double get _totalEnteredQtyOnly => _rows.fold<double>(
    0,
    (sum, row) => sum + (double.tryParse(row.qtyCtrl.text.trim()) ?? 0),
  );

  double get _totalEnteredQtyWithFoc => _totalQuantityOut;

  double get _quantityToBeAdded =>
      (widget.ordered - _totalQuantityOut).clamp(0, widget.ordered);

  String _fmtQty(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  String? _validateRequiredFields(_BatchItemRowController row, int rowIndex) {
    final rowLabel = 'Row ${rowIndex + 1}';
    final batchNo = row.batchNoCtrl.text.trim();
    final binLabel = row.binLabel?.trim() ?? '';
    final unitPack = row.unitPackCtrl.text.trim();
    final mrp = row.mrpCtrl.text.trim();
    final ptr = row.ptrCtrl.text.trim();
    final expiryDate = row.expDateCtrl.text.trim();
    final quantity = row.qtyCtrl.text.trim();
    final foc = row.focCtrl.text.trim();
    final damage = row.damageCtrl.text.trim();

    if (batchNo.isEmpty) {
      return '$rowLabel: Batch No is required';
    }
    if (binLabel.isEmpty) {
      return '$rowLabel: Bin location is required';
    }
    if (unitPack.isEmpty) {
      return '$rowLabel: Pack Size is required';
    }
    if (mrp.isEmpty) {
      return '$rowLabel: MRP is required';
    }
    if (double.tryParse(mrp) == null) {
      return '$rowLabel: MRP must be a valid number';
    }
    if (ptr.isNotEmpty && double.tryParse(ptr) == null) {
      return '$rowLabel: PTR must be a valid number';
    }
    if (expiryDate.isEmpty || row.expDate == null) {
      return '$rowLabel: Expiry Date is required';
    }
    final parsedQty = double.tryParse(quantity) ?? 0;
    final parsedFoc = double.tryParse(foc) ?? 0;
    if (parsedQty <= 0 && parsedFoc <= 0) {
      return _qtyOrFocMessage;
    }
    if (_showDamage && damage.isNotEmpty) {
      final parsedDamage = double.tryParse(damage);
      if (parsedDamage == null) {
        return '$rowLabel: Damage must be a valid number';
      }
      if (parsedDamage > parsedQty) {
        return '$rowLabel: Damage cannot exceed quantity';
      }
    }

    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int flex,
    bool isNumeric = false,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
    bool showHoverTooltip = false,
  }) {
    final textField = SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        textAlign: isNumeric ? TextAlign.left : TextAlign.left,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: isNumeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        onChanged: onChanged,
        inputFormatters: isNumeric ? [_numericInputFormatter] : [],
        style: const TextStyle(
          fontSize: 13,
          color: _textPrimary,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: readOnly ? const Color(0xFFF3F4F6) : Colors.white,
          isDense: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          constraints: const BoxConstraints(minHeight: 38, maxHeight: 38),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _fieldBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _focusBorder, width: 1.5),
          ),
          hintText: hint,
          hintStyle: const TextStyle(color: _hintColor, fontSize: 13),
        ),
      ),
    );

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: showHoverTooltip
            ? _HoverOverlayWrapper(controller: controller, child: textField)
            : textField,
      ),
    );
  }



  DateTime? _parseDateTime(String? str) {
    if (str == null || str.trim().isEmpty || str.trim() == '-') return null;
    final s = str.trim();
    DateTime? dt = DateTime.tryParse(s);
    if (dt != null) return dt;
    try {
      return DateFormat('dd-MM-yyyy').parse(s);
    } catch (_) {}
    try {
      return DateFormat('dd/MM/yyyy').parse(s);
    } catch (_) {}
    try {
      return DateFormat('yyyy-MM-dd').parse(s);
    } catch (_) {}
    return null;
  }

  Widget _buildBatchNoDropdown(_BatchItemRowController row) {
    return Expanded(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: _BatchNoTextFieldWithSuggestions(
          row: row,
          batchOptions: widget.batchOptions,
          batchDetails: widget.batchDetails,
          batchIdsByBinId: _batchIdsByBinId,
          batchIdsByBin: _batchIdsByBin,
          productUnitPackId: _productUnitPackId,
          readOnly: widget.readOnly,
          onBatchSelectedOrAutoloaded: ({
            String? mrp,
            String? ptr,
            String? expDateStr,
            String? mfgDateStr,
            String? mfgBatch,
            String? unitPack,
          }) {
            setState(() {
              if (mrp != null && mrp.isNotEmpty) row.mrpCtrl.text = mrp;
              if (ptr != null && ptr.isNotEmpty) row.ptrCtrl.text = ptr;
              if (expDateStr != null && expDateStr.isNotEmpty) {
                final expDate = _parseDateTime(expDateStr);
                if (expDate != null) {
                  row.expDate = expDate;
                  row.expDateCtrl.text = DateFormat('dd-MM-yyyy').format(expDate);
                }
              }
              if (mfgDateStr != null && mfgDateStr.isNotEmpty) {
                final mfgDate = _parseDateTime(mfgDateStr);
                if (mfgDate != null) {
                  row.mfgDate = mfgDate;
                  row.mfgDateCtrl.text = DateFormat('dd-MM-yyyy').format(mfgDate);
                }
              }
              if (mfgBatch != null && mfgBatch.isNotEmpty) {
                row.mfgBatchCtrl.text = mfgBatch;
              }
              if (unitPack != null && unitPack.isNotEmpty) {
                row.unitPackCtrl.text = unitPack;
              } else if (row.unitPackCtrl.text.isEmpty &&
                  _productUnitPackId != null &&
                  _productUnitPackId!.isNotEmpty) {
                row.unitPackCtrl.text = _productUnitPackId!;
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildBinDropdown(_BatchItemRowController row) {
    final binItems = widget.bins
        .map((b) => (b['bin_code'] ?? b['binCode'])?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return Expanded(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
          height: 38,
          child: FormDropdown<String>(
            height: 38,
            value: row.binLabel,
            items: binItems,
            hint: "Select Bin",
            showSearch: true,
            enabled: !widget.readOnly,
            fillColor: widget.readOnly ? const Color(0xFFF3F4F6) : Colors.white,
            border: Border.all(color: _fieldBorder, width: 1),
            itemBuilder: (item, isSelected, isHovered) =>
                _buildDropdownOverlayItem(item, isSelected, isHovered),
            onChanged: (bin) {
              setState(() {
                row.binLabel = bin;
                final selectedBinObj = widget.bins.firstWhere(
                  (b) =>
                      (b['bin_code'] ?? b['binCode'])?.toString().trim() ==
                      bin?.trim(),
                  orElse: () => <String, dynamic>{},
                );
                if (selectedBinObj.isNotEmpty) {
                  row.binId =
                      (selectedBinObj['id'] ?? selectedBinObj['binId'])
                          ?.toString();
                } else {
                  row.binId = null;
                }
                row.batchNoCtrl.clear();
                _disposeBatchInputResources(row);
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownOverlayItem(
    String text,
    bool isSelected,
    bool isHovered,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHovered
            ? const Color(0xFF3B82F6)
            : (isSelected ? const Color(0xFFF3F4F6) : Colors.white),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isHovered ? Colors.white : const Color(0xFF1F2937),
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required TextEditingController controller,
    required GlobalKey targetKey,
    int? flex,
    double? width,
    required VoidCallback onTap,
    bool readOnly = false,
  }) {
    final dateField = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        height: 38,
        child: TextField(
          key: targetKey,
          controller: controller,
          readOnly: true,
          onTap: readOnly ? null : onTap,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 13,
            color: _textPrimary,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? const Color(0xFFF3F4F6) : _bgWhite,
            isDense: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            constraints: const BoxConstraints(minHeight: 38, maxHeight: 38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: _fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: _focusBorder, width: 1.2),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 30,
              maxHeight: 38,
            ),
            suffixIcon: const Icon(
              LucideIcons.calendar,
              size: 14,
              color: _hintColor,
            ),
          ),
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: dateField);
    }

    return Expanded(flex: flex ?? 15, child: dateField);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
      child: Container(
        width: _showMfgDetails ? 1550 : 1050,
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Add Batch',
                    style: TextStyle(
                      fontSize: 18,
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
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: _dangerRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _borderCol),
            if (_dialogErrorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF9D3D3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: _textPrimary,
                              fontFamily: 'Inter',
                              height: 1.3,
                            ),
                            children: [
                              TextSpan(
                                text: '•  ',
                                style: TextStyle(fontSize: 16, height: 1.05),
                              ),
                              TextSpan(text: _dialogErrorMessage ?? ''),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _dialogErrorMessage = null),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8, top: 2),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: _dangerRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                children: [
                  const Icon(LucideIcons.home, size: 16, color: _hintColor),
                  const SizedBox(width: 8),
                  Text(
                    'Location : ${widget.warehouseName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Text(
                    'BATCH DETAILS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Item: ${widget.itemName}',
                    style: const TextStyle(fontSize: 12, color: _hintColor),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Total Quantity : ${_fmtQty(widget.ordered)} | Quantity to be added : ${_fmtQty(_quantityToBeAdded)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Checkbox(
                      value: _showMfgDetails,
                      onChanged: widget.readOnly
                          ? null
                          : (val) =>
                                setState(() => _showMfgDetails = val ?? false),
                      activeColor: _greenBtn,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Manufacture Details',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 32),
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Checkbox(
                      value: _showFoc,
                      onChanged: widget.readOnly
                          ? null
                          : (val) => setState(() => _showFoc = val ?? false),
                      activeColor: _greenBtn,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'FOC',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Checkbox(
                      value: _showDamage,
                      onChanged: widget.readOnly
                          ? null
                          : (val) {
                              final enabled = val ?? false;
                              setState(() => _showDamage = enabled);
                              widget.onDamageChanged?.call(enabled);
                            },
                      activeColor: _greenBtn,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Damage',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Checkbox(
                      value: _overwriteLineItem,
                      onChanged: widget.readOnly
                          ? null
                          : (val) => setState(
                              () => _overwriteLineItem = val ?? false,
                            ),
                      activeColor: _greenBtn,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overwrite the line item with ${_fmtQty(_totalEnteredQtyWithFoc)} quantities',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(bottom: BorderSide(color: _borderCol)),
              ),
              child: Row(
                children: [
                  _headerCell('BIN LOCATION*', 3),
                  _headerCell('BATCH NO*', 3),
                  _headerCell('PACK SIZE*', 2),
                  _headerCell('MRP*', 2),
                  _headerCell('P RATE', 2),
                  _headerCell('EXPIRY DATE*', 3),
                  if (_showMfgDetails) ...[
                    _headerCell('MFG DATE', 3),
                    _headerCell('MFG BATCH', 2),
                  ],
                  _headerCell('QUANTITY*', 2),
                  if (_showFoc) _headerCell('FOC', 2),
                  if (_showDamage) _headerCell('DAMAGE', 2),
                  const SizedBox(width: 32),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.4,
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                itemCount: _rows.length,
                itemBuilder: (context, index) {
                  final row = _rows[index];
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            _buildBinDropdown(row),
                            _buildBatchNoDropdown(row),
                            _buildTextField(
                              controller: row.unitPackCtrl,
                              hint: 'Pack',
                              flex: 2,
                              isNumeric: false,
                              readOnly: true,
                              showHoverTooltip: true,
                            ),
                            _buildTextField(
                              controller: row.mrpCtrl,
                              hint: '0',
                              flex: 2,
                              isNumeric: true,
                              readOnly: row.isAutoLoaded || widget.readOnly,
                            ),
                            _buildTextField(
                              controller: row.ptrCtrl,
                              hint: '0',
                              flex: 2,
                              isNumeric: true,
                              readOnly: row.isAutoLoaded || widget.readOnly,
                            ),
                            _buildDatePicker(
                              controller: row.expDateCtrl,
                              targetKey: row.expKey,
                              flex: 3,
                              readOnly: widget.readOnly,
                              onTap: () async {
                                final now = DateTime.now();
                                final today = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                );
                                final picked = await ZerpaiDatePicker.show(
                                  context,
                                  initialDate: row.expDate ?? now,
                                  firstDate: today,
                                  targetKey: row.expKey,
                                );
                                if (picked != null) {
                                  setState(() {
                                    row.expDate = picked;
                                    row.expDateCtrl.text = DateFormat(
                                      'dd-MM-yyyy',
                                    ).format(picked);
                                  });
                                }
                              },
                            ),
                            if (_showMfgDetails) ...[
                              _buildDatePicker(
                                controller: row.mfgDateCtrl,
                                targetKey: row.mfgKey,
                                flex: 3,
                                readOnly: widget.readOnly,
                                onTap: () async {
                                  final picked = await ZerpaiDatePicker.show(
                                    context,
                                    initialDate: row.mfgDate ?? DateTime.now(),
                                    targetKey: row.mfgKey,
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      row.mfgDate = picked;
                                      row.mfgDateCtrl.text = DateFormat(
                                        'dd-MM-yyyy',
                                      ).format(picked);
                                    });
                                  }
                                },
                              ),
                              _buildTextField(
                                controller: row.mfgBatchCtrl,
                                hint: 'Mfg Batch',
                                flex: 2,
                                readOnly: widget.readOnly,
                              ),
                            ],
                            _buildTextField(
                              controller: row.qtyCtrl,
                              hint: '0',
                              flex: 2,
                              isNumeric: true,
                              readOnly: widget.readOnly,
                              onChanged: (_) {
                                setState(() {
                                  _dialogErrorMessage = null;
                                });
                              },
                            ),
                            if (_showFoc)
                              _buildTextField(
                                controller: row.focCtrl,
                                hint: '0',
                                flex: 2,
                                isNumeric: true,
                                readOnly: widget.readOnly,
                                onChanged: (_) {
                                  setState(() {
                                    _dialogErrorMessage = null;
                                  });
                                },
                              ),
                            if (_showDamage)
                              _buildTextField(
                                controller: row.damageCtrl,
                                hint: 'Damage',
                                flex: 2,
                                isNumeric: true,
                                readOnly: widget.readOnly,
                                onChanged: (val) {
                                  final entered = double.tryParse(val) ?? 0;
                                  final maxQty =
                                      double.tryParse(row.qtyCtrl.text) ?? 0;

                                  if (entered > maxQty) {
                                    row.damageCtrl.text = _fmtQty(maxQty);
                                    row.damageCtrl.selection =
                                        TextSelection.fromPosition(
                                          TextPosition(
                                            offset: row.damageCtrl.text.length,
                                          ),
                                        );
                                  }
                                },
                              ),
                            SizedBox(
                              width: 32,
                              child: IconButton(
                                icon: const Icon(
                                  LucideIcons.xCircle,
                                  size: 16,
                                  color: _dangerRed,
                                ),
                                onPressed:
                                    (_rows.length > 1 && !widget.readOnly)
                                    ? () => _removeRow(index)
                                    : null,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < _rows.length - 1)
                        const Divider(height: 1, color: _borderCol),
                    ],
                  );
                },
              ),
            ),
            if (!widget.readOnly)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: InkWell(
                  onTap: _addRow,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.plus,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'New Row',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: _borderCol),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (widget.readOnly) {
                        Navigator.pop(context);
                        return;
                      }

                      if (!_overwriteLineItem &&
                          _totalEnteredQtyOnly != widget.ordered) {
                        const mismatchMessage =
                            "There's a mismatch between the quantity entered in the line item and the total quantity across all batches.";
                        setState(() {
                          _dialogErrorMessage = mismatchMessage;
                        });
                        widget.onTopError?.call(mismatchMessage);
                        return;
                      }

                      for (var i = 0; i < _rows.length; i++) {
                        final validationMessage = _validateRequiredFields(
                          _rows[i],
                          i,
                        );
                        if (validationMessage != null) {
                          setState(() {
                            _dialogErrorMessage = validationMessage;
                          });
                          if (validationMessage == _qtyOrFocMessage) {
                            widget.onTopError?.call(_qtyOrFocMessage);
                          }
                          return;
                        }
                      }

                      final results = _rows
                          .map((r) => r.toBatchInfo())
                          .toList();

                      // SUCCESS: Save and Close
                      setState(() {
                        _dialogErrorMessage = null;
                      });
                      widget.onSave(results);
                      Navigator.pop(context);
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
                    child: Text(
                      widget.readOnly ? 'Close' : 'Save',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!widget.readOnly) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textPrimary,
                        side: const BorderSide(color: _fieldBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(
    String text,
    int flex, {
    TextAlign alignment = TextAlign.center,
  }) {
    final bool isMandatory = text.contains('*');
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            text,
            textAlign: alignment,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isMandatory ? const Color(0xFFD32F2F) : _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}

class _PRDashedBorderPainter extends CustomPainter {
  final Color color;

  const _PRDashedBorderPainter({this.color = const Color(0xFFCBD5E1)});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      const Radius.circular(6),
    );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dash = 4.0;
    const gap = 3.0;

    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PRDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _HoverOverlayWrapper extends StatefulWidget {
  final Widget child;
  final TextEditingController? controller;
  final String? text;

  const _HoverOverlayWrapper({required this.child, this.controller, this.text});

  @override
  State<_HoverOverlayWrapper> createState() => _HoverOverlayWrapperState();
}

class _HoverOverlayWrapperState extends State<_HoverOverlayWrapper> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay() {
    if (_overlayEntry != null) return;
    if (!mounted) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                offset: const Offset(0, 4),
                child: Material(
                  color: Colors.transparent,
                  child: widget.controller != null
                      ? ValueListenableBuilder<TextEditingValue>(
                          valueListenable: widget.controller!,
                          builder: (context, value, _) {
                            if (value.text.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return _buildOverlayBox(value.text);
                          },
                        )
                      : (widget.text != null && widget.text!.isNotEmpty
                            ? _buildOverlayBox(widget.text!)
                            : const SizedBox.shrink()),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildOverlayBox(String textVal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        textVal,
        style: const TextStyle(
          color: Color(0xFF374151),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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

// ── Batch No Text Field with Inline Suggestions Overlay ──────────────────────
class _BatchNoTextFieldWithSuggestions extends StatefulWidget {
  final _BatchItemRowController row;
  final List<String> batchOptions;
  final List<Map<String, dynamic>> batchDetails;
  final Map<String, Set<String>> batchIdsByBinId;
  final Map<String, Set<String>> batchIdsByBin;
  final String? productUnitPackId;
  final bool readOnly;
  final void Function({
    String? mrp,
    String? ptr,
    String? expDateStr,
    String? mfgDateStr,
    String? mfgBatch,
    String? unitPack,
  }) onBatchSelectedOrAutoloaded;

  const _BatchNoTextFieldWithSuggestions({
    required this.row,
    required this.batchOptions,
    required this.batchDetails,
    required this.batchIdsByBinId,
    required this.batchIdsByBin,
    this.productUnitPackId,
    this.readOnly = false,
    required this.onBatchSelectedOrAutoloaded,
  });

  @override
  State<_BatchNoTextFieldWithSuggestions> createState() =>
      _BatchNoTextFieldWithSuggestionsState();
}

class _BatchNoTextFieldWithSuggestionsState
    extends State<_BatchNoTextFieldWithSuggestions> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _hideOverlay();
        }
      });
    }
  }

  List<Map<String, dynamic>> _getMatchingBatches() {
    final query = widget.row.batchNoCtrl.text.trim().toLowerCase();
    final selectedBinCode = (widget.row.binLabel ?? '').trim().toLowerCase();
    final selectedBinId = (widget.row.binId ?? '').trim();

    final allDetailsMap = <String, Map<String, dynamic>>{};
    for (final b in widget.batchDetails) {
      final bNo = (b['batch_no'] ?? b['batchNo'])?.toString().trim();
      if (bNo != null && bNo.isNotEmpty) {
        allDetailsMap[bNo.toLowerCase()] = Map<String, dynamic>.from(b);
      }
    }
    for (final opt in widget.batchOptions) {
      final optTrim = opt.trim();
      if (optTrim.isNotEmpty && !allDetailsMap.containsKey(optTrim.toLowerCase())) {
        allDetailsMap[optTrim.toLowerCase()] = {
          'batch_no': optTrim,
          'batchNo': optTrim,
          'balance': '0',
          'expiry_date': '-',
          'expiryDate': '-',
          'mrp': '0.00',
          'prate': '0.00',
          'ptr': '0.00',
        };
      }
    }

    Set<String>? allowedBatchKeys;
    if (selectedBinId.isNotEmpty && widget.batchIdsByBinId.containsKey(selectedBinId)) {
      allowedBatchKeys = widget.batchIdsByBinId[selectedBinId];
    } else if (selectedBinCode.isNotEmpty && widget.batchIdsByBin.containsKey(selectedBinCode)) {
      allowedBatchKeys = widget.batchIdsByBin[selectedBinCode];
    }

    final candidates = <Map<String, dynamic>>[];
    for (final entry in allDetailsMap.entries) {
      final item = entry.value;
      final bNo = (item['batch_no'] ?? item['batchNo'])?.toString() ?? '';
      final bId = (item['id'] ?? item['batchId'] ?? item['batch_id'])?.toString() ?? '';
      final bBinId = (item['bin_id'] ?? item['binId'] ?? item['bin_master_id'])?.toString() ?? '';
      final bBinCode = (item['bin_code'] ?? item['binCode'] ?? item['bin_location'])?.toString() ?? '';

      bool matchesBin = true;
      if (selectedBinId.isNotEmpty || selectedBinCode.isNotEmpty) {
        matchesBin = false;
        if (selectedBinId.isNotEmpty && bBinId == selectedBinId) matchesBin = true;
        if (selectedBinCode.isNotEmpty && bBinCode.toLowerCase() == selectedBinCode) matchesBin = true;
        if (allowedBatchKeys != null) {
          if ((bId.isNotEmpty && allowedBatchKeys.contains(bId)) ||
              (bNo.isNotEmpty && allowedBatchKeys.contains(bNo.toLowerCase()))) {
            matchesBin = true;
          }
        }
      }

      if (matchesBin) {
        if (query.isEmpty || bNo.toLowerCase().contains(query)) {
          candidates.add(item);
        }
      }
    }

    if (candidates.isEmpty) {
      for (final entry in allDetailsMap.entries) {
        final item = entry.value;
        final bNo = (item['batch_no'] ?? item['batchNo'])?.toString() ?? '';
        if (query.isEmpty || bNo.toLowerCase().contains(query)) {
          candidates.add(item);
        }
      }
    }

    return candidates;
  }

  void _showOverlay() {
    _hideOverlay();

    final initialCandidates = _getMatchingBatches();
    if (initialCandidates.isEmpty) {
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final currentCandidates = _getMatchingBatches();
        if (currentCandidates.isEmpty) {
          return const SizedBox.shrink();
        }

        return Positioned(
          width: 320,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 40),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: currentCandidates.length,
                  itemBuilder: (context, index) {
                    final item = currentCandidates[index];
                    final batchNo = (item['batch_no'] ?? item['batchNo'])?.toString() ?? '';
                    final balance = item['balance']?.toString() ?? '0';
                    final expDate = (item['expiry_date'] ?? item['expiryDate'])?.toString() ?? '-';
                    final mrp = (item['mrp'] ?? '0.00').toString();
                    final ptr = (item['ptr'] ?? item['prate'] ?? '0.00').toString();

                    final displayText = '$batchNo | Bal: $balance | Exp: $expDate | MRP: $mrp | prate: $ptr';

                    return _BatchSuggestionTile(
                      text: displayText,
                      onTap: () {
                        _selectBatchItem(item);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectBatchItem(Map<String, dynamic> item) {
    final batchNo = (item['batch_no'] ?? item['batchNo'])?.toString().trim() ?? '';
    widget.row.batchNoCtrl.text = batchNo;

    final mrp = item['mrp']?.toString();
    final ptr = item['ptr']?.toString() ?? item['prate']?.toString();
    final expDateStr = item['expiry_date']?.toString() ?? item['expiryDate']?.toString();
    final mfgDateStr = item['manufacture_date']?.toString() ?? item['manufactureDate']?.toString();
    final mfgBatch = item['manufacture_batch']?.toString() ?? item['manufactureBatch']?.toString();
    final unitPack = item['unit_pack']?.toString() ?? item['unitPack']?.toString();

    widget.onBatchSelectedOrAutoloaded(
      mrp: mrp,
      ptr: ptr,
      expDateStr: expDateStr,
      mfgDateStr: mfgDateStr,
      mfgBatch: mfgBatch,
      unitPack: unitPack,
    );

    _focusNode.unfocus();
    _hideOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        height: 38,
        child: TextField(
          controller: widget.row.batchNoCtrl,
          focusNode: _focusNode,
          readOnly: widget.readOnly,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1F2937),
            fontFamily: 'Inter',
          ),
          onChanged: (text) {
            final val = text.trim();
            final candidates = _getMatchingBatches();
            if (candidates.isEmpty) {
              _hideOverlay();
            } else if (_overlayEntry != null) {
              _overlayEntry!.markNeedsBuild();
            } else if (_focusNode.hasFocus) {
              _showOverlay();
            }

            final match = widget.batchDetails.firstWhere(
              (b) => (b['batch_no'] ?? b['batchNo'])?.toString().trim().toLowerCase() == val.toLowerCase(),
              orElse: () => <String, dynamic>{},
            );

            if (match.isNotEmpty) {
              final mrp = match['mrp']?.toString();
              final ptr = match['ptr']?.toString() ?? match['prate']?.toString();
              final expDateStr = match['expiry_date']?.toString() ?? match['expiryDate']?.toString();
              final mfgDateStr = match['manufacture_date']?.toString() ?? match['manufactureDate']?.toString();
              final mfgBatch = match['manufacture_batch']?.toString() ?? match['manufactureBatch']?.toString();
              final unitPack = match['unit_pack']?.toString() ?? match['unitPack']?.toString();

              widget.onBatchSelectedOrAutoloaded(
                mrp: mrp,
                ptr: ptr,
                expDateStr: expDateStr,
                mfgDateStr: mfgDateStr,
                mfgBatch: mfgBatch,
                unitPack: unitPack,
              );
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.readOnly ? const Color(0xFFF3F4F6) : Colors.white,
            isDense: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            constraints: const BoxConstraints(minHeight: 38, maxHeight: 38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
            ),
            hintText: 'Select or enter Batch',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _BatchSuggestionTile extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _BatchSuggestionTile({
    required this.text,
    required this.onTap,
  });

  @override
  State<_BatchSuggestionTile> createState() => _BatchSuggestionTileState();
}

class _BatchSuggestionTileState extends State<_BatchSuggestionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          widget.onTap();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: _isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 12,
              color: _isHovered ? Colors.white : const Color(0xFF1F2937),
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}
