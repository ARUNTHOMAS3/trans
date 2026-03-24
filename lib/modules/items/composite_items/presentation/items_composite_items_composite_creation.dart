import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/items/composite_items/models/composite_item_model.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_state.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/modules/sales/models/hsn_sac_model.dart';
import 'package:zerpai_erp/shared/widgets/hsn_sac_search_modal.dart';
import 'package:zerpai_erp/shared/widgets/inputs/category_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_categories_dialog.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

enum CompositeItemType { assembly, kit }

class CompositeCreateScreen extends ConsumerStatefulWidget {
  final CompositeItem? item;
  const CompositeCreateScreen({super.key, this.item});

  @override
  ConsumerState<CompositeCreateScreen> createState() =>
      _CompositeCreateScreenState();
}

class _CompositeCreateScreenState extends ConsumerState<CompositeCreateScreen> {
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _hsnCtrl = TextEditingController();

  CompositeItemType _itemType = CompositeItemType.assembly;
  bool _isReturnable = true;
  bool _pushToEcommerce = false;
  bool _trackBinLocation = false;

  String? _selectedUnitId;
  String? _selectedCategoryId;
  String? _taxPreference = 'Taxable';
  String? _exemptionReason;

  // Sales Info
  final _sellingPriceCtrl = TextEditingController();
  final _salesDescriptionCtrl = TextEditingController();
  bool _isSellable = true;
  String? _selectedSalesAccountId;

  // Purchase Info
  final _costPriceCtrl = TextEditingController();
  final _purchaseDescriptionCtrl = TextEditingController();
  bool _isPurchasable = true;
  String? _selectedPurchaseAccountId;
  String? _selectedVendorId;

  // Tax Info
  String? _selectedIntraTaxRateId;
  String? _selectedInterTaxRateId;
  bool _isEditingTax = false;

  // Dimensions & Weight
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String _selectedDimensionUnit = 'cm';
  final _weightCtrl = TextEditingController();
  String _selectedWeightUnit = 'kg';

  // Manufacturer & Brand
  String? _selectedManufacturerId;
  String? _selectedBrandId;

  // Identifiers
  final _upcCtrl = TextEditingController();
  final _mpnCtrl = TextEditingController();
  final _eanCtrl = TextEditingController();
  final _isbnCtrl = TextEditingController();

  // Advanced Inventory Tracking
  String _trackingType = 'Track Batches';
  String? _selectedInventoryAccountId;
  String? _selectedValuationMethod;
  final _reorderPointCtrl = TextEditingController();
  String? _selectedReorderTermId;

  final List<_CompositeItemRowData> _rows = [];
  final List<_CompositeItemRowData> _serviceRows = [];
  bool _showServices = false;

  final List<PlatformFile> _selectedImages = [];
  int _primaryImageIndex = 0;

  static const List<String> _taxPreferenceOptions = [
    'Taxable',
    'Out Of Scope',
    'Non-Taxable',
    'Non-GST Supply',
  ];
  static const List<String> _exemptionReasonOptions = [
    'GSTMARGINCHEME',
    'LACK OF STOCK',
  ];
  static const double _inputHeight = 44.0;
  static const double _labelWidth = 160.0;
  static const double _fieldMaxWidth = 360.0;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _initializeWithItem(widget.item!);
    } else {
      _rows.add(_CompositeItemRowData());
    }
  }

  void _initializeWithItem(CompositeItem item) {
    _nameCtrl.text = item.productName;
    _skuCtrl.text = item.sku ?? '';
    _hsnCtrl.text = item.hsnCode ?? '';
    _itemType = item.type == 'kit'
        ? CompositeItemType.kit
        : CompositeItemType.assembly;
    _isReturnable = item.isReturnable;
    _pushToEcommerce = item.pushToEcommerce;
    _trackBinLocation = item.trackBinLocation;
    _selectedUnitId = item.unitId;
    _selectedCategoryId = item.categoryId;
    _taxPreference = item.taxPreference ?? 'Taxable';
    _sellingPriceCtrl.text = item.sellingPrice?.toString() ?? '';
    _salesDescriptionCtrl.text = item.salesDescription ?? '';
    _selectedSalesAccountId = item.salesAccountId;
    _costPriceCtrl.text = item.costPrice?.toString() ?? '';
    _purchaseDescriptionCtrl.text = item.purchaseDescription ?? '';
    _selectedPurchaseAccountId = item.purchaseAccountId;
    _selectedVendorId = item.preferredVendorId;
    _selectedIntraTaxRateId = item.intraStateTaxId;
    _selectedInterTaxRateId = item.interStateTaxId;
    _lengthCtrl.text = item.length?.toString() ?? '';
    _widthCtrl.text = item.width?.toString() ?? '';
    _heightCtrl.text = item.height?.toString() ?? '';
    _selectedDimensionUnit = item.dimensionUnit;
    _weightCtrl.text = item.weight?.toString() ?? '';
    _selectedWeightUnit = item.weightUnit;
    _selectedManufacturerId = item.manufacturerId;
    _selectedBrandId = item.brandId;
    _upcCtrl.text = item.upc ?? '';
    _mpnCtrl.text = item.mpn ?? '';
    _eanCtrl.text = item.ean ?? '';
    _isbnCtrl.text = item.isbn ?? '';
    _selectedInventoryAccountId = item.inventoryAccountId;
    _selectedValuationMethod = item.inventoryValuationMethod;
    _reorderPointCtrl.text = item.reorderPoint.toString();
    _selectedReorderTermId = item.reorderTermId;
    _trackingType = item.trackBatches
        ? 'Track Batches'
        : (item.trackSerialNumber ? 'Track Serial Numbers' : 'Track Batches');

    if (item.parts != null) {
      for (final part in item.parts!) {
        _rows.add(
          _CompositeItemRowData(
            itemId: part.componentProductId,
            quantity: part.quantity.toString(),
            sellingPrice: part.sellingPriceOverride?.toString() ?? '0.00',
            costPrice: part.costPriceOverride?.toString() ?? '0.00',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _hsnCtrl.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    for (final row in _serviceRows) {
      row.dispose();
    }
    _sellingPriceCtrl.dispose();
    _salesDescriptionCtrl.dispose();
    _costPriceCtrl.dispose();
    _purchaseDescriptionCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _upcCtrl.dispose();
    _mpnCtrl.dispose();
    _eanCtrl.dispose();
    _isbnCtrl.dispose();
    _reorderPointCtrl.dispose();
    super.dispose();
  }

  void _openCategoryConfigDialog() {
    final itemsState = ref.read(itemsControllerProvider);
    final controller = ref.read(itemsControllerProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => ManageCategoriesDialog(
        nodes: CategoryNode.fromFlatList(itemsState.categories),
        flatList: itemsState.categories,
        selectedCategory: _selectedCategoryId,
        onCategoryApplied: (id) => setState(() => _selectedCategoryId = id),
        onSave: (newList) => controller.syncCategories(newList),
      ),
    );
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null) return;

    setState(() {
      _selectedImages.addAll(result.files);
      if (_selectedImages.isNotEmpty &&
          _primaryImageIndex >= _selectedImages.length) {
        _primaryImageIndex = 0;
      }
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_primaryImageIndex >= _selectedImages.length) {
        _primaryImageIndex = 0;
      }
    });
  }

  String _itemKey(Item item) => item.id ?? item.itemCode;

  String? _itemLabel(Item item) {
    return item.productName;
  }

  Widget _buildImageUploadBox() {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFD),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD4D7E2)),
      ),
      padding: const EdgeInsets.all(12),
      child: _selectedImages.isEmpty
          ? InkWell(
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(6),
              child: _emptyImageState(),
            )
          : Column(
              children: [
                SizedBox(height: 148, child: _primaryImageView()),
                const SizedBox(height: 8),
                SizedBox(height: 22, child: _primaryStatusRow()),
                const SizedBox(height: 8),
                SizedBox(height: 48, child: _thumbnailStrip()),
              ],
            ),
    );
  }

  Widget _emptyImageState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.image_outlined, size: 42, color: AppTheme.textMuted),
        SizedBox(height: 12),
        Text(
          "Drag images here or",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13),
        ),
        SizedBox(height: 4),
        Text(
          "Browse images",
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF1B8EF1),
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }

  Widget _primaryImageView() {
    final file = _selectedImages[_primaryImageIndex];
    bool isHovering = false;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return MouseRegion(
          onEnter: (_) => setLocalState(() => isHovering = true),
          onExit: (_) => setLocalState(() => isHovering = false),
          child: GestureDetector(
            onTap: () => _openImagePreview(startIndex: _primaryImageIndex),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    file.bytes!,
                    height: 148,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (isHovering)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.search,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _primaryStatusRow() {
    final bool isPrimary = _primaryImageIndex == 0;

    return Row(
      children: [
        if (isPrimary)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppTheme.successGreen,
                ),
                SizedBox(width: 6),
                Text(
                  "Primary",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successTextDark,
                  ),
                ),
              ],
            ),
          )
        else
          Material(
            color: AppTheme.infoBg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  final img = _selectedImages.removeAt(_primaryImageIndex);
                  _selectedImages.insert(0, img);
                  _primaryImageIndex = 0;
                });
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  "Mark as Primary",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlueDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        const Spacer(),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _removeImage(_primaryImageIndex),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.delete_outline,
                size: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _thumbnailStrip() {
    const double thumbSize = 48;
    const int maxThumbs = 3;

    final extraCount = _selectedImages.length > maxThumbs
        ? _selectedImages.length - maxThumbs
        : 0;
    final visible = _selectedImages.take(maxThumbs).toList();

    return Row(
      children: [
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isActive = index == _primaryImageIndex;
              return InkWell(
                onTap: () => setState(() => _primaryImageIndex = index),
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.primaryBlueDark
                          : AppTheme.borderColor,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.memory(
                      visible[index].bytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (extraCount > 0) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _openImagePreview(startIndex: maxThumbs),
            child: Container(
              width: thumbSize,
              height: thumbSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderColor),
                color: AppTheme.bgDisabled,
              ),
              child: Text(
                '+$extraCount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        InkWell(
          onTap: _pickImages,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Icon(Icons.add, color: AppTheme.primaryBlueDark),
          ),
        ),
      ],
    );
  }

  void _openImagePreview({required int startIndex}) {
    if (_selectedImages.isEmpty) return;
    int current = startIndex.clamp(0, _selectedImages.length - 1);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Image preview',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (ctx, _, __) {
        return StatefulBuilder(
          builder: (ctx, setDlg) {
            void goPrev() => setDlg(
              () => current =
                  (current - 1 + _selectedImages.length) %
                  _selectedImages.length,
            );
            void goNext() =>
                setDlg(() => current = (current + 1) % _selectedImages.length);

            final file = _selectedImages[current];

            return SafeArea(
              child: Center(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: 860,
                    height: 520,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  40,
                                  24,
                                  40,
                                  12,
                                ),
                                child: Center(
                                  child: InteractiveViewer(
                                    minScale: 1,
                                    maxScale: 4,
                                    child: Image.memory(
                                      file.bytes!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 110,
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                12,
                                24,
                                14,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppTheme.borderColor),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Material(
                                        color: current == 0
                                            ? const Color(0xFFE6F4EA)
                                            : AppTheme.infoBg,
                                        borderRadius: BorderRadius.circular(10),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          onTap: current == 0
                                              ? null
                                              : () {
                                                  setState(() {
                                                    final img = _selectedImages
                                                        .removeAt(current);
                                                    _selectedImages.insert(
                                                      0,
                                                      img,
                                                    );
                                                    _primaryImageIndex = 0;
                                                  });
                                                  setDlg(() => current = 0);
                                                },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (current == 0) ...[
                                                  const Icon(
                                                    Icons.check_circle,
                                                    size: 14,
                                                    color:
                                                        AppTheme.successGreen,
                                                  ),
                                                  const SizedBox(width: 6),
                                                ],
                                                Text(
                                                  current == 0
                                                      ? "Primary"
                                                      : "Mark as Primary",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: current == 0
                                                        ? const Color(
                                                            0xFF166534,
                                                          )
                                                        : const Color(
                                                            0xFF2563EB,
                                                          ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Material(
                                        color: AppTheme.errorBgBorder,
                                        borderRadius: BorderRadius.circular(10),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          onTap: () {
                                            setState(() {
                                              _selectedImages.removeAt(current);
                                              _primaryImageIndex = 0;
                                            });
                                            if (_selectedImages.isEmpty) {
                                              Navigator.pop(ctx);
                                              return;
                                            }
                                            setDlg(() {
                                              current = current.clamp(
                                                0,
                                                _selectedImages.length - 1,
                                              );
                                            });
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  size: 16,
                                                  color: AppTheme.errorRed,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  "Delete",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.errorRed,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 42,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _selectedImages.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 8),
                                      itemBuilder: (_, i) {
                                        final active = i == current;
                                        return InkWell(
                                          onTap: () =>
                                              setDlg(() => current = i),
                                          child: Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: active
                                                    ? AppTheme.primaryBlueDark
                                                    : AppTheme.borderColor,
                                                width: active ? 2 : 1,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              child: Image.memory(
                                                _selectedImages[i].bytes!,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _roundIcon(
                            icon: Icons.close,
                            onTap: () => Navigator.pop(ctx),
                          ),
                        ),
                        _navArrow(
                          Icons.chevron_left,
                          Alignment.centerLeft,
                          goPrev,
                        ),
                        _navArrow(
                          Icons.chevron_right,
                          Alignment.centerRight,
                          goNext,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _roundIcon({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _navArrow(IconData icon, Alignment align, VoidCallback onTap) {
    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Material(
          color: Colors.black.withValues(alpha: 0.08),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(icon, size: 26),
            ),
          ),
        ),
      ),
    );
  }

  String? _toBackendTaxPreference(String? uiValue) {
    switch (uiValue) {
      case 'Taxable':
        return 'taxable';
      case 'Tax Exempt':
        return 'exempt';
      case 'Non-Taxable':
        return 'non-taxable';
      default:
        return null;
    }
  }

  double _parseNumber(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  double get _totalSelling {
    double total = 0;
    for (final row in _rows) {
      total +=
          _parseNumber(row.quantityCtrl.text) *
          _parseNumber(row.sellingPriceCtrl.text);
    }
    for (final row in _serviceRows) {
      total +=
          _parseNumber(row.quantityCtrl.text) *
          _parseNumber(row.sellingPriceCtrl.text);
    }
    return total;
  }

  double get _totalCost {
    double total = 0;
    for (final row in _rows) {
      total +=
          _parseNumber(row.quantityCtrl.text) *
          _parseNumber(row.costPriceCtrl.text);
    }
    for (final row in _serviceRows) {
      total +=
          _parseNumber(row.quantityCtrl.text) *
          _parseNumber(row.costPriceCtrl.text);
    }
    return total;
  }

  void _addRow() {
    setState(() => _rows.add(_CompositeItemRowData()));
  }

  void _removeRow(int index) {
    if (_rows.length == 1) return;
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  void _addServiceRow() {
    setState(() => _serviceRows.add(_CompositeItemRowData()));
  }

  void _removeServiceRow(int index) {
    if (_serviceRows.length == 1) return;
    setState(() {
      _serviceRows[index].dispose();
      _serviceRows.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsControllerProvider);
    final itemsController = ref.read(itemsControllerProvider.notifier);

    return ZerpaiLayout(
      pageTitle: 'New Composite Item',
      enableBodyScroll: true,
      footer: _buildFooter(itemsController, itemsState),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 1000;
          final form = _buildForm(itemsState);
          final images = _buildImagePanel();

          final topRow = isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: form,
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(width: 310, child: images),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [form, const SizedBox(height: 24), images],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              topRow,
              const SizedBox(height: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAssociateItemsSection(itemsState),
                    if (_showServices) ...[
                      const SizedBox(height: 32),
                      _buildAssociateServicesSection(itemsState),
                    ],
                    const SizedBox(height: 32),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 800) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildSalesInfoSection(itemsState),
                              ),
                              if (_itemType != CompositeItemType.kit) ...[
                                const SizedBox(width: 32),
                                Expanded(
                                  child: _buildPurchaseInfoSection(itemsState),
                                ),
                              ],
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSalesInfoSection(itemsState),
                              if (_itemType != CompositeItemType.kit) ...[
                                const SizedBox(height: 32),
                                _buildPurchaseInfoSection(itemsState),
                              ],
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    const SizedBox(height: 32),
                    _buildDefaultTaxRatesSection(itemsState),
                    const SizedBox(height: 32),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    const SizedBox(height: 32),
                    _buildDimensionsWeightSection(),
                    const SizedBox(height: 24),
                    _buildManufacturerBrandSection(itemsState),
                    const SizedBox(height: 24),
                    _buildIdentifiersSection(),
                    if (_itemType != CompositeItemType.kit) ...[
                      const SizedBox(height: 32),
                      const Divider(height: 1, color: AppTheme.borderColor),
                      const SizedBox(height: 32),
                      _buildInventoryTrackingSection(itemsState),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildForm(ItemsState itemsState) {
    final unitItems = itemsState.units;

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SharedFieldLayout(
              label: 'Name',
              required: true,
              labelWidth: _labelWidth,
              child: _constrainedField(
                CustomTextField(
                  controller: _nameCtrl,
                  hintText: 'Enter composite item name',
                  height: _inputHeight,
                ),
              ),
            ),
            SharedFieldLayout(
              label: 'Item Type',
              required: true,
              labelWidth: _labelWidth,
              crossAxisAlignment: CrossAxisAlignment.start,
              child: RadioGroup<CompositeItemType>(
                groupValue: _itemType,
                onChanged: (val) {
                  if (val != null) setState(() => _itemType = val);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeOption(
                      CompositeItemType.assembly,
                      'Assembly Item',
                      'A group of items combined together to be tracked and managed as a single item.',
                    ),
                    const SizedBox(height: 16),
                    _buildTypeOption(
                      CompositeItemType.kit,
                      'Kit Item',
                      'Individual items sold together as one kit.',
                    ),
                  ],
                ),
              ),
            ),
            SharedFieldLayout(
              label: 'SKU',
              labelWidth: _labelWidth,
              child: _constrainedField(
                CustomTextField(
                  controller: _skuCtrl,
                  hintText: 'Optional SKU',
                  height: _inputHeight,
                ),
              ),
            ),
            SharedFieldLayout(
              label: 'Unit',
              required: true,
              labelWidth: _labelWidth,
              tooltip: 'Primary unit of measure for this item',
              child: _constrainedField(
                FormDropdown<String>(
                  value: _selectedUnitId,
                  hint: 'Select or type to add',
                  items: unitItems.map((u) => u.id).toList(),
                  displayStringForValue: (val) {
                    if (unitItems.isEmpty) return val;
                    final match = unitItems.firstWhere(
                      (u) => u.id == val,
                      orElse: () => unitItems.first,
                    );
                    return match.unitName;
                  },
                  searchStringForValue: (id) {
                    final match = unitItems.firstWhere(
                      (u) => u.id == id,
                      orElse: () => unitItems.first,
                    );
                    return match.unitName;
                  },
                  itemBuilder: (id, isSelected, isHovered) {
                    final unit = unitItems.firstWhere(
                      (u) => u.id == id,
                      orElse: () => unitItems.first,
                    );
                    return Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: isHovered
                            ? AppTheme.primaryBlueDark
                            : isSelected
                            ? AppTheme.infoBg
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              unit.unitName,
                              style: TextStyle(
                                fontSize: 13,
                                color: isHovered
                                    ? Colors.white
                                    : isSelected
                                    ? AppTheme.primaryBlueDark
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: isHovered
                                  ? Colors.white
                                  : AppTheme.primaryBlueDark,
                            ),
                        ],
                      ),
                    );
                  },
                  allowClear: true,
                  height: _inputHeight,
                  onChanged: (value) => setState(() => _selectedUnitId = value),
                ),
              ),
            ),
            SharedFieldLayout(
              label: 'Category',
              labelWidth: _labelWidth,
              child: _constrainedField(
                CategoryDropdown(
                  nodes: CategoryNode.fromFlatList(itemsState.categories),
                  value: _selectedCategoryId,
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                  onManageCategoriesTap: _openCategoryConfigDialog,
                ),
              ),
            ),
            SharedFieldLayout(
              label: null,
              labelWidth: _labelWidth,
              child: Row(
                children: [
                  // Returnable Item
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _isReturnable,
                          onChanged: (value) =>
                              setState(() => _isReturnable = value ?? false),
                          activeColor: AppTheme.primaryBlueDark,
                          side: const BorderSide(
                            color: AppTheme.borderColor,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Returnable Item',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textBody,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ZTooltip(
                        message:
                            'Check if this item can be returned by customers',
                        child: Icon(
                          Icons.help_outline,
                          size: 16,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16), // Adjusted spacing
                  // Ecommercable
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _pushToEcommerce,
                          onChanged: (value) =>
                              setState(() => _pushToEcommerce = value ?? false),
                          activeColor: AppTheme.primaryBlueDark,
                          side: const BorderSide(
                            color: AppTheme.borderColor,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'E-commercable',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textBody,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ZTooltip(
                        message:
                            'Enable this to sync this item with your connected ecommerce stores',
                        child: Icon(
                          Icons.help_outline,
                          size: 16,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SharedFieldLayout(
              label: 'HSN Code',
              labelWidth: _labelWidth,
              child: _constrainedField(
                CustomTextField(
                  controller: _hsnCtrl,
                  hintText: 'Enter HSN code',
                  height: _inputHeight,
                  suffixWidget: IconButton(
                    icon: const Icon(Icons.search, size: 20),
                    onPressed: _openHsnSacSearch,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                  ),
                ),
              ),
            ),
            SharedFieldLayout(
              label: 'Tax Preference',
              required: true,
              labelWidth: _labelWidth,
              child: _constrainedField(
                FormDropdown<String>(
                  value: _taxPreference,
                  hint: 'Select tax preference',
                  items: _taxPreferenceOptions,
                  allowClear: false,
                  height: _inputHeight,
                  onChanged: (value) {
                    setState(() {
                      _taxPreference = value;
                      _exemptionReason = null;
                    });
                  },
                ),
              ),
            ),
            if (_taxPreference == 'Non-Taxable')
              SharedFieldLayout(
                label: 'Exemption Reason',
                required: true,
                labelWidth: _labelWidth,
                tooltip: 'Reason for exempting this item',
                child: _constrainedField(
                  FormDropdown<String>(
                    value: _exemptionReason,
                    hint: 'Select or type to add',
                    items: _exemptionReasonOptions,
                    allowClear: false,
                    height: _inputHeight,
                    onChanged: (value) =>
                        setState(() => _exemptionReason = value),
                    itemBuilder: (id, isSelected, isHovered) {
                      return Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: isHovered
                              ? AppTheme.primaryBlueDark
                              : isSelected
                              ? AppTheme.infoBg
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                id,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isHovered
                                      ? Colors.white
                                      : isSelected
                                      ? AppTheme.primaryBlueDark
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: 16,
                                color: isHovered
                                    ? Colors.white
                                    : AppTheme.primaryBlueDark,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAssociateItemsSection(ItemsState itemsState) {
    final goods = itemsState.items.where((i) => i.type == 'goods').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Associate Items',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.errorRedDark,
          ),
        ),
        const SizedBox(height: 8),
        _buildCustomTable(
          items: goods,
          rows: _rows,
          title: 'Item Details',
          onRemove: _removeRow,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _addRow,
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: AppTheme.primaryBlueDark,
                ),
                label: const Text(
                  'Add New Row',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (!_showServices)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showServices = true;
                      if (_serviceRows.isEmpty) {
                        _serviceRows.add(_CompositeItemRowData());
                      }
                    });
                  },
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: AppTheme.primaryBlueDark,
                  ),
                  label: const Text(
                    'Add Services',
                    style: TextStyle(
                      fontSize: 12,
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

  Widget _buildAssociateServicesSection(ItemsState itemsState) {
    final services = itemsState.items
        .where((i) => i.type == 'service')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Associate Services',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.errorRedDark,
          ),
        ),
        const SizedBox(height: 8),
        _buildCustomTable(
          items: services,
          rows: _serviceRows,
          title: 'Service Details',
          onRemove: _removeServiceRow,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addServiceRow,
            icon: const Icon(
              Icons.add_circle_outline,
              size: 16,
              color: AppTheme.primaryBlueDark,
            ),
            label: const Text(
              'Add New Row',
              style: TextStyle(fontSize: 12, color: AppTheme.primaryBlueDark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesInfoSection(ItemsState itemsState) {
    // Pre-select Sales account if not set
    if (_selectedSalesAccountId == null && itemsState.accounts.isNotEmpty) {
      try {
        final salesAcc = itemsState.accounts.firstWhere(
          (a) => a['account_name'].toString().toLowerCase().contains('sales'),
        );
        _selectedSalesAccountId = salesAcc['id'].toString();
      } catch (_) {
        _selectedSalesAccountId = itemsState.accounts.first['id'].toString();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sales Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _isSellable,
                  onChanged: (val) => setState(() => _isSellable = val ?? true),
                  activeColor: AppTheme.primaryBlueDark,
                  visualDensity: VisualDensity.compact,
                ),
                const Text(
                  'Sellable',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SharedFieldLayout(
          label: 'Selling Price (INR)',
          required: _isSellable,
          child: CustomTextField(
            controller: _sellingPriceCtrl,
            keyboardType: TextInputType.number,
            suffix: _isSellable
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _sellingPriceCtrl.text = _totalSelling
                              .toStringAsFixed(2);
                        });
                      },
                      child: const Text(
                        'Copy from total',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryBlueDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        SharedFieldLayout(
          label: 'Account',
          required: _isSellable,
          child: FormDropdown<String>(
            value: _selectedSalesAccountId,
            hint: 'Select an account',
            items: itemsState.accounts.map((a) => a['id'].toString()).toList(),
            displayStringForValue: (id) {
              try {
                return itemsState.accounts.firstWhere(
                  (a) => a['id'].toString() == id,
                )['account_name'];
              } catch (_) {
                return '';
              }
            },
            onChanged: (val) => setState(() => _selectedSalesAccountId = val),
            onSearch: (q) async {
              final results = await ref
                  .read(itemsControllerProvider.notifier)
                  .searchAccounts(q);
              return results.map((a) => a['id'].toString()).toList();
            },
          ),
        ),
        const SizedBox(height: 16),
        SharedFieldLayout(
          label: 'Description',
          child: CustomTextField(
            controller: _salesDescriptionCtrl,
            maxLines: 3,
            hintText: 'Enter sales description',
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseInfoSection(ItemsState itemsState) {
    // Pre-select Cost of Goods Sold account if not set
    if (_selectedPurchaseAccountId == null && itemsState.accounts.isNotEmpty) {
      try {
        final cogsAcc = itemsState.accounts.firstWhere(
          (a) => a['account_name'].toString().toLowerCase().contains(
            'cost of goods',
          ),
        );
        _selectedPurchaseAccountId = cogsAcc['id'].toString();
      } catch (_) {
        // Fallback to first account if possible
        if (_selectedSalesAccountId != null && itemsState.accounts.length > 1) {
          // Try to find an account that is not the sales account
          try {
            _selectedPurchaseAccountId = itemsState.accounts
                .firstWhere(
                  (a) => a['id'].toString() != _selectedSalesAccountId,
                )['id']
                .toString();
          } catch (_) {
            _selectedPurchaseAccountId = itemsState.accounts.first['id']
                .toString();
          }
        } else {
          _selectedPurchaseAccountId = itemsState.accounts.first['id']
              .toString();
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Purchase Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _isPurchasable,
                  onChanged: (val) =>
                      setState(() => _isPurchasable = val ?? true),
                  activeColor: AppTheme.primaryBlueDark,
                  visualDensity: VisualDensity.compact,
                ),
                const Text(
                  'Purchasable',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SharedFieldLayout(
          label: 'Cost Price (INR)',
          required: _isPurchasable,
          child: CustomTextField(
            controller: _costPriceCtrl,
            keyboardType: TextInputType.number,
            suffix: _isPurchasable
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _costPriceCtrl.text = _totalCost.toStringAsFixed(2);
                        });
                      },
                      child: const Text(
                        'Copy from total',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryBlueDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        SharedFieldLayout(
          label: 'Account',
          required: _isPurchasable,
          child: FormDropdown<String>(
            value: _selectedPurchaseAccountId,
            hint: 'Select an account',
            items: itemsState.accounts.map((a) => a['id'].toString()).toList(),
            displayStringForValue: (id) {
              try {
                return itemsState.accounts.firstWhere(
                  (a) => a['id'].toString() == id,
                )['account_name'];
              } catch (_) {
                return '';
              }
            },
            onChanged: (val) =>
                setState(() => _selectedPurchaseAccountId = val),
            onSearch: (q) async {
              final results = await ref
                  .read(itemsControllerProvider.notifier)
                  .searchAccounts(q);
              return results.map((a) => a['id'].toString()).toList();
            },
          ),
        ),
        const SizedBox(height: 16),
        SharedFieldLayout(
          label: 'Description',
          child: CustomTextField(
            controller: _purchaseDescriptionCtrl,
            maxLines: 3,
            hintText: 'Enter purchase description',
          ),
        ),
        const SizedBox(height: 16),
        SharedFieldLayout(
          label: 'Preferred Vendor',
          child: FormDropdown<String>(
            value: _selectedVendorId,
            hint: 'Select a vendor',
            items: itemsState.vendors.map((v) => v['id'].toString()).toList(),
            displayStringForValue: (id) {
              try {
                return itemsState.vendors.firstWhere(
                  (v) => v['id'].toString() == id,
                )['name'];
              } catch (_) {
                return '';
              }
            },
            onChanged: (val) => setState(() => _selectedVendorId = val),
            onSearch: (q) async {
              final results = await ref
                  .read(itemsControllerProvider.notifier)
                  .searchVendors(q);
              return results.map((v) => v['id'].toString()).toList();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultTaxRatesSection(ItemsState itemsState) {
    String getTaxDisplay(String? id) {
      if (id == null || itemsState.taxRates.isEmpty) return 'None';
      try {
        final tax = itemsState.taxRates.firstWhere((t) => t.id == id);
        return '${tax.taxName} (${tax.taxRate} %)';
      } catch (_) {
        return 'None';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Default Tax Rates',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => setState(() => _isEditingTax = !_isEditingTax),
              icon: Icon(
                _isEditingTax
                    ? Icons.check_circle_outline
                    : Icons.edit_outlined,
                size: 16,
                color: AppTheme.primaryBlueDark,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!_isEditingTax) ...[
          // Static View
          _buildStaticTaxRow(
            'Intra State Tax Rate',
            getTaxDisplay(_selectedIntraTaxRateId),
          ),
          const SizedBox(height: 12),
          _buildStaticTaxRow(
            'Inter State Tax Rate',
            getTaxDisplay(_selectedInterTaxRateId),
          ),
        ] else ...[
          // Editable View
          SharedFieldLayout(
            label: 'Intra State Tax Rate',
            labelWidth: 160,
            child: FormDropdown<String>(
              value: _selectedIntraTaxRateId,
              hint: 'Select tax rate',
              items: itemsState.taxRates.map((t) => t.id).toList(),
              displayStringForValue: (id) => itemsState.taxRates
                  .firstWhere(
                    (t) => t.id == id,
                    orElse: () => itemsState.taxRates.first,
                  )
                  .taxName,
              onChanged: (val) => setState(() => _selectedIntraTaxRateId = val),
              onSearch: (q) async {
                final results = await ref
                    .read(itemsControllerProvider.notifier)
                    .searchTaxRates(q);
                return results.map((t) => t.id).toList();
              },
            ),
          ),
          const SizedBox(height: 12),
          SharedFieldLayout(
            label: 'Inter State Tax Rate',
            labelWidth: 160,
            child: FormDropdown<String>(
              value: _selectedInterTaxRateId,
              hint: 'Select tax rate',
              items: itemsState.taxRates.map((t) => t.id).toList(),
              displayStringForValue: (id) => itemsState.taxRates
                  .firstWhere(
                    (t) => t.id == id,
                    orElse: () => itemsState.taxRates.first,
                  )
                  .taxName,
              onChanged: (val) => setState(() => _selectedInterTaxRateId = val),
              onSearch: (q) async {
                final results = await ref
                    .read(itemsControllerProvider.notifier)
                    .searchTaxRates(q);
                return results.map((t) => t.id).toList();
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStaticTaxRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.textMuted,
                      width: 0.8,
                      style: BorderStyle
                          .none, // We'll use a custom painter if we want dashed
                    ),
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textBody,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dashed,
                    decorationColor: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsWeightSection() {
    Widget buildIntegratedInput({
      required Widget child,
      required String unitValue,
      required List<String> units,
      required ValueChanged<String?> onUnitChanged,
    }) {
      const borderColor = Color(0xFFCDD6E1);
      return Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(child: child),
            Container(width: 1, height: 38, color: borderColor),
            Container(
              width: 54, // Adjusted slightly for better spacing
              decoration: const BoxDecoration(
                color: Color(
                  0xFFF9FAFB,
                ), // Lighter background matching screenshot
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: unitValue,
                  isExpanded: true, // Fill the fixed width
                  menuWidth: 70, // Matches the target design perfectly
                  borderRadius: BorderRadius.circular(8),
                  dropdownColor: Colors.white,
                  selectedItemBuilder: (context) {
                    return units.map((u) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            u,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList();
                  },
                  items: units
                      .map(
                        (u) => DropdownMenuItem(
                          value: u,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, // Premium spacing
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: u == unitValue
                                  ? AppTheme.infoBlue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              u,
                              style: TextStyle(
                                fontSize: 13,
                                color: u == unitValue
                                    ? Colors.white
                                    : AppTheme.textBody,
                                fontWeight: u == unitValue
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onUnitChanged,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: AppTheme.textPrimary,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SharedFieldLayout(
                customLabel: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Dimensions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '(Length X Width X Height)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                child: buildIntegratedInput(
                  unitValue: _selectedDimensionUnit,
                  units: const ['cm', 'in', 'mm'],
                  onUnitChanged: (val) =>
                      setState(() => _selectedDimensionUnit = val ?? 'cm'),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _lengthCtrl,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const Text(
                        'x',
                        style: TextStyle(
                          color: Color(0xFFCDD6E1),
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _widthCtrl,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const Text(
                        'x',
                        style: TextStyle(
                          color: Color(0xFFCDD6E1),
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _heightCtrl,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: SharedFieldLayout(
                label: 'Weight',
                labelWidth: _labelWidth,
                child: buildIntegratedInput(
                  unitValue: _selectedWeightUnit,
                  units: const ['kg', 'g', 'lb', 'oz'],
                  onUnitChanged: (val) =>
                      setState(() => _selectedWeightUnit = val ?? 'kg'),
                  child: TextField(
                    controller: _weightCtrl,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManufacturerBrandSection(ItemsState itemsState) {
    return Row(
      children: [
        Expanded(
          child: SharedFieldLayout(
            label: 'Manufacturer',
            labelWidth: _labelWidth,
            child: FormDropdown<String>(
              value: _selectedManufacturerId,
              hint: 'Select or Add Manufacturer',
              items: itemsState.manufacturers
                  .map((m) => m['id'].toString())
                  .toList(),
              displayStringForValue: (id) =>
                  itemsState.manufacturers.firstWhere(
                    (m) => m['id'].toString() == id,
                    orElse: () => {'name': ''},
                  )['name'],
              onChanged: (val) => setState(() => _selectedManufacturerId = val),
              onSearch: (q) async {
                final results = await ref
                    .read(itemsControllerProvider.notifier)
                    .searchManufacturers(q);
                return results.map((m) => m['id'].toString()).toList();
              },
            ),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: SharedFieldLayout(
            label: 'Brand',
            labelWidth: _labelWidth,
            child: FormDropdown<String>(
              value: _selectedBrandId,
              hint: 'Select or Add Brand',
              items: itemsState.brands.map((b) => b['id'].toString()).toList(),
              displayStringForValue: (id) => itemsState.brands.firstWhere(
                (b) => b['id'].toString() == id,
                orElse: () => {'name': ''},
              )['name'],
              onChanged: (val) => setState(() => _selectedBrandId = val),
              onSearch: (q) async {
                final results = await ref
                    .read(itemsControllerProvider.notifier)
                    .searchBrands(q);
                return results.map((b) => b['id'].toString()).toList();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentifiersSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SharedFieldLayout(
                label: 'UPC',
                labelWidth: _labelWidth,
                tooltip: 'Universal Product Code',
                child: CustomTextField(controller: _upcCtrl),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: SharedFieldLayout(
                label: 'MPN',
                labelWidth: _labelWidth,
                tooltip: 'Manufacturer Part Number',
                child: CustomTextField(controller: _mpnCtrl),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SharedFieldLayout(
                label: 'EAN',
                labelWidth: _labelWidth,
                tooltip: 'European Article Number',
                child: CustomTextField(controller: _eanCtrl),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: SharedFieldLayout(
                label: 'ISBN',
                labelWidth: _labelWidth,
                tooltip: 'International Standard Book Number',
                child: CustomTextField(controller: _isbnCtrl),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInventoryTrackingSection(ItemsState itemsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _trackBinLocation,
                onChanged: (val) =>
                    setState(() => _trackBinLocation = val ?? false),
                activeColor: AppTheme.primaryBlueDark,
                side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Track Bin location for this item',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textBody,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 32),
          child: Text(
            'Enable this option if you want to track the bin locations for this item while creating transactions',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Advanced Inventory Tracking',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ZerpaiRadioGroup<String>(
          current: _trackingType,
          orientation: Axis.vertical,
          options: const ['None', 'Track Serial Number', 'Track Batches'],
          onChanged: (val) => setState(() => _trackingType = val),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SharedFieldLayout(
                label: 'Inventory Account',
                labelWidth: _labelWidth,
                required: true,
                child: FormDropdown<String>(
                  value: _selectedInventoryAccountId,
                  hint: 'Select an account',
                  items: itemsState.accounts
                      .map((a) => a['id'].toString())
                      .toList(),
                  displayStringForValue: (id) => itemsState.accounts.firstWhere(
                    (a) => a['id'].toString() == id,
                    orElse: () => {'name': ''},
                  )['name'],
                  onChanged: (val) =>
                      setState(() => _selectedInventoryAccountId = val),
                  onSearch: (q) async {
                    final results = await ref
                        .read(itemsControllerProvider.notifier)
                        .searchAccounts(q);
                    return results.map((a) => a['id'].toString()).toList();
                  },
                ),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: SharedFieldLayout(
                label: 'Inventory Valuation Method',
                labelWidth: _labelWidth,
                required: true,
                child: FormDropdown<String>(
                  value: _selectedValuationMethod,
                  hint: 'Select the valuation method',
                  items: const ['FIFO', 'LIFO', 'Average Cost'],
                  displayStringForValue: (val) => val,
                  onChanged: (val) =>
                      setState(() => _selectedValuationMethod = val),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SharedFieldLayout(
                label: 'Reorder Point',
                labelWidth: _labelWidth,
                child: CustomTextField(
                  controller: _reorderPointCtrl,
                  hintText: 'Enter reorder point',
                  keyboardType: TextInputType.number,
                ),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: SharedFieldLayout(
                label: 'Reorder Rule',
                labelWidth: _labelWidth,
                child: FormDropdown<String>(
                  value: _selectedReorderTermId,
                  hint: 'Select term',
                  items: itemsState.reorderTerms
                      .map((t) => t['id'].toString())
                      .toList(),
                  displayStringForValue: (id) =>
                      itemsState.reorderTerms.firstWhere(
                        (t) => t['id'].toString() == id,
                        orElse: () => {'name': ''},
                      )['name'],
                  onChanged: (val) =>
                      setState(() => _selectedReorderTermId = val),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _constrainedField(Widget child) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _fieldMaxWidth),
        child: child,
      ),
    );
  }

  Widget _buildTypeOption(
    CompositeItemType type,
    String title,
    String description,
  ) {
    return InkWell(
      onTap: () => setState(() => _itemType = type),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Radio<CompositeItemType>(
                value: type,
                activeColor: AppTheme.primaryBlueDark,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTable({
    required List<Item> items,
    required List<_CompositeItemRowData> rows,
    required String title,
    required Function(int) onRemove,
  }) {
    final itemIds = items.map(_itemKey).toList();
    final itemLabelMap = {
      for (final item in items) _itemKey(item): _itemLabel(item),
    };

    double totalSelling = 0;
    double totalCost = 0;

    for (var row in rows) {
      totalSelling +=
          _parseNumber(row.sellingPriceCtrl.text) *
          _parseNumber(row.quantityCtrl.text);
      totalCost +=
          _parseNumber(row.costPriceCtrl.text) *
          _parseNumber(row.quantityCtrl.text);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: AppTheme.bgLight,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSubtle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Quantity',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSubtle),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Selling Price',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSubtle),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Cost Price',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSubtle),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
          const Divider(height: 1),
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.bgDisabled,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.image_outlined,
                                size: 16,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FormDropdown<String>(
                                value: row.itemId,
                                hint: 'Click to select an item',
                                items: itemIds,
                                allowClear: true,
                                displayStringForValue: (val) =>
                                    itemLabelMap[val] ?? '',
                                searchStringForValue: (id) =>
                                    itemLabelMap[id] ?? id,
                                itemBuilder: (id, isSelected, isHovered) {
                                  final label = itemLabelMap[id] ?? id;
                                  return Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      color: isHovered
                                          ? AppTheme.primaryBlueDark
                                          : isSelected
                                          ? AppTheme.infoBg
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isHovered
                                                  ? Colors.white
                                                  : isSelected
                                                  ? AppTheme.primaryBlueDark
                                                  : AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check,
                                            size: 16,
                                            color: isHovered
                                                ? Colors.white
                                                : AppTheme.primaryBlueDark,
                                          ),
                                      ],
                                    ),
                                  );
                                },
                                onEdit: () {
                                  if (row.itemId != null) {
                                    try {
                                      final item = items.firstWhere(
                                        (i) => _itemKey(i) == row.itemId,
                                      );
                                      context.pushNamed(
                                        AppRoutes.itemsCreate,
                                        extra: item,
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error finding item details: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                showArrowOnSelection: false,
                                onChanged: (value) {
                                  setState(() {
                                    row.itemId = value;
                                    if (value != null) {
                                      try {
                                        final item = items.firstWhere(
                                          (i) => _itemKey(i) == value,
                                        );
                                        row.sellingPriceCtrl.text =
                                            (item.sellingPrice ?? 0.0)
                                                .toStringAsFixed(2);
                                        row.costPriceCtrl.text =
                                            (item.costPrice ?? 0.0)
                                                .toStringAsFixed(2);
                                      } catch (_) {
                                        // Item not found or error parsing
                                      }
                                    }
                                  });
                                },
                                onSearch: (q) async {
                                  final results = await ref
                                      .read(itemsControllerProvider.notifier)
                                      .searchItems(q);
                                  return results.map(_itemKey).toList();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                          controller: row.quantityCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                          controller: row.sellingPriceCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                          controller: row.costPriceCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: IconButton(
                          onPressed: () => onRemove(index),
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppTheme.errorRed,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < rows.length - 1) const Divider(height: 1),
              ],
            );
          }),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Total (₹) :',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textBody,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(flex: 2, child: SizedBox.shrink()),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    totalSelling.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    totalCost.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Images',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildImageUploadBox(),
          const SizedBox(height: 12),
          const Text(
            'You can add up to 15 images, each not exceeding 5 MB.',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ItemsController controller, ItemsState itemsState) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ZButton.secondary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          ZButton.primary(
            label: 'Save',
            loading: itemsState.isSaving,
            onPressed: itemsState.isSaving
                ? null
                : () => _saveCompositeItem(controller),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCompositeItem(ItemsController controller) async {
    String? primaryImageUrl;
    List<String>? imageUrls;

    if (_selectedImages.isNotEmpty) {
      try {
        final storage = StorageService();
        final uploadedUrls = await storage.uploadProductImages(_selectedImages);
        if (uploadedUrls.isNotEmpty) {
          primaryImageUrl = uploadedUrls[_primaryImageIndex];
          imageUrls = uploadedUrls;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warning: Failed to upload images: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }

    // final fallbackCode = _skuCtrl.text.trim().isNotEmpty
    //     ? _skuCtrl.text.trim()
    //     : _nameCtrl.text.trim();

    // Collect parts
    final parts = <Map<String, dynamic>>[];
    for (final row in _rows) {
      if (row.itemId != null) {
        parts.add({
          'component_product_id': row.itemId,
          'quantity': _parseNumber(row.quantityCtrl.text),
          'selling_price_override': _parseNumber(row.sellingPriceCtrl.text),
          'cost_price_override': _parseNumber(row.costPriceCtrl.text),
        });
      }
    }
    for (final row in _serviceRows) {
      if (row.itemId != null) {
        parts.add({
          'component_product_id': row.itemId,
          'quantity': _parseNumber(row.quantityCtrl.text),
          'selling_price_override': _parseNumber(row.sellingPriceCtrl.text),
          'cost_price_override': _parseNumber(row.costPriceCtrl.text),
        });
      }
    }

    final payload = {
      'type': _itemType.name, // assembly or kit
      'product_name': _nameCtrl.text.trim(),
      'sku': _skuCtrl.text.trim(),
      'unit_id': _selectedUnitId,
      'category_id': _selectedCategoryId,
      'is_returnable': _isReturnable,
      'push_to_ecommerce': _pushToEcommerce,
      'primary_image_url': primaryImageUrl,
      'image_urls': imageUrls,
      'hsn_code': _hsnCtrl.text.trim(),
      'tax_preference': _toBackendTaxPreference(_taxPreference),
      'intra_state_tax_id': _selectedIntraTaxRateId,
      'inter_state_tax_id': _selectedInterTaxRateId,
      'selling_price': _parseNumber(_sellingPriceCtrl.text),
      'sales_account_id': _selectedSalesAccountId,
      'sales_description': _salesDescriptionCtrl.text.trim(),
      'cost_price': _parseNumber(_costPriceCtrl.text),
      'purchase_account_id': _selectedPurchaseAccountId,
      'preferred_vendor_id': _selectedVendorId,
      'purchase_description': _purchaseDescriptionCtrl.text.trim(),
      'length': double.tryParse(_lengthCtrl.text),
      'width': double.tryParse(_widthCtrl.text),
      'height': double.tryParse(_heightCtrl.text),
      'dimension_unit': _selectedDimensionUnit,
      'weight': double.tryParse(_weightCtrl.text),
      'weight_unit': _selectedWeightUnit,
      'manufacturer_id': _selectedManufacturerId,
      'brand_id': _selectedBrandId,
      'upc': _upcCtrl.text.trim().isEmpty ? null : _upcCtrl.text.trim(),
      'mpn': _mpnCtrl.text.trim().isEmpty ? null : _mpnCtrl.text.trim(),
      'ean': _eanCtrl.text.trim().isEmpty ? null : _eanCtrl.text.trim(),
      'isbn': _isbnCtrl.text.trim().isEmpty ? null : _isbnCtrl.text.trim(),
      'is_track_inventory': true,
      'track_serial_number': _trackingType == 'Track Serial Number',
      'track_batches': _trackingType == 'Track Batches',
      'inventory_account_id': _selectedInventoryAccountId,
      'inventory_valuation_method': _selectedValuationMethod,
      'reorder_point': int.tryParse(_reorderPointCtrl.text) ?? 0,
      'reorder_term_id': _selectedReorderTermId,
      'parts': parts,
    };

    final messenger = ScaffoldMessenger.of(context);
    final success = await controller.createCompositeItem(payload);
    if (!mounted) return;

    if (success) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text(
                'Success!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: const Text(
            'Composite item saved successfully!',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const CompositeCreateScreen(),
                  ),
                );
              },
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    } else {
      final freshState = ref.read(itemsControllerProvider);
      final errors = freshState.validationErrors;
      if (errors.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Validation failed: ${errors.values.first}'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (freshState.error != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${freshState.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openHsnSacSearch() async {
    final result = await showDialog<HsnSacCode>(
      context: context,
      builder: (context) => const HsnSacSearchModal(type: 'HSN'),
    );

    if (result != null) {
      setState(() {
        _hsnCtrl.text = result.code;

        if (result.gstRate != null) {
          final itemsState = ref.read(itemsControllerProvider);
          final matchingRate = itemsState.taxRates
              .where((r) => (r.taxRate - result.gstRate!).abs() < 0.01)
              .firstOrNull;
          if (matchingRate != null) {
            _selectedIntraTaxRateId = matchingRate.id;
            _selectedInterTaxRateId = matchingRate.id;
          }
        }
      });
    }
  }
}

class _CompositeItemRowData {
  String? itemId;
  final TextEditingController quantityCtrl;
  final TextEditingController sellingPriceCtrl;
  final TextEditingController costPriceCtrl;

  _CompositeItemRowData({
    this.itemId,
    String quantity = '1',
    String sellingPrice = '0.00',
    String costPrice = '0.00',
  }) : quantityCtrl = TextEditingController(text: quantity),
       sellingPriceCtrl = TextEditingController(text: sellingPrice),
       costPriceCtrl = TextEditingController(text: costPrice);

  void dispose() {
    quantityCtrl.dispose();
    sellingPriceCtrl.dispose();
    costPriceCtrl.dispose();
  }
}
