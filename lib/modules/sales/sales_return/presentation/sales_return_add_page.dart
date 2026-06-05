import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/core/workflow/transaction_status_normalizer.dart';
import 'package:zerpai_erp/core/workflow/transaction_status_transition_guard.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/bulk_items_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/advanced_customer_search_dialog.dart';
import 'package:zerpai_erp/modules/sales/sales_return/models/sales_return_model.dart';
import 'package:zerpai_erp/modules/sales/sales_return/providers/sales_return_provider.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:intl/intl.dart';

/// Sales Return Add Page
class SalesReturnsAddPage extends ConsumerStatefulWidget {
  const SalesReturnsAddPage({super.key});

  @override
  ConsumerState<SalesReturnsAddPage> createState() => _SalesReturnsAddPageState();
}

class _SalesReturnsAddPageState extends ConsumerState<SalesReturnsAddPage> {
  static const double _tableFieldHeight = 44;
  // --- Form State ---
  SalesCustomer? _selectedCustomerObj;
  String? _selectedCustomer;
  String? _selectedReason;
  late final TextEditingController _referenceNumberController;

  late final TextEditingController _rmaNumberController;
  late final TextEditingController _rmaDateController;
  final _rmaDateKey = GlobalKey();
  DateTime _rmaDate = DateTime.now();
  late final TextEditingController _rmaReasonController;
  bool _creditOnlyGoods = false;

  Warehouse? _selectedWarehouse;

  bool _rmaAutoGenerate = true;
  late final TextEditingController _rmaPrefixController;
  late final TextEditingController _rmaNextNumberController;

  bool _showItemDetailsPanel = false;
  _SalesReturnItem? _detailsItem;


  static const double _labelWidth = 150.0;
  static const double _rowMaxWidth = 1100.0;
  static const double _gapWidth = 16.0;
  static const double _fieldHeight = 32.0;
  static const double _customerFieldWidth = 500.0;

  final List<_SalesReturnItem> _items = [];

  @override
  void initState() {
    super.initState();
    _referenceNumberController = TextEditingController();
    _rmaNumberController = TextEditingController(text: 'RMA-00001');
    _rmaDateController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(_rmaDate),
    );
    _rmaReasonController = TextEditingController();
    _rmaPrefixController = TextEditingController(text: 'RMA-');
    _rmaNextNumberController = TextEditingController(text: '00001');
    _items.clear();
    _addItem();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchNextRmaNumber());
  }

  Future<void> _fetchNextRmaNumber() async {
    try {
      final repo = ref.read(salesReturnRepositoryProvider);
      final next = await repo.getNextRmaNumber(prefix: _rmaPrefixController.text);
      if (mounted) {
        setState(() {
          _rmaNumberController.text = next;
          // Extract the numeric part for the next-number field
          final numPart = next.replaceAll(_rmaPrefixController.text, '');
          _rmaNextNumberController.text = numPart;
        });
      }
    } catch (_) {
      // fallback stays as RMA-00001
    }
  }

  void _addItem() {
    setState(() {
      _items.add(_SalesReturnItem(
        name: '',
        shipped: '0',
        returned: '0',
        returnQty: '1',
        stock: '0 pcs',
        rate: '0.00',
      ));
    });
  }

  void _removeItem(int index) {
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
              _items.add(_SalesReturnItem(
                name: entry.key.productName,
                shipped: '0',
                returned: '0',
                returnQty: entry.value.toString(),
                stock: '0',
                hsnCode: entry.key.hsnCode ?? '',
              ));
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
    _rmaNumberController.dispose();
    _rmaDateController.dispose();
    _rmaReasonController.dispose();
    _rmaPrefixController.dispose();
    _rmaNextNumberController.dispose();
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

  void _openItemDetails(_SalesReturnItem item) {
    setState(() {
      _showItemDetailsPanel = true;
      _detailsItem = item;
    });
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
                if (autoGenerate) _fetchNextRmaNumber();
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveSalesReturn(String status) async {
    final user = ref.read(authUserProvider);
    final entity = ref.read(entityProvider);
    final normalizedTargetStatus = normalizeTransactionStatus(status);
    final decision = TransactionStatusTransitionGuard.canTransition(
      user: user,
      transactionType: 'sales.return',
      fromStatus: 'draft',
      toStatus: normalizedTargetStatus,
      branchId: entity.branchId,
      warehouseId: _selectedWarehouse?.id,
      requiredPermission: 'sales.return.edit',
      reason: _rmaReasonController.text.trim(),
    );
    if (!decision.allowed) {
      if (mounted) {
        ZerpaiToast.error(context, decision.reason);
      }
      return;
    }

    if (_selectedCustomerObj == null || _selectedCustomerObj!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    final validItems = _items
        .where((item) => item.productId != null && item.productId!.isNotEmpty)
        .toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    final payload = CreateSalesReturnPayload(
      customerId: _selectedCustomerObj!.id,
      rmaNumber: _rmaNumberController.text.trim(),
      returnDate: DateFormat('yyyy-MM-dd').format(_rmaDate),
      warehouseId: _selectedWarehouse?.id,
      reason: _rmaReasonController.text.trim().isEmpty
          ? null
          : _rmaReasonController.text.trim(),
      referenceNumber: _referenceNumberController.text.trim().isEmpty
          ? null
          : _referenceNumberController.text.trim(),
      containsCreditOnlyGoods: _creditOnlyGoods,
      status: normalizedTargetStatus,
      items: validItems.map((item) {
        final returnQty =
            double.tryParse(item.returnQtyController.text) ?? 0.0;
        final creditOnlyQty =
            double.tryParse(item.creditOnlyQtyController.text) ?? 0.0;
        return SalesReturnItem(
          productId: item.productId!,
          returnQty: returnQty,
          creditOnlyQty: creditOnlyQty,
        );
      }).toList(),
    );

    final result =
        await ref.read(salesReturnProvider.notifier).createSalesReturn(payload);

    if (!mounted) return;

    if (result != null) {
      if (user != null) {
        final auditEvent = TransactionStatusTransitionGuard.buildAuditEvent(
          transactionType: 'sales.return',
          transactionId: result.id,
          beforeStatus: 'draft',
          afterStatus: normalizedTargetStatus,
          actor: user,
          reason: _rmaReasonController.text.trim().isEmpty
              ? 'Sales return status transition'
              : _rmaReasonController.text.trim(),
          permissionUsed: decision.requiredPermission,
          branchId: entity.branchId,
          warehouseId: _selectedWarehouse?.id,
          metadata: <String, dynamic>{
            'entity_context': entity.entityId,
            'branch_context': entity.branchId,
            'warehouse_context': _selectedWarehouse?.id,
          },
        );
        AppLogger.info(
          'Sales return status transition',
          module: 'sales_return',
          userId: user.id,
          orgId: user.orgId,
          data: auditEvent.toJson(),
        );
      }
      ref.invalidate(salesReturnsListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            normalizedTargetStatus == 'draft'
                ? 'Sales return saved as draft'
                : 'Sales return approved successfully',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save sales return. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);
    final customers = customersAsync.value ?? [];
    final products = ref.watch(itemsControllerProvider).items;
    final warehouses = ref.watch(warehousesProvider).valueOrNull ?? [];
    final srCustomerNames = customers.map((c) => c.displayName).toList();
    final srCustomerDetails = <String, _SrCustomerDropdownDetails>{
      for (final c in customers)
        c.displayName: _SrCustomerDropdownDetails(
          code: c.customerNumber ?? '',
          addressLine: [
            c.billingAddressCity,
            c.billingAddressZip,
          ].where((p) => p != null && p.isNotEmpty).join(', ').isNotEmpty
              ? [c.billingAddressCity, c.billingAddressZip]
                    .where((p) => p != null && p.isNotEmpty)
                    .join(', ')
              : c.companyName ?? c.displayName,
        ),
    };
    return Stack(
      children: [
        Container(
      color: Colors.white,
      child: ZerpaiLayout(
        pageTitle: 'New Sales Return',
        enableBodyScroll: true,
        onSave: () => _saveSalesReturn('draft'),
        useHorizontalPadding: true,
        footer: Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: MaxWidthContainer(
            maxWidth: _rowMaxWidth,
            child: Row(
              children: [
                ZButton.primary(
                  label: 'Save as Draft',
                  onPressed: () => _saveSalesReturn('draft'),
                ),
                const SizedBox(width: 12),
                ZButton.secondary(
                  label: 'Save and Approve',
                  onPressed: () => _saveSalesReturn('approved'),
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
                _CompactFormRow(
                  label: 'Customer Name',
                  required: true,
                  fieldWidth: _selectedCustomer == null
                      ? _customerFieldWidth
                      : _rowMaxWidth - _labelWidth - _gapWidth,
                  child: Row(
                    children: [
                      SizedBox(
                        width: _customerFieldWidth,
                        child: Row(
                          children: [
                            Expanded(
                              child: FormDropdown<String>(
                                value: _selectedCustomer,
                                items: srCustomerNames,
                                hint: 'Select a customer',
                                placeholder: 'Search',
                                height: _fieldHeight,
                                menuMaxHeight: 300,
                                itemHeight: 72,
                                displayStringForValue: (customer) => customer,
                                searchStringForValue: (customer) {
                                  final details = srCustomerDetails[customer];
                                  return [
                                    customer,
                                    if (details != null) details.code,
                                    if (details != null) details.addressLine,
                                  ].join(' ');
                                },
                                itemBuilder: (customer, isSelected, isHovered) {
                                  final details = srCustomerDetails[customer];
                                  return _SrCustomerDropdownItem(
                                    customerName: customer,
                                    customerCode: details?.code ?? 'CUS-00000',
                                    addressLine: details?.addressLine ?? customer,
                                    highlighted: isSelected || isHovered,
                                  );
                                },
                                allowClear: true,
                                showRightBorder: false,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  bottomLeft: Radius.circular(4),
                                ),
                                onChanged: (val) => setState(() {
                                  _selectedCustomer = val;
                                  _selectedCustomerObj = val == null
                                      ? null
                                      : customers.firstWhere(
                                          (c) => c.displayName == val,
                                          orElse: () => SalesCustomer(id: '', displayName: val),
                                        );
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
                                icon: const Icon(LucideIcons.search, size: 16, color: Colors.white),
                                onPressed: () async {
                                  List<SalesCustomer> customers;
                                  try {
                                    customers = await ref.read(salesCustomersProvider.future);
                                  } catch (_) {
                                    customers = ref.read(salesCustomersProvider).valueOrNull ?? [];
                                  }
                                  if (!mounted) return;
                                  await showGeneralDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    barrierLabel: 'Advanced Customer Search',
                                    barrierColor: Colors.black.withValues(alpha: 0.4),
                                    transitionDuration: const Duration(milliseconds: 200),
                                    pageBuilder: (ctx, _, __) => AdvancedCustomerSearchDialog(
                                      customers: customers,
                                      onSelect: (SalesCustomer c) {
                                        setState(() {
                                          _selectedCustomer = c.displayName;
                                          _selectedCustomerObj = c;
                                        });
                                        Navigator.of(ctx).pop();
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedCustomer != null) ...[
                        const SizedBox(width: 12),
                        const _SrCurrencyBadge(),
                      ],
                    ],
                  ),
                ),
                if (_selectedCustomerObj != null) ...[
                  _SrCustomerAddressPanel(
                    customer: _selectedCustomerObj!,
                    onCustomerUpdated: (updated) =>
                        setState(() => _selectedCustomerObj = updated),
                    width: _customerFieldWidth,
                  ),
                ],
                _CompactFormRow(
                  label: 'Reason',
                  fieldWidth: 330,
                  child: FormDropdown<String>(
                    value: _selectedReason,
                    items: const ['Damaged', 'Wrong item', 'Other'],
                    hint: 'Select a reason',
                    height: _fieldHeight,
                    onChanged: (val) => setState(() => _selectedReason = val),
                  ),
                ),
                _CompactFormRow(
                  label: 'Reference#',
                  fieldWidth: 330,
                  child: CustomTextField(
                    controller: _referenceNumberController,
                    hintText: 'Enter reference number',
                    height: _fieldHeight,
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(color: AppTheme.borderLight),
                ),

                // --- RMA Section ---
                _CompactFormRow(
                  label: 'RMA#',
                  required: true,
                  fieldWidth: 330,
                  child: CustomTextField(
                    controller: _rmaNumberController,
                    suffixWidget: GestureDetector(
                    onTap: _showRmaPreferencesDialog,
                    child: const Icon(LucideIcons.settings, size: 14, color: AppTheme.primaryBlue),
                  ),
                    height: _fieldHeight,
                  ),
                ),
                _CompactFormRow(
                  label: 'Date',
                  required: true,
                  fieldWidth: 330,
                  child: CustomTextField(
                    key: _rmaDateKey,
                    controller: _rmaDateController,
                    readOnly: true,
                    onTap: () async {
                      final picked = await ZerpaiDatePicker.show(context, initialDate: _rmaDate, targetKey: _rmaDateKey);
                      if (picked != null) _updateRmaDate(picked);
                    },
                    suffixWidget: const Icon(LucideIcons.calendar, size: 14, color: AppTheme.textSecondary),
                    height: _fieldHeight,
                  ),
                ),
                _CompactFormRow(
                  label: '',
                  child: Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _creditOnlyGoods,
                          onChanged: (val) => setState(() => _creditOnlyGoods = val ?? false),
                          activeColor: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'This sales return contains credit-only goods',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      const _HelpPopover(
                        child: Icon(LucideIcons.helpCircle, size: 14, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // --- Item Table Toolbar ---
                _ItemTableToolbar(
                  selectedWarehouse: _selectedWarehouse,
                  warehouseOptions: warehouses,
                  onWarehouseChanged: (w) =>
                      setState(() => _selectedWarehouse = w),
                ),
                const SizedBox(height: 16),

                // --- Items Grid ---
                _SalesReturnItemsGrid(
                  items: _items,
                  products: products,
                  creditOnly: _creditOnlyGoods,
                  warehouse: _selectedWarehouse?.name,
                  onRemoveItem: _removeItem,
                  onAddItem: _addItem,
                  onAddBulkItems: _showBulkItemsDialog,
                  onItemSelected: (index) {
                    if (index == _items.length - 1) {
                      _addItem();
                    }
                  },
                  onViewItemDetails: _openItemDetails,
                ),

                const SizedBox(height: 32),
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
            child: _ItemDetailsSidePanel(
              item: _detailsItem!,
              onClose: () => setState(() {
                _showItemDetailsPanel = false;
                _detailsItem = null;
              }),
            ),
          ),
      ],
    );
  }

}

class _SalesReturnItem {
  String name;
  String? productId;
  String description;
  String shipped;
  String returned;
  TextEditingController returnQtyController;
  TextEditingController creditOnlyQtyController;
  TextEditingController descriptionController;
  TextEditingController rateController;
  TextEditingController discountController;
  String stock;
  String hsnCode;
  String? locationName;
  Map<String, String?> selectedTagValues = {};

  _SalesReturnItem({
    required this.name,
    this.description = '',
    required this.shipped,
    required this.returned,
    required String returnQty,
    String creditOnlyQty = '0',
    required this.stock,
    this.hsnCode = '',
    String rate = '0.00',
    String discountValue = '0',
  })  : returnQtyController = TextEditingController(text: returnQty),
        creditOnlyQtyController = TextEditingController(text: creditOnlyQty),
        descriptionController = TextEditingController(text: description),
        rateController = TextEditingController(text: rate),
        discountController = TextEditingController(text: discountValue);

  void dispose() {
    returnQtyController.dispose();
    creditOnlyQtyController.dispose();
    descriptionController.dispose();
    rateController.dispose();
    discountController.dispose();
  }
}

/// Custom Compact Form Row with Overflow Fixes
class _CompactFormRow extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  final double? fieldWidth;

  const _CompactFormRow({
    required this.label,
    this.required = false,
    required this.child,
    this.fieldWidth,
  });

  @override
  Widget build(BuildContext context) {
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        if (required)
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: fieldWidth ?? 434,
            child: child,
          ),
        ],
      ),
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
                        border: Border.all(color: AppTheme.primaryBlue, width: 2),
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
                          _buildBulletRow('Enable this option if your sales return contains items that are damaged or expired.'),
                          const SizedBox(height: 12),
                          _buildBulletRow('The quantity specified under this category will not be brought back into stock.'),
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
            style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1F2937)),
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
      child: GestureDetector(
        onTap: _togglePopover,
        child: widget.child,
      ),
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
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(width: 24),
                                const Text('View: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                PopupMenuButton<String>(
                                  initialValue: _selectedView,
                                  onSelected: (val) {
                                    setOverlayState(() => _selectedView = val);
                                  },
                                  itemBuilder: (context) => [
                                    'Available for Sale',
                                    'Stock on Hand',
                                    'Commited Stock'
                                  ].map((v) => PopupMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
                                  child: Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.borderColor),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(_selectedView, style: const TextStyle(fontSize: 13)),
                                        const Icon(Icons.keyboard_arrow_down, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Toggle
                                Container(
                                  height: 32,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.primaryBlue),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => setOverlayState(() => _isAccountingStock = true),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: _isAccountingStock ? AppTheme.primaryBlue : Colors.white,
                                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Accounting Stock',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _isAccountingStock ? Colors.white : AppTheme.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setOverlayState(() => _isAccountingStock = false),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: !_isAccountingStock ? AppTheme.primaryBlue : Colors.white,
                                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Physical Stock',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: !_isAccountingStock ? Colors.white : AppTheme.primaryBlue,
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
                                  icon: const Icon(Icons.close, size: 20, color: AppTheme.errorRed),
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
                                          Text('Location Name ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                          Icon(Icons.search, size: 14, color: AppTheme.textSecondary),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const VerticalDivider(width: 1, color: AppTheme.borderColor),
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 32,
                                          alignment: Alignment.center,
                                          child: Text(_isAccountingStock ? 'Accounting Stock' : 'Physical Stock', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                        ),
                                        const Divider(height: 1, color: AppTheme.borderColor),
                                        IntrinsicHeight(
                                          child: Row(
                                            children: [
                                              _buildSubHeader('Stock on Hand'),
                                              const VerticalDivider(width: 1, color: AppTheme.borderColor),
                                              _buildSubHeader('Committed Stock'),
                                              const VerticalDivider(width: 1, color: AppTheme.borderColor),
                                              _buildSubHeader('Available for Sale'),
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
                          _buildRow('ZABNIX PRIVATE LIMITED', '13.00', '51.00', '-38.00'),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildRow('DEMO WAREHOUSE 1 (Warehouse)', '2.00', '5.00', '-3.00'),
                          const SizedBox(height: 24),
                          // Footer Notes
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Stock on Hand : This is calculated based on Bills and Invoices.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                SizedBox(height: 4),
                                Text('Committed Stock : Stock that is committed to sales order(s) but not yet invoiced', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                SizedBox(height: 4),
                                Text('Available for Sale : Stock on Hand - Committed Stock', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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

  Widget _buildRow(String name, String soh, String committed, String available) {
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
              child: Text(name, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
            ),
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Expanded(child: Text(soh, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14))),
                  const SizedBox(width: 24),
                  Expanded(child: Text(committed, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14))),
                  const SizedBox(width: 24),
                  Expanded(child: Text(available, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
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
      child: GestureDetector(
        onTap: _togglePopover,
        child: widget.child,
      ),
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

class _SrGridHeader extends StatelessWidget {
  final String label;
  final bool center;

  const _SrGridHeader({
    required this.label,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

class _SalesReturnItemsGrid extends StatefulWidget {
  final bool creditOnly;
  final String? warehouse;
  final List<_SalesReturnItem> items;
  final List<Item> products;
  final VoidCallback onAddItem;
  final VoidCallback onAddBulkItems;
  final Function(int) onRemoveItem;
  final Function(int) onItemSelected;
  final Function(_SalesReturnItem) onViewItemDetails;

  const _SalesReturnItemsGrid({
    required this.creditOnly,
    required this.warehouse,
    required this.items,
    required this.products,
    required this.onAddItem,
    required this.onAddBulkItems,
    required this.onRemoveItem,
    required this.onItemSelected,
    required this.onViewItemDetails,
  });

  @override
  State<_SalesReturnItemsGrid> createState() => _SalesReturnItemsGridState();
}

class _SalesReturnItemsGridState extends State<_SalesReturnItemsGrid> {
  OverlayEntry? _addRowOverlay;

  @override
  void dispose() {
    _addRowOverlay?.remove();
    super.dispose();
  }

  Widget _buildAddRowButton() {
    return InkWell(
      onTap: widget.onAddItem,
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
            Icon(LucideIcons.plusCircle, size: 18, color: AppTheme.primaryBlueDark),
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
            Icon(LucideIcons.plusCircle, size: 18, color: AppTheme.primaryBlueDark),
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

  @override
  Widget build(BuildContext context) {
    const bs = BorderSide(color: AppTheme.borderLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── HEADER ──────────────────────────────────────────────
        _HoverableRowSlot(
          showX: false,
          onDelete: null,
          content: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      color: AppTheme.tableHeaderBg,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: const _SrGridHeader(label: 'ITEMS & DESCRIPTION'),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppTheme.borderLight),
                  Container(
                    width: 160,
                    color: AppTheme.tableHeaderBg,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    alignment: Alignment.center,
                    child: const _SrGridHeader(label: 'INVOICED', center: true),
                  ),
                  const VerticalDivider(width: 1, color: AppTheme.borderLight),
                  Container(
                    width: 140,
                    color: AppTheme.tableHeaderBg,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    alignment: Alignment.center,
                    child: const _SrGridHeader(label: 'RETURNED', center: true),
                  ),
                  const VerticalDivider(width: 1, color: AppTheme.borderLight),
                  if (widget.creditOnly)
                    Container(
                      width: 260,
                      color: AppTheme.tableHeaderBg,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: const _SrGridHeader(label: 'RETURN DETAILS', center: true),
                          ),
                          const Divider(height: 1, color: AppTheme.borderLight),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: const _SrGridHeader(label: 'RECEIVABLE\nQUANTITY', center: true),
                                  ),
                                ),
                                const VerticalDivider(width: 1, color: AppTheme.borderLight),
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const _SrGridHeader(label: 'CREDIT-ONLY ', center: true),
                                        ZTooltip(
                                          message: 'The quantity specified under this category will not be received. You can only provide credits.',
                                          child: const Icon(LucideIcons.helpCircle, size: 14, color: AppTheme.textMuted),
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
                    )
                  else
                    Container(
                      width: 200,
                      color: AppTheme.tableHeaderBg,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      alignment: Alignment.centerRight,
                      child: const _SrGridHeader(label: 'RETURN QUANTITY'),
                    ),
                ],
              ),
            ),
          ),
        ),

        // ── DATA ROWS ────────────────────────────────────────────
        ...List.generate(widget.items.length, (index) {
          return _HoverableRowSlot(
            showX: index != 0,
            onDelete: () => widget.onRemoveItem(index),
            content: Container(
              decoration: BoxDecoration(
                border: Border(left: bs, right: bs, bottom: bs),
              ),
              child: _ItemRowWidget(
                item: widget.items[index],
                warehouse: widget.warehouse,
                creditOnly: widget.creditOnly,
                products: widget.products,
                onRemove: () => widget.onRemoveItem(index),
                canRemove: index != 0,
                onItemSelected: () => widget.onItemSelected(index),
              ),
            ),
          );
        }),

        // ── TABLE BOTTOM CAP ─────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            border: Border(left: bs, right: bs, bottom: bs),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          height: 4,
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

class _HoverableRowSlot extends StatefulWidget {
  final Widget content;
  final bool showX;
  final VoidCallback? onDelete;

  const _HoverableRowSlot({
    required this.content,
    required this.showX,
    this.onDelete,
  });

  @override
  State<_HoverableRowSlot> createState() => _HoverableRowSlotState();
}

class _HoverableRowSlotState extends State<_HoverableRowSlot> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: widget.content),
            SizedBox(
              width: 36,
              child: (widget.showX && _isHovered)
                  ? Center(
                      child: GestureDetector(
                        onTap: widget.onDelete,
                        behavior: HitTestBehavior.opaque,
                        child: const Icon(LucideIcons.x, size: 16, color: AppTheme.errorRed),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRowWidget extends StatefulWidget {
  final _SalesReturnItem item;
  final String? warehouse;
  final bool creditOnly;
  final List<Item> products;
  final VoidCallback onRemove;
  final bool canRemove;
  final VoidCallback? onItemSelected;

  const _ItemRowWidget({
    required this.item,
    required this.warehouse,
    required this.creditOnly,
    required this.products,
    required this.onRemove,
    this.canRemove = true,
    this.onItemSelected,
  });

  @override
  State<_ItemRowWidget> createState() => _ItemRowWidgetState();
}

class _ItemRowWidgetState extends State<_ItemRowWidget> {

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ITEMS & DESCRIPTION
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: item.name.isEmpty
                  ? FormDropdown<String>(
                      value: null,
                      items: widget.products.take(10).map((p) => p.productName).toList(),
                      hint: 'Type or click to select an item.',
                      height: _SalesReturnsAddPageState._tableFieldHeight,
                      hideBorderDefault: true,
                      
                      onChanged: (val) {
                        if (val != null) {
                          final matched = widget.products.firstWhere(
                            (p) => p.productName == val,
                            orElse: () => widget.products.first,
                          );
                          setState(() {
                            item.name = val;
                            item.productId = matched.id;
                            item.rateController.text = matched.sellingPrice?.toStringAsFixed(2) ?? '0.00';
                            item.hsnCode = matched.hsnCode ?? '';
                          });
                          widget.onItemSelected?.call();
                        }
                      },
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (item.descriptionController.text.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.descriptionController.text,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          const VerticalDivider(width: 1, color: AppTheme.borderLight),
          // INVOICED — read-only, centered
          SizedBox(
            width: 160,
            child: Center(
              child: Text(
                item.shipped,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: AppTheme.borderLight),
          // RETURNED — read-only, centered
          SizedBox(
            width: 140,
            child: Center(
              child: Text(
                item.returned,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: AppTheme.borderLight),
          // RETURN QUANTITY / RETURN DETAILS
          if (widget.creditOnly)
            SizedBox(
                width: 260,
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomTextField(
                            controller: item.returnQtyController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.right,
                            hideBorderDefault: true,
                            height: 32,
                            contentCase: ContentCase.none,
                          ),
                          const SizedBox(height: 4),
                          Builder(
                            builder: (btnCtx) => GestureDetector(
                              onTap: () {
                                const dialogWidth = 420.0;
                                final box = btnCtx.findRenderObject() as RenderBox;
                                final triggerPos = box.localToGlobal(Offset.zero);
                                final triggerSize = box.size;
                                final screen = MediaQuery.of(btnCtx).size;

                                double left = triggerPos.dx + triggerSize.width - dialogWidth;
                                if (left < 8) left = 8;
                                if (left + dialogWidth > screen.width - 8) {
                                  left = screen.width - dialogWidth - 8;
                                }
                                double top = triggerPos.dy + triggerSize.height + 6;
                                if (top + 220 > screen.height - 8) {
                                  top = triggerPos.dy - 220 - 6;
                                }

                                showGeneralDialog<void>(
                                  context: btnCtx,
                                  barrierDismissible: true,
                                  barrierLabel: '',
                                  barrierColor: Colors.transparent,
                                  transitionDuration: Duration.zero,
                                  pageBuilder: (ctx, _, __) => Stack(
                                    children: [
                                      Positioned(
                                        left: left,
                                        top: top,
                                        width: dialogWidth,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: _WarehouseLocationsForm(
                                            onLocationSelected: (name) {
                                              setState(() => item.locationName = name);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(LucideIcons.warehouse, size: 13, color: AppTheme.primaryBlue),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      item.locationName ?? widget.warehouse ?? 'Select warehouse',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: (item.locationName ?? widget.warehouse) != null
                                            ? AppTheme.primaryBlue
                                            : AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                  const VerticalDivider(width: 1, color: AppTheme.borderLight),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustomTextField(
                            controller: item.creditOnlyQtyController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.right,
                            hideBorderDefault: true,
                            height: 32,
                            contentCase: ContentCase.none,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: 200,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomTextField(
                      controller: item.returnQtyController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.right,
                      hideBorderDefault: true,
                      height: 32,
                      contentCase: ContentCase.none,
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (btnCtx) => GestureDetector(
                        onTap: () {
                          const dialogWidth = 420.0;
                          final box = btnCtx.findRenderObject() as RenderBox;
                          final triggerPos = box.localToGlobal(Offset.zero);
                          final triggerSize = box.size;
                          final screen = MediaQuery.of(btnCtx).size;

                          double left = triggerPos.dx + triggerSize.width - dialogWidth;
                          if (left < 8) left = 8;
                          if (left + dialogWidth > screen.width - 8) {
                            left = screen.width - dialogWidth - 8;
                          }
                          double top = triggerPos.dy + triggerSize.height + 6;
                          if (top + 220 > screen.height - 8) {
                            top = triggerPos.dy - 220 - 6;
                          }

                          showGeneralDialog<void>(
                            context: btnCtx,
                            barrierDismissible: true,
                            barrierLabel: '',
                            barrierColor: Colors.transparent,
                            transitionDuration: Duration.zero,
                            pageBuilder: (ctx, _, __) => Stack(
                              children: [
                                Positioned(
                                  left: left,
                                  top: top,
                                  width: dialogWidth,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: _WarehouseLocationsForm(
                                      onLocationSelected: (name) {
                                        setState(() => item.locationName = name);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(LucideIcons.warehouse, size: 13, color: AppTheme.primaryBlue),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.locationName ?? widget.warehouse ?? 'Select warehouse',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: (item.locationName ?? widget.warehouse) != null
                                      ? AppTheme.primaryBlue
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }
}


class _ItemDetailsSidePanel extends StatefulWidget {
  final _SalesReturnItem item;
  final VoidCallback onClose;

  const _ItemDetailsSidePanel({required this.item, required this.onClose});

  @override
  State<_ItemDetailsSidePanel> createState() => _ItemDetailsSidePanelState();
}

class _ItemDetailsSidePanelState extends State<_ItemDetailsSidePanel> {
  int _tab = 0;

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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
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
                    child: const Icon(LucideIcons.x, size: 16, color: AppTheme.errorRed),
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
                  child: const Icon(LucideIcons.image, size: 28, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inventory Items',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.item.name.toUpperCase(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(LucideIcons.externalLink, size: 14, color: AppTheme.primaryBlue),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('pcs', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
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
                _PanelTabButton(label: 'ITEM DETAILS', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                _PanelTabButton(label: 'STOCK LOCATIONS', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                _PanelTabButton(label: 'TRANSACTIONS', selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
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
        const _PanelSectionHeading('Sales Information'),
        const SizedBox(height: 12),
        const _PanelDetailRow(label: 'Price', value: 'â‚¹115.00'),
        const SizedBox(height: 8),
        const _PanelDetailRow(label: 'Account', value: 'Sales'),
        const SizedBox(height: 24),
        const _PanelSectionHeading('Purchase Information'),
        const SizedBox(height: 12),
        const _PanelDetailRow(label: 'Price', value: 'â‚¹100.00'),
        const SizedBox(height: 8),
        const _PanelDetailRow(label: 'Account', value: 'Cost of Goods Sold'),
        const SizedBox(height: 24),
        const _PanelSectionHeading('Other Details'),
      ],
    );
  }

  Widget _buildStockLocationsTab() {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(
        child: Text('No stock location data available.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(
        child: Text('No transactions available.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      ),
    );
  }
}

class _PanelTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PanelTabButton({required this.label, required this.selected, required this.onTap});

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

class _PanelSectionHeading extends StatelessWidget {
  final String text;
  const _PanelSectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
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
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Item Table Toolbar — above the items grid
// ---------------------------------------------------------------------------

class _ItemTableToolbar extends StatelessWidget {
  const _ItemTableToolbar({
    required this.selectedWarehouse,
    required this.warehouseOptions,
    required this.onWarehouseChanged,
  });

  final Warehouse? selectedWarehouse;
  final List<Warehouse> warehouseOptions;
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
            child: FormDropdown<Warehouse>(
              value: selectedWarehouse,
              items: warehouseOptions,
              hint: 'Select Warehouse',
              height: 36,
              hideBorderDefault: true,
              allowClear: true,
              displayStringForValue: (w) => w.name,
              searchStringForValue: (w) => w.name,
              onChanged: onWarehouseChanged,
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
  final void Function(String prefix, String nextNumber, bool autoGenerate) onSave;

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
                    'Configure RMA Number Preferences',
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
                    child: const Icon(LucideIcons.x, size: 16, color: AppTheme.errorRed),
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
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Associated Series',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
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
                        style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Default Transaction Series',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
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
                  'Your RMA numbers are set on auto-generate mode to save your time.',
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
                        onChanged: (val) => setState(() => _autoGenerate = val ?? true),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text(
                        'Continue auto-generating RMA numbers',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.info, size: 14, color: AppTheme.textSecondary),
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
                            const Text('Prefix', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
                            const Text('Next Number', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
                        onChanged: (val) => setState(() => _autoGenerate = val ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text(
                        'Enter RMA numbers manually',
                        style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
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

class _BulkMenuHoverItem extends StatefulWidget {
  final String label;
  const _BulkMenuHoverItem({required this.label});

  @override
  State<_BulkMenuHoverItem> createState() => _BulkMenuHoverItemState();
}

class _BulkMenuHoverItemState extends State<_BulkMenuHoverItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: _hovered ? const Color(0xFFEEF2FF) : Colors.transparent,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            color: _hovered ? AppTheme.primaryBlue : AppTheme.textPrimary,
            fontWeight: _hovered ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _BulkUpdateLineItemsDialog extends StatefulWidget {
  const _BulkUpdateLineItemsDialog();

  @override
  State<_BulkUpdateLineItemsDialog> createState() => _BulkUpdateLineItemsDialogState();
}

class _BulkUpdateLineItemsDialogState extends State<_BulkUpdateLineItemsDialog> {
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
      child: SizedBox(
        width: 600,
        child: _buildContent(context),
      ),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
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
                  child: const Icon(LucideIcons.x, size: 14, color: AppTheme.errorRed),
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
                    const Text('ADGF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
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
                    const Text('shedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    FormDropdown<String>(
                      value: _selectedShedule,
                      items: const ['None', 'Option 1', 'Option 2'],
                      hint: 'None',
                      height: 36,
                      onChanged: (val) => setState(() => _selectedShedule = val),
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
              const Text('demo adavced reporting tag', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
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
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Update', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: AppTheme.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulkUpdateAccountDialog extends StatefulWidget {
  const _BulkUpdateAccountDialog();

  @override
  State<_BulkUpdateAccountDialog> createState() => _BulkUpdateAccountDialogState();
}

class _BulkUpdateAccountDialogState extends State<_BulkUpdateAccountDialog> {
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
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
                      child: const Icon(LucideIcons.x, size: 14, color: AppTheme.errorRed),
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
                  const Text('Choose Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 280,
                    child: FormDropdown<String>(
                      value: _selectedAccount,
                      items: const ['Select an account', 'Account 1', 'Account 2'],
                      hint: 'Select an account',
                      height: 36,
                      onChanged: (val) => setState(() => _selectedAccount = val),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Update', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF374151),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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

class _BulkUpdateDiscountAccountDialog extends StatefulWidget {
  const _BulkUpdateDiscountAccountDialog();

  @override
  State<_BulkUpdateDiscountAccountDialog> createState() => _BulkUpdateDiscountAccountDialogState();
}

class _BulkUpdateDiscountAccountDialogState extends State<_BulkUpdateDiscountAccountDialog> {
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
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
                      child: const Icon(LucideIcons.x, size: 14, color: AppTheme.errorRed),
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
                      items: const ['Select an account', 'Account 1', 'Account 2'],
                      hint: 'Select an account',
                      height: 36,
                      onChanged: (val) => setState(() => _selectedAccount = val),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Update', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF374151),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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

class _WarehouseLocationsForm extends StatefulWidget {
  final ValueChanged<String> onLocationSelected;

  const _WarehouseLocationsForm({required this.onLocationSelected});

  @override
  State<_WarehouseLocationsForm> createState() => _WarehouseLocationsFormState();
}

class _WarehouseLocationsFormState extends State<_WarehouseLocationsForm> {
  String _selectedLocation = 'ZABNIX PRIVATE LIMITED';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Bar with inline X button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                const Text(
                  'Warehouse Locations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.errorRed, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(LucideIcons.x, size: 14, color: AppTheme.errorRed),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: const [
                Text(
                  'Location Name',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                SizedBox(width: 4),
                Icon(LucideIcons.search, size: 14, color: AppTheme.textSecondary),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // List
          RadioListTile<String>(
            value: 'ZABNIX PRIVATE LIMITED',
            groupValue: _selectedLocation,
            onChanged: (val) {
              setState(() => _selectedLocation = val!);
              widget.onLocationSelected(val!);
              Navigator.of(context).pop();
            },
            activeColor: AppTheme.primaryBlue,
            title: const Text('ZABNIX PRIVATE LIMITED', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            dense: true,
          ),
          RadioListTile<String>(
            value: 'DEMO WAREHOUSE 1 (Warehouse)',
            groupValue: _selectedLocation,
            onChanged: (val) {
              setState(() => _selectedLocation = val!);
              widget.onLocationSelected(val!);
              Navigator.of(context).pop();
            },
            activeColor: AppTheme.primaryBlue,
            title: const Text('DEMO WAREHOUSE 1 (Warehouse)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            dense: true,
          ),
        ],
      ),
    );
  }
}

// ─── Customer Dropdown Data ────────────────────────────────────────────────────


class _SrCustomerDropdownDetails {
  final String code;
  final String addressLine;

  const _SrCustomerDropdownDetails({
    required this.code,
    required this.addressLine,
  });
}

// ─── Customer Dropdown Item Widget ────────────────────────────────────────────

class _SrCustomerDropdownItem extends StatelessWidget {
  final String customerName;
  final String customerCode;
  final String addressLine;
  final bool highlighted;

  const _SrCustomerDropdownItem({
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
    final textColor = highlighted ? AppTheme.backgroundColor : AppTheme.textBody;
    final secondaryColor = highlighted ? AppTheme.backgroundColor : AppTheme.textSecondary;

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
                    Icon(LucideIcons.building2, size: 14, color: secondaryColor),
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

// ─── Currency Badge ────────────────────────────────────────────────────────────

class _SrCurrencyBadge extends StatelessWidget {
  const _SrCurrencyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _SalesReturnsAddPageState._fieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.badgeDollarSign, size: 16, color: AppTheme.successGreen),
          SizedBox(width: 6),
          Text(
            'INR',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ─── Customer Address Panel ────────────────────────────────────────────────────

class _SrCustomerAddressPanel extends ConsumerStatefulWidget {
  final SalesCustomer customer;
  final ValueChanged<SalesCustomer>? onCustomerUpdated;
  final double? width;

  const _SrCustomerAddressPanel({
    required this.customer,
    this.onCustomerUpdated,
    this.width,
  });

  @override
  ConsumerState<_SrCustomerAddressPanel> createState() =>
      _SrCustomerAddressPanelState();
}

class _SrCustomerAddressPanelState
    extends ConsumerState<_SrCustomerAddressPanel> {
  bool get _hasBilling =>
      widget.customer.billingAddressStreet1?.isNotEmpty == true ||
      widget.customer.billingAddressCity?.isNotEmpty == true;

  bool get _hasShipping =>
      widget.customer.shippingAddressStreet1?.isNotEmpty == true ||
      widget.customer.shippingAddressCity?.isNotEmpty == true;

  List<String> get _billingLines => [
        widget.customer.billingAddressStreet1,
        widget.customer.billingAddressStreet2,
        widget.customer.billingAddressCity,
        widget.customer.billingAddressZip,
        if (widget.customer.billingAddressPhone?.isNotEmpty == true)
          'Ph: ${widget.customer.billingAddressPhone}',
      ].whereType<String>().where((s) => s.isNotEmpty).toList();

  List<String> get _shippingLines => [
        widget.customer.shippingAddressStreet1,
        widget.customer.shippingAddressStreet2,
        widget.customer.shippingAddressCity,
        widget.customer.shippingAddressZip,
        if (widget.customer.shippingAddressPhone?.isNotEmpty == true)
          'Ph: ${widget.customer.shippingAddressPhone}',
      ].whereType<String>().where((s) => s.isNotEmpty).toList();

  void _openDialog({required bool isBilling}) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _SrAddressFormDialog(
        isBilling: isBilling,
        customer: widget.customer,
        onSaved: (updated) {
          widget.onCustomerUpdated?.call(updated);
          ref.invalidate(salesCustomersProvider);
        },
      ),
    );
  }

  Widget _buildAddressColumn({
    required String title,
    required bool hasAddress,
    required List<String> lines,
    required bool isBilling,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            if (hasAddress) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _openDialog(isBilling: isBilling),
                child: const Icon(LucideIcons.pencil,
                    size: 12, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (!hasAddress)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _openDialog(isBilling: isBilling),
              child: const Text(
                'New Address',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.primaryBlue),
              ),
            ),
          )
        else ...[
          Text(
            widget.customer.displayName,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(line,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              )),
        ],
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
                  hasAddress: _hasBilling,
                  lines: _billingLines,
                  isBilling: true,
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _buildAddressColumn(
                  title: 'SHIPPING ADDRESS',
                  hasAddress: _hasShipping,
                  lines: _shippingLines,
                  isBilling: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Address Form Dialog ───────────────────────────────────────────────────────

class _SrAddressFormDialog extends ConsumerStatefulWidget {
  final bool isBilling;
  final SalesCustomer customer;
  final ValueChanged<SalesCustomer>? onSaved;

  const _SrAddressFormDialog({
    required this.isBilling,
    required this.customer,
    this.onSaved,
  });

  @override
  ConsumerState<_SrAddressFormDialog> createState() =>
      _SrAddressFormDialogState();
}

class _SrAddressFormDialogState extends ConsumerState<_SrAddressFormDialog> {
  late final TextEditingController _attentionCtrl;
  late final TextEditingController _street1;
  late final TextEditingController _street2;
  late final TextEditingController _city;
  late final TextEditingController _zip;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _faxCtrl;
  String? _country;
  String? _state;
  bool _saving = false;

  static const _countries = ['India', 'United States', 'United Kingdom', 'UAE'];
  static const _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh',
    'Jammu & Kashmir', 'Jharkhand', 'Karnataka', 'Kerala', 'Ladakh',
    'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    if (widget.isBilling) {
      _attentionCtrl = TextEditingController(text: c.displayName);
      _street1 = TextEditingController(text: c.billingAddressStreet1 ?? '');
      _street2 = TextEditingController(text: c.billingAddressStreet2 ?? '');
      _city = TextEditingController(text: c.billingAddressCity ?? '');
      _zip = TextEditingController(text: c.billingAddressZip ?? '');
      _phoneCtrl = TextEditingController(text: c.billingAddressPhone ?? '');
    } else {
      _attentionCtrl = TextEditingController(text: c.displayName);
      _street1 = TextEditingController(text: c.shippingAddressStreet1 ?? '');
      _street2 = TextEditingController(text: c.shippingAddressStreet2 ?? '');
      _city = TextEditingController(text: c.shippingAddressCity ?? '');
      _zip = TextEditingController(text: c.shippingAddressZip ?? '');
      _phoneCtrl = TextEditingController(text: c.shippingAddressPhone ?? '');
    }
    _faxCtrl = TextEditingController();
    _country = 'India';
  }

  @override
  void dispose() {
    for (final c in [_attentionCtrl, _street1, _street2, _city, _zip, _phoneCtrl, _faxCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final apiService = ref.read(salesOrderApiServiceProvider);
      final addressKey = widget.isBilling ? 'billingAddress' : 'shippingAddress';
      final updated = await apiService.updateCustomer(widget.customer.id, {
        addressKey: {
          if (_attentionCtrl.text.trim().isNotEmpty) 'attention': _attentionCtrl.text.trim(),
          'street1': _street1.text.trim(),
          if (_street2.text.trim().isNotEmpty) 'street2': _street2.text.trim(),
          if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
          if (_zip.text.trim().isNotEmpty) 'zip': _zip.text.trim(),
          if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        },
      });
      widget.onSaved?.call(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to save address');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
      );

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        CustomTextField(
          controller: ctrl,
          hintText: label,
          keyboardType: keyboardType,
          maxLines: maxLines,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isBilling ? 'Billing Address' : 'Shipping Address';
    final noteText = 'Changes made here will be updated for this customer.';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(left: 280, right: 280, top: 0, bottom: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
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
            // Body
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
                      hint: 'Select',
                      onChanged: (v) => setState(() => _country = v),
                    ),
                    const SizedBox(height: 16),
                    _label('Address'),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _street1,
                      hintText: 'Street 1',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _street2,
                      hintText: 'Street 2',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _field('City', _city),
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
                                hint: 'Select or type to add',
                                onChanged: (v) => setState(() => _state = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _field('Pin Code', _zip,
                              keyboardType: TextInputType.number),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.borderLight),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text('+91',
                                            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                                        SizedBox(width: 4),
                                        Icon(Icons.keyboard_arrow_down,
                                            size: 16, color: AppTheme.textSecondary),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _phoneCtrl,
                                      hintText: 'Phone number',
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _field('Fax Number', _faxCtrl,
                              keyboardType: TextInputType.phone),
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
                                color: AppTheme.textSecondary),
                          ),
                          TextSpan(
                            text: noteText,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  ZButton.primary(
                    label: _saving ? 'Saving...' : 'Save',
                    onPressed: _saving ? null : _save,
                  ),
                  const SizedBox(width: 12),
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
}

// Unused legacy classes removed — replaced by _SrAddressFormDialog
class _SrAddressPickerRow extends StatefulWidget {
  final Map<String, dynamic> address;
  final bool isSelected;
  final VoidCallback onSelected;
  final VoidCallback? onEdit;

  const _SrAddressPickerRow({
    required this.address,
    required this.isSelected,
    required this.onSelected,
    required this.onEdit,
  });

  @override
  State<_SrAddressPickerRow> createState() => _SrAddressPickerRowState();
}

class _SrAddressPickerRowState extends State<_SrAddressPickerRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final lines = widget.address['lines'] as List<String>? ?? const <String>[];
    final bgColor = _hovered
        ? AppTheme.primaryBlue
        : widget.isSelected
            ? AppTheme.bgDisabled
            : AppTheme.backgroundColor;
    final titleColor = _hovered ? AppTheme.backgroundColor : AppTheme.textPrimary;
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
                      color: _hovered ? AppTheme.backgroundColor : AppTheme.primaryBlue,
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

// ─── New Address Action ────────────────────────────────────────────────────────

class _SrNewAddressAction extends StatefulWidget {
  final VoidCallback onTap;

  const _SrNewAddressAction({required this.onTap});

  @override
  State<_SrNewAddressAction> createState() => _SrNewAddressActionState();
}

class _SrNewAddressActionState extends State<_SrNewAddressAction> {
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
                style: TextStyle(fontSize: 13, color: fgColor, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Address Edit Dialog ───────────────────────────────────────────────────────

class _SrAddressEditDialog extends StatefulWidget {
  final Map<String, dynamic> address;
  final String title;
  const _SrAddressEditDialog({
    required this.address,
    required this.title,
  });

  @override
  State<_SrAddressEditDialog> createState() => _SrAddressEditDialogState();
}

class _SrAddressEditDialogState extends State<_SrAddressEditDialog> {
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
  static const List<String> _states = ['Kerala', 'Karnataka', 'Tamil Nadu', 'Maharashtra', 'Delhi', 'Goa'];

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
    _country = 'India';
    _state = 'Kerala';
  }

  @override
  void dispose() {
    for (final c in [_attentionCtrl, _addressCtrl, _street2Ctrl, _cityCtrl, _pinCtrl, _phoneCtrl, _faxCtrl]) {
      c.dispose();
    }
    super.dispose();
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
        CustomTextField(controller: ctrl, keyboardType: keyboardType, hintText: label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const noteText = 'Changes made here will be updated for this customer.';

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
                                items: _states,
                                hint: 'Select state',
                                onChanged: (v) => setState(() => _state = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _field('Pin Code', _pinCtrl, keyboardType: TextInputType.number),
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
                        Expanded(
                          child: _field('Fax Number', _faxCtrl, keyboardType: TextInputType.phone),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Note: ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                          ),
                          TextSpan(
                            text: noteText,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
}
