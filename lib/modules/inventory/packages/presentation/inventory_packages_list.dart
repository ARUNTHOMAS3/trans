import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import '../../../../shared/widgets/z_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/inventory_package_model.dart';
import '../providers/inventory_packages_provider.dart';
import '../../picklists/providers/inventory_picklists_provider.dart';
import '../../picklists/models/inventory_picklist_model.dart';
import '../../../../core/providers/org_settings_provider.dart';
import '../../../../core/models/org_settings_model.dart';
import 'dart:convert';

import '../../../../shared/widgets/inputs/z_tooltip.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/utils/zerpai_toast.dart';

// Provider to track picklists that have been dispatched (generated entrypass) but not yet packaged.
final pendingDispatchedPicklistsProvider = StateProvider<List<Picklist>>(
  (ref) => [],
);

final packageSortProvider = StateProvider<({String field, bool isAscending})>((ref) {
  return (field: 'Created Time', isAscending: false);
});

class InventoryPackagesListScreen extends ConsumerStatefulWidget {
  final String? id;
  const InventoryPackagesListScreen({super.key, this.id});

  @override
  ConsumerState<InventoryPackagesListScreen> createState() =>
      _InventoryPackagesListScreenState();
}

class _InventoryPackagesListScreenState
    extends ConsumerState<InventoryPackagesListScreen> {
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderCol = Color(0xFFE5E7EB);
  static const Color _greenBtn = Color(0xFF10B981);

  // Column Colors – exact Zoho match
  static const Color _col1Bg = Color(0xFFD9F3F7); // Packages, Not Shipped
  static const Color _col2Bg = Color(0xFFF6EDB7); // Shipped Packages
  static const Color _col3Bg = Color(0xFFDDEDC8); // Delivered Packages

  bool _isListView = false;
  bool _shouldWrapText = false;
  String _selectedView = 'All';
  Map<String, double>? _customColumnWidths;

  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  final List<String> _visibleColumns = [
    'package_date',
    'package#',
    'carrier',
    'tracking#',
    'sales_order#',
    'status',
    'shipment_date',
    'customer_name',
    'quantity',
  ];

  final Map<String, String> _columnLabels = {
    'package_date': 'PACKAGE DATE',
    'package#': 'PACKAGE#',
    'carrier': 'CARRIER',
    'tracking#': 'TRACKING#',
    'sales_order#': 'SALES ORDER#',
    'status': 'STATUS',
    'shipment_date': 'SHIPMENT DATE',
    'customer_name': 'CUSTOMER NAME',
    'quantity': 'QUANTITY',
  };

  final Set<String> _selectedPackageIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedPackageIds.contains(id)) {
        _selectedPackageIds.remove(id);
      } else {
        _selectedPackageIds.add(id);
      }
    });
  }

  void _toggleAll(List<InventoryPackage> packages) {
    setState(() {
      if (_selectedPackageIds.length == packages.length) {
        _selectedPackageIds.clear();
      } else {
        _selectedPackageIds.clear();
        for (final p in packages) {
          if (p.id != null) _selectedPackageIds.add(p.id!);
        }
      }
    });
  }

  void _showCustomizeColumnsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.list, size: 20, color: AppTheme.textSecondary),
                        const SizedBox(width: 12),
                        Text('Customize Columns', style: AppTheme.sectionHeader),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.bgDisabled, borderRadius: BorderRadius.circular(12)),
                          child: Text('${_visibleColumns.length} of ${_columnLabels.length} Selected', style: AppTheme.metaHelper),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(LucideIcons.x, size: 20, color: AppTheme.errorRed),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search columns...',
                        prefixIcon: Icon(LucideIcons.search, size: 16),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: SingleChildScrollView(
                        child: Column(
                          children: _columnLabels.entries.map((entry) {
                            final isVisible = _visibleColumns.contains(entry.key);
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  if (isVisible) {
                                    if (_visibleColumns.length > 1) _visibleColumns.remove(entry.key);
                                  } else {
                                    _visibleColumns.add(entry.key);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.gripVertical, size: 16, color: AppTheme.borderColor),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isVisible ? LucideIcons.checkSquare : LucideIcons.square,
                                      size: 18,
                                      color: isVisible ? AppTheme.primaryBlue : AppTheme.borderColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      entry.value,
                                      style: AppTheme.bodyText.copyWith(
                                        color: isVisible ? AppTheme.textPrimary : AppTheme.textSecondary,
                                        fontWeight: isVisible ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        ZButton.primary(
                          label: 'Save',
                          onPressed: () {
                            setState(() {}); // Apply visible columns
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(width: 12),
                        ZButton.secondary(
                          label: 'Cancel',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryPackagesProvider.notifier).fetchPackages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDetailOpen = widget.id != null;

    return ZerpaiLayout(
      pageTitle: '', // Hidden as we use titleWidget
      titleWidget: isDetailOpen ? null : _buildTitleDropdown(),
      enableBodyScroll: false,
      useHorizontalPadding: false,
      horizontalPaddingValue: 0,
      useTopPadding: !isDetailOpen,
      titlePadding: const EdgeInsets.only(left: 20, right: 20),
      actions: isDetailOpen ? null : [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const DispatchEntrypassDialog(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create Dispatch Entrypass',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.fileText, size: 14),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                border: Border.all(color: _borderCol),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  ZTooltip(
                    message: 'List View',
                    direction: ZTooltipDirection.bottom,
                    child: InkWell(
                      onTap: () => setState(() => _isListView = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        color: _isListView ? Colors.white : Colors.transparent,
                        child: Icon(
                          LucideIcons.list,
                          size: 14,
                          color: _isListView ? _textPrimary : _textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, color: _borderCol),
                  ZTooltip(
                    message: 'Kanban View',
                    direction: ZTooltipDirection.bottom,
                    child: InkWell(
                      onTap: () => setState(() => _isListView = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        color: !_isListView ? Colors.white : Colors.transparent,
                        child: Icon(
                          LucideIcons.layoutGrid,
                          size: 14,
                          color: !_isListView ? _textPrimary : _textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '0000000000';
                context.go('/$orgId/inventory/packages/create');
              },
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text(
                'New',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _greenBtn,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 8),
            if (_isListView) _buildMoreMenu(),
          ],
        ),
      ],
      child: ref.watch(inventoryPackagesProvider).isLoading
          ? const Center(child: CircularProgressIndicator())
          : isDetailOpen
              ? _buildSplitView()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                if (!_isListView) const Divider(height: 1, thickness: 1, color: _borderCol),
                Expanded(
                  child: _isListView
                      ? _buildVirtualizedTable()
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final bool useFixedDesktopColumns = constraints.maxWidth >= 1220;

                              if (useFixedDesktopColumns) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    SizedBox(
                                      width: 405,
                                      child: _PackageColumn(
                                        title: 'Packages, Not Shipped',
                                        headerColor: _col1Bg,
                                        type: _ColumnType.first,
                                      ),
                                    ),
                                    SizedBox(width: 24),
                                    SizedBox(
                                      width: 405,
                                      child: _PackageColumn(
                                        title: 'Shipped Packages',
                                        headerColor: _col2Bg,
                                        type: _ColumnType.middle,
                                      ),
                                    ),
                                    SizedBox(width: 24),
                                    SizedBox(
                                      width: 405,
                                      child: _PackageColumn(
                                        title: 'Delivered Packages',
                                        headerColor: _col3Bg,
                                        type: _ColumnType.last,
                                      ),
                                    ),
                                    Expanded(flex: 1, child: SizedBox.shrink()),
                                  ],
                                );
                              }

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 980),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        width: 305,
                                        child: _PackageColumn(
                                          title: 'Packages, Not Shipped',
                                          headerColor: _col1Bg,
                                          type: _ColumnType.first,
                                        ),
                                      ),
                                      SizedBox(width: 24),
                                      SizedBox(
                                        width: 305,
                                        child: _PackageColumn(
                                          title: 'Shipped Packages',
                                          headerColor: _col2Bg,
                                          type: _ColumnType.middle,
                                        ),
                                      ),
                                      SizedBox(width: 24),
                                      SizedBox(
                                        width: 305,
                                        child: _PackageColumn(
                                          title: 'Delivered Packages',
                                          headerColor: _col3Bg,
                                          type: _ColumnType.last,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSplitView() {
    final allPackages = ref.watch(inventoryPackagesProvider).packages;
    final packages = allPackages.where((p) {
      if (_selectedView == 'All') return true;
      return p.status == _selectedView;
    }).toList();

    return Row(
      children: [
        SizedBox(
          width: 340,
          child: Column(
            children: [
              _buildLeftSplitHeader(),
              const Divider(height: 1, color: _borderCol),
              Expanded(child: _buildCompactList(packages)),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: _borderCol),
        Expanded(
          child: _PackageDetailPanel(
            id: widget.id!,
            onClose: () {
              final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
              context.go('/$orgId/inventory/packages');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeftSplitHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildTitleDropdown(isCompact: true),
          const Spacer(),
          IconButton(
            onPressed: () {
              final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
              context.go('/$orgId/inventory/packages/create');
            },
            icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: _greenBtn,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              minimumSize: const Size(28, 28),
              fixedSize: const Size(28, 28),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),
          _buildCompactMoreMenu(),
        ],
      ),
    );
  }

  Widget _buildCompactMoreMenu() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: _borderCol),
        borderRadius: BorderRadius.circular(4),
      ),
      child: MenuAnchor(
        builder: (context, controller, child) {
          return IconButton(
            onPressed: () => controller.isOpen ? controller.close() : controller.open(),
            icon: const Icon(LucideIcons.moreHorizontal, size: 16),
            padding: EdgeInsets.zero,
          );
        },
        menuChildren: [
          MenuItemButton(
            onPressed: () => ref.read(inventoryPackagesProvider.notifier).fetchPackages(),
            child: const Text('Refresh List'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactList(List<InventoryPackage> packages) {
    return ListView.builder(
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final pkg = packages[index];
        final isActive = widget.id == pkg.id;
        final isSelected = _selectedPackageIds.contains(pkg.id);

        return InkWell(
          onTap: () {
            final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
            context.go('/$orgId/inventory/packages/${pkg.id}');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFF0F7FF) : Colors.transparent,
              border: const Border(bottom: BorderSide(color: _borderCol)),
            ),
            child: Row(
              children: [
                _buildCheckboxWidget(isSelected, onTap: () => _toggleSelection(pkg.id!)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            pkg.customerName ?? 'No Customer',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            pkg.totalQty.toString(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            pkg.packageNumber,
                            style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue),
                          ),
                          Text(
                            pkg.packageDate != null ? DateFormat('dd-MM-yyyy').format(pkg.packageDate!) : '',
                            style: const TextStyle(fontSize: 11, color: _textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pkg.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: pkg.status == 'Not Shipped' ? AppTheme.errorRed : _greenBtn,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitleDropdown({bool isCompact = false}) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCompact ? 'Packages, $_selectedView' : '$_selectedView Packages',
                style: TextStyle(
                  fontSize: isCompact ? 16 : 24,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronDown, size: isCompact ? 14 : 20, color: AppTheme.primaryBlue),
            ],
          ),
        );
      },
      menuChildren: [
        _buildViewMenuItem('All'),
        _buildViewMenuItem('Not Shipped'),
        _buildViewMenuItem('Shipped'),
        _buildViewMenuItem('Delivered'),
      ],
    );
  }

  Widget _buildViewMenuItem(String view) {
    final bool isActive = _selectedView == view;
    return MenuItemButton(
      onPressed: () => setState(() => _selectedView = view),
      style: _menuItemButtonStyle(isActive: isActive),
      child: Container(
        width: 240,
        child: Row(
          children: [
            Text(view, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            Icon(
              isActive ? LucideIcons.star : LucideIcons.star,
              size: 16,
              color: isActive ? Colors.white : AppTheme.borderColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreMenu() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: MenuAnchor(
        alignmentOffset: const Offset(0, 4),
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
          surfaceTintColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          elevation: const WidgetStatePropertyAll(8),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
          ),
        ),
        builder: (context, controller, child) {
          return IconButton(
            onPressed: () => controller.isOpen ? controller.close() : controller.open(),
            icon: const Icon(LucideIcons.moreHorizontal, size: 16, color: AppTheme.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          );
        },
        menuChildren: [_buildMoreMenuOptions()],
      ),
    );
  }

  Widget _buildMoreMenuOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SubmenuButton(
          menuStyle: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
            surfaceTintColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            elevation: const WidgetStatePropertyAll(8),
          ),
          style: _menuItemButtonStyle(isHeader: true),
          menuChildren: [
            _buildSortMenuItem('Package Date'),
            _buildSortMenuItem('Package#'),
            _buildSortMenuItem('Carrier'),
            _buildSortMenuItem('Sales Order#'),
            _buildSortMenuItem('Shipment Date'),
            _buildSortMenuItem('Customer Name'),
            _buildSortMenuItem('Quantity'),
            _buildSortMenuItem('Created Time', isActive: true),
            _buildSortMenuItem('Last Modified Time'),
          ],
          child: Row(
            children: const [
              Icon(LucideIcons.arrowUpDown, size: 16),
              SizedBox(width: 12),
              Text('Sort by', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.bgDisabled),
        SubmenuButton(
          menuStyle: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
            surfaceTintColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            elevation: const WidgetStatePropertyAll(8),
          ),
          style: _menuItemButtonStyle(isHeader: true),
          menuChildren: [
            _buildSimpleMenuItem('Import Packages', () {}),
            _buildSimpleMenuItem('Import Shipments', () {}),
          ],
          child: Row(
            children: const [
              Icon(LucideIcons.import, size: 16),
              SizedBox(width: 12),
              Text('Import', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.bgDisabled),
        SubmenuButton(
          menuStyle: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
            surfaceTintColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            elevation: const WidgetStatePropertyAll(8),
          ),
          style: _menuItemButtonStyle(isHeader: true),
          menuChildren: [
            _buildSimpleMenuItem('Export Packages', () {}),
            _buildSimpleMenuItem('Export Shipments', () {}),
          ],
          child: Row(
            children: const [
              Icon(LucideIcons.upload, size: 16),
              SizedBox(width: 12),
              Text('Export', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.bgDisabled),
        MenuItemButton(
          onPressed: () => ref.read(inventoryPackagesProvider.notifier).fetchPackages(),
          style: _menuItemButtonStyle(),
          child: Row(
            children: const [
              Icon(LucideIcons.refreshCw, size: 16),
              SizedBox(width: 12),
              Text('Refresh List', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortMenuItem(String label, {bool isActive = false}) {
    return MenuItemButton(
      onPressed: () {},
      style: _menuItemButtonStyle(isActive: isActive),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          if (isActive) const Icon(LucideIcons.arrowDown, size: 16),
        ],
      ),
    );
  }

  Widget _buildSimpleMenuItem(String label, VoidCallback onPressed) {
    return MenuItemButton(
      onPressed: onPressed,
      style: _menuItemButtonStyle(),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }

  ButtonStyle _menuItemButtonStyle({bool isActive = false, bool isHeader = false}) {
    return ButtonStyle(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (isActive) return AppTheme.primaryBlue;
        if (states.contains(WidgetState.hovered)) return AppTheme.primaryBlue;
        return isHeader ? Colors.transparent : AppTheme.backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (isActive || states.contains(WidgetState.hovered)) return Colors.white;
        return AppTheme.textPrimary;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (isActive || states.contains(WidgetState.hovered)) return Colors.white;
        return AppTheme.primaryBlue;
      }),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      minimumSize: const WidgetStatePropertyAll(Size(240, 44)),
      alignment: Alignment.centerLeft,
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
    );
  }

  Widget _buildVirtualizedTable() {
    final allPackages = ref.watch(inventoryPackagesProvider).packages;
    final packages = allPackages.where((p) {
      if (_selectedView == 'All') return true;
      return p.status == _selectedView;
    }).toList();

    if (packages.isEmpty) {
      return const Center(child: Text('No Records Found', style: TextStyle(color: _textSecondary)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidths =
            _customColumnWidths ?? _calculateColumnWidths(constraints.maxWidth);
        // Actual prefix: SizedBox(8) + HeaderMenuButton(28) + SizedBox(12) + checkbox(18) + SizedBox(12) = 78
        const double actualPrefixWidth = 78.0;
        final double totalColumnsWidth =
            columnWidths.values.fold(0.0, (sum, w) => sum + w);
        // screenWidth = always enough to hold all columns + prefix + safety margin
        final screenWidth =
            math.max(constraints.maxWidth, totalColumnsWidth + actualPrefixWidth + 40);

        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: screenWidth > constraints.maxWidth,
          trackVisibility: screenWidth > constraints.maxWidth,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: screenWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTableHeader(columnWidths, packages),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: packages.length,
                      itemExtent: 40,
                      itemBuilder: (context, index) =>
                          _buildVirtualRow(packages[index], columnWidths),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeader(
    Map<String, double> columnWidths,
    List<InventoryPackage> packages,
  ) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          _HeaderMenuButton(
            wrapText: _shouldWrapText,
            onWrapChange: (v) => setState(() => _shouldWrapText = v),
            onCustomize: _showCustomizeColumnsDialog,
          ),
          const SizedBox(width: 12),
          _buildSelectAllCheckbox(packages),
          const SizedBox(width: 12),
          ..._visibleColumns.map((colId) {
            final width = columnWidths[colId]!;
            return _ResizableHeaderCell(
              width: width,
              onResize: (dx) => _resizeColumn(colId, dx),
              child: _buildHeaderCell(_columnLabels[colId]!, width: width),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.tableHeader.copyWith(fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildVirtualRow(
    InventoryPackage pkg,
    Map<String, double> columnWidths,
  ) {
    final isSelected = _selectedPackageIds.contains(pkg.id);
    return InkWell(
      onTap: () {
        final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
        context.go('/$orgId/inventory/packages/${pkg.id}');
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7FF) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: AppTheme.bgDisabled)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            const SizedBox(width: 28),
            const SizedBox(width: 12),
            _buildCheckboxWidget(isSelected, onTap: () => _toggleSelection(pkg.id ?? '')),
            const SizedBox(width: 12),
            ..._visibleColumns.map((colId) => _buildCell(pkg, colId, width: columnWidths[colId]!)),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(InventoryPackage pkg, String colId, {required double width}) {
    String text = '';
    Color? textColor;
    bool isBold = false;

    switch (colId) {
      case 'package_date':
        text = pkg.packageDate != null ? DateFormat('dd-MM-yyyy').format(pkg.packageDate!) : '-';
        break;
      case 'package#':
        text = pkg.packageNumber;
        textColor = AppTheme.primaryBlue;
        isBold = true;
        break;
      case 'carrier':
        text = pkg.carrier ?? '';
        break;
      case 'tracking#':
        text = pkg.trackingNumber ?? '';
        break;
      case 'sales_order#':
        text = pkg.salesOrderNumbers.join(', ');
        break;
      case 'status':
        if (pkg.shipmentDate != null) {
          text = 'SHIPPED';
          textColor = const Color(0xFFE65100);
        } else {
          text = pkg.status.toUpperCase();
          if (text == 'NOT SHIPPED') {
            textColor = AppTheme.errorRed;
          } else if (text == 'SHIPPED') {
            textColor = const Color(0xFFE65100);
          } else if (text == 'DELIVERED') {
            textColor = AppTheme.successGreen;
          } else {
            textColor = AppTheme.primaryBlue;
          }
        }
        isBold = true;
        break;
      case 'shipment_date':
        text = pkg.shipmentDate != null ? DateFormat('dd-MM-yyyy').format(pkg.shipmentDate!) : '-';
        break;
      case 'customer_name':
        text = pkg.customerName ?? '';
        break;
      case 'quantity':
        text = pkg.items.fold(0.0, (sum, item) => sum + item.quantity).toStringAsFixed(2);
        break;
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: _shouldWrapText ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: textColor ?? _textPrimary,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSelectAllCheckbox(List<InventoryPackage> packages) {
    final isAllSelected = packages.isNotEmpty && _selectedPackageIds.length == packages.length;
    final isPartially = _selectedPackageIds.isNotEmpty && _selectedPackageIds.length < packages.length;
    return _buildCheckboxWidget(isAllSelected, isPartially: isPartially, onTap: () => _toggleAll(packages));
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

  void _resizeColumn(String key, double dx) {
    setState(() {
      if (_customColumnWidths == null) {
        // Initialize with current constraints to avoid jump
        _customColumnWidths = _calculateColumnWidths(context.size?.width ?? 1200);
      }
      final current = _customColumnWidths![key] ?? 120.0;
      _customColumnWidths![key] = (current + dx).clamp(50.0, 2000.0);
    });
  }

  Map<String, double> _calculateColumnWidths(double totalWidth) {
    const staticPrefixWidth = 84.0;
    final Map<String, ({double min, double flex})> metrics = {
      'package_date': (min: 120.0, flex: 1.5),
      'package#': (min: 130.0, flex: 2.0),
      'carrier': (min: 120.0, flex: 1.5),
      'tracking#': (min: 150.0, flex: 2.0),
      'sales_order#': (min: 130.0, flex: 2.0),
      'status': (min: 120.0, flex: 1.5),
      'shipment_date': (min: 120.0, flex: 1.5),
      'customer_name': (min: 180.0, flex: 3.0),
      'quantity': (min: 100.0, flex: 1.0),
    };

    double totalMinWidth = staticPrefixWidth;
    double totalFlex = 0;
    for (final colId in _visibleColumns) {
      final m = metrics[colId] ?? (min: 150.0, flex: 1.5);
      totalMinWidth += m.min;
      totalFlex += m.flex;
    }

    final extraSpace = math.max(0.0, totalWidth - totalMinWidth);
    final results = <String, double>{};
    for (final colId in _visibleColumns) {
      final m = metrics[colId] ?? (min: 150.0, flex: 1.5);
      results[colId] = m.min + (m.flex / totalFlex) * extraSpace;
    }
    return results;
  }
}

class _PackageDetailPanel extends ConsumerStatefulWidget {
  final String id;
  final VoidCallback onClose;

  const _PackageDetailPanel({required this.id, required this.onClose});

  @override
  ConsumerState<_PackageDetailPanel> createState() => _PackageDetailPanelState();
}

class _PackageDetailPanelState extends ConsumerState<_PackageDetailPanel> {
  bool _showPdfView = true;
  int _activeTabIndex = 0;
  bool _isTabsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final packageAsync = ref.watch(packageByIdProvider(widget.id));

    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: packageAsync.when(
            data: (pkg) => pkg == null
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      _buildToolbarButton(
                        LucideIcons.edit,
                        'Edit',
                        onPressed: () {
                          final orgId = GoRouterState.of(context)
                              .pathParameters['orgSystemId']!;
                          context.pushNamed(
                            AppRoutes.packagesEdit,
                            pathParameters: {
                              'orgSystemId': orgId,
                              'id': pkg.id!,
                            },
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildShipDropdown(),
                      _buildDivider(),
                      _buildPdfPrintDropdown(pkg),
                      _buildDivider(),
                      _buildToolbarButton(
                        LucideIcons.trash2,
                        'Delete',
                        color: AppTheme.errorRed,
                        onPressed: () => _deletePackage(pkg.id!),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
                      ),
                    ],
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        Expanded(
          child: packageAsync.when(
            data: (pkg) {
              if (pkg == null) return const Center(child: Text('Package not found'));
              return Column(
                children: [
                  _buildDetailTabs(pkg),
                  Expanded(
                    child: _showPdfView ? _PackagePdfView(package: pkg) : _buildStandardView(pkg),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarButton(IconData icon, String label, {VoidCallback? onPressed, Color? color}) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: color ?? const Color(0xFF4B5563)),
      label: Text(label, style: TextStyle(fontSize: 13, color: color ?? const Color(0xFF4B5563))),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
    );
  }

  Future<void> _deletePackage(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Package'),
        content: const Text('Are you sure you want to delete this package?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(inventoryPackagesProvider.notifier).deletePackage(id);
      if (success && mounted) {
        ZerpaiToast.success(context, 'Package deleted successfully');
        widget.onClose();
      } else if (mounted) {
        ZerpaiToast.error(context, 'Failed to delete package');
      }
    }
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 16, color: const Color(0xFFE5E7EB), margin: const EdgeInsets.symmetric(horizontal: 8));
  }

  Widget _buildShipDropdown() {
    return _buildToolbarButton(LucideIcons.truck, 'Ship', onPressed: () {});
  }

  Widget _buildPdfPrintDropdown(InventoryPackage pkg) {
    final orgSettings = ref.read(orgSettingsProvider).asData?.value;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () async {
            final bytes = await _generatePackagePdf(pkg, orgSettings);
            await Printing.sharePdf(
              bytes: bytes,
              filename: '${pkg.packageNumber}.pdf',
            );
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.hovered) ? AppTheme.primaryBlue : Colors.white),
            foregroundColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.hovered) ? Colors.white : AppTheme.textPrimary),
            iconColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.hovered) ? Colors.white : AppTheme.primaryBlue),
            padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            minimumSize: const WidgetStatePropertyAll(Size(160, 44)),
            alignment: Alignment.centerLeft,
            shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
          ),
          child: const Row(children: [
            Icon(LucideIcons.fileText, size: 16),
            SizedBox(width: 12),
            Text('PDF', style: TextStyle(fontSize: 14)),
          ]),
        ),
        MenuItemButton(
          onPressed: () async {
            final bytes = await _generatePackagePdf(pkg, orgSettings);
            await Printing.layoutPdf(
              onLayout: (_) async => bytes,
              name: pkg.packageNumber,
            );
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.hovered) ? AppTheme.primaryBlue : Colors.white),
            foregroundColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.hovered) ? Colors.white : AppTheme.textPrimary),
            iconColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.hovered) ? Colors.white : AppTheme.primaryBlue),
            padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            minimumSize: const WidgetStatePropertyAll(Size(160, 44)),
            alignment: Alignment.centerLeft,
            shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
          ),
          child: const Row(children: [
            Icon(LucideIcons.printer, size: 16),
            SizedBox(width: 12),
            Text('Print', style: TextStyle(fontSize: 14)),
          ]),
        ),
      ],
      builder: (context, controller, _) => _buildToolbarButton(
        LucideIcons.fileText,
        'PDF/Print',
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }

  Future<Uint8List> _generatePackagePdf(InventoryPackage pkg, OrgSettings? org) async {
    final doc = pw.Document();

    // Attempt to load company logo
    pw.MemoryImage? logoImage;
    if (org?.logoUrl != null && org!.logoUrl!.trim().isNotEmpty) {
      try {
        final res = await Dio().get<List<int>>(
          org.logoUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.data != null) {
          logoImage = pw.MemoryImage(Uint8List.fromList(res.data!));
        }
      } catch (_) {}
    }

    final dateStr = pkg.packageDate != null
        ? DateFormat('dd-MM-yyyy').format(pkg.packageDate!)
        : '-';
    final soNumber = pkg.salesOrderNumbers.isNotEmpty
        ? pkg.salesOrderNumbers.join(', ')
        : (pkg.salesOrderNumber ?? '-');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 130,
                          height: 56,
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Container(
                          width: 130,
                          height: 56,
                          color: const PdfColor.fromInt(0xFF101820),
                          child: pw.Center(
                            child: pw.Text('LOGO',
                                style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                          ),
                        ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        org?.name.trim().toUpperCase() ?? 'YOUR COMPANY',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                      if (org?.paymentStubAddress?.trim().isNotEmpty == true)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 3),
                          child: pw.Text(
                            org!.paymentStubAddress!.trim(),
                            style: const pw.TextStyle(fontSize: 9, lineSpacing: 2),
                          ),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'PACKAGE',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 28,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Package# ${pkg.packageNumber}',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              // ── Info row ────────────────────────────────────────────────
              pw.Row(
                children: [
                  _pwInfoCell('Package#', pkg.packageNumber),
                  _pwInfoCell('Order Date', dateStr),
                  _pwInfoCell('Package Date', dateStr),
                  _pwInfoCell('Sales Order#', soNumber),
                  _pwInfoCell('Total Qty', pkg.totalQty.toStringAsFixed(0)),
                ],
              ),
              pw.Divider(color: PdfColors.grey300, height: 24),
              // ── Bill To / Ship To ────────────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill To',
                            style: pw.TextStyle(
                                color: PdfColors.blue,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(pkg.customerName ?? '',
                            style: pw.TextStyle(
                                fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Ship To',
                            style: pw.TextStyle(
                                color: PdfColors.blue,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(pkg.customerName ?? '',
                            style: pw.TextStyle(
                                fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              // ── Items table ──────────────────────────────────────────────
              pw.Table(
                columnWidths: const {
                  0: pw.FixedColumnWidth(32),
                  1: pw.FlexColumnWidth(5),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FixedColumnWidth(60),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF1F2937)),
                    children: [
                      _pwHeaderCell('#'),
                      _pwHeaderCell('Item & Description'),
                      _pwHeaderCell('HSN/SAC'),
                      _pwHeaderCell('Qty', align: pw.Alignment.centerRight),
                    ],
                  ),
                  ...pkg.items.asMap().entries.map((e) {
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: e.key.isEven ? PdfColors.white : const PdfColor.fromInt(0xFFF9FAFB),
                        border: const pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey200),
                        ),
                      ),
                      children: [
                        _pwDataCell('${e.key + 1}'),
                        _pwDataCell(e.value.itemName ?? ''),
                        _pwDataCell(''),
                        _pwDataCell(
                          e.value.quantity.toStringAsFixed(0),
                          align: pw.Alignment.centerRight,
                        ),
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

  pw.Widget _pwInfoCell(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.SizedBox(height: 3),
          pw.Text(value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _pwHeaderCell(String text, {pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Align(
        alignment: align,
        child: pw.Text(text,
            style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold)),
      ),
    );
  }

  pw.Widget _pwDataCell(String text, {pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Align(
        alignment: align,
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _buildDetailTabs(InventoryPackage pkg) {
    final hasPicklists = pkg.picklistNumbers.isNotEmpty;
    final hasSalesOrders = pkg.salesOrderNumbers.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isTabsExpanded = !_isTabsExpanded),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  _buildDropdownOption(
                    'Picklists',
                    pkg.picklistNumbers.length,
                    _activeTabIndex == 0,
                    () => setState(() {
                      _activeTabIndex = 0;
                      _isTabsExpanded = true;
                    }),
                  ),
                  _buildDropdownOption(
                    'Associated sales orders',
                    pkg.salesOrderNumbers.length,
                    _activeTabIndex == 1,
                    () => setState(() {
                      _activeTabIndex = 1;
                      _isTabsExpanded = true;
                    }),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      _isTabsExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                      size: 16,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isTabsExpanded)
            Container(
              child: _activeTabIndex == 0 
                ? (hasPicklists ? _buildPicklistsTable(pkg) : _buildEmptyState('No picklists found')) 
                : (hasSalesOrders ? _buildSalesOrdersTable(pkg) : _buildEmptyState('No sales orders found')),
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
              color: isActive ? const Color(0xFF0088FF) : Colors.transparent,
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
                color: isActive ? const Color(0xFF111827) : const Color(0xFF6B7280),
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
                style: const TextStyle(fontSize: 11, color: Color(0xFF0088FF), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildPicklistsTable(InventoryPackage pkg) {
    final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFF9FAFB),
          child: Row(
            children: const [
              Expanded(flex: 3, child: Text('Picklist#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
              Expanded(flex: 3, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
              Expanded(flex: 3, child: Text('Assignee', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
              Expanded(flex: 3, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
            ],
          ),
        ),
        ...List.generate(pkg.picklistNumbers.length, (index) {
          final num = pkg.picklistNumbers[index];
          final id = pkg.picklistIds.length > index ? pkg.picklistIds[index] : null;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: id == null ? null : () => context.go('/$orgId/inventory/picklists/$id'),
                    child: Text(
                      num,
                      style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                Expanded(flex: 3, child: Text(DateFormat('dd-MM-yyyy').format(pkg.packageDate ?? DateTime.now()), style: const TextStyle(fontSize: 13))),
                const Expanded(flex: 3, child: Text('UNASSIGNED', style: TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                Expanded(
                  flex: 3,
                  child: Text(
                    'IN PROGRESS',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSalesOrdersTable(InventoryPackage pkg) {
    final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFF9FAFB),
          child: Row(
            children: const [
              Expanded(flex: 3, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
              Expanded(flex: 3, child: Text('Sales Order#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
              Expanded(flex: 3, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
              Expanded(flex: 3, child: Text('Shipment Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
            ],
          ),
        ),
        ...List.generate(pkg.salesOrderNumbers.length, (index) {
          final num = pkg.salesOrderNumbers[index];
          final id = pkg.salesOrderIds.length > index ? pkg.salesOrderIds[index] : null;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(DateFormat('dd-MM-yyyy').format(pkg.packageDate ?? DateTime.now()), style: const TextStyle(fontSize: 13))),
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: id == null ? null : () => context.go('/$orgId/sales/orders/$id'),
                    child: Text(
                      num,
                      style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'CONFIRMED',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Expanded(flex: 3, child: Text('-', style: TextStyle(fontSize: 13, color: Color(0xFF111827)))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStandardView(InventoryPackage pkg) {
    return const Center(child: Text('Standard View Content'));
  }
}

class _PackagePdfView extends ConsumerWidget {
  final InventoryPackage package;
  const _PackagePdfView({required this.package});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    return Container(
      color: const Color(0xFFF3F4F6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 800,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
                ),
                child: ClipRect(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _PdfCornerRibbon(
                          label: package.status.replaceAll('_', ' '),
                          color: _getPdfStatusColor(package.status),
                        ),
                      ),
                      Column(
                        children: [
                          _buildPdfHeader(orgSettings),
                          _buildPdfContent(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (package.notes != null && package.notes!.isNotEmpty) ...[
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Package Notes', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.paperclip, size: 12, color: Color(0xFF6B7280)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(package.notes!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1F2937))),
                  ],
                ),
                const SizedBox(height: 32),
              ],
              Container(
                width: 800,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _buildBottomDetails(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfHeader(OrgSettings? orgSettings) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
                    _formatAddress(orgSettings!.paymentStubAddress!.trim()),
                    style: const TextStyle(fontSize: 10, height: 1.5),
                  ),
                )
              else
                const Text(
                  'Address Line 1\nCity, State PIN\nCountry',
                  style: TextStyle(fontSize: 10, height: 1.5),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('PACKAGE', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text('Package# ${package.packageNumber}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            ],
          ),
        ],
      ),
    );
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

  Color _getPdfStatusColor(String status) {
    switch (status.toUpperCase().replaceAll(' ', '_')) {
      case 'PACKAGED':
        return const Color(0xFF0088FF);
      case 'SHIPPED':
        return const Color(0xFF1E8E3E);
      case 'DELIVERED':
        return const Color(0xFF009688);
      case 'NOT_SHIPPED':
        return const Color(0xFF78909C);
      default:
        return const Color(0xFFC4C4C4);
    }
  }

  String _formatAddress(String address) {
    if (address.isEmpty) return address;
    if (address.trim().startsWith('{')) {
      try {
        final data = json.decode(address);
        if (data is Map) {
          final List<String> parts = [];
          if (data['attention'] != null && data['attention'].toString().isNotEmpty) parts.add(data['attention'].toString());
          if (data['street1'] != null && data['street1'].toString().isNotEmpty) parts.add(data['street1'].toString());
          if (data['street2'] != null && data['street2'].toString().isNotEmpty) parts.add(data['street2'].toString());
          final cityStateZip = [data['city'], data['state_name'] ?? data['state'], data['pincode'] ?? data['zip_code']].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');
          if (cityStateZip.isNotEmpty) parts.add(cityStateZip);
          if (data['phone'] != null && data['phone'].toString().isNotEmpty) parts.add('Phone: ${data['phone']}');
          if (parts.isNotEmpty) return parts.join('\n');
        }
      } catch (_) {}
    }
    return address;
  }

  Widget _buildPdfContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildInfo('Package#', package.packageNumber),
              _buildInfo('Order Date', package.packageDate != null ? DateFormat('dd-MM-yyyy').format(package.packageDate!) : '-'),
              _buildInfo('Package Date', package.packageDate != null ? DateFormat('dd-MM-yyyy').format(package.packageDate!) : '-'),
              _buildInfo('Sales Order#', package.salesOrderNumber ?? '-'),
              _buildInfo('Total Qty', package.totalQty.toString()),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAddress('Bill To', package.customerName ?? 'Customer')),
              Expanded(child: _buildAddress('Ship To', package.customerName ?? 'Customer')),
            ],
          ),
          const SizedBox(height: 40),
          _buildItemsTable(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBottomDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Batches Section with Tab styling as per 2nd screenshot
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.primaryBlue, width: 2)),
                ),
                child: const Text(
                  'Batches',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Batch Detail Card matching 2nd screenshot
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.primaryBlue, width: 1.5), // Blue border as seen in focused state
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Text('BIN2', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
                    const Spacer(),
                    const Text('1 Batches', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.checkCircle2, size: 16, color: AppTheme.primaryBlue),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFF9FAFB),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('BATCH DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    Text('QUANTITY OUT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('dsdsdf', style: TextStyle(fontSize: 13, color: AppTheme.primaryBlue)),
                        SizedBox(height: 6),
                        Text('Manufacturer Batch# : sdsdsds', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        Text('Manufactured date : 2026-04-06', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        Text('Expiry Date: 2027-06-18', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      ],
                    ),
                    const Text('5 box', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAddress(String label, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const Text('Address Line 1', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
        const Text('City, State, Zip', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFF1F2937),
            child: Row(
              children: const [
                SizedBox(width: 12),
                Expanded(flex: 1, child: Text('#', style: TextStyle(color: Colors.white, fontSize: 11))),
                Expanded(flex: 6, child: Text('Item & Description', style: TextStyle(color: Colors.white, fontSize: 11))),
                Expanded(flex: 3, child: Text('HSN/SAC', style: TextStyle(color: Colors.white, fontSize: 11))),
                Expanded(flex: 2, child: Text('Qty', style: TextStyle(color: Colors.white, fontSize: 11))),
              ],
            ),
          ),
          ...List.generate(package.items.length, (index) {
            final item = package.items[index];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
              child: Row(
                children: [
                  SizedBox(width: 12),
                  Expanded(flex: 1, child: Text((index + 1).toString(), style: const TextStyle(fontSize: 12))),
                  Expanded(flex: 6, child: Text(item.itemName ?? 'Item', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  const Expanded(flex: 3, child: Text('30045037', style: TextStyle(fontSize: 12))),
                  Expanded(flex: 2, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.quantity.toStringAsFixed(2), style: const TextStyle(fontSize: 12)),
                      const Text('box', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                    ],
                  )),
                ],
              ),
            );
          }),
        ],
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

class _HeaderMenuButton extends StatelessWidget {
  final bool wrapText;
  final ValueChanged<bool> onWrapChange;
  final VoidCallback onCustomize;

  const _HeaderMenuButton({required this.wrapText, required this.onWrapChange, required this.onCustomize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      child: MenuAnchor(
        alignmentOffset: const Offset(0, 4),
        builder: (context, controller, child) => IconButton(
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(LucideIcons.sliders, size: 14, color: AppTheme.textSecondary),
          padding: EdgeInsets.zero,
        ),
        menuChildren: [
          MenuItemButton(
            onPressed: () => onWrapChange(!wrapText),
            child: Row(
              children: [
                Icon(wrapText ? LucideIcons.checkSquare : LucideIcons.square, size: 16),
                const SizedBox(width: 12),
                const Text('Wrap Text', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          MenuItemButton(
            onPressed: onCustomize,
            child: Row(
              children: const [
                Icon(LucideIcons.columns, size: 16),
                const SizedBox(width: 12),
                const Text('Customize Columns', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResizableHeaderCell extends StatefulWidget {
  final double width;
  final Widget child;
  final ValueChanged<double> onResize;

  const _ResizableHeaderCell({required this.width, required this.child, required this.onResize});

  @override
  State<_ResizableHeaderCell> createState() => _ResizableHeaderCellState();
}

class _ResizableHeaderCellState extends State<_ResizableHeaderCell> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        width: widget.width,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            Positioned(
              right: -5,
              top: 0,
              bottom: 0,
              width: 10,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) => widget.onResize(details.delta.dx),
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: Container(color: _isHovering ? AppTheme.primaryBlue.withValues(alpha: 0.2) : Colors.transparent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ColumnType { first, middle, last }

class _PackageColumn extends ConsumerWidget {
  final String title;
  final Color headerColor;
  final _ColumnType type;

  const _PackageColumn({
    required this.title,
    required this.headerColor,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesState = ref.watch(inventoryPackagesProvider);
    final packages = packagesState.packages;

    final sort = ref.watch(packageSortProvider);

    final String targetStatus = type == _ColumnType.first
        ? 'Not Shipped'
        : type == _ColumnType.middle
        ? 'Shipped'
        : 'Delivered';

    final List<InventoryPackage> filteredPackages = packages
        .where((p) => p.status == targetStatus)
        .toList();

    // Sort the list
    filteredPackages.sort((a, b) {
      int cmp = 0;
      switch (sort.field) {
        case 'Package Date':
          cmp = (a.packageDate ?? DateTime(0)).compareTo(b.packageDate ?? DateTime(0));
          break;
        case 'Package#':
          cmp = a.packageNumber.compareTo(b.packageNumber);
          break;
        case 'Carrier':
          cmp = (a.carrier ?? '').compareTo(b.carrier ?? '');
          break;
        case 'Sales Order#':
          final aSo = a.salesOrderNumbers.isNotEmpty ? a.salesOrderNumbers.first : '';
          final bSo = b.salesOrderNumbers.isNotEmpty ? b.salesOrderNumbers.first : '';
          cmp = aSo.compareTo(bSo);
          break;
        case 'Shipment Date':
          cmp = (a.shipmentDate ?? DateTime(0)).compareTo(b.shipmentDate ?? DateTime(0));
          break;
        case 'Customer Name':
          cmp = (a.customerName ?? '').compareTo(b.customerName ?? '');
          break;
        case 'Quantity':
          cmp = a.totalQty.compareTo(b.totalQty);
          break;
        case 'Created Time':
        case 'Last Modified Time':
          // Use id or packageNumber as fallback if createdAt is missing
          cmp = a.packageNumber.compareTo(b.packageNumber);
          break;
        default:
          cmp = 0;
      }
      return sort.isAscending ? cmp : -cmp;
    });

    const double headerHeight = 60.0;
    const double arrowPadding = 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: headerHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                right: type == _ColumnType.last ? 0 : -arrowPadding,
                child: ClipPath(
                  clipper: _HeaderClipper(type),
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: type == _ColumnType.last ? 16 : 32,
                    ),
                    color: headerColor,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                            fontFamily: 'Inter',
                          ),
                        ),
                        _buildColumnMoreMenu(context, ref),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: filteredPackages.isEmpty
                    ? Container(
                        width: double.infinity,
                        height: 160,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'No Records Found',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.normal,
                            fontFamily: 'Inter',
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredPackages.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          final pkg = filteredPackages[index];
                          return _PackageCard(package: pkg);
                        },
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnMoreMenu(BuildContext context, WidgetRef ref) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: const WidgetStatePropertyAll(8),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
        ),
      ),
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(LucideIcons.menu, size: 18, color: Color(0xFF4B5563)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          hoverColor: Colors.black.withValues(alpha: 0.05),
        );
      },
      menuChildren: [
        _buildColumnMenuOptions(context, ref),
      ],
    );
  }

  Widget _buildColumnMenuOptions(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColumnSortSubmenu(ref),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        _buildColumnSimpleItem(LucideIcons.import, 'Import Packages', () {}),
        _buildColumnSimpleItem(LucideIcons.upload, 'Export Packages', () {}),
        _buildColumnSimpleItem(LucideIcons.import, 'Import Shipments', () {}),
        _buildColumnSimpleItem(LucideIcons.upload, 'Export Shipments', () {}),
      ],
    );
  }

  Widget _buildColumnSortSubmenu(WidgetRef ref) {
    final sort = ref.watch(packageSortProvider);

    return SubmenuButton(
      menuStyle: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: const WidgetStatePropertyAll(8),
      ),
      menuChildren: [
        _buildSortItem(ref, 'Package Date', sort.field == 'Package Date', sort.isAscending),
        _buildSortItem(ref, 'Package#', sort.field == 'Package#', sort.isAscending),
        _buildSortItem(ref, 'Carrier', sort.field == 'Carrier', sort.isAscending),
        _buildSortItem(ref, 'Sales Order#', sort.field == 'Sales Order#', sort.isAscending),
        _buildSortItem(ref, 'Shipment Date', sort.field == 'Shipment Date', sort.isAscending),
        _buildSortItem(ref, 'Customer Name', sort.field == 'Customer Name', sort.isAscending),
        _buildSortItem(ref, 'Quantity', sort.field == 'Quantity', sort.isAscending),
        _buildSortItem(ref, 'Created Time', sort.field == 'Created Time', sort.isAscending),
        _buildSortItem(ref, 'Last Modified Time', sort.field == 'Last Modified Time', sort.isAscending),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: const [
            Text('Sort by', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSortItem(WidgetRef ref, String label, bool isActive, bool isAscending) {
    return MenuItemButton(
      onPressed: () {
        final currentSort = ref.read(packageSortProvider);
        if (currentSort.field == label) {
          // Toggle direction
          ref.read(packageSortProvider.notifier).state = (field: label, isAscending: !currentSort.isAscending);
        } else {
          // New field, default to descending for Created/Modified Time, ascending for others?
          // User said "default descending order"
          ref.read(packageSortProvider.notifier).state = (field: label, isAscending: false);
        }
      },
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(isActive ? AppTheme.primaryBlue : Colors.transparent),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
      ),
      child: Container(
        width: 160,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? Colors.white : const Color(0xFF1F2937),
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (isActive)
              Icon(
                isAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                size: 14,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnSimpleItem(IconData icon, String label, VoidCallback onTap) {
    return MenuItemButton(
      onPressed: onTap,
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final InventoryPackage package;

  const _PackageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final String dateStr = package.packageDate != null
        ? dateFormat.format(package.packageDate!)
        : '-';

    String soStr = '';
    if (package.salesOrderNumbers.isNotEmpty) {
      soStr = '  ${package.salesOrderNumbers.join(', ')}';
    }

    final String plStr = package.picklistNumbers.isNotEmpty
        ? '${package.picklistNumbers.join(', ')}  |  '
        : '';

    return InkWell(
      onTap: () {
        final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
        context.go('/$orgId/inventory/packages/${package.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  package.customerName ?? 'No Customer',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  package.weight > 0
                      ? '${package.weight.toStringAsFixed(2)} ${package.weightUnit}'
                      : '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
                children: [
                  TextSpan(text: package.packageNumber),
                  if (soStr.isNotEmpty)
                    TextSpan(
                      text: soStr,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              plStr + dateStr,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  final _ColumnType type;
  const _HeaderClipper(this.type);

  @override
  Path getClip(Size size) {
    final path = Path();
    final double arrowWidth = 20.0;
    path.moveTo(0, 0);
    if (type == _ColumnType.last) {
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.lineTo(size.width - arrowWidth, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - arrowWidth, size.height);
    }
    path.lineTo(0, size.height);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}



/// Popup Dialog for creating Dispatch Entrypasses.
class DispatchEntrypassDialog extends ConsumerStatefulWidget {
  final Picklist? initialPicklist;

  const DispatchEntrypassDialog({super.key, this.initialPicklist});

  @override
  ConsumerState<DispatchEntrypassDialog> createState() =>
      _DispatchEntrypassDialogState();
}

class _DispatchEntrypassDialogState
    extends ConsumerState<DispatchEntrypassDialog> {
  final Set<String> _selectedIds = {};
  List<Picklist> _allPicklists = [];
  List<Picklist> _filteredPicklists = [];
  bool _isLoading = true;
  bool _showEntrypassOnly = false;

  final TextEditingController _picklistSearchCtrl = TextEditingController();
  final TextEditingController _soSearchCtrl = TextEditingController();
  final TextEditingController _customerSearchCtrl = TextEditingController();

  bool _showPicklistSearch = false;
  bool _showSoSearch = false;
  bool _showCustomerSearch = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _picklistSearchCtrl.dispose();
    _soSearchCtrl.dispose();
    _customerSearchCtrl.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final picklistsAsync = ref.read(picklistsProvider);
      picklistsAsync.whenData((all) {
        setState(() {
          if (widget.initialPicklist != null) {
            _allPicklists = [widget.initialPicklist!];
            _selectedIds.add(widget.initialPicklist!.id ?? '');
          } else {
            _allPicklists = all.where((p) {
              final isApproved = p.status.toUpperCase() == 'APPROVED';
              if (_showEntrypassOnly) {
                return isApproved && p.isEntrypass == true;
              } else {
                return isApproved && p.isEntrypass == false;
              }
            }).toList();
          }
          _filterPicklists();
          _isLoading = false;
        });
      });
    });
  }

  void _filterPicklists() {
    setState(() {
      _filteredPicklists = _allPicklists.where((p) {
        final picklistMatch =
            _picklistSearchCtrl.text.isEmpty ||
            p.picklistNumber.toLowerCase().contains(
              _picklistSearchCtrl.text.toLowerCase(),
            );
        final soMatch =
            _soSearchCtrl.text.isEmpty ||
            (p.salesOrderNumber ?? '').toLowerCase().contains(
              _soSearchCtrl.text.toLowerCase(),
            );
        final customerMatch =
            _customerSearchCtrl.text.isEmpty ||
            (p.customerName ?? '').toLowerCase().contains(
              _customerSearchCtrl.text.toLowerCase(),
            );
        return picklistMatch && soMatch && customerMatch;
      }).toList();
    });
  }

  void _toggleAll(bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedIds.addAll(
          _filteredPicklists
              .map((p) => p.id ?? '')
              .where((id) => id.isNotEmpty),
        );
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleView() {
    setState(() {
      _showEntrypassOnly = !_showEntrypassOnly;
      _isLoading = true;
      _selectedIds.clear();
      _showPicklistSearch = false;
      _showSoSearch = false;
      _showCustomerSearch = false;
      _picklistSearchCtrl.clear();
      _soSearchCtrl.clear();
      _customerSearchCtrl.clear();
    });
    _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 40), // Top padding 0
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Container(
        width: 1200,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPicklists.isEmpty
                  ? _buildEmptyState()
                  : _buildTable(),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.truck, size: 22, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          const Text(
            'Create Dispatch Entrypass',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              LucideIcons.x,
              size: 20,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: _toggleView,
            child: Text(
              _showEntrypassOnly
                  ? 'PENDING ENRYPASS APPROVEL'
                  : 'APROVED ENTRYPASS',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
                letterSpacing: 0.5,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No approved records found',
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final bool allSelected =
        _selectedIds.length == _filteredPicklists.length &&
        _filteredPicklists.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: InkWell(
            onTap: _toggleView,
            child: Text(
              _showEntrypassOnly
                  ? 'PENDING ENRYPASS APPROVEL'
                  : 'APROVED ENTRYPASS',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
                letterSpacing: 0.5,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        // Table Header
        Container(
          color: AppTheme.bgLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              if (!_showEntrypassOnly)
                SizedBox(
                  width: 40,
                  child: Checkbox(
                    value: allSelected,
                    onChanged: _toggleAll,
                    activeColor: AppTheme.primaryBlue,
                  ),
                )
              else
                const SizedBox(width: 40),
              const Expanded(
                flex: 1,
                child: Text('DATE', style: _tableHeaderStyle),
              ),
              Expanded(
                flex: 2,
                child: _buildSearchHeader(
                  'PICKLIST#',
                  _showPicklistSearch,
                  _picklistSearchCtrl,
                  () => setState(
                    () => _showPicklistSearch = !_showPicklistSearch,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: _buildSearchHeader(
                  'SALES ORDER#',
                  _showSoSearch,
                  _soSearchCtrl,
                  () => setState(() => _showSoSearch = !_showSoSearch),
                ),
              ),
              Expanded(
                flex: 2,
                child: _buildSearchHeader(
                  'CUSTOMER NAME',
                  _showCustomerSearch,
                  _customerSearchCtrl,
                  () => setState(
                    () => _showCustomerSearch = !_showCustomerSearch,
                  ),
                ),
              ),
              const Expanded(
                flex: 1,
                child: Text('STATUS', style: _tableHeaderStyle),
              ),
              const Expanded(
                flex: 2,
                child: Text('ASSIGNEE', style: _tableHeaderStyle),
              ),
              const Expanded(
                flex: 2,
                child: Text('LOCATION', style: _tableHeaderStyle),
              ),
              const Expanded(
                flex: 2,
                child: Text('NOTES', style: _tableHeaderStyle),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        // Table Body
        Expanded(
          child: ListView.separated(
            itemCount: _filteredPicklists.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.borderColor),
            itemBuilder: (context, index) {
              final p = _filteredPicklists[index];
              final isSelected = _selectedIds.contains(p.id ?? '');

              return InkWell(
                onTap: () => _toggleSelection(p.id ?? ''),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      if (!_showEntrypassOnly)
                        SizedBox(
                          width: 40,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(p.id ?? ''),
                            activeColor: AppTheme.primaryBlue,
                          ),
                        )
                      else
                        const SizedBox(width: 40),
                      Expanded(
                        flex: 1,
                        child: Text(
                          p.date != null
                              ? DateFormat('dd-MM-yyyy').format(p.date!)
                              : '-',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          p.picklistNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          p.salesOrderNumber ?? '-',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          p.customerName ?? '-',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Approved',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF009688),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          p.assignee ?? '-',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          p.location ?? '-',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          p.notes ?? '-',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
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
            label: 'Generate Entrypass',
            onPressed: (_selectedIds.isEmpty || _showEntrypassOnly)
                ? null
                : () async {
                    final selectedPicklists = _allPicklists
                        .where((p) => _selectedIds.contains(p.id ?? ''))
                        .toList();

                    // Add selected picklists to the global pending dispatched list
                    final currentPending = ref.read(
                      pendingDispatchedPicklistsProvider,
                    );
                    ref
                        .read(pendingDispatchedPicklistsProvider.notifier)
                        .state = [
                      ...currentPending,
                      ...selectedPicklists,
                    ];

                    // Update the local list to remove the selected ones (they are "Dispatched" now)
                    setState(() {
                      _allPicklists.removeWhere(
                        (p) => _selectedIds.contains(p.id ?? ''),
                      );
                      _filterPicklists();
                      _selectedIds.clear();
                    });

                    // Persist to database
                    for (final p in selectedPicklists) {
                      if (p.id != null) {
                        ref.read(picklistsProvider.notifier).updatePicklist(
                          p.id!,
                          {'is_entrypass': true},
                        );
                      }
                    }

                    // Optional: Show success toast or navigate
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Generated Entrypass for ${selectedPicklists.length} picklists',
                        ),
                      ),
                    );

                    Navigator.pop(context);
                  },
          ),
        ],
      ),
    );
  }

  static const _tableHeaderStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppTheme.textSecondary,
    fontFamily: 'Inter',
  );

  Widget _buildSearchHeader(
    String label,
    bool isSearching,
    TextEditingController controller,
    VoidCallback onToggle,
  ) {
    return Row(
      children: [
        if (!isSearching) ...[
          Expanded(child: Text(label, style: _tableHeaderStyle)),
          IconButton(
            onPressed: onToggle,
            icon: const Icon(LucideIcons.search, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
            color: AppTheme.textSecondary,
          ),
        ] else ...[
          Expanded(
            child: SizedBox(
              height: 24,
              child: TextField(
                controller: controller,
                autofocus: true,
                onChanged: (_) => _filterPicklists(),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(fontSize: 11),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppTheme.primaryBlue),
                  ),
                  isDense: true,
                  suffixIcon: InkWell(
                    onTap: () {
                      controller.clear();
                      onToggle();
                      _filterPicklists();
                    },
                    child: const Icon(
                      LucideIcons.x,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
