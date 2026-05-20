import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/inputs/dropdown_input.dart';
import '../../../../shared/widgets/inputs/zerpai_date_picker.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import '../../../../shared/widgets/inputs/custom_text_field.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/inventory/packages/providers/inventory_packages_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

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

class InventoryShipmentsEditScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const InventoryShipmentsEditScreen({super.key, required this.shipmentId});

  @override
  ConsumerState<InventoryShipmentsEditScreen> createState() =>
      _InventoryShipmentsEditScreenState();
}

class _InventoryShipmentsEditScreenState
    extends ConsumerState<InventoryShipmentsEditScreen> {
  final TextEditingController _shipmentOrderCtrl = TextEditingController();
  final TextEditingController _trackingCtrl = TextEditingController();
  final TextEditingController _trackingUrlCtrl = TextEditingController();
  final TextEditingController _shippingChargesCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _deliveredDateCtrl = TextEditingController();
  final TextEditingController _carrierInputCtrl = TextEditingController();
  final FocusNode _carrierFocusNode = FocusNode();

  final TextEditingController _customerNameCtrl = TextEditingController();
  final TextEditingController _salesOrderCtrl = TextEditingController();

  List<String> _selectedPackages = []; 
  String? _selectedTime;


  DateTime? _selectedDate;
  DateTime? _selectedDeliveredDate;
  final GlobalKey _dateFieldKey = GlobalKey();
  final GlobalKey _deliveredDateFieldKey = GlobalKey();

  bool _isDelivered = false;
  bool _sendStatusNotification = false;


  final List<String> _carriers = ['SPEED AND SAFE', 'DHL', 'FedEx'];
  late final List<String> _times;

  String? _packageError;
  String? _shipmentOrderError;
  String? _dateError;
  String? _carrierError;


  Map<String, dynamic> _initialData = {};

  bool get _isDirty {
    if (_initialData.isEmpty) return false;
    
    return _shipmentOrderCtrl.text != _initialData['shipment_number'] ||
        _dateCtrl.text != _initialData['date'] ||
        _carrierInputCtrl.text != _initialData['carrier'] ||
        _trackingCtrl.text != _initialData['tracking_number'] ||
        _trackingUrlCtrl.text != _initialData['tracking_url'] ||
        _shippingChargesCtrl.text != _initialData['shipping_charges'] ||
        _notesCtrl.text != _initialData['notes'] ||
        _isDelivered != _initialData['is_delivered'] ||
        _deliveredDateCtrl.text != _initialData['delivered_date'] ||
        _selectedTime != _initialData['selected_time'] ||
        !_areListsEqual(_selectedPackages, _initialData['packages'] as List<String>);
  }

  bool _areListsEqual(List<String> a, List<String> b) {
    final setA = a.toSet();
    final setB = b.toSet();
    return setA.length == setB.length && setA.containsAll(setB);
  }

  @override
  void initState() {
    super.initState();
    _times = List.generate(48, (i) {
      final hour = i ~/ 2;
      final minute = (i % 2) * 30;
      return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryPackagesProvider.notifier).fetchPackages();
      _fetchShipmentDetails();
    });
  }

  void _fetchShipmentDetails() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('inventory_shipments')
          .select('*, customers(display_name), inventory_shipment_sales_orders(sales_orders(sale_number)), inventory_shipment_packages(inventory_packages(package_number))')
          .eq('id', widget.shipmentId)
          .maybeSingle();
          
      if (response != null) {
        setState(() {
          _customerNameCtrl.text = response['customers']?['display_name'] ?? '';
          
          final soList = response['inventory_shipment_sales_orders'] as List?;
          if (soList != null && soList.isNotEmpty) {
            final soNumbers = soList.map((so) => so['sales_orders']?['sale_number'] as String?).where((n) => n != null).toList();
            _salesOrderCtrl.text = soNumbers.join(', ');
          }
          
          final pkgList = response['inventory_shipment_packages'] as List?;
          if (pkgList != null && pkgList.isNotEmpty) {
            _selectedPackages = pkgList.map((pkg) => pkg['inventory_packages']?['package_number'] as String?).where((n) => n != null).cast<String>().toList();
          }
          
          _shipmentOrderCtrl.text = response['shipment_number'] ?? '';
          _dateCtrl.text = response['date'] ?? '';
          _selectedDate = DateTime.tryParse(response['date'] ?? '');
          _carrierInputCtrl.text = response['carrier'] ?? '';
          _trackingCtrl.text = response['tracking_number'] ?? '';
          _trackingUrlCtrl.text = response['tracking_url'] ?? '';
          _shippingChargesCtrl.text = (response['shipping_charges'] ?? 0.0).toString();
          _notesCtrl.text = response['notes'] ?? '';
          _isDelivered = response['is_delivered'] ?? false;
          final delDateStr = response['delivered_date'] as String?;
          if (delDateStr != null) {
            final parsed = DateTime.tryParse(delDateStr);
            if (parsed != null) {
              _selectedDeliveredDate = parsed;
              _deliveredDateCtrl.text = DateFormat('dd-MM-yyyy').format(parsed);
              final timeStr = DateFormat('HH:mm').format(parsed);
              _selectedTime = timeStr;
              if (!_times.contains(timeStr)) {
                _times.add(timeStr);
                _times.sort();
              }
            }
          }
          
          _initialData = {
            'shipment_number': _shipmentOrderCtrl.text,
            'date': _dateCtrl.text,
            'carrier': _carrierInputCtrl.text,
            'tracking_number': _trackingCtrl.text,
            'tracking_url': _trackingUrlCtrl.text,
            'shipping_charges': _shippingChargesCtrl.text,
            'notes': _notesCtrl.text,
            'is_delivered': _isDelivered,
            'delivered_date': _deliveredDateCtrl.text,
            'selected_time': _selectedTime,
            'packages': List<String>.from(_selectedPackages),
          };
        });
      }
    } catch (e) {
      print('Error fetching shipment details: $e');
    }
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
    _carrierInputCtrl.dispose();
    _carrierFocusNode.dispose();
    _customerNameCtrl.dispose();
    _salesOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveShipment() async {
    setState(() {
      _shipmentOrderError = _shipmentOrderCtrl.text.trim().isEmpty ? 'Shipment Order# is required' : null;
      _dateError = _selectedDate == null ? 'Ship Date is required' : null;
      _carrierError = _carrierInputCtrl.text.trim().isEmpty ? 'Carrier is required' : null;
    });

    if (_shipmentOrderError != null || _dateError != null || _carrierError != null) {
      ZerpaiToast.error(context, 'Please fill all mandatory fields.');
      return;
    }

    final supabase = Supabase.instance.client;

    try {
      String? fullDeliveredDate;
      if (_selectedDeliveredDate != null) {
        if (_selectedTime != null) {
          final parts = _selectedTime!.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final combined = DateTime(
            _selectedDeliveredDate!.year,
            _selectedDeliveredDate!.month,
            _selectedDeliveredDate!.day,
            hour,
            minute,
          );
          fullDeliveredDate = combined.toIso8601String();
        } else {
          fullDeliveredDate = _selectedDeliveredDate!.toIso8601String();
        }
      }

      await supabase.from('inventory_shipments').update({
        'shipment_number': _shipmentOrderCtrl.text,
        'date': _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null,
        'delivered_date': fullDeliveredDate,
        'carrier': _carrierInputCtrl.text,
        'tracking_number': _trackingCtrl.text,
        'tracking_url': _trackingUrlCtrl.text,
        'shipping_charges': double.tryParse(_shippingChargesCtrl.text) ?? 0.0,
        'notes': _notesCtrl.text,
        'is_delivered': _isDelivered,
        'send_notification': _sendStatusNotification,
      }).eq('id', widget.shipmentId);

      // Delete existing packages
      await supabase.from('inventory_shipment_packages').delete().eq('shipment_id', widget.shipmentId);

      // Insert new packages
      final packagesState = ref.read(inventoryPackagesProvider);
      final packages = packagesState.packages;
      
      final selectedPackageObjs = packages.where((p) => _selectedPackages.contains(p.packageNumber)).toList();
      
      final packageInserts = selectedPackageObjs.map((p) => {
        'shipment_id': widget.shipmentId,
        'package_id': p.id,
      }).toList();

      if (packageInserts.isNotEmpty) {
        await supabase.from('inventory_shipment_packages').insert(packageInserts);
      }

      ZerpaiToast.success(context, 'Shipment updated successfully!');
      context.go('/inventory/shipments/${widget.shipmentId}');
    } catch (e) {
      ZerpaiToast.error(context, 'Error updating shipment: $e');
    }
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
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(
          color: isHovered ? _focusBorder : _borderCol,
          width: isHovered ? 1.4 : 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(
          color: _focusBorder,
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final packagesState = ref.watch(inventoryPackagesProvider);
    final packages = packagesState.packages;
    final packageNumbers = packages.map((p) => p.packageNumber).toList();

    return ZerpaiLayout(
      pageTitle: '', 
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
                  'Edit Shipment',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    context.go('/inventory/shipments/${widget.shipmentId}');
                  },
                  icon: const Icon(LucideIcons.x, size: 20, color: _textSecondary),
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
                              child: CustomTextField(
                                controller: _customerNameCtrl,
                                height: 32,
                                readOnly: true,
                                fillColor: AppTheme.bgDisabled,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildFormRow(
                              label: 'Sales Order#',
                              child: CustomTextField(
                                controller: _salesOrderCtrl,
                                height: 32,
                                readOnly: true,
                                fillColor: AppTheme.bgDisabled,
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
                          MouseRegion(
                            onEnter: (_) => _onHover('package', true),
                            onExit: (_) => _onHover('package', false),
                            child: SizedBox(
                              width: 380,
                              child: _buildFormRow(
                                label: 'Package#',
                                isRequired: true,
                                hasError: _packageError != null,
                                child: FormDropdown<String>(
                                  value: null,
                                  selectedValues: _selectedPackages,
                                  multiSelect: true,
                                  maxVisibleItems: 4,
                                  isHovered: _hoveredFields.contains('package'),
                                  hideSelectedItemsInMultiSelect: true,
                                  items: packageNumbers,
                                  hint: 'Select Package',
                                  showSearch: true,
                                  onChanged: (_) {},
                                  onSelectedValuesChanged: (vals) {
                                    setState(() {
                                      _packageError = null;
                                      _selectedPackages = vals;
                                    });
                                  },
                                  height: 32,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Shipment Order#
                          MouseRegion(
                            onEnter: (_) => _onHover('shipmentOrder', true),
                            onExit: (_) => _onHover('shipmentOrder', false),
                            child: SizedBox(
                              width: 380,
                              child: _buildFormRow(
                                label: 'Shipment Order#',
                                isRequired: true,
                                hasError: _shipmentOrderError != null,
                                child: CustomTextField(
                                  controller: _shipmentOrderCtrl,
                                  height: 32,
                                  readOnly: true, // Usually read-only in edit
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Ship Date
                          MouseRegion(
                            onEnter: (_) => _onHover('shipDate', true),
                            onExit: (_) => _onHover('shipDate', false),
                            child: SizedBox(
                              width: 380,
                              child: _buildFormRow(
                                label: 'Ship Date',
                                isRequired: true,
                                hasError: _dateError != null,
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
                                        _dateError = null;
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

                          // Carrier and Tracking#
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
                                    hasError: _carrierError != null,
                                    child: FormDropdown<String>(
                                      fillColor: Colors.white,
                                      value: _carrierInputCtrl.text.isEmpty ? null : _carrierInputCtrl.text,
                                      height: 32,
                                      hint: 'Type or Select Carrier',
                                      items: _carriers,
                                      maxVisibleItems: 4,
                                      displayStringForValue: (val) => val,
                                      searchStringForValue: (val) => val,
                                      onChanged: (val) {
                                        setState(() {
                                          _carrierInputCtrl.text = val ?? '';
                                          _carrierError = null;
                                        });
                                      },
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
                                      onChanged: (_) => setState(() {}),
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
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Shipping Charges
                          MouseRegion(
                            onEnter: (_) => _onHover('shippingCharges', true),
                            onExit: (_) => _onHover('shippingCharges', false),
                            child: SizedBox(
                              width: 380,
                              child: _buildFormRow(
                                label: 'Shipping Charges',
                                child: CustomTextField(
                                  controller: _shippingChargesCtrl,
                                  height: 32,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                  onChanged: (_) => setState(() {}),
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
                                  onChanged: (_) => setState(() {}),
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
                                style: TextStyle(fontSize: 13, color: _textPrimary, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
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
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: _textPrimary, fontFamily: 'Inter'),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 400,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _borderCol),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextField(
                                          controller: _deliveredDateCtrl,
                                          height: 36,
                                          readOnly: true,
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
                                          suffixWidget: const Icon(LucideIcons.calendar, size: 16, color: _textSecondary),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 18,
                                        child: VerticalDivider(
                                          width: 1,
                                          thickness: 1,
                                          color: _borderCol,
                                        ),
                                      ),
                                      Expanded(
                                        child: MouseRegion(
                                          onEnter: (_) => _onHover('delTime', true),
                                          onExit: (_) => _onHover('delTime', false),
                                          child: FormDropdown<String>(
                                            value: _selectedTime,
                                            items: _times,
                                            height: 36,
                                            isHovered: _hoveredFields.contains('delTime'),
                                            hint: 'HH:MM',
                                            maxVisibleItems: 5,
                                            hideBorderDefault: true,
                                            onChanged: (val) {
                                              setState(() => _selectedTime = val);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                  onPressed: _isDirty ? _saveShipment : null,
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
                  onPressed: () {
                    context.go('/inventory/shipments/${widget.shipmentId}');
                  },
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
    bool hasError = false,
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
                      color: (isRequired || hasError) ? _dangerRed : _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (isRequired)
                    const Text(' *', style: TextStyle(color: _dangerRed, fontSize: 13, fontFamily: 'Inter')),
                ],
              ),
              if (subLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subLabel, style: const TextStyle(fontSize: 11, color: _textSecondary, fontFamily: 'Inter')),
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
