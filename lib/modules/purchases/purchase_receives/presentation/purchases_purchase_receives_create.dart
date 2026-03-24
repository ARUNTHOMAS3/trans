import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/providers/purchases_purchase_orders_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

import '../models/purchases_purchase_receives_model.dart';
import '../providers/purchases_purchase_receives_provider.dart';

const _bgWhite = Color(0xFFFFFFFF);
const _borderCol = Color(0xFFE8E8E8);
const _fieldBorder = Color(0xFFE0E0E0);
const _focusBorder = Color(0xFF0088FF);
const _labelColor = Color(0xFF444444);
const _requiredLabel = Color(0xFFD32F2F);
const _hintColor = Color(0xFF999999);
const _textPrimary = Color(0xFF333333);
const _dangerRed = Color(0xFFD32F2F);
const _infoBannerBg = Color(0xFFEAF4FC);
const _infoBannerBorder = Color(0xFFBBDEFB);
const _infoBannerText = Color(0xFF1565C0);
const _tableHeaderBg = Color(0xFFF5F5F5);

class _ReceiveItemRowController {
  final TextEditingController qtyCtrl = TextEditingController();

  void dispose() => qtyCtrl.dispose();
}

class PurchasesPurchaseReceivesCreateScreen extends ConsumerStatefulWidget {
  const PurchasesPurchaseReceivesCreateScreen({super.key});

  @override
  ConsumerState<PurchasesPurchaseReceivesCreateScreen> createState() =>
      _PurchasesPurchaseReceivesCreateScreenState();
}

class _PurchasesPurchaseReceivesCreateScreenState
    extends ConsumerState<PurchasesPurchaseReceivesCreateScreen> {
  final _receiveNumberCtrl = TextEditingController();
  final _receivedDateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final GlobalKey _dateFieldKey = GlobalKey();
  final List<PlatformFile> _attachedFiles = <PlatformFile>[];

  String? _selectedVendorId;
  String? _selectedVendorName;
  PurchaseOrder? _selectedPO;
  String? _selectedPOId;
  String? _selectedPONumber;
  List<PurchaseOrder> _vendorPOs = <PurchaseOrder>[];
  bool _isLoadingPOs = false;
  bool _isSaving = false;

  final List<PurchaseReceiveItem> _items = <PurchaseReceiveItem>[];
  final List<_ReceiveItemRowController> _rowControllers =
      <_ReceiveItemRowController>[];

  @override
  void initState() {
    super.initState();
    _receiveNumberCtrl.text = _generateReceiveNumber();
    _receivedDateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vendorProvider.notifier).loadVendors();
    });
  }

  @override
  void dispose() {
    _receiveNumberCtrl.dispose();
    _receivedDateCtrl.dispose();
    _notesCtrl.dispose();
    for (final ctrl in _rowControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  String _generateReceiveNumber() {
    final now = DateTime.now();
    return 'PR-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}001';
  }

  bool get _hasValidSelection =>
      (_selectedVendorName?.isNotEmpty ?? false) &&
      (_selectedPONumber?.isNotEmpty ?? false);

  Vendor? _findSelectedVendor(List<Vendor> vendors) {
    for (final vendor in vendors) {
      if (vendor.id == _selectedVendorId) {
        return vendor;
      }
    }
    return null;
  }

  Future<void> _fetchPOsForVendor(String vendorId) async {
    setState(() {
      _isLoadingPOs = true;
      _vendorPOs = <PurchaseOrder>[];
      _selectedPO = null;
      _selectedPOId = null;
      _selectedPONumber = null;
      _items.clear();
      for (final ctrl in _rowControllers) {
        ctrl.dispose();
      }
      _rowControllers.clear();
    });

    try {
      final pos = await ref.read(
        purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)).future,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _vendorPOs = pos.where((po) => po.vendorId == vendorId).toList();
      });
    } catch (e, st) {
      AppLogger.error(
        'Failed to load purchase orders for purchase receive',
        error: e,
        stackTrace: st,
        module: 'purchases',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingPOs = false);
      }
    }
  }

  void _onPOSelected(PurchaseOrder po) {
    setState(() {
      _selectedPO = po;
      _selectedPOId = po.id;
      _selectedPONumber = po.orderNumber;
      _items.clear();
      for (final ctrl in _rowControllers) {
        ctrl.dispose();
      }
      _rowControllers.clear();

      for (final poItem in po.items) {
        _items.add(
          PurchaseReceiveItem(
            itemId: poItem.productId,
            itemName: poItem.productName ?? '',
            description: poItem.description,
            ordered: poItem.quantity,
            quantityToReceive: poItem.quantity,
          ),
        );
        final ctrl = _ReceiveItemRowController();
        ctrl.qtyCtrl.text = poItem.quantity.toString();
        _rowControllers.add(ctrl);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vendorState = ref.watch(vendorProvider);

    return ZerpaiLayout(
      pageTitle: 'New Purchase Receive',
      enableBodyScroll: true,
      useHorizontalPadding: false,
      useTopPadding: false,
      footer: _buildFooter(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _formRow(
                  'Vendor Name',
                  true,
                  SizedBox(
                    width: 500,
                    child: FormDropdown<Vendor>(
                      value: _findSelectedVendor(vendorState.vendors),
                      items: vendorState.vendors,
                      hint: vendorState.isLoading
                          ? 'Loading vendors...'
                          : 'Select or type to search',
                      showSearch: true,
                      displayStringForValue: (vendor) => vendor.displayName,
                      searchStringForValue: (vendor) => vendor.displayName,
                      onChanged: (vendor) {
                        if (vendor == null) return;
                        setState(() {
                          _selectedVendorId = vendor.id;
                          _selectedVendorName = vendor.displayName;
                        });
                        _fetchPOsForVendor(vendor.id);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _formRow(
                  'Purchase Order#',
                  true,
                  SizedBox(
                    width: 500,
                    child: FormDropdown<PurchaseOrder>(
                      value: _selectedPO,
                      items: _vendorPOs,
                      hint: _selectedVendorId == null
                          ? 'Select a vendor first'
                          : (_vendorPOs.isEmpty && !_isLoadingPOs
                                ? 'No purchase orders found'
                                : 'Select a Purchase Order'),
                      showSearch: true,
                      isLoading: _isLoadingPOs,
                      displayStringForValue: (po) => po.orderNumber,
                      searchStringForValue: (po) =>
                          '${po.orderNumber} ${po.status} ${po.vendorName ?? ''}',
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
          ),
          const SizedBox(height: 20),
          Opacity(
            opacity: _hasValidSelection ? 1 : 0.3,
            child: IgnorePointer(
              ignoring: !_hasValidSelection,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _formRow(
                          'Purchase Receive#',
                          true,
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: _receiveNumberCtrl,
                              readOnly: true,
                              decoration: _fieldDecoration(
                                suffix: const Icon(
                                  LucideIcons.settings,
                                  size: 16,
                                  color: _hintColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _formRow(
                          'Received Date',
                          true,
                          SizedBox(
                            width: 180,
                            child: TextField(
                              key: _dateFieldKey,
                              controller: _receivedDateCtrl,
                              readOnly: true,
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
                              decoration: _fieldDecoration(
                                hintText: 'dd-MM-yyyy',
                                suffix: const Icon(
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
                  ),
                  const SizedBox(height: 20),
                  _buildInfoBanner(),
                  const SizedBox(height: 24),
                  _buildItemsTable(),
                  const SizedBox(height: 32),
                  Padding(
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
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: 800,
                          child: TextField(
                            controller: _notesCtrl,
                            maxLines: 4,
                            decoration: _fieldDecoration(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
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
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => context.go(AppRoutes.purchaseReceives),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 20, color: _hintColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _infoBannerBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _infoBannerBorder),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.info, size: 16, color: _infoBannerText),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'You can also select or scan the items to be included from the purchase order.',
                style: TextStyle(fontSize: 13, color: _infoBannerText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: _tableHeaderBg,
              border: Border(bottom: BorderSide(color: _borderCol)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: const [
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'ITEMS & DESCRIPTION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'ORDERED',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'RECEIVED',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'IN TRANSIT',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'QUANTITY TO RECEIVE',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 40),
              ],
            ),
          ),
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _borderCol)),
              ),
              child: const Text(
                'Select a purchase order to populate items',
                style: TextStyle(fontSize: 13, color: _hintColor),
              ),
            )
          else
            ..._items.asMap().entries.map((entry) {
              return _buildItemRow(entry.key, entry.value);
            }),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index, PurchaseReceiveItem item) {
    final ctrl = _rowControllers[index];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderCol, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
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
                              : 'Select an item',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: item.itemName.isNotEmpty
                                ? _textPrimary
                                : _hintColor,
                          ),
                        ),
                        if (item.description?.isNotEmpty ?? false)
                          Text(
                            item.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _hintColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _metricCell(item.ordered),
          _metricCell(item.received),
          _metricCell(item.inTransit),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 100,
                child: TextField(
                  controller: ctrl.qtyCtrl,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  onChanged: (value) {
                    final qty = double.tryParse(value) ?? 0;
                    setState(() {
                      _items[index] = _items[index].copyWith(
                        quantityToReceive: qty,
                      );
                    });
                  },
                  decoration: _fieldDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: InkWell(
              onTap: () {
                setState(() {
                  _items.removeAt(index);
                  _rowControllers[index].dispose();
                  _rowControllers.removeAt(index);
                });
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(LucideIcons.x, size: 16, color: _dangerRed),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCell(double value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2),
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13, color: _textPrimary),
        ),
      ),
    );
  }

  Widget _buildAttachFilesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: _borderCol),
          const SizedBox(height: 20),
          const Text(
            'Attach File(s) to Purchase Receive',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _labelColor,
            ),
          ),
          const SizedBox(height: 10),
          FileUploadButton(
            files: _attachedFiles,
            onFilesChanged: (files) {
              setState(() {
                _attachedFiles
                  ..clear()
                  ..addAll(files);
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            'You can upload a maximum of 5 files, 10MB each',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: const BoxDecoration(
        color: _bgWhite,
        border: Border(top: BorderSide(color: _borderCol)),
      ),
      child: Row(
        children: [
          ZButton.secondary(
            label: 'Save as Draft',
            onPressed: _isSaving || !_hasValidSelection
                ? null
                : () => _handleSave('draft'),
          ),
          const SizedBox(width: 10),
          ZButton.primary(
            label: 'Save as Received',
            onPressed: _isSaving || !_hasValidSelection
                ? null
                : () => _handleSave('received'),
            loading: _isSaving,
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => context.go(AppRoutes.purchaseReceives),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 13, color: _textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formRow(String label, bool required, Widget child) {
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
                  color: required ? _requiredLabel : _labelColor,
                ),
                children: [
                  TextSpan(text: label),
                  if (required)
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

  InputDecoration _fieldDecoration({
    String? hintText,
    Widget? suffix,
    EdgeInsets? contentPadding,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: _bgWhite,
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: _hintColor),
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _fieldBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _focusBorder, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      suffixIcon: suffix,
    );
  }

  Future<void> _handleSave(String status) async {
    if (!(_selectedVendorName?.isNotEmpty ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vendor')),
      );
      return;
    }
    if (!(_selectedPONumber?.isNotEmpty ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a purchase order')),
      );
      return;
    }
    if (_items.isEmpty || _items.every((item) => item.quantityToReceive <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter quantity to receive for at least one item',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final receive = PurchaseReceive(
      purchaseReceiveNumber: _receiveNumberCtrl.text,
      receivedDate: DateFormat('dd-MM-yyyy').parse(_receivedDateCtrl.text),
      vendorId: _selectedVendorId,
      vendorName: _selectedVendorName,
      purchaseOrderId: _selectedPOId,
      purchaseOrderNumber: _selectedPONumber,
      status: status,
      notes: _notesCtrl.text,
      items: List<PurchaseReceiveItem>.from(_items),
      quantity: _items.fold<double>(
        0,
        (sum, item) => sum + item.quantityToReceive,
      ),
    );

    final result = await ref
        .read(purchaseReceivesProvider.notifier)
        .createReceive(receive);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result == PurchaseReceiveSaveMode.remote) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'received'
                ? 'Purchase Receive saved successfully'
                : 'Purchase Receive saved as draft',
          ),
          backgroundColor: const Color(0xFF19A05E),
        ),
      );
      context.go(AppRoutes.purchaseReceives);
      return;
    }

    if (result == PurchaseReceiveSaveMode.localFallback) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Purchase Receive saved locally only because the API is unavailable.',
          ),
          backgroundColor: Color(0xFF2563EB),
        ),
      );
      context.go(AppRoutes.purchaseReceives);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to save Purchase Receive. Please try again.'),
        backgroundColor: _dangerRed,
      ),
    );
  }
}
