import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' show max;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import '../models/purchases_purchase_receives_model.dart';
import '../providers/purchase_receives_provider.dart';
import '../../vendors/providers/vendor_provider.dart';
import '../../purchase_orders/providers/purchases_purchase_orders_provider.dart';

import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/items_stock_providers.dart';
import 'package:zerpai_erp/shared/widgets/inputs/warehouse_popover.dart';

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

// ═════════════════════════════════════════════════════════════════════════════
// MAIN WIDGET
// ═════════════════════════════════════════════════════════════════════════════
class PurchasesPurchaseReceivesCreateScreen extends ConsumerStatefulWidget {
  const PurchasesPurchaseReceivesCreateScreen({super.key});

  @override
  ConsumerState<PurchasesPurchaseReceivesCreateScreen> createState() =>
      _PRCreateState();
}

class _PRCreateState
    extends ConsumerState<PurchasesPurchaseReceivesCreateScreen> {
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
  PurchaseOrder? _selectedPO;
  String? _selectedPONumber;
  String? _selectedPOId;
  List<PurchaseOrder> _vendorPOs = [];
  bool _isLoadingPOs = false;
  bool _isSaving = false;
  bool _isReceiveAutoGenerate = true;
  String _receiveNumberPrefix = 'PR-';
  int _receiveNextNumber = 35;
  bool _isManualMode = true;
  bool _isDamageEnabled = false;
  final List<String?> _preferredBins = [];
  final List<TextEditingController> _damageControllers = [];
  final Set<String> _hoveredQtyFields = <String>{};
  final Set<String> _focusedQtyFields = <String>{};
  final Set<String> _hoveredBinFields = <String>{};
  final Set<String> _focusedBinFields = <String>{};
  String _binMode = 'item'; // 'transaction' or 'item'
  bool _showFilePopup = false;
  int? _hoveredAttachmentIndex;
  final ScrollController _attachmentListScrollController = ScrollController();
  final LayerLink _filePopupLayerLink = LayerLink();
  OverlayEntry? _filePopupOverlayEntry;
  OverlayEntry? _topErrorOverlayEntry;
  Timer? _topErrorTimer;
  String? _selectedTransactionBin;
  static const List<String> _manualBinList = [
    'Bin A-01',
    'Bin B-02',
    'Bin C-03',
    'Main Rack',
  ];
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
    const baseWidth = 150.0;
    const extraPerBatch = 102.0;
    if (maxBatches > 0) {
      return (116.0 + (maxBatches * extraPerBatch)).clamp(baseWidth, 700.0);
    }
    return baseWidth;
  }

  double _tableMinWidthFactor() {
    return _binMode == 'transaction' ? 0.40 : 0.49;
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
    _receiveNumberCtrl.text = _generateReceiveNumber();
    _receivedDateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());

    // Load vendors when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vendorProvider.notifier).loadVendors();
    });
  }

  String _generateReceiveNumber() {
    return '$_receiveNumberPrefix${_receiveNextNumber.toString().padLeft(5, '0')}';
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
            }
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    if (index < _items.length) {
      setState(() {
        _items.removeAt(index);
        _rowControllers[index].dispose();
        _rowControllers.removeAt(index);
        if (index < _preferredBins.length) {
          _preferredBins.removeAt(index);
        }
        if (index < _damageControllers.length) {
          _damageControllers[index].dispose();
          _damageControllers.removeAt(index);
        }
      });
    }
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

    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
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

  void _removeUploadedFile(int index) {
    if (index < 0 || index >= _uploadedFiles.length) return;
    setState(() {
      _uploadedFiles.removeAt(index);
      if (_hoveredAttachmentIndex != null &&
          _hoveredAttachmentIndex! >= _uploadedFiles.length) {
        _hoveredAttachmentIndex = null;
      }
      if (_uploadedFiles.isEmpty) {
        _hideFilePopupOverlay();
      }
    });
  }

  @override
  void dispose() {
    _dismissTopError();
    _hideFilePopupOverlay();
    _attachmentListScrollController.dispose();
    _receiveNumberCtrl.dispose();
    _receivedDateCtrl.dispose();
    _billNoCtrl.dispose();
    _billDateCtrl.dispose();
    _invoiceTotalCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _damageControllers) {
      c.dispose();
    }
    for (var c in _rowControllers) {
      c.dispose();
    }
    super.dispose();
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
        // Filter: Only keep rows from Auto Mode that have actual values.
        final List<PurchaseReceiveItem> filteredItems = [];
        final List<_ReceiveItemRowController> filteredCtrls = [];
        final List<String?> filteredBins = [];
        final List<TextEditingController> filteredDamageCtrls = [];

        for (int i = 0; i < _items.length; i++) {
          final item = _items[i];
          final bool hasValue = item.quantityToReceive > 0 ||
              _sumBatchFoc(item.batches) > 0 ||
              item.batches.isNotEmpty;

          if (hasValue) {
            filteredItems.add(item);
            filteredCtrls.add(_rowControllers[i]);
            filteredBins.add(_preferredBins[i]);
            filteredDamageCtrls.add(_damageControllers[i]);
          }
        }

        _items.clear();
        _items.addAll(filteredItems);
        _rowControllers.clear();
        _rowControllers.addAll(filteredCtrls);
        _preferredBins.clear();
        _preferredBins.addAll(filteredBins);
        _damageControllers.clear();
        _damageControllers.addAll(filteredDamageCtrls);

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
    if (!nextIsManual && !hasPersistedRows && _selectedPO != null) {
      _onPOSelected(_selectedPO!);
    }
  }

  bool get _hasValidSelection =>
      _selectedVendorName != null &&
      _selectedVendorName!.isNotEmpty &&
      _selectedPONumber != null &&
      _selectedPONumber!.isNotEmpty;

  void _displayFilePopupOverlay() {
    if (_filePopupOverlayEntry != null) return;

    _filePopupOverlayEntry = OverlayEntry(
      builder: (context) => CompositedTransformFollower(
        link: _filePopupLayerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 8),
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            elevation: 8,
            child: IntrinsicWidth(
              child: Container(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 450),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: (_uploadedFiles.isEmpty
                        ? 56
                        : (_uploadedFiles.length > 3
                                  ? 3
                                  : _uploadedFiles.length) *
                              56),
                  ),
                  child: Scrollbar(
                    controller: _attachmentListScrollController,
                    thumbVisibility: _uploadedFiles.length > 3,
                    child: SingleChildScrollView(
                      controller: _attachmentListScrollController,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(_uploadedFiles.length, (index) {
                          final file = _uploadedFiles[index];
                          final fileSizeKb = file.size / 1024;
                          final isHovered = _hoveredAttachmentIndex == index;

                          return MouseRegion(
                            onEnter: (_) =>
                                setState(() => _hoveredAttachmentIndex = index),
                            onExit: (_) => setState(() {
                              if (_hoveredAttachmentIndex == index) {
                                _hoveredAttachmentIndex = null;
                              }
                            }),
                            child: Container(
                              height: 56,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isHovered
                                    ? const Color(0xFF3B82F6)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.image,
                                    size: 16,
                                    color: isHovered
                                        ? Colors.white
                                        : const Color(0xFF3B82F6),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          file.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isHovered
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'File Size: ${fileSizeKb.toStringAsFixed(2)} KB',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isHovered
                                                ? const Color(0xFFEAF2FF)
                                                : const Color(0xFF6B7280),
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () => _removeUploadedFile(index),
                                    child: Icon(
                                      LucideIcons.trash2,
                                      size: 15,
                                      color: isHovered
                                          ? Colors.white
                                          : const Color(0xFF3B82F6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_filePopupOverlayEntry!);
    setState(() => _showFilePopup = true);
  }

  void _hideFilePopupOverlay() {
    _filePopupOverlayEntry?.remove();
    _filePopupOverlayEntry = null;
    setState(() => _showFilePopup = false);
  }

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
            opacity: _hasValidSelection ? 1.0 : 0.5,
            child: IgnorePointer(
              ignoring: !_hasValidSelection,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // ── Info Banner ──
                  _buildInfoBanner(),
                  const SizedBox(height: 20),
                  _buildBinSelectionSection(),
                  const SizedBox(height: 24),
                  // ── Items Table ──
                  _buildItemsTable(),
                  const SizedBox(height: 32),
                  // ── Notes Section ──
                  _buildNotesSection(),
                  const SizedBox(height: 32),
                  // ── Attach Files Section ──
                  _buildAttachFilesSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
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
          const Text(
            'New Purchase Receive',
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SELECTION DIALOGS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _fetchPOsForVendor(String vendorId) async {
    setState(() {
      _isLoadingPOs = true;
      _vendorPOs.clear();
      _selectedPO = null;
      _selectedPONumber = null;
      _selectedPOId = null;
      _clearAllRows();
    });

    try {
      final pos = await ref.read(
        purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)).future,
      );
      if (mounted) {
        setState(() {
          _vendorPOs = pos;
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

  Future<void> _onPOSelected(PurchaseOrder po) async {
    setState(() {
      _selectedPO = po;
      _selectedPONumber = po.orderNumber;
      _selectedPOId = po.id;
      _isLoadingPOs = true;
    });

    try {
      final fullPO = await ref.read(purchaseOrderProvider(po.id!).future);
      if (!mounted) return;

      setState(() {
        _selectedPO = fullPO ?? po;
        _isLoadingPOs = false;
        _clearAllRows();

        if (!_isManualMode && fullPO != null && fullPO.items.isNotEmpty) {
          for (var poItem in fullPO.items) {
            _items.add(
              PurchaseReceiveItem(
                itemId: poItem.productId,
                itemName: poItem.productName ?? poItem.itemCode ?? "",
                description: poItem.description,
                ordered: poItem.quantity,
                received: 0,
                inTransit: 0,
                quantityToReceive: 0,
              ),
            );
            final controller = _ReceiveItemRowController();
            controller.qtyCtrl.text = '0';
            _rowControllers.add(controller);
            _preferredBins.add(null);
            _damageControllers.add(TextEditingController());
          }
        }
      });
    } catch (e) {
      AppLogger.error(
        "Failed to load purchase order details",
        error: e,
        module: "purchases",
      );
      if (mounted) setState(() => _isLoadingPOs = false);
    }
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
                child: Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: FormDropdown<Vendor>(
                      height: 32,
                      value: ref
                          .read(vendorProvider)
                          .vendors
                          .where((v) => v.id == _selectedVendorId)
                          .firstOrNull,
                      items: ref.watch(vendorProvider).vendors,
                      hint: "Select or type to search",
                      showSearch: true,
                      displayStringForValue: (v) => v.displayName,
                      searchStringForValue: (v) => v.displayName,
                      itemBuilder: (item, isSelected, isHovered) {
                        return _buildDropdownOverlayItem(
                          item.displayName,
                          isSelected,
                          isHovered,
                        );
                      },
                      onChanged: (vendor) {
                        if (vendor != null) {
                          setState(() {
                            _selectedVendorId = vendor.id;
                            _selectedVendorName = vendor.displayName;
                          });
                          _fetchPOsForVendor(vendor.id);
                        }
                      },
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildFormRow(
                label: "Purchase Order#",
                labelColor: _dangerRed,
                child: SizedBox(
                  width: 400,
                  child: FormDropdown<PurchaseOrder>(
                    height: 32,
                    itemHeight: 60.0,
                    value: _selectedPO,
                    items: _vendorPOs,
                    hint: _selectedVendorId == null
                        ? "Select a vendor first"
                        : (_vendorPOs.isEmpty && !_isLoadingPOs
                              ? "No POs found"
                              : "Select a Purchase Order"),
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
                              : (isSelected || (po.id == _selectedPO?.id))
                                  ? const Color(0xFFF3F4F6)
                                  : Colors.white,
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
                                      fontWeight: FontWeight.w400,
                                      color: showHover
                                          ? Colors.white
                                          : (isSelected || (po.id == _selectedPO?.id))
                                              ? _textPrimary
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
                                          : (isSelected
                                                ? Colors.grey
                                                : _hintColor),
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
                    onChanged: (po) {
                      if (po != null) {
                        _onPOSelected(po);
                      }
                    },
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Opacity(
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
                                filled: true,
                                fillColor: _hasValidSelection
                                    ? _bgWhite
                                    : const Color(0xFFF5F5F5),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: _fieldBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: _focusBorder,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
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
                            child: TextField(
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
                                filled: true,
                                fillColor: _hasValidSelection
                                    ? _bgWhite
                                    : const Color(0xFFF5F5F5),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                hintText: "dd-MM-yyyy",
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: _hintColor,
                                  fontFamily: "Inter",
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: _fieldBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: _focusBorder,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
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
                      const SizedBox(height: 20),
                      _buildFormRow(
                        label: "Bill invoice total",
                        isRequired: true,
                        child: SizedBox(
                          width: 180,
                          child: SizedBox(
                            height: 32,
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
                                filled: true,
                                fillColor: _hasValidSelection
                                    ? _bgWhite
                                    : const Color(0xFFF5F5F5),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: _fieldBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: _focusBorder,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
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
                          child: SizedBox(
                            height: 32,
                            child: TextField(
                              controller: _receiveNumberCtrl,
                              readOnly: _isReceiveAutoGenerate,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textPrimary,
                                fontFamily: "Inter",
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: _hasValidSelection
                                    ? _bgWhite
                                    : const Color(0xFFF5F5F5),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: _fieldBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: _focusBorder,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
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
                      const SizedBox(height: 20),
                      _buildFormRow(
                        label: "Received date",
                        isRequired: true,
                        child: SizedBox(
                          width: 180,
                          child: SizedBox(
                            height: 32,
                            child: TextField(
                              controller: _receivedDateCtrl,
                              readOnly: true,
                              key: _dateFieldKey,
                              onTap: () async {
                                final picked = await ZerpaiDatePicker.show(
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
                                filled: true,
                                fillColor: _hasValidSelection
                                    ? _bgWhite
                                    : const Color(0xFFF5F5F5),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: _fieldBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: _focusBorder,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 20),
          if (_binMode == 'transaction')
            SizedBox(
              width: 220,
              child: FormDropdown<String>(
                height: 32,
                value: _selectedTransactionBin,
                items: _manualBinList,
                hint: 'Select Bin',
                itemBuilder: (item, isSelected, isHovered) {
                  return _buildDropdownOverlayItem(item, isSelected, isHovered);
                },
                onChanged: (val) {
                  setState(() {
                    _selectedTransactionBin = val;
                  });
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
    if (_isManualMode) {
      return _buildManualItemsTable(); // ✅ Manual table
    } else {
      return _buildItemsTableNormal(); // ✅ PO table (default)
    }
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
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicWidth(
                child: Container(
                  constraints: BoxConstraints(
                    minWidth:
                        MediaQuery.of(context).size.width *
                        _tableMinWidthFactor(),
                  ),
                  decoration: const BoxDecoration(
                    border: Border.fromBorderSide(
                      BorderSide(color: _borderCol),
                    ),
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
                          children: [
                            _tableHeaderCell(
                              "ITEMS & DESCRIPTION",
                              fixedWidth: 300,
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
                            if (_binMode == "item")
                              _tableHeaderCell("BIN", fixedWidth: 160),
                            _buildQtyHeaderCell(
                              fixedWidth: _dynamicQtyToReceiveColumnWidth(),
                            ),
                            _tableHeaderCell(
                              "",
                              fixedWidth: 12,
                              isLastColumn: true,
                            ),
                          ],
                        ),
                      ),
                      // Table Body
                      if (_isLoadingPOs)
                        _buildLoadingRow()
                      else if (_items.isEmpty)
                        _buildEmptyRow()
                      else
                        ...List.generate(
                          _items.length,
                          (index) => _buildItemRow(index, _items[index]),
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
                  constraints: BoxConstraints(
                    minWidth:
                        MediaQuery.of(context).size.width *
                        _tableMinWidthFactor(),
                  ),
                  decoration: const BoxDecoration(
                    border: Border.fromBorderSide(
                      BorderSide(color: _borderCol),
                    ),
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
                          children: [
                            _tableHeaderCell(
                              "",
                              fixedWidth: 300,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "ITEMS & DESCRIPTION",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _textPrimary,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  if (_selectedPO != null) ...[
                                    const SizedBox(height: 2),
                                    InkWell(
                                      onTap: _addAllItemsFromPO,
                                      child: const Text(
                                        "Add all Items",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _linkBlue,
                                          fontFamily: 'Inter',
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
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
                            if (_binMode == "item")
                              _tableHeaderCell("BIN", fixedWidth: 160),
                            _buildQtyHeaderCell(
                              fixedWidth: _dynamicQtyToReceiveColumnWidth(),
                            ),
                            _tableHeaderCell(
                              "",
                              fixedWidth: 16,
                              isLastColumn: true,
                            ),
                          ],
                        ),
                      ),
                      // Table Rows
                      if (_items.isEmpty)
                        KeyedSubtree(
                          key: const ValueKey('ephemeral-row'),
                          child: _buildManualRow(
                            0,
                            PurchaseReceiveItem(),
                            isEphemeral: true,
                          ),
                        )
                      else
                        ..._items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final ctrlKey = _rowControllers.length > index
                              ? _rowControllers[index].hashCode
                              : index;
                          return KeyedSubtree(
                            key: ValueKey('row-$ctrlKey'),
                            child: _buildManualRow(index, item),
                          );
                        }),
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
            ),
            // Insert New Row Button
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildInsertRowButton(),
            ),
          ],
        ),
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
      decoration: BoxDecoration(
        border: Border(
          right: isLastColumn
              ? BorderSide.none
              : const BorderSide(color: _borderCol, width: 0.8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child ??
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

  Widget _buildQtyHeaderCell({required double fixedWidth}) {
    return SizedBox(
      width: fixedWidth,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: _borderCol, width: 0.8)),
        ),
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
  }) {
    final isActive =
        _hoveredQtyFields.contains(fieldKey) ||
        _focusedQtyFields.contains(fieldKey);

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
      child: SizedBox(
        width: 84,
        height: height,
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
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
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
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: _bgWhite,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 2,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color(0xFFBDBDBD),
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _focusBorder, width: 1.2),
                borderRadius: BorderRadius.circular(4),
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
    final currentQty =
        double.tryParse(ctrl.qtyCtrl.text.isEmpty ? '0' : ctrl.qtyCtrl.text) ??
        0;
    final nextQty = (currentQty + delta).clamp(0, double.infinity).toDouble();
    final display = nextQty == nextQty.roundToDouble()
        ? nextQty.toInt().toString()
        : nextQty.toStringAsFixed(2);

    setState(() {
      ctrl.qtyCtrl.text = display;
      _items[index] = _items[index].copyWith(quantityToReceive: nextQty);
    });
  }

  void _onRowQtyChanged(int index, String value) {
    if (index >= _items.length) return;
    final qty = double.tryParse(value.isEmpty ? '0' : value) ?? 0;
    setState(() {
      _items[index] = _items[index].copyWith(quantityToReceive: qty);
    });
  }

  void _fillAllUnreceivedQuantities() {
    if (_items.isEmpty) return;
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        if (i >= _rowControllers.length) continue;
        if (_items[i].batches.isNotEmpty) continue;
        final ordered = _items[i].ordered;
        final display = ordered == ordered.roundToDouble()
            ? ordered.toInt().toString()
            : ordered.toStringAsFixed(2);
        _rowControllers[i].qtyCtrl.text = display;
        _items[i] = _items[i].copyWith(quantityToReceive: ordered);
      }
    });
  }

  Widget _buildAddBatchButton(int index, {double height = 38}) {
    return InkWell(
      onTap: () => _showSelectBatchDialog(index),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _bgWhite,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _fieldBorder),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plus, size: 12, color: _textPrimary),
            SizedBox(width: 6),
            Text(
              'Add Batch',
              style: TextStyle(
                fontSize: 11,
                color: _textPrimary,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
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
    final qty = _sumBatchQuantity(item.batches);
    final foc = _sumBatchFoc(item.batches);
    if (item.batches.isEmpty || foc <= 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${_fmtPcs(qty)}pcs + ${_fmtPcs(foc)}foc',
        style: const TextStyle(
          fontSize: 10,
          color: _hintColor,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _batchText(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderCol)),
      ),
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: _focusBorder),
      ),
    );
  }

  Widget _buildInlineBatchSection(PurchaseReceiveItem item, int index) {
    if (item.batches.isEmpty && item.quantityToReceive > 0) {
      return Align(
        alignment: Alignment.center,
        child: _buildAddBatchButton(index),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _tableBodyCell({
    int flex = 1,
    double? fixedWidth,
    required Widget child,
    bool isLastColumn = false,
    bool hideRightBorder = false,
  }) {
    Widget content = Container(
      alignment: Alignment.centerLeft,
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
      height: 38,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: InkWell(
              onTap: onDecrement,
              child: const Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      LucideIcons.minus,
                      size: 10,
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
                decoration: BoxDecoration(
                  color: _bgWhite,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: isActive ? _focusBorder : const Color(0xFFBDBDBD),
                    width: 1.2,
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
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 9),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
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
              child: const Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFEAF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      LucideIcons.plus,
                      size: 10,
                      color: _focusBorder,
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

  Widget _qtyStepButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isTop,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: isTop ? const Radius.circular(6) : Radius.zero,
              bottom: isTop ? Radius.zero : const Radius.circular(6),
            ),
          ),
          child: Icon(icon, size: 12, color: _textPrimary),
        ),
      ),
    );
  }

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
            ? const Color(0xFF3B82F6)
            : (isDisabled || isSelected)
                ? const Color(0xFFF3F4F6)
                : Colors.white,
        borderRadius: BorderRadius.circular(4),
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

  Widget _buildManualRow(
    int index,
    PurchaseReceiveItem item, {
    bool isEphemeral = false,
  }) {
    if (!_rowSelectedWarehouses.containsKey(index)) {
      _rowSelectedWarehouses[index] = 'ZABNIX PVT/LTD';
    }
    if (!_rowSelectedViews.containsKey(index)) {
      _rowSelectedViews[index] = 'Accounting';
    }
    final ctrl = index < _rowControllers.length
        ? _rowControllers[index]
        : _ReceiveItemRowController();
    final poItems = (_selectedPO?.items ?? <PurchaseOrderItem>[])
        .map((e) => e)
        .toList();
    final selectedIds = _items.map((e) => e.itemId).whereType<String>().toSet();
    final availablePoItems = poItems.where((poItem) {
      return !selectedIds.contains(poItem.productId) ||
          poItem.productId == item.itemId;
    }).toList();
    final selectedItem = poItems
        .where((it) => it.productId == item.itemId)
        .firstOrNull;
    final selectedBin = index < _preferredBins.length
        ? _preferredBins[index]
        : null;
    final hasBatches = !isEphemeral && item.batches.isNotEmpty;

    if (ctrl.qtyCtrl.text.isEmpty) {
      ctrl.qtyCtrl.text = '0';
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: _borderCol, width: 0.8),
          bottom: BorderSide(color: _borderCol, width: 0.8),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tableBodyCell(
              fixedWidth: 300,
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
                      child: FormDropdown<PurchaseOrderItem>(
                        value: selectedItem,
                        items: availablePoItems,
                        hint: 'Type or click to select an item',
                        showSearch: true,
                        displayStringForValue: (poItem) =>
                            poItem.productName ?? poItem.itemCode ?? 'Unnamed item',
                        searchStringForValue: (poItem) =>
                            '${poItem.productName ?? ''} ${poItem.itemCode ?? ''}',
                        itemBuilder: (poItem, isSelected, isHovered) {
                          final bool isAlreadySelected =
                              selectedIds.contains(poItem.productId) &&
                              poItem.productId != item.itemId;
                          return _buildDropdownOverlayItem(
                            poItem.productName ?? 'Unnamed item',
                            isSelected,
                            isHovered,
                            isDisabled: isAlreadySelected,
                          );
                        },
                        onChanged: (poItem) {
                          if (poItem == null) return;
                          setState(() {
                            if (isEphemeral) {
                              _items.add(
                                poItem.productId.isNotEmpty
                                    ? PurchaseReceiveItem(
                                        itemId: poItem.productId,
                                        itemName: poItem.productName ?? '',
                                        description: poItem.description,
                                        ordered: poItem.quantity,
                                        received: 0,
                                        inTransit: 0,
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
                                _items[index] = _items[index].copyWith(
                                  itemId: poItem.productId,
                                  itemName: poItem.productName ?? '',
                                  description: poItem.description,
                                  ordered: poItem.quantity,
                                  received: 0,
                                  inTransit: 0,
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
                  ],
                ),
              ),
            ),
            _tableBodyCell(
              fixedWidth: 100,
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
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: SizedBox(),
              ),
            ),
            _tableBodyCell(
              fixedWidth: 110,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: SizedBox(),
              ),
            ),
            if (_binMode == "item")
              _tableBodyCell(
                fixedWidth: 160,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: MouseRegion(
                    onEnter: (_) => setState(
                      () => _hoveredBinFields.add("manual-bin-$index"),
                    ),
                    onExit: (_) => setState(
                      () => _hoveredBinFields.remove("manual-bin-$index"),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => setState(() {
                        _focusedBinFields
                          ..clear()
                          ..add("manual-bin-$index");
                      }),
                      child: SizedBox(
                        height: 44,
                        child: FormDropdown<String>(
                          value: selectedBin,
                          items: _manualBinList,
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
                              _focusedBinFields.remove("manual-bin-$index");
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            _tableBodyCell(
              fixedWidth: _dynamicQtyToReceiveColumnWidth(),
              hideRightBorder: true,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
                child: WarehouseHoverPopover(
                  warehouseName:
                      _rowSelectedWarehouses[index] ?? 'ZABNIX PVT/LTD',
                  selectedView: _rowSelectedViews[index] ?? 'Accounting',
                  onWarehouseChanged: (name) =>
                      setState(() => _rowSelectedWarehouses[index] = name),
                  onViewChanged: (view) =>
                      setState(() => _rowSelectedViews[index] = view),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Column(
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
                            if (!isEphemeral &&
                                !hasBatches &&
                                item.quantityToReceive > 0) ...[
                              const SizedBox(height: 4),
                              _buildAddBatchesLinkButton(index),
                            ],
                            if (!isEphemeral) _buildQtyAndFocBreakdown(item),
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
            ),
            _tableBodyCell(
              fixedWidth: 14,
              isLastColumn: true,
              child: isEphemeral
                  ? const SizedBox()
                  : Center(
                      child: InkWell(
                        onTap: () => _removeItem(index),
                        borderRadius: BorderRadius.circular(4),
                        child: const Icon(
                          LucideIcons.x,
                          size: 14,
                          color: _dangerRed,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, PurchaseReceiveItem item) {
    final ctrl = index < _rowControllers.length
        ? _rowControllers[index]
        : _ReceiveItemRowController();
    final hasBatches = item.batches.isNotEmpty;

    if (ctrl.qtyCtrl.text.isEmpty) {
      ctrl.qtyCtrl.text = '0';
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: _borderCol, width: 0.8),
          bottom: BorderSide(color: _borderCol, width: 0.8),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tableBodyCell(
              fixedWidth: 300,
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
                              fontWeight: FontWeight.w500,
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
            if (_binMode == "item")
              _tableBodyCell(
                fixedWidth: 160,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: MouseRegion(
                    onEnter: (_) =>
                        setState(() => _hoveredBinFields.add("po-bin-$index")),
                    onExit: (_) => setState(
                      () => _hoveredBinFields.remove("po-bin-$index"),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => setState(() {
                        _focusedBinFields
                          ..clear()
                          ..add("po-bin-$index");
                      }),
                      child: SizedBox(
                        height: 44,
                        child: FormDropdown<String>(
                          value: index < _preferredBins.length
                              ? _preferredBins[index]
                              : null,
                          items: _manualBinList,
                          hint: "Select Bin",
                          showSearch: true,
                          border: Border.all(
                            color:
                                (_hoveredBinFields.contains("po-bin-$index") ||
                                    _focusedBinFields.contains("po-bin-$index"))
                                ? _focusBorder
                                : Colors.transparent,
                            width:
                                (_hoveredBinFields.contains("po-bin-$index") ||
                                    _focusedBinFields.contains("po-bin-$index"))
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
                              _focusedBinFields.remove("po-bin-$index");
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            _tableBodyCell(
              fixedWidth: _dynamicQtyToReceiveColumnWidth(),
              hideRightBorder: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: WarehouseHoverPopover(
                  warehouseName:
                      _rowSelectedWarehouses[index] ?? 'ZABNIX PVT/LTD',
                  selectedView: _rowSelectedViews[index] ?? 'Accounting',
                  onWarehouseChanged: (name) =>
                      setState(() => _rowSelectedWarehouses[index] = name),
                  onViewChanged: (view) =>
                      setState(() => _rowSelectedViews[index] = view),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 94,
                        child: Column(
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
                            _buildQtyAndFocBreakdown(item),
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
            ),
            _tableBodyCell(
              fixedWidth: 12,
              isLastColumn: true,
              child: Center(
                child: InkWell(
                  onTap: () => _removeItem(index),
                  borderRadius: BorderRadius.circular(4),
                  child: const Icon(LucideIcons.x, size: 12, color: _dangerRed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTES SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  borderSide: const BorderSide(color: _fieldBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: _focusBorder, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ATTACH FILES SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAttachFilesSection() {
    final uploadLimitReached = _uploadedFiles.length >= _maxUploadFiles;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Container(height: 1, color: _borderCol),
          const SizedBox(height: 20),
          const Text(
            'Attach File(s) to Purchase Receive',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _labelColor,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: uploadLimitReached ? 0.5 : 1,
                child: CompositedTransformTarget(
                  link: _filePopupLayerLink,
                  child: GestureDetector(
                    onTap: uploadLimitReached
                        ? null
                        : () {
                            if (_uploadedFiles.isNotEmpty) {
                              _displayFilePopupOverlay();
                            } else {
                              _pickFiles();
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _fieldBorder),
                        color: _bgWhite,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.uploadCloud,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Upload File',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.chevronDown,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_uploadedFiles.isNotEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_showFilePopup) {
                      _hideFilePopupOverlay();
                    } else {
                      _displayFilePopupOverlay();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _linkBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.link,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _uploadedFiles.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Allowed files: ${_uploadedFiles.length}/$_maxUploadFiles',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontFamily: 'Inter',
            ),
          ),
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
            onPressed: _isSaving || !_hasValidSelection
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
            onPressed: _isSaving || !_hasValidSelection
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

    if (_items.isEmpty) {
      missingFields.add('Item');
    } else {
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item.itemId == null || item.itemId!.isEmpty) {
          missingFields.add('Item in row ${i + 1}');
        }
        if (item.quantityToReceive <= 0) {
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
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final totalBatchQtyOnly = item.batches.fold<double>(
        0,
        (sum, b) => sum + b.quantity,
      );
      if (item.batches.isNotEmpty && totalBatchQtyOnly != item.ordered) {
        hasMismatch = true;
        break;
      }
    }

    if (hasMismatch) {
      _showTopError(
        "There's a mismatch between the quantity entered in the line item and the total quantity across all batches.",
      );
      return;
    }

    setState(() => _isSaving = true);

    // Build the model
    final receive = PurchaseReceive(
      purchaseReceiveNumber: _receiveNumberCtrl.text,
      receivedDate: DateFormat('dd-MM-yyyy').parse(_receivedDateCtrl.text),
      vendorName: _selectedVendorName,
      purchaseOrderId: _selectedPOId,
      purchaseOrderNumber: _selectedPONumber,
      status: status,
      notes: _notesCtrl.text,
      items: _items,
    );

    AppLogger.info(
      'Saving Purchase Receive...',
      data: {'status': status, 'receiveNumber': receive.purchaseReceiveNumber},
      module: 'purchases',
    );

    final success = await ref
        .read(purchaseReceivesProvider.notifier)
        .createReceive(receive);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'received'
                ? 'Purchase receive saved successfully'
                : 'Purchase receive saved as draft',
          ),
          backgroundColor: _greenBtn,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save purchase receive. Please try again.'),
          backgroundColor: _dangerRed,
        ),
      );
    }
  }

  void _addAllItemsFromPO() async {
    if (_selectedPO == null) return;

    // Ensure we have the full PO with items
    PurchaseOrder? fullPO;
    if (_selectedPO!.items.isEmpty) {
      if (mounted) setState(() => _isLoadingPOs = true);
      fullPO = await ref.read(purchaseOrderProvider(_selectedPO!.id!).future);
      if (mounted) setState(() => _isLoadingPOs = false);
    } else {
      fullPO = _selectedPO;
    }

    if (fullPO != null && fullPO.items.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _clearAllRows();
        for (var poItem in fullPO!.items) {
          _items.add(
            PurchaseReceiveItem(
              itemId: poItem.productId,
              itemName: poItem.productName ?? poItem.itemCode ?? "",
              description: poItem.description,
              ordered: poItem.quantity,
              received: 0,
              inTransit: 0,
              quantityToReceive: 0,
            ),
          );
          final controller = _ReceiveItemRowController();
          controller.qtyCtrl.text = '0';
          _rowControllers.add(controller);
          _preferredBins.add(null);
          _damageControllers.add(TextEditingController());
        }
      });
    }
  }

  Future<void> _showSelectBatchDialog(int itemIndex) async {
    final item = _items[itemIndex];
    final batchOptions = <String>{
      ...item.batches.map((b) => b.batchNo.trim()).where((v) => v.isNotEmpty),
    };

    final itemId = item.itemId?.trim();
    if (itemId != null && itemId.isNotEmpty) {
      try {
        final dbBatchNumbers = await ref.refresh(
          itemBatchNumbersProvider(itemId).future,
        );
        batchOptions.addAll(dbBatchNumbers);
      } catch (_) {
        // keep existing local options if remote lookup fails
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _SelectBatchDialog(
        itemName: item.itemName,
        batchOptions: batchOptions.toList()..sort(),
        initialBatches: item.batches,
        // Total in batch dialog must follow Ordered quantity in line item.
        ordered: item.ordered,
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
              (sum, batch) => sum + batch.quantity + batch.foc,
            );

            _items[itemIndex] = item.copyWith(
              batches: newBatches,
              quantityToReceive: combinedQty,
            );
            _rowControllers[itemIndex].qtyCtrl.text = _fmtPcs(combinedQty);
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
    if (idToLookup != null && idToLookup.isNotEmpty) {
      final whAsync = ref.read(warehousesProvider);
      if (whAsync.hasValue && whAsync.value != null) {
        try {
          final wh = whAsync.value!.firstWhere((w) => w.id == idToLookup);
          return wh.name;
        } catch (_) {
          // Fallback if not found
        }
      }
    }

    return 'ZABNIX PVT/LTD';
  }
}

class _SelectBatchDialog extends StatefulWidget {
  final String itemName;
  final String warehouseName;
  final double ordered;
  final List<String> batchOptions;
  final List<BatchInfo> initialBatches;
  final bool initialDamageEnabled;
  final ValueChanged<bool>? onDamageChanged;
  final void Function(String message)? onTopError;
  final Function(List<BatchInfo>) onSave;

  _SelectBatchDialog({
    required this.itemName,
    required this.warehouseName,
    required this.ordered,
    required this.batchOptions,
    required this.initialBatches,
    this.initialDamageEnabled = false,
    this.onDamageChanged,
    this.onTopError,
    required this.onSave,
  });

  @override
  State<_SelectBatchDialog> createState() => _SelectBatchDialogState();
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
                              const Icon(
                                LucideIcons.info,
                                size: 12,
                                color: textSecondary,
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

class _SelectBatchDialogState extends State<_SelectBatchDialog> {
  final List<_BatchItemRowController> _rows = [];
  final Map<_BatchItemRowController, TextEditingController>
  _batchInputControllers = {};
  final Map<_BatchItemRowController, FocusNode> _batchInputFocusNodes = {};
  bool _showMfgDetails = false;
  bool _showFoc = false;
  bool _showDamage = false;
  bool _overwriteLineItem = false;
  String? _dialogErrorMessage;
  static const String _quantityMismatchMessage =
      'Total quantity across all batches must equal the ordered quantity.';
  static const String _qtyExceedsMessage =
      'Total quantity across all batches cannot exceed the ordered quantity.';
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

  TextEditingController _ensureBatchInputController(
    _BatchItemRowController row,
  ) {
    return _batchInputControllers.putIfAbsent(
      row,
      () => TextEditingController(text: row.batchNoCtrl.text),
    );
  }

  FocusNode _ensureBatchInputFocusNode(_BatchItemRowController row) {
    return _batchInputFocusNodes.putIfAbsent(row, FocusNode.new);
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
    if (unitPack.isEmpty) {
      return '$rowLabel: Unit Pack is required';
    }
    if (double.tryParse(unitPack) == null) {
      return '$rowLabel: Unit Pack must be a valid number';
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
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 11,
              ),
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
        ),
      ),
    );
  }

  Widget _buildBatchNoDropdown(_BatchItemRowController row) {
    final current = row.batchNoCtrl.text.trim();
    final batchItems = <String>{...widget.batchOptions};
    if (current.isNotEmpty) {
      batchItems.add(current);
    }
    final sortedBatchItems = batchItems.toList()..sort();

    final inputController = _ensureBatchInputController(row);
    final inputFocusNode = _ensureBatchInputFocusNode(row);

    if (!inputFocusNode.hasFocus && inputController.text != current) {
      inputController.text = current;
      inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: inputController.text.length),
      );
    }

    return Expanded(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
          height: 38,
          width: double.infinity,
          child: RawAutocomplete<String>(
            textEditingController: inputController,
            focusNode: inputFocusNode,
            displayStringForOption: (option) => option,
            optionsBuilder: (textEditingValue) {
              final query = textEditingValue.text.trim().toLowerCase();
              if (query.isEmpty) {
                return sortedBatchItems;
              }

              return sortedBatchItems.where(
                (item) => item.toLowerCase().contains(query),
              );
            },
            onSelected: (selection) {
              row.batchNoCtrl.text = selection;
            },
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 11,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: _fieldBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: _focusBorder,
                          width: 1.5,
                        ),
                      ),
                      hintText: 'Batch No',
                      hintStyle: const TextStyle(
                        color: _hintColor,
                        fontSize: 13,
                      ),
                    ),
                    onChanged: (value) {
                      row.batchNoCtrl.text = value;
                    },
                    onSubmitted: (value) {
                      row.batchNoCtrl.text = value.trim();
                    },
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              final optionList = options.toList();
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 420,
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _fieldBorder),
                    ),
                    child: optionList.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(
                              'No results found',
                              style: TextStyle(
                                fontSize: 13,
                                color: _hintColor,
                                fontFamily: 'Inter',
                              ),
                            ),
                          )
                        : (() {
                            int? hoveredIndex;
                            return StatefulBuilder(
                              builder: (context, setOptionsState) {
                                return ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: optionList.length,
                                  itemBuilder: (context, index) {
                                    final item = optionList[index];
                                    final isHovered = hoveredIndex == index;
                                    final isSelected =
                                        row.batchNoCtrl.text.trim() == item;
                                    return MouseRegion(
                                      onEnter: (_) => setOptionsState(
                                        () => hoveredIndex = index,
                                      ),
                                      onExit: (_) => setOptionsState(
                                        () => hoveredIndex = null,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => onSelected(item),
                                          hoverColor: Colors.transparent,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isHovered
                                                  ? const Color(0xFF3B82F6)
                                                  : (isSelected
                                                        ? const Color(
                                                            0xFFF3F4F6,
                                                          )
                                                        : Colors.white),
                                            ),
                                            child: Text(
                                              item,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isHovered
                                                    ? Colors.white
                                                    : _textPrimary,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          })(),
                  ),
                ),
              );
            },
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
          onTap: onTap,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 13,
            color: _textPrimary,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _bgWhite,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 11,
            ),
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
              maxHeight: 40,
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
        width: _showMfgDetails ? 1150 : 820,
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
                              TextSpan(text: _quantityMismatchMessage),
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
                      onChanged: (val) =>
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
                      onChanged: (val) =>
                          setState(() => _showFoc = val ?? false),
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
                      onChanged: (val) {
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
                      onChanged: (val) =>
                          setState(() => _overwriteLineItem = val ?? false),
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
                  _headerCell('BATCH NO*', 3),
                  _headerCell('UNIT PACK*', 2),
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
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
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
                            _buildBatchNoDropdown(row),
                            _buildTextField(
                              controller: row.unitPackCtrl,
                              hint: 'Pack',
                              flex: 2,
                              isNumeric: true,
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
                              flex: 3,
                              onTap: () async {
                                final picked = await ZerpaiDatePicker.show(
                                  context,
                                  initialDate: row.expDate ?? DateTime.now(),
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
                              ),
                            ],
                            _buildTextField(
                              controller: row.qtyCtrl,
                              hint: '0',
                              flex: 2,
                              isNumeric: true,
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
                                onPressed: _rows.length > 1
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                      if (_totalEnteredQtyOnly > widget.ordered) {
                        setState(() {
                          _dialogErrorMessage = _qtyExceedsMessage;
                        });
                        widget.onTopError?.call(_qtyExceedsMessage);
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

                      if (!_overwriteLineItem &&
                          _totalEnteredQtyOnly != widget.ordered) {
                        setState(() {
                          _dialogErrorMessage = _quantityMismatchMessage;
                        });
                        return;
                      }

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
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
