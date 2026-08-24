import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/inputs/dropdown_input.dart';
import '../../../../../shared/widgets/inputs/zerpai_date_picker.dart';
import '../../../../../shared/widgets/zerpai_layout.dart';
import '../../../../../shared/widgets/inputs/z_tooltip.dart';
import '../../../../../shared/widgets/inputs/custom_text_field.dart';
import '../../../../../shared/widgets/skeleton.dart';
import '../../../../../core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/inventory/packages/models/inventory_package_model.dart';
import 'package:zerpai_erp/modules/inventory/packages/providers/inventory_packages_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/providers/entity_provider.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_list_dialog.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'inventory_shipments_list.dart';
import 'package:zerpai_erp/core/services/api_client.dart';

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
  final String? salesOrderId;
  const InventoryShipmentsCreateScreen({super.key, this.salesOrderId});

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
  final TextEditingController _carrierInputCtrl = TextEditingController();
  final FocusNode _carrierFocusNode = FocusNode();

  SalesCustomer? _selectedCustomer;
  List<String> _selectedSalesOrders = []; // Changed to list
  List<String> _selectedPackages = []; // Changed to list
  String? _selectedTime;

  List<SalesOrder> _selectedSalesOrdersData = []; // Changed to list

  DateTime? _selectedDate;
  DateTime? _selectedDeliveredDate;
  final GlobalKey _dateFieldKey = GlobalKey();
  final GlobalKey _deliveredDateFieldKey = GlobalKey();

  bool _isDelivered = false;
  bool _sendStatusNotification = false;

  bool _isAutoGenerate = true;
  String _shipmentPrefix = 'SHP-';
  int _nextNumber = 1;

  List<Map<String, dynamic>> _carriersList = [];
  late final List<String> _times;

  String? _customerError;
  String? _salesOrderError;
  String? _packageError;
  String? _shipmentOrderError;
  String? _dateError;
  String? _carrierError;
  String? _initialPackageId;
  bool _initialPrefillApplied = false;

  bool get _isSalesOrderSelected => _selectedSalesOrders.isNotEmpty;

  Widget _commonItemBuilder<T>(
    T item,
    bool isSelected,
    bool isHovered,
    String Function(T) displayFn,
  ) {
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

  Widget _buildCustomerDropdownItem(
    SalesCustomer customer,
    bool isSelected,
    bool isHovered,
  ) {
    final customerNumber = (customer.customerNumber ?? '').trim();
    final email = (customer.email ?? '').trim();
    final companyName = (customer.companyName ?? '').trim();
    final firstName = (customer.firstName ?? '').trim();

    final topLine = customerNumber.isEmpty
        ? customer.displayName
        : '${customer.displayName} | $customerNumber';

    final List<String> bottomParts = [];
    if (email.isNotEmpty) bottomParts.add(email);
    if (companyName.isNotEmpty) bottomParts.add(companyName);
    final bottomLine = bottomParts.join(' | ');

    final initialSource = firstName.isNotEmpty
        ? firstName
        : (customer.displayName.isNotEmpty ? customer.displayName : '?');
    final initial = initialSource.substring(0, 1).toUpperCase();

    final backgroundColor = isHovered
        ? const Color(0xFF3B82F6)
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.white);
    final primaryTextColor = isHovered ? Colors.white : _textPrimary;
    final secondaryTextColor = isHovered
        ? Colors.white.withValues(alpha: 0.85)
        : _textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              textAlign: TextAlign.center,
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1,
                color: isHovered ? Colors.white : const Color(0xFF64748B),
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                    fontFamily: 'Inter',
                  ),
                ),
                if (bottomLine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    bottomLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: secondaryTextColor,
                      fontFamily: 'Inter',
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

  Future<void> _loadCarriers() async {
    try {
      final lookupsService = LookupsApiService();
      final carriers = await lookupsService.getShipmentPreferences();
      if (mounted) {
        setState(() {
          _carriersList = carriers;
        });
      }
    } catch (e) {
      debugPrint('Error loading carriers: $e');
    }
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
    _selectedDate = DateTime.now();
    _deliveredDateCtrl.text = 'dd-MM-yyyy';
    _shippingChargesCtrl.text = '';
    _isDelivered = false;
    _sendStatusNotification = true;
    _shipmentOrderCtrl.text =
        '$_shipmentPrefix${_nextNumber.toString().padLeft(5, '0')}';
    _loadCarriers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialPackageId = GoRouterState.of(
        context,
      ).uri.queryParameters['packageId'];
      ref.read(inventoryPackagesProvider.notifier).fetchPackages();
      _fetchNextShipmentNumber();
      if (widget.salesOrderId != null) {
        _loadPrefilledSalesOrderData();
      }
    });
  }

  Future<void> _loadPrefilledSalesOrderData() async {
    if (widget.salesOrderId == null || _initialPrefillApplied) return;
    try {
      final response = await ref
          .read(apiClientProvider)
          .get('/sales/${widget.salesOrderId}');
      if (response.statusCode == 200 && response.data != null) {
        final payload = response.data['data'] ?? response.data;
        final order = SalesOrder.fromJson(payload);
        if (order.customer != null && mounted) {
          setState(() {
            _selectedCustomer = order.customer;
            _selectedSalesOrders = [order.saleNumber];
            _selectedSalesOrdersData = [order];
          });
        }
      }
    } catch (e) {
      debugPrint('Error prefilling shipment data: $e');
    }
  }

  void _tryApplyInitialPackagePrefill(
    List<InventoryPackage> packages,
    List<SalesCustomer> customers,
  ) {
    if (_initialPrefillApplied) return;

    if (widget.salesOrderId != null) {
      final matchedPkgs = packages
          .where((p) => p.salesOrderIds.contains(widget.salesOrderId))
          .toList();
      if (matchedPkgs.isNotEmpty) {
        final selectedCustomer = customers.cast<SalesCustomer?>().firstWhere(
          (c) => c?.id == matchedPkgs.first.customerId,
          orElse: () => null,
        );
        if (selectedCustomer != null) {
          _initialPrefillApplied = true;
          setState(() {
            _selectedCustomer = selectedCustomer;
            _selectedPackages = matchedPkgs
                .map((p) => p.packageNumber)
                .toList();
            _selectedSalesOrders = matchedPkgs
                .expand((p) => p.salesOrderNumbers)
                .toSet()
                .toList();
          });
          return;
        }
      }
    }

    final packageId = _initialPackageId;
    if (packageId == null || packageId.isEmpty) return;

    final selectedPkg = packages.cast<InventoryPackage?>().firstWhere(
      (p) => p?.id == packageId,
      orElse: () => null,
    );
    if (selectedPkg == null) return;

    final selectedCustomer = customers.cast<SalesCustomer?>().firstWhere(
      (c) => c?.id == selectedPkg.customerId,
      orElse: () => null,
    );
    if (selectedCustomer == null) return;

    _initialPrefillApplied = true;
    setState(() {
      _selectedCustomer = selectedCustomer;
      _selectedPackages = [selectedPkg.packageNumber];
      _selectedSalesOrders = selectedPkg.salesOrderNumbers.toSet().toList();
    });
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
    super.dispose();
  }

  Future<void> _fetchNextShipmentNumber() async {
    print('[_fetchNextShipmentNumber] Started');
    final entityId = ref.read(entityProvider).entityId;
    print('[_fetchNextShipmentNumber] entityId: $entityId');

    final supabase = Supabase.instance.client;
    try {
      print(
        '[_fetchNextShipmentNumber] Querying Supabase with prefix: $_shipmentPrefix%',
      );
      final response = await supabase
          .from('inventory_shipments')
          .select('shipment_number')
          .like('shipment_number', '$_shipmentPrefix%')
          .order('shipment_number', ascending: false)
          .limit(1)
          .maybeSingle();

      print('[_fetchNextShipmentNumber] Response: $response');

      if (response != null) {
        final latestNumber = response['shipment_number'] as String;
        final match = RegExp(r'\d+$').firstMatch(latestNumber);
        print('[_fetchNextShipmentNumber] Match: ${match?.group(0)}');
        if (match != null) {
          final numberStr = match.group(0)!;
          final number = int.tryParse(numberStr) ?? 0;
          setState(() {
            _nextNumber = number + 1;
            _shipmentOrderCtrl.text =
                '$_shipmentPrefix${_nextNumber.toString().padLeft(5, '0')}';
            print(
              '[_fetchNextShipmentNumber] Updated text to: ${_shipmentOrderCtrl.text}',
            );
          });
        }
      } else {
        print('[_fetchNextShipmentNumber] No record found');
      }
    } catch (e) {
      print('[_fetchNextShipmentNumber] Error: $e');
    }
  }

  Future<void> _saveShipment() async {
    var entityId = ref.read(entityProvider).entityId;
    if (entityId == null) {
      // Try to get from authUserProvider
      final user = ref.read(authUserProvider);
      entityId = user?.orgEntityId;
    }

    if (entityId == null) {
      // Fallback: Fetch the first entity from the database
      try {
        final response = await Supabase.instance.client
            .from('organisation_branch_master')
            .select('id')
            .limit(1)
            .maybeSingle();
        if (response != null) {
          entityId = response['id'] as String?;
        }
      } catch (_) {
        // Ignore DB error and proceed to check null
      }
    }

    if (entityId == null) {
      ZerpaiToast.error(context, 'Entity ID not found. Please try again.');
      return;
    }

    setState(() {
      _customerError = _selectedCustomer == null
          ? 'Please select a customer'
          : null;
      _salesOrderError = _selectedSalesOrders.isEmpty
          ? 'Please select at least one sales order'
          : null;
      _packageError = _selectedPackages.isEmpty
          ? 'Please select at least one package'
          : null;
      _shipmentOrderError = _shipmentOrderCtrl.text.trim().isEmpty
          ? 'Shipment Order# is required'
          : null;
      _dateError = _selectedDate == null ? 'Ship Date is required' : null;
      _carrierError = _carrierInputCtrl.text.trim().isEmpty
          ? 'Carrier is required'
          : null;
    });

    if (_customerError != null ||
        _salesOrderError != null ||
        _packageError != null ||
        _shipmentOrderError != null ||
        _dateError != null ||
        _carrierError != null) {
      String errorMsg = 'Please fill all mandatory fields.';
      if (_customerError != null)
        errorMsg = _customerError!;
      else if (_salesOrderError != null)
        errorMsg = _salesOrderError!;
      else if (_packageError != null)
        errorMsg = _packageError!;
      else if (_shipmentOrderError != null)
        errorMsg = _shipmentOrderError!;
      else if (_dateError != null)
        errorMsg = _dateError!;
      else if (_carrierError != null)
        errorMsg = _carrierError!;

      ZerpaiToast.error(context, errorMsg);
      return;
    }

    final supabase = Supabase.instance.client;

    try {
      // 1. Insert shipment header
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

      final shipmentResponse = await supabase
          .from('inventory_shipments')
          .insert({
            'entity_id': entityId,
            'shipment_number': _shipmentOrderCtrl.text,
            'customer_id': _selectedCustomer!.id,
            'date': _selectedDate != null
                ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                : DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'delivered_date': fullDeliveredDate,
            'carrier': _carrierInputCtrl.text,
            'tracking_number': _trackingCtrl.text,
            'tracking_url': _trackingUrlCtrl.text,
            'shipping_charges':
                double.tryParse(_shippingChargesCtrl.text) ?? 0.0,
            'notes': _notesCtrl.text,
            'is_delivered': _isDelivered,
            'send_notification': _sendStatusNotification,
            'is_delete': false,
          })
          .select('id')
          .single();

      final shipmentId = shipmentResponse['id'] as String;

      // 2. Insert into inventory_shipment_sales_orders
      final soInserts = _selectedSalesOrdersData
          .map((so) => {'shipment_id': shipmentId, 'sales_order_id': so.id})
          .toList();

      await supabase.from('inventory_shipment_sales_orders').insert(soInserts);

      // 3. Insert into inventory_shipment_packages
      final packagesState = ref.read(inventoryPackagesProvider);
      final packages = packagesState.packages;

      final selectedPackageObjs = packages
          .where((p) => _selectedPackages.contains(p.packageNumber))
          .toList();

      final packageInserts = selectedPackageObjs
          .map((p) => {'shipment_id': shipmentId, 'package_id': p.id})
          .toList();

      await supabase.from('inventory_shipment_packages').insert(packageInserts);

      // Update package status to Shipped in the database
      final packageIds = selectedPackageObjs
          .map((p) => p.id)
          .whereType<String>()
          .toList();
      if (packageIds.isNotEmpty) {
        await supabase
            .from('inventory_packages')
            .update({'status': 'Shipped'})
            .inFilter('id', packageIds);
      }

      ZerpaiToast.success(context, 'Shipment saved successfully!');
      ref.invalidate(shipmentsProvider);
      ref.invalidate(inventoryPackagesProvider);
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/inventory/shipments');
      }
    } catch (e) {
      ZerpaiToast.error(context, 'Error saving shipment: $e');
    }
  }

  void _showManageCarriersDialog() {
    showDialog(
      context: context,
      builder: (context) => ManageListDialog(
        title: 'Manage Carriers',
        singularLabel: 'Carrier',
        headerLabel: 'Carrier',
        items: _carriersList,
        selectedId: _carriersList
            .firstWhere(
              (c) => c['name'] == _carrierInputCtrl.text,
              orElse: () => <String, dynamic>{},
            )['id']
            ?.toString(),
        onSelect: (value) {
          if (value is Map<String, dynamic>) {
            setState(() {
              _carrierInputCtrl.text = value['name'] ?? '';
              _carrierError = null;
            });
          } else if (value is String) {
            setState(() {
              _carrierInputCtrl.text = value;
              _carrierError = null;
            });
          }
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncShipmentPreferences(items);
          if (mounted) {
            setState(() {
              _carriersList = updated;
            });
          }
          return updated;
        },
        onDeleteCheck: (item) async {
          if (item['id'] == null || item['id'].toString().startsWith('new_')) {
            return null;
          }
          try {
            final lookupsService = LookupsApiService();
            final usage = await lookupsService.checkLookupUsage(
              'shipment-preferences',
              item['id'].toString(),
            );
            if (usage['inUse'] == true) {
              return usage['message'] ??
                  'This carrier is in use and cannot be deleted.';
            }
          } catch (e) {
            debugPrint('Error checking carrier usage: $e');
          }
          return null;
        },
      ),
    );
  }

  void _showShipmentPreferencesDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ShipmentPreferencesDialog(
        initialAutoGenerate: _isAutoGenerate,
        initialPrefix: _shipmentPrefix,
        initialNextNumber: _nextNumber,
        onSave: (isAuto, prefix, nextNum) {
          setState(() {
            _isAutoGenerate = isAuto;
            _shipmentPrefix = prefix;
            _nextNumber = nextNum;
            if (_isAutoGenerate) {
              _shipmentOrderCtrl.text =
                  '$_shipmentPrefix${_nextNumber.toString().padLeft(5, '0')}';
            } else {
              _shipmentOrderCtrl.clear();
            }
          });
        },
      ),
    );
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
          width: isHovered
              ? AppTheme.inputActiveBorderWidth
              : AppTheme.inputBorderWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(
          color: _focusBorder,
          width: AppTheme.inputActiveBorderWidth,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final packagesState = ref.watch(inventoryPackagesProvider);
    final packages = packagesState.packages;

    final filteredPackages = _selectedCustomer != null
        ? packages.where((p) => p.customerId == _selectedCustomer!.id).toList()
        : packages;

    final packageNumbers = filteredPackages
        .map((p) => p.packageNumber)
        .toList();

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
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/inventory/shipments');
                    }
                  },
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
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
                              isRequired: true,
                              hasError: _customerError != null,
                              child: ref
                                  .watch(salesCustomersProvider)
                                  .when(
                                    data: (customers) {
                                      _tryApplyInitialPackagePrefill(
                                        packages,
                                        customers,
                                      );
                                      return FormDropdown<SalesCustomer>(
                                        fillColor: Colors.white,
                                        value: _selectedCustomer,
                                        height: 32,
                                        hint: 'Select Customer',
                                        items: customers,
                                        maxVisibleItems: 4,
                                        textStyle: const TextStyle(
                                          color: _textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Inter',
                                        ),
                                        itemBuilder:
                                            (item, isSelected, isHovered) =>
                                                _buildCustomerDropdownItem(
                                                  item,
                                                  isSelected,
                                                  isHovered,
                                                ),
                                        displayStringForValue: (val) =>
                                            val.displayName,
                                        searchStringForValue: (val) =>
                                            val.displayName,
                                        onChanged: (val) {
                                          setState(() {
                                            _initialPrefillApplied = true;
                                            _selectedCustomer = val;
                                            _selectedSalesOrders = [];
                                            _selectedSalesOrdersData = [];
                                            _selectedPackages = [];
                                          });
                                        },
                                      );
                                    },
                                    loading: () => const Skeleton(
                                      height: 32,
                                      width: double.infinity,
                                    ),
                                    error: (e, _) => Text('Error: $e'),
                                  ),
                            ),
                            const SizedBox(height: 20),
                            _buildFormRow(
                              label: 'Sales Order#',
                              isRequired: true,
                              hasError: _salesOrderError != null,
                              child: _selectedCustomer == null
                                  ? FormDropdown<String>(
                                      fillColor: AppTheme.bgDisabled,
                                      value: null,
                                      hint: 'Select Sales Order',
                                      items: const [],
                                      itemBuilder:
                                          (item, isSelected, isHovered) =>
                                              _commonItemBuilder<String>(
                                                item,
                                                isSelected,
                                                isHovered,
                                                (s) => s,
                                              ),
                                      displayStringForValue: (s) => s,
                                      searchStringForValue: (s) => s,
                                      onChanged: (val) {},
                                      height: 32,
                                      textStyle: const TextStyle(
                                        color: _textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Inter',
                                      ),
                                    )
                                  : ref
                                        .watch(
                                          salesOrdersByCustomerProvider(
                                            _selectedCustomer!.id,
                                          ),
                                        )
                                        .when(
                                          data: (orders) {
                                            if (_selectedSalesOrders
                                                    .isNotEmpty &&
                                                _selectedSalesOrdersData
                                                    .isEmpty) {
                                              _selectedSalesOrdersData = orders
                                                  .where(
                                                    (o) => _selectedSalesOrders
                                                        .contains(o.saleNumber),
                                                  )
                                                  .toList();
                                            }
                                            return FormDropdown<String>(
                                              fillColor: Colors.white,
                                              value: null,
                                              selectedValues:
                                                  _selectedSalesOrders,
                                              multiSelect: true,
                                              hint: 'Select Sales Order',
                                              items: orders
                                                  .map((o) => o.saleNumber)
                                                  .where(
                                                    (num) =>
                                                        !_selectedSalesOrders
                                                            .contains(num),
                                                  )
                                                  .toList(),
                                              maxVisibleItems: 4,
                                              itemBuilder:
                                                  (
                                                    item,
                                                    isSelected,
                                                    isHovered,
                                                  ) =>
                                                      _commonItemBuilder<
                                                        String
                                                      >(
                                                        item,
                                                        isSelected,
                                                        isHovered,
                                                        (val) => val,
                                                      ),
                                              displayStringForValue: (val) =>
                                                  val,
                                              searchStringForValue: (val) =>
                                                  val,
                                              onChanged: (_) {},
                                              onSelectedValuesChanged: (vals) {
                                                setState(() {
                                                  _salesOrderError = null;
                                                  _selectedSalesOrders = vals;
                                                  _selectedSalesOrdersData =
                                                      orders
                                                          .where(
                                                            (o) =>
                                                                vals.contains(
                                                                  o.saleNumber,
                                                                ),
                                                          )
                                                          .toList();
                                                });
                                              },
                                              height: 32,
                                              textStyle: const TextStyle(
                                                color: _textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                fontFamily: 'Inter',
                                              ),
                                            );
                                          },
                                          loading: () => const Skeleton(
                                            height: 32,
                                            width: double.infinity,
                                          ),
                                          error: (e, _) => Text('Error: $e'),
                                        ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          // Info Banner
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFFFEDD5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.info,
                                  size: 18,
                                  color: Color(0xFFC2410C),
                                ),
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
                                        hasError: _packageError != null,
                                        child: FormDropdown<String>(
                                          value: null,
                                          selectedValues: _selectedPackages,
                                          multiSelect: true,
                                          maxVisibleItems:
                                              4, // Dynamic height for 4 items
                                          isHovered: _hoveredFields.contains(
                                            'package',
                                          ),
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

                                  // Shipment Order# (Single Row)
                                  MouseRegion(
                                    onEnter: (_) =>
                                        _onHover('shipmentOrder', true),
                                    onExit: (_) =>
                                        _onHover('shipmentOrder', false),
                                    child: SizedBox(
                                      width: 380,
                                      child: _buildFormRow(
                                        label: 'Shipment Order#',
                                        isRequired: true,
                                        hasError: _shipmentOrderError != null,
                                        child: CustomTextField(
                                          controller: _shipmentOrderCtrl,
                                          height: 32,
                                          readOnly: _isAutoGenerate,
                                          onChanged: (_) {
                                            if (_shipmentOrderError != null) {
                                              setState(() {
                                                _shipmentOrderError = null;
                                              });
                                            }
                                          },
                                          suffixWidget: ZTooltip(
                                            message:
                                                'Click here to enable or disable auto-generation of Shipment numbers.',
                                            child: InkWell(
                                              onTap:
                                                  _showShipmentPreferencesDialog,
                                              child: const Icon(
                                                LucideIcons.settings,
                                                size: 16,
                                                color: Color(0xFF0088FF),
                                              ),
                                            ),
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
                                        hasError: _dateError != null,
                                        child: CustomTextField(
                                          controller: _dateCtrl,
                                          height: 32,
                                          readOnly: true,
                                          onTap: () async {
                                            final picked =
                                                await ZerpaiDatePicker.show(
                                                  context,
                                                  initialDate:
                                                      _selectedDate ??
                                                      DateTime.now(),
                                                  targetKey: _dateFieldKey,
                                                );
                                            if (picked != null && mounted) {
                                              setState(() {
                                                _dateError = null;
                                                _selectedDate = picked;
                                                _dateCtrl.text = DateFormat(
                                                  'dd-MM-yyyy',
                                                ).format(picked);
                                              });
                                            }
                                          },
                                          suffixWidget: const Icon(
                                            LucideIcons.calendar,
                                            size: 16,
                                            color: _textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Row: Carrier and Tracking#
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      MouseRegion(
                                        onEnter: (_) =>
                                            _onHover('carrier', true),
                                        onExit: (_) =>
                                            _onHover('carrier', false),
                                        child: SizedBox(
                                          width: 380,
                                          child: _buildFormRow(
                                            label: 'Carrier',
                                            isRequired: true,
                                            hasError: _carrierError != null,
                                            child: FormDropdown<String>(
                                              fillColor: Colors.white,
                                              value:
                                                  _carrierInputCtrl.text.isEmpty
                                                  ? null
                                                  : _carrierInputCtrl.text,
                                              height: 32,
                                              hint: 'Type or Select Carrier',
                                              items: _carriersList
                                                  .map(
                                                    (c) =>
                                                        c['name']?.toString() ??
                                                        '',
                                                  )
                                                  .where((n) => n.isNotEmpty)
                                                  .toList(),
                                              allowCustomValue: true,
                                              maxVisibleItems: 4,
                                              showSettings: true,
                                              settingsLabel: 'New Carrier',
                                              settingsIcon: Icons.add,
                                              onSettingsTap:
                                                  _showManageCarriersDialog,
                                              displayStringForValue: (val) =>
                                                  val,
                                              searchStringForValue: (val) =>
                                                  val,
                                              onChanged: (val) {
                                                setState(() {
                                                  _carrierError = null;
                                                  _carrierInputCtrl.text =
                                                      val ?? '';
                                                });
                                              },
                                              textStyle: const TextStyle(
                                                color: _textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 32),
                                      MouseRegion(
                                        onEnter: (_) =>
                                            _onHover('tracking', true),
                                        onExit: (_) =>
                                            _onHover('tracking', false),
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
                                    onEnter: (_) =>
                                        _onHover('trackingUrl', true),
                                    onExit: (_) =>
                                        _onHover('trackingUrl', false),
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
                                    onEnter: (_) =>
                                        _onHover('shippingCharges', true),
                                    onExit: (_) =>
                                        _onHover('shippingCharges', false),
                                    child: SizedBox(
                                      width: 380,
                                      child: _buildFormRow(
                                        label: 'Shipping Charges',
                                        child: Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              height: 32,
                                              alignment: Alignment.center,
                                              decoration: const BoxDecoration(
                                                color: AppTheme.bgDisabled,
                                                border: Border(
                                                  top: BorderSide(
                                                    color: _borderCol,
                                                  ),
                                                  bottom: BorderSide(
                                                    color: _borderCol,
                                                  ),
                                                  left: BorderSide(
                                                    color: _borderCol,
                                                  ),
                                                  right: BorderSide(
                                                    color: _borderCol,
                                                  ),
                                                ),
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(4),
                                                  bottomLeft: Radius.circular(
                                                    4,
                                                  ),
                                                ),
                                              ),
                                              child: const Text(
                                                'INR',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: _textSecondary,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(
                                                    color:
                                                        _hoveredFields.contains(
                                                          'shippingCharges',
                                                        )
                                                        ? _focusBorder
                                                        : _borderCol,
                                                    width:
                                                        _hoveredFields.contains(
                                                          'shippingCharges',
                                                        )
                                                        ? 1.4
                                                        : 1.0,
                                                  ),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                        topRight:
                                                            Radius.circular(4),
                                                        bottomRight:
                                                            Radius.circular(4),
                                                      ),
                                                ),
                                                child: TextField(
                                                  controller:
                                                      _shippingChargesCtrl,
                                                  textAlign: TextAlign.right,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.allow(
                                                      RegExp(r'[0-9.]'),
                                                    ),
                                                  ],
                                                  onChanged: (value) {
                                                    setState(() {});
                                                  },
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontFamily: 'Inter',
                                                  ),
                                                  decoration:
                                                      const InputDecoration(
                                                        isDense: true,
                                                        hintText: '0.00',
                                                        hintStyle: TextStyle(
                                                          color: _textSecondary,
                                                          fontSize: 13,
                                                        ),
                                                        filled: false,
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 8,
                                                            ),
                                                        border:
                                                            InputBorder.none,
                                                        enabledBorder:
                                                            InputBorder.none,
                                                        focusedBorder:
                                                            InputBorder.none,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
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
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: _textPrimary,
                                            fontFamily: 'Inter',
                                          ),
                                          decoration: _standardInputDecoration(
                                            isHovered: _hoveredFields.contains(
                                              'notes',
                                            ),
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
                                          onChanged: (val) => setState(
                                            () => _isDelivered = val ?? false,
                                          ),
                                          activeColor: const Color(0xFF3B82F6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          width: 400,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: _borderCol,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: MouseRegion(
                                                  onEnter: (_) =>
                                                      _onHover('delDate', true),
                                                  onExit: (_) => _onHover(
                                                    'delDate',
                                                    false,
                                                  ),
                                                  child: TextField(
                                                    controller:
                                                        _deliveredDateCtrl,
                                                    key: _deliveredDateFieldKey,
                                                    readOnly: true,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontFamily: 'Inter',
                                                      color: _textPrimary,
                                                    ),
                                                    onTap: () async {
                                                      final picked =
                                                          await ZerpaiDatePicker.show(
                                                            context,
                                                            initialDate:
                                                                _selectedDeliveredDate ??
                                                                DateTime.now(),
                                                            targetKey:
                                                                _deliveredDateFieldKey,
                                                          );
                                                      if (picked != null &&
                                                          mounted) {
                                                        setState(() {
                                                          _selectedDeliveredDate =
                                                              picked;
                                                          _deliveredDateCtrl
                                                                  .text =
                                                              DateFormat(
                                                                'dd-MM-yyyy',
                                                              ).format(picked);
                                                        });
                                                      }
                                                    },
                                                    decoration:
                                                        const InputDecoration(
                                                          isDense: true,
                                                          hintText:
                                                              'dd-MM-yyyy',
                                                          hintStyle: TextStyle(
                                                            color:
                                                                _textSecondary,
                                                            fontSize: 13,
                                                          ),
                                                          border:
                                                              InputBorder.none,
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 6,
                                                              ),
                                                          suffixIcon: Icon(
                                                            LucideIcons
                                                                .calendar,
                                                            size: 16,
                                                            color:
                                                                _textSecondary,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 18,
                                                child: const VerticalDivider(
                                                  width: 1,
                                                  thickness: 1,
                                                  color: _borderCol,
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: MouseRegion(
                                                  onEnter: (_) =>
                                                      _onHover('delTime', true),
                                                  onExit: (_) => _onHover(
                                                    'delTime',
                                                    false,
                                                  ),
                                                  child: FormDropdown<String>(
                                                    value: _selectedTime,
                                                    items: _times,
                                                    height: 30,
                                                    isHovered: _hoveredFields
                                                        .contains('delTime'),
                                                    hint: 'HH:MM',
                                                    maxVisibleItems: 5,
                                                    hideBorderDefault: true,
                                                    onChanged: (val) {
                                                      setState(
                                                        () =>
                                                            _selectedTime = val,
                                                      );
                                                    },
                                                    prefixWidget: const Icon(
                                                      LucideIcons.clock,
                                                      size: 16,
                                                      color: _textSecondary,
                                                    ),
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
                                          onChanged: (val) => setState(
                                            () => _sendStatusNotification =
                                                val ?? false,
                                          ),
                                          activeColor: const Color(0xFF3B82F6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
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
                                      const Icon(
                                        LucideIcons.alertTriangle,
                                        size: 14,
                                        color: _dangerRed,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    width: 750,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
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
                  onPressed: _saveShipment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _greenBtn,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/inventory/shipments');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textPrimary,
                    side: const BorderSide(color: _borderCol),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
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
      crossAxisAlignment: subLabel != null
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
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
                      color: (isRequired || hasError)
                          ? _dangerRed
                          : _textPrimary,
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

class _ShipmentPreferencesDialog extends StatefulWidget {
  final bool initialAutoGenerate;
  final String initialPrefix;
  final int initialNextNumber;
  final void Function(bool isAuto, String prefix, int nextNum) onSave;

  const _ShipmentPreferencesDialog({
    required this.initialAutoGenerate,
    required this.initialPrefix,
    required this.initialNextNumber,
    required this.onSave,
  });

  @override
  State<_ShipmentPreferencesDialog> createState() =>
      __ShipmentPreferencesDialogState();
}

class __ShipmentPreferencesDialogState
    extends State<_ShipmentPreferencesDialog> {
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
      child: Container(
        width: 500,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Configure Shipment Order# Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 20,
                      color: Color(0xFFEF4444),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: borderCol),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your shipment numbers are set on auto-generate mode to save your time.',
                    style: TextStyle(fontSize: 14, color: textPrimary),
                  ),
                  const Text(
                    'Are you sure about changing this setting?',
                    style: TextStyle(fontSize: 14, color: textPrimary),
                  ),
                  const SizedBox(height: 24),

                  // Auto generate option
                  InkWell(
                    onTap: () => setState(() => _isAuto = true),
                    child: Row(
                      children: [
                        RadioGroup<bool>(
                          groupValue: _isAuto,
                          onChanged: (val) => setState(() => _isAuto = val!),
                          child: Radio<bool>(
                            value: true,
                            activeColor: const Color(0xFF3B82F6),
                          ),
                        ),
                        const Text(
                          'Continue auto-generating shipment numbers',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const ZTooltip(
                          message:
                              'The edited prefix and next number will be updated in the transaction number series associated with your shipment.',
                          direction: ZTooltipDirection.top,
                          child: Icon(
                            LucideIcons.info,
                            size: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_isAuto) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 48, top: 12),
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
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _prefixCtrl,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: borderCol,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: borderCol,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
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
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _numberCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: borderCol,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: borderCol,
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

                  const SizedBox(height: 16),

                  // Manual option
                  InkWell(
                    onTap: () => setState(() => _isAuto = false),
                    child: Row(
                      children: [
                        RadioGroup<bool>(
                          groupValue: _isAuto,
                          onChanged: (val) => setState(() => _isAuto = val!),
                          child: Radio<bool>(
                            value: false,
                            activeColor: const Color(0xFF3B82F6),
                          ),
                        ),
                        const Text(
                          'Enter shipment numbers manually',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: borderCol),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final nextNum = int.tryParse(_numberCtrl.text) ?? 1;
                      widget.onSave(_isAuto, _prefixCtrl.text, nextNum);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenBtn,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: const BorderSide(color: borderCol),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
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
}
