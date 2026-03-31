import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
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
const _tableHeaderBg = Color(0xFFF5F5F5);

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
  final GlobalKey mfgKey = GlobalKey();
  final GlobalKey expKey = GlobalKey();
  DateTime? mfgDate;
  DateTime? expDate;

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
  final _notesCtrl = TextEditingController();

  // Form state
  final GlobalKey _dateFieldKey = GlobalKey();
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
  bool _isManualMode = false;
  final List<String?> _preferredBins = [];
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

  // Items
  final List<PurchaseReceiveItem> _items = [];
  final List<_ReceiveItemRowController> _rowControllers = [];

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
  }

  void _insertManualRow() {
    setState(() {
      _items.add(PurchaseReceiveItem());
      _rowControllers.add(_ReceiveItemRowController());
      _preferredBins.add(null);
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
    _notesCtrl.dispose();
    for (var c in _rowControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _switchToManualMode() {
    setState(() {
      _isManualMode = !_isManualMode;

      _clearAllRows();

      if (_isManualMode) {
        // Manual mode -> empty row
        _items.add(PurchaseReceiveItem());
        _rowControllers.add(_ReceiveItemRowController());
        _preferredBins.add(null);
      } else {
        // PO mode -> reload items from selected PO
        if (_selectedPO != null) {
          _onPOSelected(_selectedPO!);
        }
      }
    });
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
          // ── Vendor & PO Section ──
          _buildVendorAndPOFields(),
          const SizedBox(height: 20),
          // ── Dependent Sections (Disabled without PO) ──
          Opacity(
            opacity: _hasValidSelection
                ? 1.0
                : 0.3, // Match screenshot stronger fade
            child: IgnorePointer(
              ignoring: !_hasValidSelection,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOtherFormFields(),
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
      _isManualMode = false;
      _clearAllRows();
    });

    try {
      final pos = await ref.read(
        purchaseOrdersProvider(
          PurchaseOrderFilter(limit: 500),
        ).future,
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
      _isManualMode = false;
      _isLoadingPOs = true; // Show loading while fetching details
    });

    try {
      // Fetch full PO details including line items
      final fullPO = await ref.read(purchaseOrderProvider(po.id!).future);

      if (!mounted) return;

      setState(() {
        _selectedPO = fullPO ?? po;
        _isLoadingPOs = false;
        _clearAllRows();

        if (fullPO != null && fullPO.items.isNotEmpty) {
          for (var poItem in fullPO.items) {
            _items.add(
              PurchaseReceiveItem(
                itemId: poItem.productId,
                itemName: poItem.productName ?? poItem.itemCode ?? '',
                description: poItem.description,
                ordered: poItem.quantity,
                received: 0,
                inTransit: 0,
                quantityToReceive: poItem.quantity,
              ),
            );
            final ctrl = _ReceiveItemRowController();
            ctrl.qtyCtrl.text = poItem.quantity.toString();
            _rowControllers.add(ctrl);
            _preferredBins.add(null);
          }
        } else if (fullPO != null && fullPO.items.isEmpty) {
          AppLogger.warning(
            'Selected Purchase Order has no items.',
            module: 'purchases',
          );
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPOs = false);
        _showTopError('Failed to load items for this Purchase Order');
      }
      AppLogger.error(
        'Failed to fetch PO details in Purchase Receive',
        error: e,
        module: 'purchases',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildVendorAndPOFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor Name
          _buildFormRow(
            label: 'Vendor Name',
            isRequired: true,
            child: SizedBox(
              width: 420,
              child: FormDropdown<Vendor>(
                // menuMaxHeight removed
                value: ref
                    .read(vendorProvider)
                    .vendors
                    .where((v) => v.id == _selectedVendorId)
                    .firstOrNull,
                items: ref.watch(vendorProvider).vendors,
                hint: 'Select or type to search',
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
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Purchase Order
          _buildFormRow(
            label: 'Purchase Order#',
            isRequired: true,
            child: SizedBox(
              width: 420,
              child: FormDropdown<PurchaseOrder>(
                itemHeight: 60.0,
                value: _selectedPO,
                items: _vendorPOs,
                hint: _selectedVendorId == null
                    ? 'Select a vendor first'
                    : (_vendorPOs.isEmpty && !_isLoadingPOs
                          ? 'No POs found'
                          : 'Select a Purchase Order'),
                showSearch: true,
                isLoading: _isLoadingPOs,
                displayStringForValue: (po) => po.orderNumber,
                searchStringForValue: (po) =>
                    '${po.orderNumber} ${DateFormat('dd-MM-yyyy').format(po.orderDate)}',
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
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  color: showHover
                                      ? Colors.white
                                      : _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Date: ${DateFormat('dd-MM-yyyy').format(po.orderDate)} | Total: \$${po.total.toStringAsFixed(2)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Inter',
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
                onChanged: (po) {
                  if (po != null) {
                    _onPOSelected(po);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherFormFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purchase Receive#
          _buildFormRow(
            label: 'Purchase receive#',
            isRequired: true,
            child: SizedBox(
              width: 150,
              child: TextField(
                controller: _receiveNumberCtrl,
                readOnly: _isReceiveAutoGenerate,
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
                    borderSide: const BorderSide(
                      color: _focusBorder,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  suffixIcon: ZTooltip(
                    message:
                        'Click here to enable or disable autogeneration of Purchase Receive numbers.',
                    // placement removed
                    child: InkWell(
                      onTap: _showPurchaseReceivePreferencesDialog,
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
          const SizedBox(height: 20),

          // Received Date
          _buildFormRow(
            label: 'Received date',
            isRequired: true,
            child: SizedBox(
              width: 150,
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
                        'dd-MM-yyyy',
                      ).format(picked);
                    });
                  }
                },
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
                  hintText: 'dd-MM-yyyy',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: _hintColor,
                    fontFamily: 'Inter',
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: _fieldBorder),
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

  Widget _buildDropdownOverlayItem(
    String label,
    bool isSelected,
    bool isHovered,
  ) {
    final showHover = isHovered;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: showHover
            ? const Color(0xFF3B82F6)
            : (isSelected ? const Color(0xFFF3F4F6) : Colors.white),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                color: showHover ? Colors.white : _textPrimary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
  }

  Widget _buildItemsTableNormal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table Container
              Container(
                decoration: const BoxDecoration(
                  border: Border.fromBorderSide(BorderSide(color: _borderCol)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table Header
                    Container(
                      decoration: const BoxDecoration(
                        color: _tableHeaderBg,
                        border: Border(
                          top: BorderSide(color: _borderCol),
                          bottom: BorderSide(color: _borderCol),
                          left: BorderSide(color: _borderCol),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          _tableHeaderCell('ITEMS & DESCRIPTION', flex: 4),
                          _tableHeaderCell(
                            'ORDERED',
                            flex: 1,
                            align: TextAlign.center,
                          ),
                          _tableHeaderCell(
                            'RECEIVED',
                            flex: 1,
                            align: TextAlign.center,
                          ),
                          _tableHeaderCell(
                            'IN TRANSIT',
                            flex: 1,
                            align: TextAlign.center,
                          ),
                          if (_binMode == 'item')
                            _tableHeaderCell(
                              'BIN',
                              flex: 2,
                              align: TextAlign.center,
                            ),
                          _tableHeaderCell(
                            'QUANTITY TO RECEIVE',
                            flex: 2,
                            align: TextAlign.center,
                            isLastColumn: _binMode == 'item' ? false : true,
                          ),
                          _tableHeaderCell(
                            '',
                            fixedWidth: 40,
                            isLastColumn: true,
                          ),
                        ],
                      ),
                    ),

                    // Table Rows
                    if (_isLoadingPOs)
                      _buildLoadingRow()
                    else if (_items.isEmpty)
                      _buildEmptyRow()
                    else
                      ..._items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return _buildItemRow(index, item);
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
              // Insert New Row Button
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: _buildInsertRowButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualItemsTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.62,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border.fromBorderSide(BorderSide(color: _borderCol)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table Header
                    Container(
                      decoration: const BoxDecoration(
                        color: _tableHeaderBg,
                        border: Border(
                          top: BorderSide(color: _borderCol),
                          bottom: BorderSide(color: _borderCol),
                          left: BorderSide(color: _borderCol),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          _tableHeaderCell('ITEMS & DESCRIPTION', flex: 4),
                          _tableHeaderCell(
                            'ORDERED',
                            flex: 1,
                            align: TextAlign.center,
                          ),
                          _tableHeaderCell(
                            'RECEIVED',
                            flex: 1,
                            align: TextAlign.center,
                          ),
                          _tableHeaderCell(
                            'IN TRANSIT',
                            flex: 1,
                            align: TextAlign.center,
                          ),
                          if (_binMode == 'item')
                            _tableHeaderCell(
                              'BIN',
                              flex: 2,
                              align: TextAlign.center,
                            ),
                          _tableHeaderCell(
                            'QUANTITY TO RECEIVE',
                            flex: 2,
                            align: TextAlign.center,
                            isLastColumn: _binMode == 'item' ? false : true,
                          ),
                          _tableHeaderCell(
                            '',
                            fixedWidth: 40,
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
                        // Use controller identity for stable key across item selection changes
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
      child: Text(
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

  Widget _tableBodyCell({
    required Widget child,
    int flex = 1,
    double? fixedWidth,
    bool isLastColumn = false,
  }) {
    final content = Container(
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          right: isLastColumn
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

  Widget _buildQtyCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFFE7F2FF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 13, color: Color(0xFF2A95BF)),
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
    final isActive =
        _hoveredQtyFields.contains(fieldKey) ||
        _focusedQtyFields.contains(fieldKey);

    return SizedBox(
      height: 44,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildQtyCircleButton(icon: LucideIcons.minus, onTap: onDecrement),
            const SizedBox(width: 8),
            MouseRegion(
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
                width: 80,
                height: 44,
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isActive ? _focusBorder : _fieldBorder,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: _focusBorder,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildQtyCircleButton(icon: LucideIcons.plus, onTap: onIncrement),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyInputField({
    required String fieldKey,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
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
        width: 70,
        height: 44,
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
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isActive ? _focusBorder : _fieldBorder,
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
    final currentQty = double.tryParse(ctrl.qtyCtrl.text) ?? 0;
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
    final qty = double.tryParse(value) ?? 0;
    setState(() {
      _items[index] = _items[index].copyWith(quantityToReceive: qty);
    });
  }

  Widget _buildBatchesLink(PurchaseReceiveItem item, int index) {
    final hasBatches = item.batches.isNotEmpty;
    return InkWell(
      onTap: () {
        _showSelectBatchDialog(index);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            hasBatches ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
            size: 12,
            color: hasBatches ? _greenBtn : Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            hasBatches
                ? '${item.batches.length} ${item.batches.length == 1 ? 'Batch' : 'Batches'} (${item.batches.fold<double>(0, (sum, b) => sum + b.quantity).toInt()} + ${item.batches.fold<double>(0, (sum, b) => sum + b.foc).toInt()} FOC)'
                : 'Add Batches',
            style: TextStyle(
              fontSize: 11,
              color: hasBatches ? _greenBtn : Colors.orange.shade700,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
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

  Widget _buildManualRow(
    int index,
    PurchaseReceiveItem item, {
    bool isEphemeral = false,
  }) {
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
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          poItem.productName ?? 'Unnamed item',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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
                    if (isEphemeral) {
                      // Start from empty state: set first item + add empty row
                      _items.add(poItem.productId.isNotEmpty
                          ? PurchaseReceiveItem(
                              itemId: poItem.productId,
                              itemName: poItem.productName ?? '',
                              description: poItem.description,
                              ordered: poItem.quantity,
                              received: 0,
                              inTransit: 0,
                            )
                          : PurchaseReceiveItem());
                      _rowControllers.add(_ReceiveItemRowController());
                      _preferredBins.add(null);
                      // Add empty row for next entry
                      _items.add(PurchaseReceiveItem());
                      _rowControllers.add(_ReceiveItemRowController());
                      _preferredBins.add(null);
                    } else {
                      // Normal update: replace current row
                      if (index < _items.length) {
                        _items[index] = _items[index].copyWith(
                          itemId: poItem.productId,
                          itemName: poItem.productName ?? '',
                          description: poItem.description,
                          ordered: poItem.quantity,
                          received: 0,
                          inTransit: 0,
                        );
                        // Auto-add new row if this was the last one
                        if (index == _items.length - 1) {
                          _items.add(PurchaseReceiveItem());
                          _rowControllers.add(_ReceiveItemRowController());
                          _preferredBins.add(null);
                        }
                      }
                    }
                  });
                },
              ),
            ),
          ),
          _tableBodyCell(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                item.ordered > 0
                    ? item.ordered.toStringAsFixed(
                        item.ordered == item.ordered.roundToDouble() ? 0 : 2,
                      )
                    : '',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          _tableBodyCell(
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: SizedBox(),
            ),
          ),
          _tableBodyCell(
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: SizedBox(),
            ),
          ),
          if (_binMode == 'item')
            _tableBodyCell(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      _hoveredBinFields.add('manual-bin-$index');
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _hoveredBinFields.remove('manual-bin-$index');
                    });
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      setState(() {
                        _focusedBinFields
                          ..clear()
                          ..add('manual-bin-$index');
                      });
                    },
                    child: SizedBox(
                      height: 44,
                      child: FormDropdown<String>(
                        value: selectedBin,
                        items: _manualBinList,
                        hint: 'Select Bin',
                        showSearch: true,
                        border: Border.all(
                          color:
                              (_hoveredBinFields.contains(
                                    'manual-bin-$index',
                                  ) ||
                                  _focusedBinFields.contains(
                                    'manual-bin-$index',
                                  ))
                              ? _focusBorder
                              : Colors.transparent,
                          width:
                              (_hoveredBinFields.contains(
                                    'manual-bin-$index',
                                  ) ||
                                  _focusedBinFields.contains(
                                    'manual-bin-$index',
                                  ))
                              ? 1.2
                              : 1,
                        ),
                        itemBuilder: (item, isSelected, isHovered) {
                          return _buildDropdownOverlayItem(
                            item,
                            isSelected,
                            isHovered,
                          );
                        },
                        onChanged: (bin) {
                          if (isEphemeral || index >= _preferredBins.length)
                            return;
                          setState(() {
                            _preferredBins[index] = bin;
                            _focusedBinFields.remove('manual-bin-$index');
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          _tableBodyCell(
            flex: 2,
            isLastColumn: _binMode == 'item' ? false : true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  if (!isEphemeral) ...[
                    const SizedBox(height: 4),
                    _buildBatchesLink(item, index),
                  ],
                ],
              ),
            ),
          ),
          // Delete button (as proper grid cell)
          _tableBodyCell(
            fixedWidth: 40,
            isLastColumn: true,
            child: SizedBox(
              width: 40,
              child: isEphemeral
                  ? const SizedBox()
                  : InkWell(
                      onTap: () => _removeItem(index),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(LucideIcons.x, size: 16, color: _dangerRed),
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
          // Item Name & Description
          _tableBodyCell(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item thumbnail placeholder
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
                              : 'Select an item',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: item.itemName.isNotEmpty
                                ? _textPrimary
                                : _hintColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        if (item.description != null &&
                            item.description!.isNotEmpty)
                          Text(
                            item.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _hintColor,
                              fontFamily: 'Inter',
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
          // Ordered
          _tableBodyCell(
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
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          // Received
          _tableBodyCell(
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
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          // In Transit
          _tableBodyCell(
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
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          // Preferred Bin (conditional)
          if (_binMode == 'item')
            _tableBodyCell(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      _hoveredBinFields.add('po-bin-$index');
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _hoveredBinFields.remove('po-bin-$index');
                    });
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      setState(() {
                        _focusedBinFields
                          ..clear()
                          ..add('po-bin-$index');
                      });
                    },
                    child: SizedBox(
                      height: 44,
                      child: FormDropdown<String>(
                        value: index < _preferredBins.length
                            ? _preferredBins[index]
                            : null,
                        items: _manualBinList,
                        hint: 'Select Bin',
                        showSearch: true,
                        border: Border.all(
                          color:
                              (_hoveredBinFields.contains('po-bin-$index') ||
                                  _focusedBinFields.contains('po-bin-$index'))
                              ? _focusBorder
                              : Colors.transparent,
                          width:
                              (_hoveredBinFields.contains('po-bin-$index') ||
                                  _focusedBinFields.contains('po-bin-$index'))
                              ? 1.2
                              : 1,
                        ),
                        itemBuilder: (item, isSelected, isHovered) {
                          return _buildDropdownOverlayItem(
                            item,
                            isSelected,
                            isHovered,
                          );
                        },
                        onChanged: (bin) {
                          if (index >= _preferredBins.length) return;
                          setState(() {
                            _preferredBins[index] = bin;
                            _focusedBinFields.remove('po-bin-$index');
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Quantity To Receive (editable)
          _tableBodyCell(
            flex: 2,
            isLastColumn: _binMode == 'item' ? false : true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildQtyInputField(
                    fieldKey: 'item-$index',
                    controller: ctrl.qtyCtrl,
                    onChanged: (val) => _onRowQtyChanged(index, val),
                  ),
                  const SizedBox(height: 4),
                  _buildBatchesLink(item, index),
                ],
              ),
            ),
          ),
          // Delete button (as proper grid cell)
          _tableBodyCell(
            fixedWidth: 40,
            isLastColumn: true,
            child: SizedBox(
              width: 40,
              child: InkWell(
                onTap: () => _removeItem(index),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(LucideIcons.x, size: 16, color: _dangerRed),
                ),
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
                  color: isRequired ? _requiredLabel : _labelColor,
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
      final totalBatchQty = item.batches.fold<double>(
        0,
        (sum, b) => sum + b.quantity + b.foc,
      );
      if (totalBatchQty != item.quantityToReceive) {
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

  void _showSelectBatchDialog(int itemIndex) {
    final item = _items[itemIndex];
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _SelectBatchDialog(
        itemName: item.itemName,
        initialBatches: item.batches,
        // Total in batch dialog must follow current Quantity Out in line item.
        ordered: item.quantityToReceive,
        warehouseName:
            _selectedPO?.vendorName ??
            _selectedVendorName ??
            'ZABNIX PRIVATE LIMITED',
        onSave: (newBatches) {
          setState(() {
            final totalQty = newBatches.fold<double>(
              0,
              (sum, b) => sum + b.quantity,
            );
            final totalFoc = newBatches.fold<double>(
              0,
              (sum, b) => sum + b.foc,
            );
            final combinedQty = totalQty + totalFoc;

            _items[itemIndex] = item.copyWith(
              batches: newBatches,
              quantityToReceive: combinedQty,
            );
            _rowControllers[itemIndex].qtyCtrl.text = combinedQty.toString();
          });
        },
      ),
    );
  }
}

class _SelectBatchDialog extends StatefulWidget {
  final String itemName;
  final String warehouseName;
  final double ordered;
  final List<BatchInfo> initialBatches;
  final Function(List<BatchInfo>) onSave;

  const _SelectBatchDialog({
    required this.itemName,
    required this.warehouseName,
    required this.ordered,
    required this.initialBatches,
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 12,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            borderSide: const BorderSide(color: borderCol),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            borderSide: const BorderSide(color: borderCol),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            borderSide: const BorderSide(color: _focusBorder, width: 1.2),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        style: const TextStyle(
                                          fontSize: 22 / 2,
                                          color: textPrimary,
                                          fontFamily: 'Inter',
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 12,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            borderSide: const BorderSide(color: borderCol),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            borderSide: const BorderSide(color: borderCol),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            borderSide: const BorderSide(color: _focusBorder, width: 1.2),
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
                        backgroundColor: const Color(0xFFF3F4F6),
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
  bool _showMfgDetails = false;
  bool _showFoc = false;
  bool _overwriteLineItem = false;
  String? _dialogErrorMessage;
  static const String _quantityMismatchMessage =
      'There\'s a mismatch between the quantity entered in the line item and the total quantity across all batches. Click the checkbox to overwrite the quantity in the line item.';
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
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  double get _totalQuantityOut => _rows.fold<double>(
    0,
    (sum, row) => sum + (double.tryParse(row.qtyCtrl.text.trim()) ?? 0),
  );

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
    final expiryDate = row.expDateCtrl.text.trim();
    final quantity = row.qtyCtrl.text.trim();

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
    if (expiryDate.isEmpty || row.expDate == null) {
      return '$rowLabel: Expiry Date is required';
    }
    if (quantity.isEmpty) {
      return '$rowLabel: Quantity is required';
    }
    final parsedQty = double.tryParse(quantity);
    if (parsedQty == null || parsedQty <= 0) {
      return '$rowLabel: Quantity must be greater than 0';
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
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 44,
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
                horizontal: 8,
                vertical: 12,
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

  Widget _buildDatePicker({
    required TextEditingController controller,
    required GlobalKey targetKey,
    required int flex,
    required VoidCallback onTap,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 44,
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
                horizontal: 12,
                vertical: 12,
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
                minWidth: 32,
                maxHeight: 44,
              ),
              suffixIcon: const Icon(
                LucideIcons.calendar,
                size: 14,
                color: _hintColor,
              ),
            ),
          ),
        ),
      ),
    );
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
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Text(
                          '•',
                          style: TextStyle(fontSize: 16, color: _textPrimary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          _quantityMismatchMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: _textPrimary,
                            fontFamily: 'Inter',
                            height: 1.3,
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
                    'Overwrite the line item with ${_fmtQty(_totalQuantityOut)} quantities',
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
                  _headerCell('BATCH NO*', 15),
                  _headerCell('UNIT PACK*', 15),
                  _headerCell('MRP*', 15),
                  _headerCell('PTR', 15),
                  _headerCell('EXPIRY DATE*', 15),
                  if (_showMfgDetails) ...[
                    _headerCell('MANUFACTURED DATE', 15),
                    _headerCell('MANUFACTURER BATCH', 15),
                  ],
                  _headerCell('QUANTITY*', 15),
                  if (_showFoc) _headerCell('FOC', 15),
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
                            _buildTextField(
                              controller: row.batchNoCtrl,
                              hint: 'Batch No',
                              flex: 15,
                            ),
                            _buildTextField(
                              controller: row.unitPackCtrl,
                              hint: 'Pack',
                              flex: 15,
                              isNumeric: true,
                            ),
                            _buildTextField(
                              controller: row.mrpCtrl,
                              hint: '0',
                              flex: 15,
                              isNumeric: true,
                            ),
                            _buildTextField(
                              controller: row.ptrCtrl,
                              hint: '0',
                              flex: 15,
                              isNumeric: true,
                            ),
                            _buildDatePicker(
                              controller: row.expDateCtrl,
                              targetKey: row.expKey,
                              flex: 15,
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
                                flex: 15,
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
                                flex: 15,
                              ),
                            ],
                            _buildTextField(
                              controller: row.qtyCtrl,
                              hint: '0',
                              flex: 15,
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
                                flex: 15,
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
                                onPressed: () => _removeRow(index),
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
                      for (var i = 0; i < _rows.length; i++) {
                        final validationMessage = _validateRequiredFields(
                          _rows[i],
                          i,
                        );
                        if (validationMessage != null) {
                          setState(() {
                            _dialogErrorMessage = validationMessage;
                          });
                          return;
                        }
                      }

                      final results = _rows
                          .map((r) => r.toBatchInfo())
                          .toList();
                      final totalQty = results.fold<double>(
                        0,
                        (sum, b) => sum + b.quantity,
                      );

                      if (!_overwriteLineItem && totalQty != widget.ordered) {
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
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          textAlign: alignment,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isMandatory ? const Color(0xFFD32F2F) : _textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
