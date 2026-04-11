import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/inputs/dropdown_input.dart';
import '../../../../shared/widgets/inputs/zerpai_date_picker.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import '../../../../shared/widgets/inputs/z_tooltip.dart';
import '../../../../shared/widgets/inputs/custom_text_field.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../sales/controllers/sales_order_controller.dart';
import '../../../sales/models/sales_order_model.dart';
import '../../../sales/models/sales_customer_model.dart';

// ignore: constant_identifier_names
const Color _textPrimary = Color(0xFF1F2937);
// ignore: constant_identifier_names
const Color _textSecondary = Color(0xFF6B7280);
// ignore: constant_identifier_names
const Color _borderCol = Color(0xFFE5E7EB);
// ignore: constant_identifier_names
const Color _focusBorder = Color(0xFF3B82F6);
// ignore: constant_identifier_names
const Color _greenBtn = Color(0xFF10B981);
// ignore: constant_identifier_names
const Color _dangerRed = Color(0xFFDC2626);

class InventoryShipmentsCreateScreen extends ConsumerStatefulWidget {
  const InventoryShipmentsCreateScreen({super.key});

  @override
  ConsumerState<InventoryShipmentsCreateScreen> createState() =>
      _InventoryShipmentsCreateScreenState();
}

class _InventoryShipmentsCreateScreenState
    extends ConsumerState<InventoryShipmentsCreateScreen> {
  final TextEditingController _shipmentOrderCtrl = TextEditingController();
  final TextEditingController _trackingCtrl = TextEditingController();
  final TextEditingController _trackingUrlCtrl = TextEditingController();
  final TextEditingController _shippingChargesCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _deliveredDateCtrl = TextEditingController();

  String? _selectedCustomer;
  String? _selectedSO;
  List<String> _selectedPackages = []; // Changed to list
  String? _selectedCarrier;
  String? _selectedTime;

  SalesCustomer? _selectedCustomerData;
  SalesOrder? _selectedSalesOrderData;

  DateTime? _selectedDate;
  DateTime? _selectedDeliveredDate;
  final GlobalKey _dateFieldKey = GlobalKey();
  final GlobalKey _deliveredDateFieldKey = GlobalKey();

  bool _isDelivered = false;
  bool _sendStatusNotification = false;

  final List<String> _packages = ['PKG-00015', 'PKG-00016'];
  final List<String> _carriers = ['SPEED AND SAFE', 'DHL', 'FedEx'];
  late final List<String> _times;

  bool get _isSalesOrderSelected => _selectedSO != null;

  Widget _commonItemBuilder<T>(T item, bool isSelected, bool isHovered, String Function(T) displayFn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: isHovered 
          ? const Color(0xFF3B82F6) 
          : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent),
      child: Text(
        displayFn(item),
        style: TextStyle(
          fontSize: 13, 
          color: isHovered ? Colors.white : const Color(0xFF1F2937),
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _times = List.generate(48, (i) {
      final hour = i ~/ 2;
      final minute = (i % 2) * 30;
      return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
    });
    
    _dateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    _deliveredDateCtrl.text = 'dd-MM-yyyy';
    _shippingChargesCtrl.text = '0.00';
    _isDelivered = false;
    _sendStatusNotification = true;
  }

  final Set<String> _hoveredFields = {};

  void _onHover(String fieldKey, bool isHovered) {
    if (mounted) {
      setState(() {
        if (isHovered) {
          _hoveredFields.add(fieldKey);
        } else {
          _hoveredFields.remove(fieldKey);
        }
      });
    }
  }

  @override
  void dispose() {
    _shipmentOrderCtrl.dispose();
    _trackingCtrl.dispose();
    _trackingUrlCtrl.dispose();
    _shippingChargesCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    _deliveredDateCtrl.dispose();
    super.dispose();
  }

  InputDecoration _standardInputDecoration({
    String? hint,
    Widget? suffixIcon,
    bool isHovered = false,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: isHovered ? _focusBorder : _borderCol, width: isHovered ? 1.4 : 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _focusBorder, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '', // We use custom header
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: Column(
        children: [
          // Custom Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(LucideIcons.truck, size: 24, color: _textPrimary),
                const SizedBox(width: 12),
                const Text(
                  'New Shipment',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                const Text(
                  'Switch to carrier shipment',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: _textSecondary,
                  ),
                  splashRadius: 20,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _borderCol),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gray Banner for Customer & SO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 750),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormRow(
                              label: 'Customer Name',
                              isRequired: false,
                              child: MouseRegion(
                                onEnter: (_) => _onHover('customer', true),
                                onExit: (_) => _onHover('customer', false),
                                child: ref.watch(salesCustomersProvider).when(
                                    data: (customers) => FormDropdown<String>(
                                      fillColor: Colors.white,
                                      value: _selectedCustomer,
                                      height: 32,
                                      isHovered: _hoveredFields.contains('customer'),
                                      hint: 'Select Customer',
                                      items: customers.map((e) => e.id).toList(),
                                      maxVisibleItems: 4,
                                      textStyle: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontFamily: 'Inter',
                                      ),
                                      itemBuilder: (item, isSelected, isHovered) => _commonItemBuilder<String>(
                                        item, 
                                        isSelected, 
                                        isHovered, 
                                        (id) => customers.firstWhere((c) => c.id == id).displayName,
                                      ),
                                      displayStringForValue: (val) {
                                        final customer = customers.firstWhere((c) => c.id == val);
                                        return customer.displayName;
                                      },
                                      searchStringForValue: (val) {
                                        final customer = customers.firstWhere((c) => c.id == val);
                                      return customer.displayName;
                                    },
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedCustomer = val;
                                        _selectedCustomerData = customers.firstWhere((c) => c.id == val);
                                        _selectedSO = null;
                                        _selectedSalesOrderData = null;
                                      });
                                    },
                                  ),
                                  loading: () => const Skeleton(
                                    height: 32,
                                    width: double.infinity,
                                  ),
                                  error: (e, _) => Text('Error: $e'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildFormRow(
                              label: 'Sales Order#',
                              isRequired: true,
                              child: MouseRegion(
                                onEnter: (_) => _onHover('salesOrder', true),
                                onExit: (_) => _onHover('salesOrder', false),
                                child: _selectedCustomer == null
                                    ? FormDropdown<String>(
                                      fillColor: AppTheme.bgDisabled,
                                      value: null,
                                      isHovered: _hoveredFields.contains('salesOrder'),
                                      hint: 'Select Sales Order',
                                      items: const [],
                                      itemBuilder: (item, isSelected, isHovered) => _commonItemBuilder<String>(item, isSelected, isHovered, (s) => s),
                                      displayStringForValue: (s) => s,
                                      searchStringForValue: (s) => s,
                                      onChanged: (val) {},
                                      height: 32,
                                      textStyle: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontFamily: 'Inter',
                                      ),
                                    )
                                    : ref
                                        .watch(
                                          salesOrdersByCustomerProvider(
                                            _selectedCustomer!,
                                          ),
                                        )
                                      .when(
                                        data: (orders) => FormDropdown<SalesOrder>(
                                          fillColor: Colors.white,
                                          value: _selectedSalesOrderData,
                                          isHovered: _hoveredFields.contains('salesOrder'),
                                          hint: 'Select Sales Order',
                                          items: orders,
                                          maxVisibleItems: 4,
                                          itemBuilder: (item, isSelected, isHovered) => _commonItemBuilder<SalesOrder>(item, isSelected, isHovered, (val) => val.saleNumber),
                                          displayStringForValue: (val) => val.saleNumber,
                                          searchStringForValue: (val) => val.saleNumber,
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedSO = val?.id;
                                              _selectedSalesOrderData = val;
                                            });
                                          },
                                          height: 32,
                                          textStyle: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 13,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        loading: () => const Skeleton(
                                          height: 32,
                                          width: double.infinity,
                                        ),
                                        error: (e, _) => Text('Error: $e'),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                    Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          // Info Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFEDD5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.info, size: 18, color: Color(0xFFC2410C)),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Create multiple shipments for a single sales order if needed.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF9A3412),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Opacity(
                            opacity: _isSalesOrderSelected ? 1.0 : 0.3,
                            child: IgnorePointer(
                              ignoring: !_isSalesOrderSelected,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MouseRegion(
                                    onEnter: (_) => _onHover('package', true),
                                    onExit: (_) => _onHover('package', false),
                                    child: SizedBox(
                                      width: 380,
                                      child: _buildFormRow(
                                        label: 'Package#',
                                        isRequired: true,
                                        child: FormDropdown<String>(
                                          value: null,
                                          selectedValues: _selectedPackages,
                                          multiSelect: true,
                                          maxVisibleItems: 4, // Dynamic height for 4 items
                                          isHovered: _hoveredFields.contains('package'),
                                          hideSelectedItemsInMultiSelect: true,
                                          items: _packages,
                                          hint: 'Select Package',
                                          showSearch: true,
                                          onChanged: (_) {},
                                          onSelectedValuesChanged: (vals) {
                                            setState(() {
                                              _selectedPackages = vals;
                                            });
                                          },
                                          height: 32,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Shipment Order# (Single Row)
                                  MouseRegion(
                                    onEnter: (_) => _onHover('shipmentOrder', true),
                                    onExit: (_) => _onHover('shipmentOrder', false),
                                    child: SizedBox(
                                      width: 380,
                                      child: _buildFormRow(
                                        label: 'Shipment Order#',
                                        isRequired: true,
                                        child: CustomTextField(
                                          controller: _shipmentOrderCtrl,
                                          height: 32,
                                          suffixWidget: const ZTooltip(
                                            message: 'Click here to enable or disable auto-generation of Shipment numbers.',
                                            child: Icon(LucideIcons.settings, size: 16, color: Color(0xFF0088FF)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Ship Date (Below Shipment Order#)
                                  MouseRegion(
                                    onEnter: (_) => _onHover('shipDate', true),
                                    onExit: (_) => _onHover('shipDate', false),
                                    child: SizedBox(
                                      width: 380,
                                      child: _buildFormRow(
                                        label: 'Ship Date',
                                        isRequired: true,
                                        child: CustomTextField(
                                          controller: _dateCtrl,
                                          height: 32,
                                          readOnly: true,
                                          onTap: () async {
                                            final picked = await ZerpaiDatePicker.show(
                                              context,
                                              initialDate: _selectedDate ?? DateTime.now(),
                                              targetKey: _dateFieldKey,
                                            );
                                            if (picked != null && mounted) {
                                              setState(() {
                                                _selectedDate = picked;
                                                _dateCtrl.text = DateFormat('dd-MM-yyyy').format(picked);
                                              });
                                            }
                                          },
                                          suffixWidget: const Icon(LucideIcons.calendar, size: 16, color: _textSecondary),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Row: Carrier and Tracking#
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      MouseRegion(
                                        onEnter: (_) => _onHover('carrier', true),
                                        onExit: (_) => _onHover('carrier', false),
                                        child: SizedBox(
                                          width: 380,
                                          child: _buildFormRow(
                                            label: 'Carrier',
                                            isRequired: true,
                                            child: FormDropdown<String>(
                                              isHovered: _hoveredFields.contains('carrier'),
                                              value: _selectedCarrier,
                                              items: _carriers,
                                              hint: 'Select Carrier',
                                              showSearch: true,
                                              onChanged: (val) {
                                                setState(() => _selectedCarrier = val);
                                              },
                                              height: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 32),
                                      MouseRegion(
                                        onEnter: (_) => _onHover('tracking', true),
                                        onExit: (_) => _onHover('tracking', false),
                                        child: SizedBox(
                                          width: 380,
                                          child: _buildFormRow(
                                            label: 'Tracking#',
                                            child: CustomTextField(
                                              controller: _trackingCtrl,
                                              height: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Tracking URL
                                  MouseRegion(
                                    onEnter: (_) => _onHover('trackingUrl', true),
                                    onExit: (_) => _onHover('trackingUrl', false),
                                    child: SizedBox(
                                      width: 380,
                                      child: _buildFormRow(
                                        label: 'Tracking URL',
                                        child: CustomTextField(
                                          controller: _trackingUrlCtrl,
                                          height: 32,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  MouseRegion(
                                    onEnter: (_) => _onHover('shippingCharges', true),
                                    onExit: (_) => _onHover('shippingCharges', false),
                                    child: SizedBox(
                                      width: 380,
                                      child: _buildFormRow(
                                        label: 'Shipping Charges',
                                        child: Container(
                                          height: 32,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: _borderCol), 
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                height: 32,
                                                alignment: Alignment.center,
                                                decoration: const BoxDecoration(
                                                  color: AppTheme.bgDisabled,
                                                  border: Border(right: BorderSide(color: _borderCol)),
                                                ),
                                                child: const Text('INR', style: TextStyle(fontSize: 13, color: _textSecondary)),
                                              ),
                                              Expanded(
                                                child: TextField(
                                                  controller: _shippingChargesCtrl,
                                                  textAlign: TextAlign.right,
                                                  keyboardType: TextInputType.number,
                                                  style: const TextStyle(fontSize: 14, fontFamily: 'Inter'),
                                                  decoration: _standardInputDecoration(
                                                    isHovered: _hoveredFields.contains('shippingCharges'),
                                                    hint: '0.00',
                                                  ).copyWith(
                                                    fillColor: Colors.transparent,
                                                    contentPadding: EdgeInsets.zero,
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(4),
                                                      borderSide: BorderSide(
                                                        color: _hoveredFields.contains('shippingCharges') ? _focusBorder : Colors.transparent,
                                                        width: 1.4,
                                                      ),
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
                                  const SizedBox(height: 20),

                                  // Notes
                                  MouseRegion(
                                    onEnter: (_) => _onHover('notes', true),
                                    onExit: (_) => _onHover('notes', false),
                                    child: _buildFormRow(
                                      label: 'Notes',
                                      child: SizedBox(
                                        width: 622,
                                        child: TextField(
                                          controller: _notesCtrl,
                                          maxLines: 4,
                                          style: const TextStyle(fontSize: 14, color: _textPrimary, fontFamily: 'Inter'),
                                          decoration: _standardInputDecoration(
                                            isHovered: _hoveredFields.contains('notes'),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // Delivered Section
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _isDelivered,
                                          onChanged: (val) => setState(() => _isDelivered = val ?? false),
                                          activeColor: const Color(0xFF3B82F6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Shipment already delivered',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _textPrimary,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (_isDelivered) ...[
                                    const SizedBox(height: 20),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Delivered On',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: _textPrimary,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 380,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: _borderCol),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: MouseRegion(
                                                  onEnter: (_) => _onHover('delDate', true),
                                                  onExit: (_) => _onHover('delDate', false),
                                                  child: TextField(
                                                    controller: _deliveredDateCtrl,
                                                    key: _deliveredDateFieldKey,
                                                    readOnly: true,
                                                    style: const TextStyle(fontSize: 13, fontFamily: 'Inter', color: _textPrimary),
                                                    onTap: () async {
                                                      final picked = await ZerpaiDatePicker.show(
                                                        context,
                                                        initialDate: _selectedDeliveredDate ?? DateTime.now(),
                                                        targetKey: _deliveredDateFieldKey,
                                                      );
                                                      if (picked != null && mounted) {
                                                        setState(() {
                                                          _selectedDeliveredDate = picked;
                                                          _deliveredDateCtrl.text = DateFormat('dd-MM-yyyy').format(picked);
                                                        });
                                                      }
                                                    },
                                                    decoration: _standardInputDecoration(
                                                      isHovered: _hoveredFields.contains('delDate'),
                                                      hint: 'dd-MM-yyyy',
                                                    ).copyWith(
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(4),
                                                        borderSide: BorderSide(
                                                          color: _hoveredFields.contains('delDate') ? _focusBorder : Colors.transparent,
                                                          width: 1.4,
                                                        ),
                                                      ),
                                                      prefixIcon: const Icon(LucideIcons.calendar, size: 16, color: _textSecondary),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 18,
                                                child: const VerticalDivider(width: 1, thickness: 1, color: _borderCol),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: MouseRegion(
                                                  onEnter: (_) => _onHover('delTime', true),
                                                  onExit: (_) => _onHover('delTime', false),
                                                  child: FormDropdown<String>(
                                                    value: _selectedTime,
                                                    items: _times,
                                                    height: 30,
                                                    isHovered: _hoveredFields.contains('delTime'),
                                                    hint: 'HH:MM',
                                                    maxVisibleItems: 5,
                                                    hideBorderDefault: true,
                                                    onChanged: (val) {
                                                      setState(() => _selectedTime = val);
                                                    },
                                                    prefixWidget: const Icon(LucideIcons.clock, size: 16, color: _textSecondary),
                                                    textStyle: const TextStyle(
                                                      color: _textPrimary,
                                                      fontSize: 12,
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
                                  ],

                                  const SizedBox(height: 32),

                                  // Notification Section
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _sendStatusNotification,
                                          onChanged: (val) => setState(() => _sendStatusNotification = val ?? false),
                                          activeColor: const Color(0xFF3B82F6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Send Status Notification',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _textSecondary,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(LucideIcons.alertTriangle, size: 14, color: _dangerRed),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    width: 750,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F4FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Recipients of the corresponding sales order will be notified of the status of the shipment.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF003A8C),
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _borderCol)),
            ),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _greenBtn,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    elevation: 0,
                  ),
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textPrimary,
                    side: const BorderSide(color: _borderCol),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow({
    required String label,
    required Widget child,
    String? subLabel,
    bool isRequired = false,
  }) {
    return Row(
      crossAxisAlignment: subLabel != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isRequired ? _dangerRed : _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (isRequired)
                    const Text(
                      ' *',
                      style: TextStyle(
                        color: _dangerRed,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                ],
              ),
              if (subLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }
}
