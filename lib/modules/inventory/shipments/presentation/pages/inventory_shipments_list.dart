import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:math' as math;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_header_menu.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_more_menu.dart';
import '../../../../../core/providers/entity_provider.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';

const _shipmentFilterOptions = <FavoriteFilterOption>[
  FavoriteFilterOption(label: 'All', value: 'all'),
  FavoriteFilterOption(label: 'Shipped', value: 'shipped'),
  FavoriteFilterOption(label: 'In Transit', value: 'in_transit'),
  FavoriteFilterOption(label: 'Out For Delivery', value: 'out_for_delivery'),
  FavoriteFilterOption(label: 'Failed Delivery Attempt', value: 'failed_delivery_attempt'),
  FavoriteFilterOption(label: 'Customs Clearance', value: 'customs_clearance'),
  FavoriteFilterOption(label: 'Ready For Pickup', value: 'ready_for_pickup'),
  FavoriteFilterOption(label: 'Delayed', value: 'delayed'),
  FavoriteFilterOption(label: 'Delivered', value: 'delivered'),
  FavoriteFilterOption(label: 'Delivered to PO', value: 'delivered_to_po'),
  FavoriteFilterOption(label: 'White Glove Delivery', value: 'white_glove_delivery'),
  FavoriteFilterOption(label: 'Delivered from Pickup Point', value: 'delivered_from_pickup_point'),
];

final shipmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  print('[shipmentsProvider] Started');
  final supabase = Supabase.instance.client;
  final entityState = ref.watch(entityProvider);
  final entityId = entityState.entityId?.trim() ?? '';
  if (entityId.isEmpty) {
    print('[shipmentsProvider] Missing entity scope; returning empty list');
    return [];
  }
  
  try {
    print('[shipmentsProvider] Querying Supabase with entityId: $entityId');
    final response = await supabase
        .from('inventory_shipments')
        .select('*, customers(display_name, place_of_supply), inventory_shipment_sales_orders(sales_orders(sale_number, sale_date, status)), inventory_shipment_packages(inventory_packages(package_number, created_at, inventory_package_items(quantity, products(product_name))))')
        .eq('entity_id', entityId)
        .order('created_at', ascending: false);
        
    print('[shipmentsProvider] Response length: ${response.length}');
    if (response.isNotEmpty) {
      print('[shipmentsProvider] First shipment entity_id: ${response[0]['entity_id']}');
    }
    
    final list = List<Map<String, dynamic>>.from(response);
    
    // Extract items from packages
    for (var s in list) {
      final items = <Map<String, dynamic>>[];
      final packages = s['inventory_shipment_packages'] as List?;
      if (packages != null) {
        for (var pkg in packages) {
          final pkgItems = pkg['inventory_packages']?['inventory_package_items'] as List?;
          if (pkgItems != null) {
            for (var item in pkgItems) {
              items.add({
                'name': item['products']?['product_name'] ?? 'Unknown Product',
                'description': '', 
                'quantity': item['quantity'] ?? 0.0,
                'unit': 'pcs',
              });
            }
          }
        }
      }
      s['items'] = items;
    }
    
    return list;
  } catch (e) {
    print('[shipmentsProvider] Error: $e');
    return [];
  }
});

class InventoryShipmentsListScreen extends ConsumerStatefulWidget {
  final String? id;
  const InventoryShipmentsListScreen({super.key, this.id});

  @override
  ConsumerState<InventoryShipmentsListScreen> createState() => _InventoryShipmentsListScreenState();
}

class _InventoryShipmentsListScreenState extends ConsumerState<InventoryShipmentsListScreen> {
  String? _activeShipmentId;
  final Set<String> _selectedIds = {};
  String _sortField = 'created_at';
  bool _sortAscending = false;
  bool _shouldWrapText = false;
  FavoriteFilterOption _activeOption = _shipmentFilterOptions.first;
  Set<String> _visibleColumns = {
    'date', 'shipment_number', 'customer_name', 'sales_order#', 'package#', 'carrier', 'tracking#', 'status', 'shipping_rate'
  };

  void _showCustomColumnsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final allCols = [
              {'key': 'date', 'label': 'DATE'},
              {'key': 'shipment_number', 'label': 'SHIPMENT ORDER#'},
              {'key': 'customer_name', 'label': 'CUSTOMER NAME'},
              {'key': 'sales_order#', 'label': 'SALES ORDER#'},
              {'key': 'package#', 'label': 'PACKAGE#'},
              {'key': 'carrier', 'label': 'CARRIER'},
              {'key': 'tracking#', 'label': 'TRACKING#'},
              {'key': 'status', 'label': 'STATUS'},
              {'key': 'shipping_rate', 'label': 'SHIPPING RATE'},
            ];
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              title: const Text('Customize Columns', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 300,
                child: ListView(
                  shrinkWrap: true,
                  children: allCols.map((col) {
                    final key = col['key']!;
                    final label = col['label']!;
                    return CheckboxListTile(
                      title: Text(label, style: const TextStyle(fontSize: 13)),
                      value: _visibleColumns.contains(key),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            _visibleColumns.add(key);
                          } else {
                            if (_visibleColumns.length > 1) {
                              _visibleColumns.remove(key);
                            }
                          }
                        });
                        setState(() {});
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _activeShipmentId = widget.id;
  }

  Future<void> _deleteShipments(List<String> ids) async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Shipments',
      message: 'Are you sure you want to delete the selected shipments?',
      confirmLabel: 'Delete',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (!confirmed) return;

    final supabase = Supabase.instance.client;
    try {
      for (final id in ids) {
        await supabase.from('inventory_shipments').update({'is_delete': true}).eq('id', id);
      }
      ZerpaiToast.success(context, 'Shipments deleted successfully!');
      ref.invalidate(shipmentsProvider);
      setState(() {
        _selectedIds.clear();
      });
    } catch (e) {
      ZerpaiToast.error(context, 'Error deleting shipments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipmentsAsync = ref.watch(shipmentsProvider);

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: shipmentsAsync.when(
        data: (shipments) {
          if (shipments.isEmpty) {
            return _EmptyShipmentsView(
              activeOption: _activeOption,
              onOptionChanged: (opt) {
                setState(() {
                  _activeOption = opt;
                });
              },
            );
          }

          final filtered = shipments.where((s) {
            if (s['is_delete'] == true) return false;
            final isDelivered = s['is_delivered'] == true;
            final filterVal = _activeOption.value.toLowerCase();
            if (filterVal == 'all') {
              return true;
            } else if (filterVal.startsWith('delivered') || filterVal == 'white_glove_delivery') {
              return isDelivered;
            } else {
              return !isDelivered;
            }
          }).toList();

          final sorted = _getSortedList(filtered);

          return Stack(
            children: [
              _activeShipmentId == null
                  ? Column(
                      children: [
                        _buildMainToolbar(context),
                        Expanded(child: _buildTableView(sorted)),
                      ],
                    )
                  : _buildSplitView(sorted, shipments),
              if (_selectedIds.isNotEmpty && _activeShipmentId == null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildSelectionActionsPopupBar(shipments),
                ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: TableSkeleton(rows: 10, columns: 6),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  List<Map<String, dynamic>> _getSortedList(List<Map<String, dynamic>> shipments) {
    final list = List<Map<String, dynamic>>.from(shipments);
    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case 'date':
          cmp = (a['date'] ?? '').compareTo(b['date'] ?? '');
          break;
        case 'shipment_number':
          cmp = (a['shipment_number'] ?? '').compareTo(b['shipment_number'] ?? '');
          break;
        case 'carrier':
          cmp = (a['carrier'] ?? '').compareTo(b['carrier'] ?? '');
          break;
        case 'tracking_number':
          cmp = (a['tracking_number'] ?? '').compareTo(b['tracking_number'] ?? '');
          break;
        case 'created_at':
          cmp = (a['created_at'] ?? '').compareTo(b['created_at'] ?? '');
          break;
        case 'updated_at':
          cmp = (a['updated_at'] ?? '').compareTo(b['updated_at'] ?? '');
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  Widget _buildMainToolbar(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: FavoriteFilterDropdown(
              moduleName: 'shipments',
              options: _shipmentFilterOptions,
              selectedOption: _activeOption,
              onChanged: (opt) {
                setState(() {
                  _activeOption = opt;
                });
              },
            ),
          ),
          const Spacer(),
          ZButton.primary(
            onPressed: () {
              context.go('/inventory/shipments/create');
            },
            icon: LucideIcons.plus,
            label: 'New',
          ),
          const SizedBox(width: 4),
          ZTableMoreMenu(
            width: 38,
            height: 38,
            menuChildren: [
              SubmenuButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                menuStyle: ZTableMoreMenu.submenuMenuStyle(),
                alignmentOffset: const Offset(4, 0),
                leadingIcon: const Icon(LucideIcons.arrowUpDown, size: 16),
                menuChildren: [
                  _buildSortMenuItem('Date', 'date'),
                  _buildSortMenuItem('Shipment Order#', 'shipment_number'),
                  _buildSortMenuItem('Carrier', 'carrier'),
                  _buildSortMenuItem('Tracking#', 'tracking_number'),
                  _buildSortMenuItem('Created Time', 'created_at'),
                  _buildSortMenuItem('Last Modified Time', 'updated_at'),
                ],
                child: const Text('Sort by'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                leadingIcon: const Icon(LucideIcons.download, size: 16),
                onPressed: () {},
                child: const Text('Import Shipments'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                leadingIcon: const Icon(LucideIcons.upload, size: 16),
                onPressed: () {},
                child: const Text('Export Shipments'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                leadingIcon: const Icon(LucideIcons.settings, size: 16),
                onPressed: _showCustomColumnsDialog,
                child: const Text('Preferences'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                leadingIcon: const Icon(LucideIcons.refreshCw, size: 16),
                onPressed: () {
                  ref.invalidate(shipmentsProvider);
                },
                child: const Text('Refresh List'),
              ),
            ],
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildSortMenuItem(String label, String field) {
    final isSelected = _sortField == field;
    return MenuItemButton(
      style: ZTableMoreMenu.menuItemButtonStyle(isActive: isSelected),
      onPressed: () {
        setState(() {
          if (isSelected) {
            _sortAscending = !_sortAscending;
          } else {
            _sortField = field;
            _sortAscending = false;
          }
        });
      },
      child: Row(
        children: [
          Text(label),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(_sortAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown, size: 12),
          ],
        ],
      ),
    );
  }



  Widget _buildCheckboxWidget(bool isSelected, {bool isPartially = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: isSelected || isPartially
          ? Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(3)),
              child: Center(child: Icon(isPartially ? LucideIcons.minus : LucideIcons.check, size: 14, color: Colors.white)),
            )
          : Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppTheme.borderColor, width: 1.5),
              ),
            ),
    );
  }

  Widget _buildSelectionButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTableView(List<Map<String, dynamic>> shipments) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        
        // Define metrics for each column
        final Map<String, ({double min, double flex})> metrics = {
          'date': (min: 200.0, flex: 2.0),
          'shipment_number': (min: 130.0, flex: 1.5),
          'customer_name': (min: 180.0, flex: 2.5),
          'sales_order#': (min: 130.0, flex: 1.5),
          'package#': (min: 120.0, flex: 1.5),
          'carrier': (min: 120.0, flex: 1.5),
          'tracking#': (min: 150.0, flex: 2.0),
          'status': (min: 120.0, flex: 1.5),
          'shipping_rate': (min: 100.0, flex: 1.0),
        };

        double totalMinWidth = 0;
        double totalFlex = 0;
        metrics.forEach((key, value) {
          totalMinWidth += value.min;
          totalFlex += value.flex;
        });

        final extraSpace = math.max(0.0, totalWidth - totalMinWidth);
        final columnWidths = <String, double>{};
        metrics.forEach((key, value) {
          columnWidths[key] = value.min + (value.flex / totalFlex) * extraSpace;
        });

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            horizontalMargin: 0,
            columnSpacing: 0,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
            headingTextStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              fontFamily: 'Inter',
            ),
            columns: [
              if (_visibleColumns.contains('date'))
                DataColumn(
                  label: SizedBox(
                    width: columnWidths['date']!,
                    child: Row(
                      children: [
                        ZTableHeaderMenu(
                          wrapText: _shouldWrapText,
                          onWrapChange: (v) => setState(() => _shouldWrapText = v),
                          onCustomize: () {
                            _showCustomColumnsDialog();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCheckboxWidget(
                          shipments.isNotEmpty && _selectedIds.length == shipments.length,
                          onTap: () {
                            setState(() {
                              if (_selectedIds.length == shipments.length) {
                                _selectedIds.clear();
                              } else {
                                _selectedIds.addAll(shipments.map((s) => s['id'] as String));
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text('DATE'),
                      ],
                    ),
                  ),
                ),
              if (_visibleColumns.contains('shipment_number'))
                DataColumn(label: SizedBox(width: columnWidths['shipment_number']!, child: const Text('SHIPMENT ORDER#'))),
              if (_visibleColumns.contains('customer_name'))
                DataColumn(label: SizedBox(width: columnWidths['customer_name']!, child: const Text('CUSTOMER NAME'))),
              if (_visibleColumns.contains('sales_order#'))
                DataColumn(label: SizedBox(width: columnWidths['sales_order#']!, child: const Text('SALES ORDER#'))),
              if (_visibleColumns.contains('package#'))
                DataColumn(label: SizedBox(width: columnWidths['package#']!, child: const Text('PACKAGE#'))),
              if (_visibleColumns.contains('carrier'))
                DataColumn(label: SizedBox(width: columnWidths['carrier']!, child: const Text('CARRIER'))),
              if (_visibleColumns.contains('tracking#'))
                DataColumn(label: SizedBox(width: columnWidths['tracking#']!, child: const Text('TRACKING#'))),
              if (_visibleColumns.contains('status'))
                DataColumn(label: SizedBox(width: columnWidths['status']!, child: const Text('STATUS'))),
              if (_visibleColumns.contains('shipping_rate'))
                DataColumn(label: SizedBox(width: columnWidths['shipping_rate']!, child: const Text('SHIPPING RATE'))),
            ],
            rows: shipments.map((s) {
              final soList = (s['inventory_shipment_sales_orders'] as List?)
                  ?.map((e) => e['sales_orders']?['sale_number'] as String?)
                  .where((e) => e != null)
                  .join(', ') ?? '';
                  
              final pkgList = (s['inventory_shipment_packages'] as List?)
                  ?.map((e) => e['inventory_packages']?['package_number'] as String?)
                  .where((e) => e != null)
                  .join(', ') ?? '';

              final isSelected = _selectedIds.contains(s['id']);

              return DataRow(
                selected: isSelected,
                onSelectChanged: (selected) {
                  setState(() {
                    _activeShipmentId = s['id'];
                  });
                },
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (isSelected) return const Color(0xFFF0F7FF);
                  return null;
                }),
                cells: [
                  if (_visibleColumns.contains('date'))
                    DataCell(
                      SizedBox(
                        width: columnWidths['date']!,
                        child: Row(
                          children: [
                            const SizedBox(width: 28), // Space for ZTableHeaderMenu
                            const SizedBox(width: 8),
                            _buildCheckboxWidget(
                              isSelected,
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedIds.remove(s['id']);
                                  } else {
                                    _selectedIds.add(s['id']);
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(s['date'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(s['date'])) : ''),
                          ],
                        ),
                      ),
                    ),
                  if (_visibleColumns.contains('shipment_number'))
                    DataCell(
                      SizedBox(
                        width: columnWidths['shipment_number']!,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _activeShipmentId = s['id'];
                            });
                          },
                          child: Text(
                            s['shipment_number'] ?? '',
                            style: const TextStyle(color: AppTheme.primaryBlue),
                          ),
                        ),
                      ),
                    ),
                  if (_visibleColumns.contains('customer_name'))
                    DataCell(SizedBox(width: columnWidths['customer_name']!, child: Text(s['customers']?['display_name'] ?? ''))),
                  if (_visibleColumns.contains('sales_order#'))
                    DataCell(SizedBox(width: columnWidths['sales_order#']!, child: Text(soList))),
                  if (_visibleColumns.contains('package#'))
                    DataCell(SizedBox(width: columnWidths['package#']!, child: Text(pkgList))),
                  if (_visibleColumns.contains('carrier'))
                    DataCell(SizedBox(width: columnWidths['carrier']!, child: Text(s['carrier'] ?? ''))),
                  if (_visibleColumns.contains('tracking#'))
                    DataCell(SizedBox(width: columnWidths['tracking#']!, child: Text(s['tracking_number'] ?? ''))),
                  if (_visibleColumns.contains('status'))
                    DataCell(
                      SizedBox(
                        width: columnWidths['status']!,
                        child: Text(
                          s['is_delivered'] == true ? 'DELIVERED' : 'SHIPPED',
                          style: TextStyle(
                            color: s['is_delivered'] == true ? Colors.green : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_visibleColumns.contains('shipping_rate'))
                    DataCell(SizedBox(width: columnWidths['shipping_rate']!, child: Text('₹${s['shipping_charges'] ?? '0.00'}'))),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSplitView(List<Map<String, dynamic>> filteredShipments, List<Map<String, dynamic>> allShipments) {
    final selectedIndex = allShipments.indexWhere((s) => s['id'] == _activeShipmentId);
    if (selectedIndex == -1) {
      return const Center(child: Text('Shipment not found'));
    }
    final selected = allShipments[selectedIndex];
    
    return Row(
      children: [
        SizedBox(
          width: 360,
          child: Column(
            children: [
              _selectedIds.isNotEmpty ? _buildCompactSelectionBar() : _buildCompactHeader(),
              const Divider(height: 1, color: AppTheme.borderColor),
              Expanded(child: _buildCompactList(filteredShipments)),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: AppTheme.borderColor),
        Expanded(
          child: _ShipmentDetailPanel(
            shipment: selected,
            onClose: () {
              setState(() {
                _activeShipmentId = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          FavoriteFilterDropdown(
            moduleName: 'shipments',
            options: _shipmentFilterOptions,
            selectedOption: _activeOption,
            onChanged: (opt) {
              setState(() {
                _activeOption = opt;
              });
            },
          ),
          const Spacer(),
          // Green Split Button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.successGreen,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                    onPressed: () {
                      context.go('/inventory/shipments/create');
                    },
                  ),
                ),
                Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.3)),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(LucideIcons.chevronDown, size: 14, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Outlined More Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(LucideIcons.moreHorizontal, size: 16, color: AppTheme.textSecondary),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactList(List<Map<String, dynamic>> shipments) {
    return ListView.builder(
      itemCount: shipments.length,
      itemBuilder: (context, index) {
        final s = shipments[index];
        final isActive = s['id'] == _activeShipmentId;
        
        return InkWell(
          onTap: () {
            setState(() {
              _activeShipmentId = s['id'];
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.bgLight : Colors.white,
              border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildCheckboxWidget(
                      _selectedIds.contains(s['id']),
                      onTap: () {
                        setState(() {
                          if (_selectedIds.contains(s['id'])) {
                            _selectedIds.remove(s['id']);
                          } else {
                            _selectedIds.add(s['id']);
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s['shipment_number'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      s['date'] ?? '',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    s['customers']?['display_name'] ?? '',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    s['is_delivered'] == true ? 'DELIVERED' : 'SHIPPED',
                    style: TextStyle(
                      fontSize: 12,
                      color: s['is_delivered'] == true ? Colors.green : Colors.blue,
                      fontWeight: FontWeight.bold,
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

  Widget _buildSelectionActionsPopupBar(List<Map<String, dynamic>> shipments) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          _buildCheckboxWidget(true, onTap: () => setState(() => _selectedIds.clear())),
          const SizedBox(width: 16),
          // Download Button
          OutlinedButton(
            onPressed: () async {
              if (_selectedIds.isEmpty) {
                ZerpaiToast.error(context, 'Please select at least one shipment.');
                return;
              }
              final shipmentId = _selectedIds.first;
              final shipment = shipments.firstWhere((s) => s['id'] == shipmentId);
              final orgSettings = ref.read(orgSettingsProvider).asData?.value;
              final pdfBytes = await _generateShipmentPdf(shipment, orgSettings);
              await Printing.sharePdf(bytes: pdfBytes, filename: 'shipment_${shipment['shipment_number']}.pdf');
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Icon(LucideIcons.fileText, size: 16, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 8),
          // Print Button
          OutlinedButton(
            onPressed: () async {
              if (_selectedIds.isEmpty) {
                ZerpaiToast.error(context, 'Please select at least one shipment.');
                return;
              }
              final shipmentId = _selectedIds.first;
              final shipment = shipments.firstWhere((s) => s['id'] == shipmentId);
              final orgSettings = ref.read(orgSettingsProvider).asData?.value;
              final pdfBytes = await _generateShipmentPdf(shipment, orgSettings);
              await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Icon(LucideIcons.printer, size: 16, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 16),
          // Delete Button
          _buildSelectionButton('Delete', () {
            _deleteShipments(_selectedIds.toList());
          }),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_selectedIds.length} Selected',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          const Spacer(),
          const Text(
            'Esc',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => setState(() => _selectedIds.clear()),
            icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSelectionBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          _buildCheckboxWidget(true, onTap: () => setState(() => _selectedIds.clear())),
          const SizedBox(width: 16),
          MenuAnchor(
            builder: (context, controller, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: InkWell(
                  onTap: () => controller.isOpen ? controller.close() : controller.open(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bulk Actions',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                      ),
                      SizedBox(width: 4),
                      Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              );
            },
            menuChildren: [
              _buildBulkMenuItem('Download Shipment Order', () {}),
              _buildBulkMenuItem('Print Shipment Order', () {}),
              const Divider(height: 1, color: AppTheme.borderColor),
              _buildBulkMenuItem('Delete', () {
                _deleteShipments(_selectedIds.toList());
              }),
            ],
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_selectedIds.length} Selected',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => setState(() => _selectedIds.clear()),
            icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkMenuItem(String label, VoidCallback onTap) {
    return MenuItemButton(
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _EmptyShipmentsView extends StatelessWidget {
  final FavoriteFilterOption activeOption;
  final ValueChanged<FavoriteFilterOption> onOptionChanged;

  const _EmptyShipmentsView({
    required this.activeOption,
    required this.onOptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: true,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(context),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Ship with Confidence and Accuracy',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create shipment records and track delivery status for your orders.',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/inventory/shipments/create');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'CREATE SHIPMENT',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 64),
                Text(
                  'Life cycle of Shipments',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 48),
                _buildFlowchart(),
                const SizedBox(height: 64),
                Text(
                  'In the Shipments module, you can:',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.check, size: 10, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Generate and manage outbound shipments.',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
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

  Widget _buildToolbar(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: FavoriteFilterDropdown(
              moduleName: 'shipments',
              options: _shipmentFilterOptions,
              selectedOption: activeOption,
              onChanged: onOptionChanged,
            ),
          ),
          const Spacer(),
          ZButton.primary(
            onPressed: () {
              context.go('/inventory/shipments/create');
            },
            icon: LucideIcons.plus,
            label: 'New',
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildFlowchart() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNode('Sales Order Confirmed', LucideIcons.fileText, iconColor: const Color(0xFF0088FF), bgColor: const Color(0xFFEFF6FF)),
            _buildArrow(),
            _buildNode('Packages Created', LucideIcons.package, iconColor: const Color(0xFF0088FF), bgColor: const Color(0xFFEFF6FF)),
            _buildArrow(),
            _buildNode('Create Shipment', LucideIcons.filePlus, iconColor: const Color(0xFF7C3AED), bgColor: const Color(0xFFFAF5FF)),
            _buildArrow(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNode('Via Carrier', LucideIcons.truck, iconColor: const Color(0xFF0088FF), bgColor: const Color(0xFFEFF6FF)),
                const SizedBox(height: 24),
                _buildNode('Manually', LucideIcons.clipboardList, iconColor: const Color(0xFF0088FF), bgColor: const Color(0xFFEFF6FF)),
              ],
            ),
            _buildArrow(),
            _buildNode('Shipped', LucideIcons.truck, iconColor: const Color(0xFF28A745), bgColor: const Color(0xFFECFDF5)),
            _buildArrow(),
            _buildNode('Delivered', LucideIcons.packageCheck, iconColor: const Color(0xFF28A745), bgColor: const Color(0xFFECFDF5)),
          ],
        ),
      ),
    );
  }

  Widget _buildNode(String text, IconData icon, {required Color iconColor, required Color bgColor}) {
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyText.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, width: 24, color: const Color(0xFFE5E7EB)),
          const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFFD1D5DB)),
        ],
      ),
    );
  }
}

class _ShipmentDetailPanel extends ConsumerStatefulWidget {
  final Map<String, dynamic> shipment;
  final VoidCallback onClose;

  const _ShipmentDetailPanel({required this.shipment, required this.onClose});

  @override
  ConsumerState<_ShipmentDetailPanel> createState() => _ShipmentDetailPanelState();
}

class _ShipmentDetailPanelState extends ConsumerState<_ShipmentDetailPanel> {
  int _activeTab = 0; // 0: Packages, 1: Sales Orders
  bool _isTabsExpanded = false;

  Future<void> _deleteShipment(String id) async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Shipment',
      message: 'Are you sure you want to delete this shipment?',
      confirmLabel: 'Delete',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (!confirmed) return;

    final supabase = Supabase.instance.client;
    try {
      await supabase.from('inventory_shipments').update({'is_delete': true}).eq('id', id);
      ZerpaiToast.success(context, 'Shipment deleted successfully!');
      ref.invalidate(shipmentsProvider);
    } catch (e) {
      ZerpaiToast.error(context, 'Error deleting shipment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.shipment;
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Text(
                  s['shipment_number'] ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          
          // Action Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                _buildActionButton('Edit', LucideIcons.edit, () {
                  context.go('/inventory/shipments/edit/${s['id']}');
                }),
                _buildDivider(),
                _buildActionButton('Send Email', LucideIcons.mail, () {}),
                _buildDivider(),
                _buildPdfPrintDropdown(s),
                _buildDivider(),
                _buildMarkAsDeliveredDropdown(s),
                _buildDivider(),
                _buildActionButton('Delete', LucideIcons.trash2, () {
                  _deleteShipment(s['id']);
                }),
              ],
            ),
          ),
          
          _buildDetailTabs(s),
          
          // Content Scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shipment Details Section
                  Row(
                    children: [
                      const Icon(LucideIcons.truck, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      const Text(
                        'Shipment Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailItem('Date of Shipment', s['date'] ?? ''),
                              const SizedBox(height: 12),
                              _buildDetailItem('Carrier', s['carrier'] ?? ''),
                              const SizedBox(height: 12),
                              _buildDetailItem('Tracking Status', s['is_delivered'] == true ? 'Delivered' : 'Shipped'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                _buildDetailItem(
                                  'Shipment Notes',
                                  s['notes'] != null && s['notes'].toString().isNotEmpty ? s['notes'] : 'Add Notes',
                                  isLink: true,
                                  onTap: () {
                                    _showEditNotesDialog(s);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Document Preview
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRect(
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              child: _PdfCornerRibbon(
                                label: s['is_delivered'] == true ? 'Delivered' : 'Shipped',
                                color: s['is_delivered'] == true ? AppTheme.successGreen : AppTheme.primaryBlue,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Document Header
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 40), // Push logo below the diagonal ribbon
                                          _buildPdfLogo(orgSettings),
                                          const SizedBox(height: 16),
                                          Text(
                                            orgSettings?.name.trim().isNotEmpty == true
                                                ? orgSettings!.name.trim().toUpperCase()
                                                : 'YOUR COMPANY NAME',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                          if (orgSettings?.paymentStubAddress?.trim().isNotEmpty == true)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                _formatAddress(orgSettings!.paymentStubAddress),
                                                style: const TextStyle(fontSize: 10, height: 1.5),
                                              ),
                                            ),
                                        ],
                                      ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'SHIPMENT ORDER',
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Shipment Order# ${s['shipment_number'] ?? ''}',
                                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Addresses
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Ship To', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(s['customers']?['display_name'] ?? 'CUS-1', style: const TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          _buildPreviewRow('Sales Order#:', (s['inventory_shipment_sales_orders'] as List?)
                                              ?.map((e) => e['sales_orders']?['sale_number'] as String?)
                                              .where((e) => e != null)
                                              .join(', ') ?? ''),
                                          const SizedBox(height: 4),
                                          _buildPreviewRow('Order Date:', (s['inventory_shipment_sales_orders'] as List?)
                                              ?.map((e) => e['sales_orders']?['sale_date'] as String?)
                                              .where((e) => e != null)
                                              .map((e) => DateFormat('dd-MM-yyyy').format(DateTime.parse(e!)))
                                              .join(', ') ?? ''),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  Text(
                                    'Place of Supply: ${_getPlaceOfSupply(s['customers'])}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Items Table
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.borderColor),
                                    ),
                                    child: Column(
                                      children: [
                                        // Table Header
                                        Container(
                                          color: const Color(0xFF374151),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          child: const Row(
                                            children: [
                                              SizedBox(width: 30, child: Text('#', style: TextStyle(color: Colors.white, fontSize: 12))),
                                              Expanded(child: Text('Item & Description', style: TextStyle(color: Colors.white, fontSize: 12))),
                                              SizedBox(width: 50, child: Text('Qty', style: TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.end)),
                                            ],
                                          ),
                                        ),
                                        // Table Rows
                                        ...List.generate((s['items'] as List? ?? []).length, (index) {
                                          final item = s['items'][index];
                                          return Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                child: Row(
                                                  children: [
                                                    SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 12))),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(item['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                                          if (item['description']?.toString().isNotEmpty == true)
                                                            Text(item['description'].toString(), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 50, child: Text('${item['quantity']}\n${item['unit']}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.end)),
                                                  ],
                                                ),
                                              ),
                                              if (index < (s['items'] as List).length - 1)
                                                const Divider(height: 1, color: AppTheme.borderColor),
                                            ],
                                          );
                                        }),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool hasDropdown = false,
  }) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isHovered ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isHovered ? const Color(0xFFD3D9E3) : Colors.transparent,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: AppTheme.textPrimary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hasDropdown) ...[
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronDown, size: 12, color: AppTheme.textPrimary),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  MenuStyle _menuStyle() {
    return MenuStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevation: const WidgetStatePropertyAll(8),
      backgroundColor: const WidgetStatePropertyAll(Colors.white),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      color: AppTheme.borderLight,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildPdfPrintDropdown(Map<String, dynamic> shipment) {
    final orgSettings = ref.read(orgSettingsProvider).asData?.value;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: _menuStyle(),
      menuChildren: [
        MenuItemButton(
          onPressed: () async {
            final bytes = await _generateShipmentPdf(shipment, orgSettings);
            await Printing.sharePdf(
              bytes: bytes,
              filename: '${shipment['shipment_number'] ?? 'shipment'}.pdf',
            );
          },
          style: ZTableMoreMenu.menuItemButtonStyle(),
          child: const Text('Download PDF'),
        ),
        MenuItemButton(
          onPressed: () async {
            final bytes = await _generateShipmentPdf(shipment, orgSettings);
            await Printing.layoutPdf(
              onLayout: (_) async => bytes,
              name: shipment['shipment_number'] ?? 'shipment',
            );
          },
          style: ZTableMoreMenu.menuItemButtonStyle(),
          child: const Text('Print'),
        ),
      ],
      builder: (context, controller, _) => _buildActionButton(
        'PDF/Print',
        LucideIcons.printer,
        () => controller.isOpen ? controller.close() : controller.open(),
        hasDropdown: true,
      ),
    );
  }

  Widget _buildMarkAsDeliveredDropdown(Map<String, dynamic> shipment) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: _menuStyle(),
      menuChildren: [
        MenuItemButton(
          onPressed: () => _showMarkAsDeliveredDialog(shipment),
          style: ZTableMoreMenu.menuItemButtonStyle(),
          child: const Text('Mark as Delivered'),
        ),
      ],
      builder: (context, controller, _) => _buildActionButton(
        'Mark as Delivered',
        LucideIcons.check,
        () => controller.isOpen ? controller.close() : controller.open(),
        hasDropdown: true,
      ),
    );
  }

  void _showEditNotesDialog(Map<String, dynamic> shipment) {
    final controller = TextEditingController(text: shipment['notes'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Edit Shipment Notes'),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Enter shipment notes here...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final supabase = Supabase.instance.client;
              try {
                await supabase.from('inventory_shipments').update({
                  'notes': controller.text,
                }).eq('id', shipment['id']);
                
                ZerpaiToast.success(context, 'Notes updated successfully!');
                ref.invalidate(shipmentsProvider);
                Navigator.pop(context);
              } catch (e) {
                ZerpaiToast.error(context, 'Error updating notes: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMarkAsDeliveredDialog(Map<String, dynamic> shipment) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mark as Delivered'),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivered On', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Date Picker
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                              const Icon(LucideIcons.calendar, size: 16, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Time Picker
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setState(() => selectedTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(selectedTime.format(context)),
                              const Icon(LucideIcons.chevronDown, size: 16, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final supabase = Supabase.instance.client;
                final combinedDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                
                try {
                  await supabase.from('inventory_shipments').update({
                    'is_delivered': true,
                    'delivered_date': combinedDateTime.toIso8601String(),
                  }).eq('id', shipment['id']);
                  
                  ZerpaiToast.success(context, 'Shipment marked as delivered!');
                  ref.invalidate(shipmentsProvider);
                  Navigator.pop(context);
                } catch (e) {
                  ZerpaiToast.error(context, 'Error updating status: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTabs(Map<String, dynamic> s) {
    final packages = s['inventory_shipment_packages'] as List? ?? [];
    final salesOrders = s['inventory_shipment_sales_orders'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isTabsExpanded = !_isTabsExpanded),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  _buildDropdownOption(
                    'Packages',
                    packages.length,
                    _activeTab == 0,
                    () => setState(() {
                      _activeTab = 0;
                      _isTabsExpanded = true;
                    }),
                  ),
                  _buildDropdownOption(
                    'Associated sales orders',
                    salesOrders.length,
                    _activeTab == 1,
                    () => setState(() {
                      _activeTab = 1;
                      _isTabsExpanded = true;
                    }),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      _isTabsExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isTabsExpanded)
            Container(
              width: double.infinity,
              child: _activeTab == 0 
                ? (packages.isNotEmpty ? _buildPackagesTable(packages) : _buildEmptyState('No packages found')) 
                : (salesOrders.isNotEmpty ? _buildSalesOrdersTable(salesOrders) : _buildEmptyState('No sales orders found')),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownOption(String label, int count, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 12, bottom: 10, left: 16, right: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildPackagesTable(List packages) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFF9FAFB),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Package#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
              Expanded(flex: 3, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
              Expanded(flex: 3, child: Text('Total Quantity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
            ],
          ),
        ),
        ...List.generate(packages.length, (index) {
          final p = packages[index];
          final pkg = p['inventory_packages'];
          final items = pkg?['inventory_package_items'] as List? ?? [];
          final totalQty = items.fold(0.0, (sum, item) => sum + (item['quantity'] ?? 0.0));
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(pkg?['package_number'] ?? '', style: const TextStyle(fontSize: 13))),
                Expanded(flex: 3, child: Text(pkg?['created_at'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(pkg['created_at'])) : '', style: const TextStyle(fontSize: 13))),
                Expanded(flex: 3, child: Text(totalQty.toString(), style: const TextStyle(fontSize: 13))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSalesOrdersTable(List salesOrders) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFF9FAFB),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
              Expanded(flex: 3, child: Text('Sales Order#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
              Expanded(flex: 3, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
              Expanded(flex: 3, child: Text('Shipment Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
            ],
          ),
        ),
        ...List.generate(salesOrders.length, (index) {
          final so = salesOrders[index];
          final order = so['sales_orders'];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(order?['sale_date'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(order['sale_date'])) : '', style: const TextStyle(fontSize: 13))),
                Expanded(flex: 3, child: Text(order?['sale_number'] ?? '', style: const TextStyle(fontSize: 13))),
                Expanded(flex: 3, child: Text(order?['status'] ?? '', style: const TextStyle(fontSize: 13))),
                Expanded(flex: 3, child: Text(order?['shipment_date'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(order['shipment_date'])) : '', style: const TextStyle(fontSize: 13))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isLink = false, VoidCallback? onTap}) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ),
        InkWell(
          onTap: onTap,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isLink ? AppTheme.primaryBlue : AppTheme.textPrimary,
              fontWeight: isLink ? FontWeight.bold : FontWeight.normal,
              decoration: isLink ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }


  String _getPlaceOfSupply(Map<String, dynamic>? customer) {
    final pos = customer?['place_of_supply']?.toString();
    if (pos == null || pos.isEmpty) return '';
    final parts = pos.split('-');
    if (parts.length > 1) {
      return parts[1].trim();
    }
    return pos;
  }

  Widget _buildPdfLogo(OrgSettings? orgSettings) {
    final logoUrl = orgSettings?.logoUrl;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return Container(
        width: 140,
        height: 60,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _pdfLogoFallback(),
        ),
      );
    }
    return _pdfLogoFallback();
  }

  Widget _pdfLogoFallback() {
    return Container(
      width: 140,
      height: 60,
      color: const Color(0xFF101820),
      child: const Center(
        child: Text(
          'LOGO',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _PdfCornerRibbon extends StatelessWidget {
  final String label;
  final Color color;

  const _PdfCornerRibbon({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    const double size = 110;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _CornerFoldPainter(color: color),
          ),
          Positioned(
            top: 24,
            left: -32,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 170,
                height: 30,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 22,
            left: -34,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 170,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color,
                      HSLColor.fromColor(color)
                          .withLightness((HSLColor.fromColor(color).lightness * 0.85).clamp(0.0, 1.0))
                          .toColor(),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    shadows: [
                      Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


}

String _formatAddress(String? addressStr) {
  if (addressStr == null || addressStr.trim().isEmpty) return '';
  try {
    final data = jsonDecode(addressStr);
    if (data is Map<String, dynamic>) {
      final lines = <String>[];
      if (data['attention'] != null && data['attention'].toString().isNotEmpty) {
        lines.add(data['attention'].toString());
      }
      if (data['street1'] != null && data['street1'].toString().isNotEmpty) {
        lines.add(data['street1'].toString());
      }
      if (data['street2'] != null && data['street2'].toString().isNotEmpty) {
        lines.add(data['street2'].toString());
      }
      final cityStateZip = <String>[];
      if (data['city'] != null && data['city'].toString().isNotEmpty) {
        cityStateZip.add(data['city'].toString());
      }
      if (data['state_name'] != null && data['state_name'].toString().isNotEmpty) {
        cityStateZip.add(data['state_name'].toString());
      }
      if (data['pincode'] != null && data['pincode'].toString().isNotEmpty) {
        cityStateZip.add(data['pincode'].toString());
      }
      if (cityStateZip.isNotEmpty) lines.add(cityStateZip.join(' '));
      if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
        lines.add('Phone: ${data['phone']}');
      }
      return lines.join('\n');
    }
  } catch (e) {
    // Not JSON, return as is
  }
  return addressStr;
}

  Future<Uint8List> _generateShipmentPdf(Map<String, dynamic> shipment, OrgSettings? orgSettings) async {
    final doc = pw.Document();
    
    // Attempt to load company logo
    pw.MemoryImage? logoImage;
    if (orgSettings?.logoUrl != null && orgSettings!.logoUrl!.trim().isNotEmpty) {
      try {
        final res = await Dio().get<List<int>>(
          orgSettings.logoUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.data != null) {
          logoImage = pw.MemoryImage(Uint8List.fromList(res.data!));
        }
      } catch (_) {}
    }

    /* final dateStr = shipment['date_of_shipment'] != null
        ? DateFormat('dd-MM-yyyy').format(DateTime.parse(shipment['date_of_shipment']))
        : '-'; */

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 130,
                          height: 56,
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Container(
                          width: 130,
                          height: 56,
                          color: const PdfColor.fromInt(0xFF101820),
                          child: pw.Center(
                            child: pw.Text('LOGO', style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                          ),
                        ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        orgSettings?.name.trim().toUpperCase() ?? 'YOUR COMPANY',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                      if (orgSettings?.paymentStubAddress?.trim().isNotEmpty == true)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 3),
                          child: pw.Text(
                            _formatAddress(orgSettings!.paymentStubAddress!.trim()),
                            style: const pw.TextStyle(fontSize: 9, lineSpacing: 2),
                          ),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('SHIPMENT ORDER', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                      pw.Text('Shipment Order# ${shipment['shipment_number'] ?? '-'}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              
              // Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Ship To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey600)),
                      pw.Text(shipment['customers']?['display_name'] ?? 'Walk-in Customer', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Sales Order#: ${(shipment['inventory_shipment_sales_orders'] as List?)?.map((e) => e['sales_orders']?['sale_number'] as String?).where((e) => e != null).join(', ') ?? ''}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Order Date: ${(shipment['inventory_shipment_sales_orders'] as List?)?.map((e) => e['sales_orders']?['sale_date'] as String?).where((e) => e != null).map((e) => DateFormat('dd-MM-yyyy').format(DateTime.parse(e!))).join(', ') ?? ''}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF323B4B)),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('#', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item & Description', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  ...List.generate((shipment['items'] as List).length, (index) {
                    final item = (shipment['items'] as List)[index];
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${index + 1}', style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item['name'] ?? '', style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${item['quantity']}', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

class _CornerFoldPainter extends CustomPainter {
  final Color color;
  _CornerFoldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final darkColor = HSLColor.fromColor(color)
        .withLightness((HSLColor.fromColor(color).lightness * 0.45).clamp(0.0, 1.0))
        .toColor();

    final paint = Paint()..color = darkColor;

    final path = Path()
      ..moveTo(72, 0)
      ..lineTo(84, 0)
      ..lineTo(72, 12)
      ..close()
      ..moveTo(0, 72)
      ..lineTo(0, 84)
      ..lineTo(12, 72)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
