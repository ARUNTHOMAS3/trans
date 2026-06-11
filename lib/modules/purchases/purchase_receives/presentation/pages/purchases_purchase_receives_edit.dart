import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' show max;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import '../../models/purchases_purchase_receives_model.dart';
import '../../providers/purchase_receives_provider.dart';
import '../../../purchase_orders/providers/purchases_purchase_orders_provider.dart'
    hide warehousesProvider;
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/items_stock_providers.dart';
import 'package:skeletonizer/skeletonizer.dart' hide Skeleton;
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';
import 'package:zerpai_erp/shared/providers/lookup_providers.dart';

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

Widget _buildDropdownOverlayItem(
  String text,
  bool isSelected,
  bool isHovered, {
  bool isDisabled = false,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: isHovered
          ? AppTheme.primaryBlue
          : (isDisabled || isSelected)
          ? const Color(0xFFF3F4F6)
          : Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: isHovered
            ? Colors.white
            : (isDisabled ? Colors.grey.shade600 : _textPrimary),
        fontFamily: 'Inter',
      ),
    ),
  );
}

class _ReceiveItemRowController {
  final TextEditingController qtyCtrl = TextEditingController();

  void dispose() {
    qtyCtrl.dispose();
  }
}

class _BatchItemRowController {
  final LayerLink layerLink = LayerLink();
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
  String? selectedBatchNo;

  _BatchItemRowController({BatchInfo? initial}) {
    if (initial != null) {
      batchNoCtrl.text = initial.batchNo;
      unitPackCtrl.text = initial.unitPack;
      mrpCtrl.text = initial.mrp.toString();
      ptrCtrl.text = initial.ptr.toString();
      qtyCtrl.text = initial.quantity.toString();
      focCtrl.text = initial.foc.toString();
      mfgBatchCtrl.text = initial.manufactureBatch;
      mfgDate = initial.manufactureDate;
      expDate = initial.expiryDate;
      if (mfgDate != null)
        mfgDateCtrl.text = DateFormat('dd-MM-yyyy').format(mfgDate!);
      if (expDate != null)
        expDateCtrl.text = DateFormat('dd-MM-yyyy').format(expDate!);
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
    );
  }
}

class PurchasesPurchaseReceivesEditScreen extends ConsumerStatefulWidget {
  final String id;
  const PurchasesPurchaseReceivesEditScreen({super.key, required this.id});

  @override
  ConsumerState<PurchasesPurchaseReceivesEditScreen> createState() =>
      _PREditState();
}

class _PREditState extends ConsumerState<PurchasesPurchaseReceivesEditScreen> {
  final _receiveNumberCtrl = TextEditingController();
  final _receivedDateCtrl = TextEditingController();
  final _billNoCtrl = TextEditingController();
  final _billDateCtrl = TextEditingController();
  final _invoiceTotalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _vendorNameCtrl = TextEditingController();
  final _poNumbersCtrl = TextEditingController();

  final GlobalKey _dateFieldKey = GlobalKey();
  final GlobalKey _billDateFieldKey = GlobalKey();
  String? _selectedVendorName;
  String? _selectedVendorId;
  String? _selectedWarehouseName;
  String? _selectedWarehouseId;
  bool _isLoadingData = true;
  bool _isSaving = false;
  bool _isManualMode = false;
  bool _isDamageEnabled = false;
  final List<String?> _preferredBins = [];
  final List<TextEditingController> _damageControllers = [];
  final List<PurchaseReceiveItem> _items = [];
  final List<_ReceiveItemRowController> _rowControllers = [];
  final Map<int, String> _rowSelectedWarehouses = {};
  final Map<int, String> _rowSelectedViews = {};

  final Set<String> _hoveredBinFields = <String>{};
  final Set<String> _focusedBinFields = <String>{};
  final Set<int> _hiddenManualIndices = <int>{};

  bool _showPOSearch = false;
  final TextEditingController _poSearchCtrl = TextEditingController();
  bool _showItemSearch = false;
  final TextEditingController _itemSearchCtrl = TextEditingController();
  bool _isBatchDialogOpen = false;

  OverlayEntry? _topErrorOverlayEntry;
  Timer? _topErrorTimer;
  final ScrollController _attachmentListScrollController = ScrollController();
  String _binMode = 'item';
  String? _selectedTransactionBin;

  static const TextStyle _batchChipTextStyle = TextStyle(
    fontSize: 10,
    height: 1.35,
    color: _textPrimary,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
  );

  static const TextStyle _itemNameMeasureStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFamily: 'Inter',
  );

  static const TextStyle _itemDescriptionMeasureStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: 'Inter',
  );

  static const TextStyle _itemHeaderMeasureStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    fontFamily: 'Inter',
  );

  void _selectAllIfZero(TextEditingController controller) {
    final String text = controller.text.trim();
    if (!RegExp(r'^0+(?:\.0+)?$').hasMatch(text)) return;
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  double _measureBatchLineWidth(String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _batchChipTextStyle),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  double _itemDetailsColumnWidth() {
    const baseWidth = 300.0;
    final headerWidth = _measureTextWidth(
      'ITEMS & DESCRIPTION',
      _itemHeaderMeasureStyle,
    );
    final itemWidth = _items.fold<double>(0, (currentMax, item) {
      final name = item.itemName.trim().isNotEmpty
          ? item.itemName.trim()
          : 'Unnamed Item';
      final description = item.description?.trim() ?? '';
      final nameWidth = _measureTextWidth(name, _itemNameMeasureStyle);
      final descriptionWidth = description.isEmpty
          ? 0
          : _measureTextWidth(description, _itemDescriptionMeasureStyle);
      return max(currentMax, max(nameWidth, descriptionWidth).toDouble());
    });
    final headerNeeded = headerWidth + 24;
    final itemNeeded = itemWidth + 100.0; // Reduced because no dropdown arrow
    return max(
      baseWidth,
      max(headerNeeded, itemNeeded),
    ).clamp(baseWidth, 2500.0);
  }

  double _batchCardWidth(BatchInfo batch) {
    final lines = <String>[
      'Batch: ${batch.batchNo}',
      'Qty: ${_fmtPcs(batch.quantity)} pcs',
      if (batch.foc > 0) 'FOC: ${_fmtPcs(batch.foc)} pcs',
      'Pack: ${batch.unitPack}',
      'MRP: ${batch.mrp}',
      'Purchase Rate: ${batch.ptr}',
      'Exp: ${batch.expiryDate != null ? DateFormat('dd-MM-yyyy').format(batch.expiryDate!) : ''}',
    ];
    final maxLineWidth = lines
        .map(_measureBatchLineWidth)
        .fold<double>(0, (maxWidth, width) => max(maxWidth, width));
    return (maxLineWidth + 18).clamp(80.0, 1200.0);
  }

  double _dynamicQtyToReceiveColumnWidth() {
    const baseWidth = 150.0;
    final headerWidth = _measureTextWidth(
      'QUANTITY TO RECEIVE',
      _itemHeaderMeasureStyle,
    );
    final headerNeeded = headerWidth + 24 + 10;
    const fixedContentWidth = 110.0;
    if (_items.isEmpty) return max(baseWidth, headerNeeded);
    final requiredWidth = _items.fold<double>(baseWidth, (currentMax, item) {
      if (item.batches.isEmpty) return currentMax;
      final cardsWidth = item.batches
          .map(_batchCardWidth)
          .fold<double>(0, (sum, width) => sum + width);
      return max(
        currentMax,
        fixedContentWidth + cardsWidth + (item.batches.length * 2.0),
      );
    });
    return max(requiredWidth, headerNeeded).clamp(baseWidth, 2400.0);
  }

  double _dynamicBinColumnWidth() => 160.0;

  double _poColumnWidth() {
    const baseWidth = 140.0;
    final headerWidth = _measureTextWidth(
      'PURCHASE ORDER',
      _itemHeaderMeasureStyle,
    );
    final headerNeeded = headerWidth + 5 + 12 + 24 + 10;

    // In edit mode, we might not have all POs loaded as objects, so we check the items
    final poNums = _items.map((i) => i.purchaseOrderNumber ?? '').toSet();
    final maxPoWidth = poNums.fold<double>(0, (maxW, num) {
      final w = _measureTextWidth(
        num,
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      );
      return w > maxW ? w : maxW;
    });
    return max(
      baseWidth,
      max(headerNeeded, maxPoWidth + 40),
    ).clamp(baseWidth, 300.0);
  }

  String _fmtPcs(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  @override
  void initState() {
    super.initState();
    _loadReceiveData();
  }

  Future<void> _loadReceiveData() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);

    try {
      final repository = ref.read(purchaseReceiveRepositoryProvider);
      final receive = await repository.getPurchaseReceive(widget.id);

      if (receive == null) {
        if (mounted) {
          ZerpaiToast.error(context, 'Purchase Receive not found');
          context.pop();
        }
        return;
      }

      if (!mounted) return;

      // Extract unique PO IDs from the receive items
      final uniquePOIds = receive.items
          .map((i) => i.purchaseOrderId)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      // Load actual PurchaseOrder objects so the table grouping works
      final loadedPOs = <PurchaseOrder>[];
      for (final poId in uniquePOIds) {
        try {
          final po = await ref.read(purchaseOrderProvider(poId).future);
          if (po != null) loadedPOs.add(po);
        } catch (e) {
          AppLogger.warning(
            'Could not load PO $poId for edit screen',
            error: e,
            module: 'purchases',
          );
        }
      }

      if (!mounted) return;

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
        _selectedVendorName = receive.vendorName;
        _vendorNameCtrl.text = receive.vendorName ?? '';

        // Populate loaded POs

        // Populate items
        _items.clear();
        _rowControllers.clear();
        _preferredBins.clear();
        _damageControllers.clear();

        for (final item in receive.items) {
          var poNum = item.purchaseOrderNumber;
          if (poNum == null || poNum.isEmpty) {
            try {
              poNum = loadedPOs
                  .firstWhere((p) => p.id == item.purchaseOrderId)
                  .orderNumber;
            } catch (_) {}
          }
          if (poNum == null || poNum.isEmpty) {
            poNum = receive.purchaseOrderNumber;
          }
          final updatedItem = poNum != item.purchaseOrderNumber
              ? item.copyWith(purchaseOrderNumber: poNum)
              : item;

          _items.add(updatedItem);
          final ctrl = _ReceiveItemRowController();
          ctrl.qtyCtrl.text = _fmtPcs(item.quantityToReceive);
          _rowControllers.add(ctrl);
          _preferredBins.add(item.binLabel);
          _damageControllers.add(TextEditingController());
        }

        // Set up PO numbers display
        final poNums = _items
            .map((i) => i.purchaseOrderNumber)
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toSet()
            .join(', ');
        _poNumbersCtrl.text = poNums.isNotEmpty ? poNums : (receive.purchaseOrderNumber ?? '');

        // Set warehouse from receive or first PO if available
        _selectedWarehouseId = receive.warehouseId;
        if (_selectedWarehouseId == null && loadedPOs.isNotEmpty) {
          final firstPO = loadedPOs.first;
          _selectedWarehouseId = firstPO.warehouseId;
          _selectedWarehouseName = firstPO.warehouseName;
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

  void _showTopError(String message) {
    _dismissTopError();
    final overlay = Overlay.of(context, rootOverlay: true);
    _topErrorOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
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
      ),
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

  @override
  void dispose() {
    _dismissTopError();
    _attachmentListScrollController.dispose();
    _receiveNumberCtrl.dispose();
    _receivedDateCtrl.dispose();
    _billNoCtrl.dispose();
    _billDateCtrl.dispose();
    _invoiceTotalCtrl.dispose();
    _notesCtrl.dispose();
    _vendorNameCtrl.dispose();
    _poNumbersCtrl.dispose();
    _poSearchCtrl.dispose();
    _itemSearchCtrl.dispose();
    for (final c in _damageControllers) c.dispose();
    for (var c in _rowControllers) c.dispose();
    super.dispose();
  }

  void _onRowQtyChanged(int index, String value) {
    if (index >= _items.length) return;
    final qty = double.tryParse(value.isEmpty ? '0' : value) ?? 0;
    setState(() {
      _items[index] = _items[index].copyWith(quantityToReceive: qty);
    });
  }

  void _adjustRowQuantity(int index, {required int delta}) {
    if (index >= _items.length || index >= _rowControllers.length) return;
    final ctrl = _rowControllers[index];
    final currentQty =
        double.tryParse(ctrl.qtyCtrl.text.isEmpty ? '0' : ctrl.qtyCtrl.text) ??
        0;
    final nextQty = (currentQty + delta).clamp(0, double.infinity).toDouble();
    final display = nextQty <= 0 ? '' : _fmtPcs(nextQty);
    setState(() {
      ctrl.qtyCtrl.text = display;
      _items[index] = _items[index].copyWith(quantityToReceive: nextQty);
    });
  }

  void _fillAllUnreceivedQuantities() {
    if (_items.isEmpty) return;
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        if (i >= _rowControllers.length) continue;
        final item = _items[i];
        final val = item.ordered - item.received;
        if (val > 0) {
          _rowControllers[i].qtyCtrl.text = _fmtPcs(val);
          _items[i] = _items[i].copyWith(quantityToReceive: val);
        }
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

  Future<void> _handleSave(String status) async {
    if (_isSaving) return;
    if (_billNoCtrl.text.trim().isEmpty) {
      _showTopError('Please enter Bill no#');
      return;
    }
    if (_billDateCtrl.text.trim().isEmpty) {
      _showTopError('Please enter Bill date');
      return;
    }
    if (_invoiceTotalCtrl.text.trim().isEmpty) {
      _showTopError('Please enter Bill invoice total');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repository = ref.read(purchaseReceiveRepositoryProvider);

      final updatedReceive = PurchaseReceive(
        id: widget.id,
        purchaseReceiveNumber: _receiveNumberCtrl.text.trim(),
        receivedDate: DateFormat(
          'dd-MM-yyyy',
        ).parse(_receivedDateCtrl.text.trim()),
        billNo: _billNoCtrl.text.trim(),
        billDate: DateFormat('dd-MM-yyyy').parse(_billDateCtrl.text.trim()),
        invoiceTotal: double.tryParse(_invoiceTotalCtrl.text.trim()) ?? 0,
        notes: _notesCtrl.text.trim(),
        vendorId: _selectedVendorId ?? '',
        vendorName: _selectedVendorName ?? '',
        status: status,
        items: _items.asMap().entries.map((e) {
          final item = e.value;
          return item;
        }).toList(),
      );

      final success = await repository.updatePurchaseReceive(
        widget.id,
        updatedReceive,
      );

      if (!mounted) return;

      if (success != null) {
        ZerpaiToast.success(context, 'Purchase receive updated successfully');
        context.pop(true);
      } else {
        ZerpaiToast.error(context, 'Failed to update purchase receive');
      }
    } catch (e, st) {
      if (mounted) {
        AppLogger.error(
          'Failed to update purchase receive',
          error: e,
          stackTrace: st,
          module: 'purchases',
        );
        ZerpaiToast.error(context, 'Failed to update purchase receive');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: true,
      useHorizontalPadding: false,
      useTopPadding: false,
      footer: _buildStickyFooter(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildFormSection(),
          const SizedBox(height: 20),
          _buildBinSelectionSection(),
          const SizedBox(height: 24),
          _buildItemsTable(),
          const SizedBox(height: 32),
          _buildNotesAndUploadSection(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          const Icon(LucideIcons.package, size: 22, color: _textPrimary),
          const SizedBox(width: 10),
          const Text(
            'Edit Purchase Receive',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => context.pop(),
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

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFEEEEEE),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormRow(
                label: "Vendor Name",
                isRequired: true,
                child: SizedBox(
                  width: 400,
                  child: CustomTextField(
                    height: 32,
                    controller: _vendorNameCtrl,
                    readOnly: true,
                    fillColor: const Color(0xFFF5F5F5),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildFormRow(
                label: "Purchase Order#",
                child: SizedBox(
                  width: 400,
                  child: CustomTextField(
                    height: 32,
                    controller: _poNumbersCtrl,
                    readOnly: true,
                    fillColor: const Color(0xFFF5F5F5),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
                      child: CustomTextField(
                        height: 32,
                        controller: _billNoCtrl,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r"[a-zA-Z0-9]"),
                          ),
                        ],
                        textStyle: const TextStyle(
                          fontSize: 13,
                          color: _textPrimary,
                          fontFamily: "Inter",
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
                      child: CustomTextField(
                        height: 32,
                        controller: _billDateCtrl,
                        key: _billDateFieldKey,
                        readOnly: true,
                        onTap: () async {
                          final picked = await ZerpaiDatePicker.show(
                            context,
                            initialDate: DateTime.now(),
                            targetKey: _billDateFieldKey,
                          );
                          if (picked != null && mounted) {
                            setState(
                              () => _billDateCtrl.text = DateFormat(
                                "dd-MM-yyyy",
                              ).format(picked),
                            );
                          }
                        },
                        textStyle: const TextStyle(
                          fontSize: 13,
                          color: _textPrimary,
                          fontFamily: "Inter",
                        ),
                        hintText: "dd-MM-yyyy",
                        suffixWidget: const Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: _hintColor,
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
                      child: CustomTextField(
                        height: 32,
                        controller: _invoiceTotalCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$'),
                          ),
                        ],
                        textStyle: const TextStyle(
                          fontSize: 13,
                          color: _textPrimary,
                          fontFamily: "Inter",
                        ),
                        hintText: "0.00",
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 60),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormRow(
                    label: "Purchase Receive#",
                    isRequired: true,
                    child: SizedBox(
                      width: 180,
                      child: CustomTextField(
                        height: 32,
                        controller: _receiveNumberCtrl,
                        readOnly: true,
                        fillColor: const Color(0xFFF5F5F5),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          color: _textPrimary,
                          fontFamily: "Inter",
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
                      child: CustomTextField(
                        height: 32,
                        controller: _receivedDateCtrl,
                        key: _dateFieldKey,
                        readOnly: true,
                        onTap: () async {
                          final picked = await ZerpaiDatePicker.show(
                            context,
                            initialDate: DateTime.now(),
                            targetKey: _dateFieldKey,
                          );
                          if (picked != null && mounted) {
                            setState(
                              () => _receivedDateCtrl.text = DateFormat(
                                "dd-MM-yyyy",
                              ).format(picked),
                            );
                          }
                        },
                        textStyle: const TextStyle(
                          fontSize: 13,
                          color: _textPrimary,
                          fontFamily: "Inter",
                        ),
                        hintText: "dd-MM-yyyy",
                        suffixWidget: const Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: _hintColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }



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
                      text: ' *',
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
              itemBuilder: (item, isSelected, isHovered) =>
                  _buildDropdownOverlayItem(
                    item == 'transaction' ? 'Transaction Level' : 'Item Level',
                    isSelected,
                    isHovered,
                  ),
              displayStringForValue: (v) =>
                  v == 'transaction' ? 'Transaction Level' : 'Item Level',
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _binMode = val;
                    if (_binMode == 'item') {
                      // Ensure _preferredBins is correctly sized
                      while (_preferredBins.length < _items.length) {
                        _preferredBins.add(_selectedTransactionBin);
                      }
                      // Propagate transaction bin to ALL items when switching to Item Level
                      if (_selectedTransactionBin != null) {
                        for (int i = 0; i < _preferredBins.length; i++) {
                          _preferredBins[i] = _selectedTransactionBin;
                        }
                      }
                    }
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 20),
          if (_binMode == 'transaction')
            SizedBox(
              width: 220,
              child: Consumer(
                builder: (context, ref, _) {
                  final binsAsync = ref.watch(
                    binsLookupProvider(_selectedWarehouseId),
                  );
                  final bins = binsAsync.asData?.value.map((b) => b['bin_code']!).toList() ?? [];
                  return Skeletonizer(
                    enabled: binsAsync.isLoading,
                    child: FormDropdown<String>(
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
                        for (int i = 0; i < _preferredBins.length; i++) {
                          _preferredBins[i] = val;
                        }
                      }
                    }),
                  ),);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    if (_isManualMode) {
      return _buildManualItemsTable();
    } else {
      return _buildItemsTableNormal();
    }
  }

  Widget _buildItemsTableNormal() {
    final poSearch = _poSearchCtrl.text.trim().toLowerCase();
    final itemSearch = _itemSearchCtrl.text.trim().toLowerCase();

    // Group consecutive items by purchaseOrderId
    final visibleEntries = _items.asMap().entries.where((e) {
      final item = e.value;

      // Filter by PO Search
      if (_showPOSearch && poSearch.isNotEmpty) {
        if (!(item.purchaseOrderNumber ?? '').toLowerCase().contains(poSearch)) {
          return false;
        }
      }

      // Filter by Item Search
      if (_showItemSearch && itemSearch.isNotEmpty) {
        final matchesName = item.itemName.toLowerCase().contains(itemSearch);
        final matchesDesc = (item.description ?? '').toLowerCase().contains(itemSearch);
        if (!matchesName && !matchesDesc) {
          return false;
        }
      }

      // In edit mode, we show all items that are part of the receive
      return true;
    }).toList();

    final groups =
        <
          ({
            String? poId,
            String? poNumber,
            List<MapEntry<int, PurchaseReceiveItem>> entries,
          })
        >[];
    for (final entry in visibleEntries) {
      final poId = entry.value.purchaseOrderId;
      if (groups.isEmpty || groups.last.poId != poId) {
        groups.add((
          poId: poId,
          poNumber: entry.value.purchaseOrderNumber,
          entries: [entry],
        ));
      } else {
        groups.last.entries.add(entry);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicWidth(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border.fromBorderSide(
                      BorderSide(color: _borderCol),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildItemsTableHeaderNormal(),
                      if (visibleEntries.isEmpty)
                        _buildEmptyRow()
                      else
                        ...groups.map(
                          (group) => _buildPOGroupRows(
                            poNumber: group.poNumber,
                            entries: group.entries,
                            isManual: false,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildManualItemsTable() {
    final poSearch = _poSearchCtrl.text.trim().toLowerCase();
    final itemSearch = _itemSearchCtrl.text.trim().toLowerCase();

    final visibleEntries = _items
        .asMap()
        .entries
        .where((e) {
          if (_hiddenManualIndices.contains(e.key)) return false;
          
          final item = e.value;
          // Filter by PO Search
          if (_showPOSearch && poSearch.isNotEmpty) {
            if (!(item.purchaseOrderNumber ?? '').toLowerCase().contains(poSearch)) {
              return false;
            }
          }

          // Filter by Item Search
          if (_showItemSearch && itemSearch.isNotEmpty) {
            final matchesName = item.itemName.toLowerCase().contains(itemSearch);
            final matchesDesc = (item.description ?? '').toLowerCase().contains(itemSearch);
            if (!matchesName && !matchesDesc) {
              return false;
            }
          }
          
          return true;
        })
        .toList();

    final groups =
        <
          ({
            String? poId,
            String? poNumber,
            List<MapEntry<int, PurchaseReceiveItem>> entries,
          })
        >[];
    for (final entry in visibleEntries) {
      final poId = entry.value.purchaseOrderId;
      if (groups.isEmpty || groups.last.poId != poId) {
        groups.add((
          poId: poId,
          poNumber: entry.value.purchaseOrderNumber,
          entries: [entry],
        ));
      } else {
        groups.last.entries.add(entry);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicWidth(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border.fromBorderSide(
                      BorderSide(color: _borderCol),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildItemsTableHeaderManual(),
                      if (visibleEntries.isEmpty)
                        _buildEmptyRow()
                      else
                        ...groups.map(
                          (group) => _buildPOGroupRows(
                            poNumber: group.poNumber,
                            entries: group.entries,
                            isManual: true,
                          ),
                        ),
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: _borderCol,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildInsertRowButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTableHeaderNormal() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(bottom: BorderSide(color: _borderCol, width: 0.8)),
      ),
      child: Row(
        children: [
          _tableHeaderCell(
            "",
            fixedWidth: _poColumnWidth(),
            child: _showPOSearch
                ? _buildHeaderSearchField(
                    controller: _poSearchCtrl,
                    hint: "Search PO...",
                    onClose: () {
                      setState(() {
                        _showPOSearch = false;
                        _poSearchCtrl.clear();
                      });
                    },
                  )
                : InkWell(
                    onTap: () => setState(() => _showPOSearch = true),
                    child: Row(
                      children: [
                        const Text(
                          "PURCHASE ORDER",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Inter',
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          LucideIcons.search,
                          size: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ),
          ),
          _tableHeaderCell(
            "",
            fixedWidth: _itemDetailsColumnWidth(),
            child: _showItemSearch
                ? _buildHeaderSearchField(
                    controller: _itemSearchCtrl,
                    hint: "Search Item...",
                    onClose: () {
                      setState(() {
                        _showItemSearch = false;
                        _itemSearchCtrl.clear();
                      });
                    },
                  )
                : InkWell(
                    onTap: () => setState(() => _showItemSearch = true),
                    child: Row(
                      children: [
                        const Text(
                          "ITEMS & DESCRIPTION",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Inter',
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          LucideIcons.search,
                          size: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ),
          ),
          _tableHeaderCell(
            "ORDERED",
            fixedWidth: 110,
            align: TextAlign.center,
            containerAlignment: Alignment.center,
          ),
          _tableHeaderCell(
            "RECEIVED",
            fixedWidth: 110,
            align: TextAlign.center,
            containerAlignment: Alignment.center,
          ),
          _tableHeaderCell(
            "IN TRANSIT",
            fixedWidth: 120,
            align: TextAlign.center,
            containerAlignment: Alignment.center,
          ),
          if (_binMode == "item")
            _tableHeaderCell("BIN", fixedWidth: _dynamicBinColumnWidth()),
          _buildQtyHeaderCell(fixedWidth: _dynamicQtyToReceiveColumnWidth()),
          _tableHeaderCell(
            "",
            fixedWidth: 32,
            isLastColumn: true,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTableHeaderManual() {
    return _buildItemsTableHeaderNormal();
  }

  Widget _buildEmptyRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderCol)),
      ),
      child: const Text(
        'No items to display',
        style: TextStyle(fontSize: 13, color: _hintColor, fontFamily: 'Inter'),
      ),
    );
  }

  Widget _buildInsertRowButton() {
    return TextButton(
      onPressed: _insertManualRow,
      style: TextButton.styleFrom(
        foregroundColor: _linkBlue,
        padding: EdgeInsets.zero,
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



  void _insertManualRow() {
    setState(() {
      _items.add(PurchaseReceiveItem());
      _rowControllers.add(_ReceiveItemRowController());
      _preferredBins.add(null);
      _damageControllers.add(TextEditingController());
    });
  }

  Widget _buildQtyHeaderCell({required double fixedWidth}) {
    return SizedBox(
      width: fixedWidth,
      child: Container(
        decoration: const BoxDecoration(border: Border(right: BorderSide.none)),
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

  Widget _tableHeaderCell(
    String text, {
    double? fixedWidth,
    TextAlign? align,
    Alignment? containerAlignment,
    bool isLastColumn = false,
    Widget? child,
    EdgeInsetsGeometry? padding,
  }) {
    final content = Container(
      alignment: containerAlignment,
      decoration: BoxDecoration(
        border: Border(
          right: isLastColumn
              ? BorderSide.none
              : const BorderSide(color: _borderCol, width: 0.8),
        ),
      ),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

    return Expanded(child: content);
  }

  Widget _buildPOGroupRows({
    required String? poNumber,
    required List<MapEntry<int, PurchaseReceiveItem>> entries,
    required bool isManual,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PO cell – spans all items in the group
          Container(
            width: _poColumnWidth(),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: _borderCol, width: 0.8),
                bottom: BorderSide(color: _borderCol, width: 0.8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            alignment: Alignment.center,
            child: Text(
              poNumber ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          // Item rows stacked vertically
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: entries
                  .map(
                    (entry) => isManual
                        ? _buildManualRowCells(entry.key, entry.value)
                        : _buildItemRowCells(entry.key, entry.value),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualRowCells(int index, PurchaseReceiveItem item) {
    if (!_rowSelectedWarehouses.containsKey(index)) {
      _rowSelectedWarehouses[index] = _selectedWarehouseName ?? '';
    }
    if (!_rowSelectedViews.containsKey(index)) {
      _rowSelectedViews[index] = 'Accounting';
    }
    final ctrl = index < _rowControllers.length
        ? _rowControllers[index]
        : _ReceiveItemRowController();

    // In edit mode, we use the items already in the receive
    final hasBatches = item.batches.isNotEmpty;
    final bool hasItem = (item.itemId ?? '').isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderCol, width: 0.8)),
      ),
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tableBodyCell(
              fixedWidth: _itemDetailsColumnWidth(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
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
                                : "No item selected",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: item.itemName.isNotEmpty
                                  ? _textPrimary
                                  : _hintColor,
                              fontFamily: "Inter",
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
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
                              overflow: TextOverflow.visible,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: 110,
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  _fmtPcs(item.ordered),
                  textAlign: TextAlign.center,
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
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  _fmtPcs(item.received),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
                    fontFamily: "Inter",
                  ),
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: 120,
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  _fmtPcs(item.inTransit),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
                    fontFamily: "Inter",
                  ),
                ),
              ),
            ),
            if (_binMode == "item")
              _tableBodyCell(
                fixedWidth: _dynamicBinColumnWidth(),
                child: !hasItem
                    ? const SizedBox()
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _BinHoverBox(
                          isEnabled: index < _preferredBins.length &&
                              _preferredBins[index] != null &&
                              _preferredBins[index]!.isNotEmpty,
                          message: index < _preferredBins.length
                              ? (_preferredBins[index] ?? '')
                              : '',
                          child: Consumer(
                            builder: (context, ref, _) {
                              final binsAsync = ref.watch(
                                binsLookupProvider(_selectedWarehouseId),
                              );
                              final bins = binsAsync.asData?.value.map((b) => b['bin_code']!).toList() ?? [];

                              return Skeletonizer(
                                enabled: binsAsync.isLoading,
                                child: FormDropdown<String>(
                                  value: index < _preferredBins.length
                                      ? _preferredBins[index]
                                      : null,
                                  items: bins,
                                  hint: "Select Bin",
                                  showSearch: true,
                                border: Border.all(
                                  color:
                                      (_hoveredBinFields.contains(
                                            "manual-bin-$index",
                                          ) ||
                                          _focusedBinFields.contains(
                                            "manual-bin-$index",
                                          ))
                                      ? _focusBorder
                                      : Colors.transparent,
                                  width:
                                      (_hoveredBinFields.contains(
                                            "manual-bin-$index",
                                          ) ||
                                          _focusedBinFields.contains(
                                            "manual-bin-$index",
                                          ))
                                      ? 1.2
                                      : 1,
                                ),
                                itemBuilder: (item, isSelected, isHovered) =>
                                    _buildDropdownOverlayItem(
                                      item,
                                      isSelected,
                                      isHovered,
                                    ),
                                onChanged: (bin) {
                                  if (index >= _preferredBins.length) return;
                                  setState(() {
                                    _preferredBins[index] = bin;
                                    _focusedBinFields.remove(
                                      "manual-bin-$index",
                                    );
                                  });
                                },
                              ),
                            );
                            },
                          ),
                        ),
                      ),
              ),
            _tableBodyCell(
              fixedWidth: _dynamicQtyToReceiveColumnWidth(),
              hideRightBorder: true,
              padding: EdgeInsets.zero,
              child: !hasItem
                  ? const SizedBox()
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                                _buildQtyControl(
                                  fieldKey: 'manual-$index',
                                  controller: ctrl.qtyCtrl,
                                  onChanged: (val) =>
                                      _onRowQtyChanged(index, val),
                                  onIncrement: () =>
                                      _adjustRowQuantity(index, delta: 1),
                                  onDecrement: () =>
                                      _adjustRowQuantity(index, delta: -1),
                                ),
                                if (!hasBatches &&
                                    item.quantityToReceive > 0 &&
                                    item.quantityToReceive <= item.ordered) ...[
                                  const SizedBox(height: 4),
                                  _buildAddBatchesLinkButton(index),
                                ],
                                _buildQtyAndFocBreakdown(item),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (hasBatches)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (final batch in item.batches) ...[
                                        GestureDetector(
                                          onTap: () =>
                                              _showSelectBatchDialog(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F9F5),
                                              border: Border.all(
                                                color: const Color(0xFFCFE9D8),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _batchText(
                                                  'Batch: ${batch.batchNo}',
                                                ),
                                                _batchText(
                                                  'Qty: ${_fmtPcs(batch.quantity)} pcs',
                                                ),
                                                if (batch.foc > 0)
                                                  _batchText(
                                                    'FOC: ${_fmtPcs(batch.foc)} pcs',
                                                  ),
                                                _batchText(
                                                  'Pack: ${batch.unitPack}',
                                                ),
                                                _batchText('MRP: ${batch.mrp}'),
                                                _batchText(
                                                  'Purchase Rate: ${batch.ptr}',
                                                ),
                                                _batchText(
                                                  'Exp: ${batch.expiryDate != null ? DateFormat('dd-MM-yyyy').format(batch.expiryDate!) : ''}',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
            ),
            _tableBodyCell(
              fixedWidth: 32,
              isLastColumn: true,
              child: _getVisibleCount() <= 1
                  ? const SizedBox()
                  : Center(
                      child: InkWell(
                        onTap: () => _removeItem(index),
                        borderRadius: BorderRadius.circular(4),
                        child: const Icon(LucideIcons.x, size: 14, color: _dangerRed),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRowCells(int index, PurchaseReceiveItem item) {
    return _buildManualRowCells(index, item);
  }

  Widget _tableBodyCell({
    double? fixedWidth,
    Alignment alignment = Alignment.centerLeft,
    required Widget child,
    bool isLastColumn = false,
    bool hideRightBorder = false,
    EdgeInsetsGeometry? padding,
  }) {
    return SizedBox(
      width: fixedWidth,
      child: Container(
        alignment: alignment,
        decoration: BoxDecoration(
          border: Border(
            right: (isLastColumn || hideRightBorder)
                ? BorderSide.none
                : const BorderSide(color: _borderCol, width: 0.8),
          ),
        ),
        padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
        child: child,
      ),
    );
  }

  Widget _buildQtyControl({
    required String fieldKey,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return SizedBox(
      width: 80,
      child: CustomTextField(
        height: 32,
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          fontFamily: 'Inter',
          color: _textPrimary,
        ),
        onTap: () => _selectAllIfZero(controller),
        hintText: '0',
      ),
    );
  }

  Widget _batchText(String text) => Text(text, style: _batchChipTextStyle);

  int _getVisibleCount() {
    final poSearch = _poSearchCtrl.text.trim().toLowerCase();
    final itemSearch = _itemSearchCtrl.text.trim().toLowerCase();

    return _items.asMap().entries.where((e) {
      if (_isManualMode && _hiddenManualIndices.contains(e.key)) return false;

      final item = e.value;
      if (_showPOSearch && poSearch.isNotEmpty) {
        if (!(item.purchaseOrderNumber ?? '')
            .toLowerCase()
            .contains(poSearch)) {
          return false;
        }
      }
      if (_showItemSearch && itemSearch.isNotEmpty) {
        final matchesName = item.itemName.toLowerCase().contains(itemSearch);
        final matchesDesc =
            (item.description ?? '').toLowerCase().contains(itemSearch);
        if (!matchesName && !matchesDesc) {
          return false;
        }
      }
      return true;
    }).length;
  }

  void _removeItem(int index) {
    if (_getVisibleCount() <= 1) return;
    setState(() {
      if (index < _items.length) {
        _items.removeAt(index);
        _rowControllers[index].dispose();
        _rowControllers.removeAt(index);
        _preferredBins.removeAt(index);
        _damageControllers[index].dispose();
        _damageControllers.removeAt(index);
        _hiddenManualIndices.remove(index);
      }
    });
  }

  Widget _buildQtyAndFocBreakdown(PurchaseReceiveItem item) {
    final qty = item.batches.fold<double>(0, (sum, b) => sum + b.quantity);
    final foc = item.batches.fold<double>(0, (sum, b) => sum + b.foc);
    if (qty <= 0 && foc <= 0) return const SizedBox.shrink();
    return Text(
      "${_fmtPcs(qty)} pcs${foc > 0 ? ' + ${_fmtPcs(foc)} foc' : ''}",
      style: const TextStyle(fontSize: 11, color: _hintColor),
    );
  }

  Future<void> _showSelectBatchDialog(int itemIndex) async {
    if (_isBatchDialogOpen) return;
    _isBatchDialogOpen = true;

    final item = _items[itemIndex];
    List<BatchData> batchDataOptions = [];
    final batchOptions = <String>{};

    final itemId = item.itemId?.trim();
    if (itemId != null && itemId.isNotEmpty) {
      try {
        await ref.read(warehousesProvider.future);
        final dbBatches = await ref.refresh(itemBatchesProvider(itemId).future);
        final dbBatchNumbers = dbBatches
            .map((b) => b.batchReference.trim())
            .where((v) => v.isNotEmpty)
            .toList();
        batchOptions.addAll(dbBatchNumbers);
        batchDataOptions = dbBatches;
      } catch (_) {}
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _SelectBatchDialog(
        itemName: item.itemName,
        batchOptions: batchOptions.toList()..sort(),
        batchDataOptions: batchDataOptions,
        initialBatches: item.batches,
        ordered:
            double.tryParse(_rowControllers[itemIndex].qtyCtrl.text) ??
            item.quantityToReceive,
        poOrdered: item.ordered,
        warehouseName:
            _rowSelectedWarehouses[itemIndex] ??
            _selectedWarehouseName ??
            "Not Available",
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
              (sum, batch) => sum + batch.quantity + batch.foc,
            );
 
            _items[itemIndex] = item.copyWith(
              batches: newBatches,
              quantityToReceive: combinedQty,
            );
            _rowControllers[itemIndex].qtyCtrl.text = _fmtPcs(combinedQty);
            _hiddenManualIndices.remove(itemIndex);
          });
        },
      ),
    ).then((_) {
      _isBatchDialogOpen = false;
    });
  }

  Widget _buildHeaderSearchField({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onClose,
  }) {
    return Container(
      width: double.infinity,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(
          fontSize: 12,
          color: _textPrimary,
          fontFamily: 'Inter',
        ),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 12,
            color: _hintColor,
            fontFamily: 'Inter',
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: InkWell(
            onTap: onClose,
            child: const Icon(LucideIcons.x, size: 14, color: _hintColor),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesAndUploadSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Notes",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _labelColor,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _notesCtrl,
            maxLines: 3,
            height: 80,
            hintText: "Enter notes here...",
            textStyle: const TextStyle(
              fontSize: 13,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: const BoxDecoration(
        color: _bgWhite,
        border: Border(top: BorderSide(color: _borderCol)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [

          ElevatedButton(
            onPressed: _isSaving ? null : () => _handleSave('received'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _greenBtn,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Mark as Received',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => context.pop(),
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
        ],
      ),
    );
  }
}

class _SelectBatchDialog extends StatefulWidget {
  final String itemName;
  final String warehouseName;
  final double ordered;
  final double poOrdered;
  final List<String> batchOptions;
  final List<BatchData> batchDataOptions;
  final List<BatchInfo> initialBatches;
  final bool initialDamageEnabled;
  final ValueChanged<bool>? onDamageChanged;
  final void Function(String message)? onTopError;
  final Function(List<BatchInfo>) onSave;

  _SelectBatchDialog({
    required this.itemName,
    required this.warehouseName,
    required this.ordered,
    required this.poOrdered,
    required this.batchOptions,
    required this.batchDataOptions,
    required this.initialBatches,
    this.initialDamageEnabled = false,
    this.onDamageChanged,
    this.onTopError,
    required this.onSave,
  });

  @override
  State<_SelectBatchDialog> createState() => _SelectBatchDialogState();
}

class _SelectBatchDialogState extends State<_SelectBatchDialog> {
  final List<_BatchItemRowController> _rows = [];
  final Map<_BatchItemRowController, TextEditingController>
  _batchInputControllers = {};
  final Map<_BatchItemRowController, FocusNode> _batchInputFocusNodes = {};
  OverlayEntry? _batchOverlayEntry;
  _BatchItemRowController? _activeRowForOverlay;

  bool _showMfgDetails = false;
  bool _showFoc = false;
  bool _showDamage = false;
  bool _overwriteLineItem = false;
  String? _dialogErrorMessage;

  static const String _qtyOrFocMessage =
      'Either Quantity or FOC must be entered';
  static const String _batchNoMissingMessage =
      'Please make sure that you have entered batch reference numbers for all the batches.';
  static const String _unitPackMissingMessage =
      'Unit Pack cannot be empty. Enter a unit pack to proceed.';
  static const String _mrpMissingMessage =
      'MRP cannot be empty. Enter an MRP to proceed.';
  static const String _expDateMissingMessage =
      'Expiry Date cannot be empty. Select an expiry date to proceed.';

  void _selectAllIfZero(TextEditingController controller) {
    final String text = controller.text.trim();
    if (!RegExp(r'^0+(?:\.0+)?$').hasMatch(text)) return;
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  final TextInputFormatter _numericInputFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text;
        if (text.isEmpty || RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
          return newValue;
        }
        return oldValue;
      });

  @override
  void initState() {
    super.initState();
    _showDamage = widget.initialDamageEnabled;
    if (widget.initialBatches.isEmpty) {
      final firstRow = _BatchItemRowController();
      firstRow.qtyCtrl.text = widget.ordered.toString();
      _rows.add(firstRow);
    } else {
      for (var b in widget.initialBatches) {
        _rows.add(_BatchItemRowController(initial: b));
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
    _hideBatchOverlay();
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
      _rows.add(_BatchItemRowController());
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

  void _hideBatchOverlay() {
    _batchOverlayEntry?.remove();
    _batchOverlayEntry = null;
    _activeRowForOverlay = null;
  }

  void _showBatchOverlay(
    BuildContext context,
    _BatchItemRowController row,
    LayerLink link,
  ) {
    _hideBatchOverlay();
    final overlay = Overlay.of(context);
    _activeRowForOverlay = row;

    _batchOverlayEntry = OverlayEntry(
      builder: (context) {
        int? hoveredIndex;
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            final query = _batchInputControllers[row]?.text.toLowerCase() ?? '';
            final filtered = widget.batchDataOptions.where((b) {
              return b.batchReference.toLowerCase().contains(query) ||
                  b.manufacturerBatch.toLowerCase().contains(query);
            }).toList();

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _hideBatchOverlay,
                  ),
                ),
                CompositedTransformFollower(
                  link: link,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 40),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                    child: Container(
                      width: 450,
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        border: Border.all(color: _borderCol),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: filtered.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text(
                                'No matching batches found',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _hintColor,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final isHovered = hoveredIndex == index;
                                return MouseRegion(
                                  onEnter: (_) => setOverlayState(
                                    () => hoveredIndex = index,
                                  ),
                                  onExit: (_) => setOverlayState(
                                    () => hoveredIndex = null,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      _onBatchSelected(row, item);
                                      _hideBatchOverlay();
                                    },
                                    child: _buildDropdownOverlayItem(
                                      '${item.batchReference} | Mfg Batch: ${item.manufacturerBatch} | Bal: ${item.quantityAvailable} | Exp: ${item.expiryDate} | MRP: ${item.mrp}',
                                      false,
                                      isHovered,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    overlay.insert(_batchOverlayEntry!);
  }

  void _onBatchSelected(_BatchItemRowController row, BatchData match) {
    row.batchNoCtrl.text = match.batchReference;
    _batchInputControllers[row]?.text = match.batchReference;
    row.selectedBatchNo = match.batchReference;
    row.unitPackCtrl.text = match.unitPack;
    row.mrpCtrl.text = match.mrp.toString();
    row.ptrCtrl.text = match.ptr.toString();
    row.expDateCtrl.text = match.expiryDate;
    row.mfgBatchCtrl.text = match.manufacturerBatch;
    row.mfgDateCtrl.text = match.manufacturedDate;

    try {
      if (match.expiryDate.isNotEmpty) {
        final parts = match.expiryDate.split('-');
        if (parts.length == 3) {
          row.expDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
      if (match.manufacturedDate.isNotEmpty) {
        final parts = match.manufacturedDate.split('-');
        if (parts.length == 3) {
          row.mfgDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
    } catch (_) {}
    row.isAutoLoaded = true;
    setState(() {});
  }

  Widget _buildDropdownOverlayItem(
    String text,
    bool isSelected,
    bool isHovered,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: isHovered
          ? AppTheme.primaryBlue
          : (isSelected ? const Color(0xFFF3F4F6) : Colors.white),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isHovered ? Colors.white : _textPrimary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildBatchNoTextField(_BatchItemRowController row) {
    if (!_batchInputControllers.containsKey(row)) {
      _batchInputControllers[row] = TextEditingController(
        text: row.batchNoCtrl.text,
      );
      _batchInputFocusNodes[row] = FocusNode();
      _batchInputFocusNodes[row]!.addListener(() {
        if (_batchInputFocusNodes[row]!.hasFocus) {
          _showBatchOverlay(context, row, row.layerLink);
        } else {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && !_batchInputFocusNodes[row]!.hasFocus) {
              if (_activeRowForOverlay == row) _hideBatchOverlay();
            }
          });
        }
      });
    }

    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: CompositedTransformTarget(
          link: row.layerLink,
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: _batchInputControllers[row]!,
              focusNode: _batchInputFocusNodes[row]!,
              onChanged: (val) {
                row.batchNoCtrl.text = val;
                row.selectedBatchNo = val;
                row.isAutoLoaded = false;
                _batchOverlayEntry?.markNeedsBuild();
              },
              style: const TextStyle(
                fontSize: 13,
                color: _textPrimary,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                isDense: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _focusBorder, width: 1.4),
                ),
                hintText: 'Enter Batch No',
                hintStyle: const TextStyle(color: _hintColor, fontSize: 13),
                suffixIcon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: _hintColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

  double get _quantityToBeAdded =>
      (widget.ordered - _totalQuantityOut).clamp(0, widget.ordered);

  String _fmtQty(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int flex,
    bool isNumeric = false,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
          height: 38,
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: isNumeric ? () => _selectAllIfZero(controller) : null,
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
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _focusBorder, width: 1.4),
              ),
              hintText: hint,
              hintStyle: const TextStyle(color: _hintColor, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required TextEditingController controller,
    required GlobalKey targetKey,
    int? flex,
    double? width,
    bool readOnly = false,
    required VoidCallback onTap,
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
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _focusBorder, width: 1.2),
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
    return width != null
        ? SizedBox(width: width, child: dateField)
        : Expanded(flex: flex ?? 15, child: dateField);
  }

  @override
  Widget build(BuildContext context) {
    double dialogWidth = 920;
    if (_showMfgDetails) dialogWidth += 350;
    if (_showFoc) dialogWidth += 140;
    if (_showDamage) dialogWidth += 140;

    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Container(
        width: dialogWidth.clamp(
          850.0,
          MediaQuery.of(context).size.width * 0.95,
        ),
        height: MediaQuery.of(context).size.height * 0.86,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Select Batch',
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_dialogErrorMessage != null) _buildErrorMessage(),
                    _buildInfoBar(),
                    _buildBatchSectionHeader(),
                    const SizedBox(height: 12),
                    _buildToggleOptions(),
                    const SizedBox(height: 16),
                    _buildRowsTable(),
                    _buildAddRowButton(),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: _borderCol),
            _buildDialogFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF9D3D3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _dialogErrorMessage!,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 16, color: _dangerRed),
              onPressed: () => setState(() => _dialogErrorMessage = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBar() {
    return Padding(
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
    );
  }

  Widget _buildBatchSectionHeader() {
    return Padding(
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
            'Total Quantity : ${_fmtQty(widget.ordered)} | Qty to add : ${_fmtQty(_quantityToBeAdded)}',
            style: const TextStyle(
              fontSize: 12,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _checkbox(
            'Manufacture Details',
            _showMfgDetails,
            (v) => setState(() => _showMfgDetails = v!),
          ),
          const SizedBox(width: 32),
          _checkbox('FOC', _showFoc, (v) => setState(() => _showFoc = v!)),
          const SizedBox(width: 20),
          _checkbox('Damage', _showDamage, (v) {
            setState(() => _showDamage = v!);
            widget.onDamageChanged?.call(v!);
          }),
          const Spacer(),
          _checkbox(
            'Overwrite line item',
            _overwriteLineItem,
            (v) => setState(() => _overwriteLineItem = v!),
          ),
        ],
      ),
    );
  }

  Widget _checkbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        SizedBox(
          height: 20,
          width: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: _greenBtn,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: _textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildRowsTable() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            border: Border(bottom: BorderSide(color: _borderCol)),
          ),
          child: Row(
            children: [
              _headerCell('BATCH NO*', 2),
              _headerCell('UNIT PACK*', 2),
              _headerCell('MRP*', 2),
              _headerCell('PURCHASE RATE', 2),
              _headerCell('EXPIRY DATE*', 2),
              if (_showMfgDetails) ...[
                _headerCell('MFG DATE', 2),
                _headerCell('MFG BATCH', 2),
              ],
              _headerCell('QUANTITY*', 2),
              if (_showFoc) _headerCell('FOC', 2),
              if (_showDamage) _headerCell('DAMAGE', 2),
              const SizedBox(width: 32),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: _rows.length,
          itemBuilder: (context, index) {
            final row = _rows[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _buildBatchNoTextField(row),
                  _buildTextField(
                    controller: row.unitPackCtrl,
                    hint: 'Pack',
                    flex: 2,
                    readOnly: row.isAutoLoaded,
                  ),
                  _buildTextField(
                    controller: row.mrpCtrl,
                    hint: '0',
                    flex: 2,
                    isNumeric: true,
                  ),
                  _buildTextField(
                    controller: row.ptrCtrl,
                    hint: '0',
                    flex: 2,
                    isNumeric: true,
                  ),
                  _buildDatePicker(
                    controller: row.expDateCtrl,
                    targetKey: row.expKey,
                    flex: 2,
                    readOnly: row.isAutoLoaded,
                    onTap: () async {
                      final p = await ZerpaiDatePicker.show(
                        context,
                        initialDate: row.expDate ?? DateTime.now(),
                        targetKey: row.expKey,
                      );
                      if (p != null)
                        setState(() {
                          row.expDate = p;
                          row.expDateCtrl.text = DateFormat(
                            'dd-MM-yyyy',
                          ).format(p);
                        });
                    },
                  ),
                  if (_showMfgDetails) ...[
                    _buildDatePicker(
                      controller: row.mfgDateCtrl,
                      targetKey: row.mfgKey,
                      flex: 2,
                      readOnly: row.isAutoLoaded,
                      onTap: () async {
                        final p = await ZerpaiDatePicker.show(
                          context,
                          initialDate: row.mfgDate ?? DateTime.now(),
                          targetKey: row.mfgKey,
                        );
                        if (p != null)
                          setState(() {
                            row.mfgDate = p;
                            row.mfgDateCtrl.text = DateFormat(
                              'dd-MM-yyyy',
                            ).format(p);
                          });
                      },
                    ),
                    _buildTextField(
                      controller: row.mfgBatchCtrl,
                      hint: 'Mfg Batch',
                      flex: 2,
                      readOnly: row.isAutoLoaded,
                    ),
                  ],
                  _buildTextField(
                    controller: row.qtyCtrl,
                    hint: '0',
                    flex: 2,
                    isNumeric: true,
                  ),
                  if (_showFoc)
                    _buildTextField(
                      controller: row.focCtrl,
                      hint: '0',
                      flex: 2,
                      isNumeric: true,
                    ),
                  if (_showDamage)
                    _buildTextField(
                      controller: row.damageCtrl,
                      hint: '0',
                      flex: 2,
                      isNumeric: true,
                    ),
                  SizedBox(
                    width: 32,
                    child: IconButton(
                      icon: const Icon(
                        LucideIcons.xCircle,
                        size: 16,
                        color: _dangerRed,
                      ),
                      onPressed: _rows.length > 1
                          ? () => _removeRow(index)
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddRowButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: InkWell(
        onTap: _addRow,
        child: const Row(
          children: [
            Icon(LucideIcons.plus, size: 16, color: AppTheme.primaryBlue),
            SizedBox(width: 4),
            Text(
              'New Row',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: _validateAndSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: _greenBtn,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Save'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(foregroundColor: _textPrimary),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _validateAndSave() {
    for (var r in _rows) {
      if (r.batchNoCtrl.text.isEmpty) {
        setState(() => _dialogErrorMessage = _batchNoMissingMessage);
        return;
      }
      if (r.unitPackCtrl.text.isEmpty) {
        setState(() => _dialogErrorMessage = _unitPackMissingMessage);
        return;
      }
      if (r.mrpCtrl.text.isEmpty) {
        setState(() => _dialogErrorMessage = _mrpMissingMessage);
        return;
      }
      if (r.expDate == null) {
        setState(() => _dialogErrorMessage = _expDateMissingMessage);
        return;
      }
      if ((double.tryParse(r.qtyCtrl.text) ?? 0) <= 0 &&
          (double.tryParse(r.focCtrl.text) ?? 0) <= 0) {
        setState(() => _dialogErrorMessage = _qtyOrFocMessage);
        return;
      }
    }
    final totalEnteredQtyOnly = _rows.fold<double>(
      0,
      (sum, row) => sum + (double.tryParse(row.qtyCtrl.text.trim()) ?? 0),
    );
    if (!_overwriteLineItem &&
        (totalEnteredQtyOnly - widget.ordered).abs() > 0.001) {
      setState(
        () => _dialogErrorMessage =
            "Total matches Qty to Receive (${_fmtQty(widget.ordered)}). Currently ${_fmtQty(totalEnteredQtyOnly)}.",
      );
      return;
    }
    widget.onSave(_rows.map((r) => r.toBatchInfo()).toList());
    Navigator.pop(context);
  }

  Widget _headerCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: text.contains('*') ? _dangerRed : _textPrimary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _BinHoverBox extends StatefulWidget {
  final String message;
  final Widget child;
  final bool isEnabled;

  const _BinHoverBox({
    required this.message,
    required this.child,
    this.isEnabled = true,
  });
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
      builder: (context) => Stack(
        children: [
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            offset: const Offset(0, 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 250),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
    link: _layerLink,
    child: MouseRegion(
      onEnter: (_) => _showOverlay(),
      onExit: (_) => _hideOverlay(),
      child: widget.child,
    ),
  );
}

