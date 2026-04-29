import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_data_table_shell.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_search_field.dart';
// import 'package:zerpai_erp/core/routing/app_routes.dart';

import '../models/inventory_picklist_model.dart';
import '../providers/inventory_picklists_provider.dart';
import 'package:zerpai_erp/modules/auth/providers/user_provider.dart';

/// Performance-optimized List Screen for Inventory Picklists.
/// Supports master-detail view when [id] is provided.
class InventoryPicklistsListScreen extends ConsumerStatefulWidget {
  final String? id;

  const InventoryPicklistsListScreen({super.key, this.id});

  @override
  ConsumerState<InventoryPicklistsListScreen> createState() => _InventoryPicklistsListScreenState();
}

class _InventoryPicklistsListScreenState extends ConsumerState<InventoryPicklistsListScreen> {
  String _selectedView = 'All';
  final Set<String> _selectedIds = {};
  final List<String> _visibleColumns = [
    'date',
    'picklist#',
    'status',
    'assignee',
    'location',
    'notes',
    'customer_name',
    'sales_order_number',
  ];

  final Map<String, String> _columnLabels = {
    'date': 'DATE',
    'picklist#': 'PICKLIST#',
    'status': 'STATUS',
    'assignee': 'ASSIGNEE',
    'location': 'LOCATION',
    'notes': 'NOTES',
    'customer_name': 'CUSTOMER NAME',
    'sales_order_number': 'SALES ORDER#',
  };

  void _toggleSelection(String id) {
    if (id.isEmpty) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleAll(List<Picklist> picklists) {
    setState(() {
      if (_selectedIds.length == picklists.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        for (final p in picklists) {
          if (p.id != null) {
            _selectedIds.add(p.id!);
          }
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
                          decoration: BoxDecoration(
                            color: AppTheme.bgDisabled,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_visibleColumns.length} of ${_columnLabels.length} Selected',
                            style: AppTheme.metaHelper,
                          ),
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
                    const ZSearchField(hintText: 'Search columns...'),
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
                                    if (_visibleColumns.length > 1) {
                                      _visibleColumns.remove(entry.key);
                                    }
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

  bool _isNewCustomViewOpen = false;

  @override
  Widget build(BuildContext context) {
    final picklistsAsync = ref.watch(picklistsProvider);
    final isDetailOpen = widget.id != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Row(
            children: [
              // Master List
              Expanded(
                flex: isDetailOpen ? 3 : 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Actions
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                      ),
                      child: Row(
                        children: [
                          _buildViewSelector(),
                          const Spacer(),
                          _buildActionIcons(),
                          const SizedBox(width: 12),
                          _buildNewButton(),
                          const SizedBox(width: 8),
                          _buildMoreMenu(),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: picklistsAsync.when(
                        data: (picklists) => _buildVirtualizedTable(picklists),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(child: Text('Error: $err')),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Side Detail Panel
              if (isDetailOpen)
                const VerticalDivider(width: 1),
              if (isDetailOpen)
                Expanded(
                  flex: 7,
                  child: _PicklistDetailPanel(
                    id: widget.id!,
                    onClose: () {
                      final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
                      context.go('/$orgId/inventory/picklists');
                    },
                  ),
                ),
            ],
          ),
          if (_isNewCustomViewOpen)
            Positioned.fill(
              child: NewCustomViewOverlay(
                onClose: () => setState(() => _isNewCustomViewOpen = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
        surfaceTintColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: const WidgetStatePropertyAll(8),
      ),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) controller.close();
            else controller.open();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedView == 'All' ? 'All Picklists' : _selectedView,
                style: AppTheme.pageTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevronDown, size: 18, color: AppTheme.primaryBlue),
            ],
          ),
        );
      },
      menuChildren: [
        _buildViewMenuItem('All'),
        _buildViewMenuItem('Yet to Start'),
        _buildViewMenuItem('In Progress'),
        _buildViewMenuItem('On Hold'),
        _buildViewMenuItem('Completed'),
        _buildViewMenuItem('Force Complete'),
        _buildViewMenuItem('Approved'),
        const Divider(height: 1, color: AppTheme.borderColor),
        MenuItemButton(
          onPressed: () {
            setState(() {
              _isNewCustomViewOpen = true;
            });
          },
          style: _menuItemButtonStyle(),
          child: Row(
            children: [
              const Icon(LucideIcons.plusCircle, size: 16, color: AppTheme.primaryBlue),
              const SizedBox(width: 12),
              Text('New Custom View', style: AppTheme.bodyText.copyWith(color: AppTheme.primaryBlue, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewMenuItem(String label) {
    final isActive = _selectedView == label;
    return MenuItemButton(
      onPressed: () => setState(() => _selectedView = label),
      style: _menuItemButtonStyle(isActive: isActive),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Icon(LucideIcons.star, size: 14, color: isActive ? Colors.white70 : AppTheme.borderColor),
        ],
      ),
    );
  }

  Widget _buildActionIcons() {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(LucideIcons.search, size: 18, color: AppTheme.textSecondary),
          tooltip: 'Search',
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(LucideIcons.filter, size: 18, color: AppTheme.textSecondary),
          tooltip: 'Filter',
        ),
      ],
    );
  }

  Widget _buildNewButton() {
    final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '0000000000';
    return ZButton.primary(
      label: 'New',
      icon: LucideIcons.plus,
      onPressed: () => context.push('/$orgId/inventory/picklists/create'),
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
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppTheme.space4)),
          )),
        ),
        builder: (context, controller, child) {
          return IconButton(
            onPressed: () {
              if (controller.isOpen) controller.close();
              else controller.open();
            },
            icon: const Icon(LucideIcons.moreHorizontal, size: 16, color: AppTheme.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          );
        },
        menuChildren: [
          SubmenuButton(
            menuStyle: MenuStyle(
              backgroundColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
              surfaceTintColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              elevation: const WidgetStatePropertyAll(8),
            ),
            style: _menuItemButtonStyle(isHeader: true),
            menuChildren: [
              _buildSortMenuItem('Date'),
              _buildSortMenuItem('Picklist#'),
              _buildSortMenuItem('Created Time', isActive: true),
              _buildSortMenuItem('Last Modified Time'),
            ],
            child: const Row(
              children: [
                Icon(LucideIcons.arrowUpDown, size: 16),
                SizedBox(width: 12),
                Text('Sort by', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Spacer(),
                Icon(LucideIcons.chevronRight, size: 16),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.bgDisabled),
          MenuItemButton(
            onPressed: () => ref.read(picklistsProvider.notifier).refresh(),
            style: _menuItemButtonStyle(),
            child: const Row(
              children: [
                Icon(LucideIcons.refreshCw, size: 18),
                SizedBox(width: 15),
                Text('Refresh List', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortMenuItem(String label, {bool isActive = false}) {
    return MenuItemButton(
      onPressed: () {},
      style: _menuItemButtonStyle(isActive: isActive),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          if (isActive) const Icon(LucideIcons.arrowUp, size: 16),
        ],
      ),
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
  Widget _buildVirtualizedTable(List<Picklist> allPicklists) {
    // Filter by selected view status
    final picklists = _selectedView == 'All'
        ? allPicklists
        : allPicklists.where((p) {
            final statusUpper = p.status.toUpperCase().replaceAll(' ', '_');
            switch (_selectedView) {
              case 'Yet to Start': return statusUpper == 'YET_TO_START' || statusUpper == 'YET_TO_PICK';
              case 'In Progress': return statusUpper == 'IN_PROGRESS';
              case 'On Hold': return statusUpper == 'ON_HOLD';
              case 'Completed': return statusUpper == 'COMPLETED';
              case 'Force Complete': return statusUpper == 'FORCE_COMPLETE';
              case 'Approved': return statusUpper == 'APPROVED';
              default: return true;
            }
          }).toList();
    if (picklists.isEmpty) return _buildEmptyState();

    final isDetailOpen = widget.id != null;
    if (isDetailOpen) {
      return _buildCompactList(picklists);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic widths based on available width
        final screenWidth = math.max(constraints.maxWidth, 1000.0);
        final columnWidths = _calculateColumnWidths(screenWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: screenWidth,
            child: ZDataTableShell(
              header: _buildTableHeader(columnWidths, picklists),
              body: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: picklists.length,
                itemExtent: 40, // High density Zoho style
                itemBuilder: (context, index) {
                  return _buildVirtualRow(picklists[index], columnWidths, screenWidth);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactList(List<Picklist> picklists) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: picklists.length,
      itemBuilder: (context, index) {
        final picklist = picklists[index];
        final isSelected = _selectedIds.contains(picklist.id);
        final isActive = widget.id == picklist.id;

        return InkWell(
          onTap: () {
            final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
            context.go('/$orgId/inventory/picklists/${picklist.id}');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isActive 
                  ? const Color(0xFFF0F7FF) // Light blue background for active
                  : Colors.transparent,
              border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: InkWell(
                    onTap: () => _toggleSelection(picklist.id ?? ''),
                    child: _buildCheckboxWidget(isSelected),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        picklist.picklistNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getFormattedStatus(picklist.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(picklist.status),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  picklist.date != null ? DateFormat('dd-MM-yyyy').format(picklist.date!) : '-',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFormattedStatus(String status) {
    final statusUpper = status.toUpperCase().replaceAll(' ', '_');
    switch (statusUpper) {
      case 'YET_TO_START': return 'Yet to Start';
      case 'YET_TO_PICK': return 'Yet to Start';
      case 'IN_PROGRESS': return 'In Progress';
      case 'ON_HOLD': return 'On Hold';
      case 'COMPLETED': return 'Completed';
      case 'FORCE_COMPLETE': return 'Force Complete';
      case 'APPROVED': return 'Approved';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    final statusUpper = status.toUpperCase().replaceAll(' ', '_');
    switch (statusUpper) {
      case 'YET_TO_START': return const Color(0xFF5F6368);
      case 'YET_TO_PICK': return const Color(0xFF5F6368);
      case 'IN_PROGRESS': return const Color(0xFFE65100);
      case 'ON_HOLD': return const Color(0xFFD93025);
      case 'COMPLETED': return const Color(0xFF1E8E3E);
      case 'FORCE_COMPLETE': return const Color(0xFF3F51B5);
      case 'APPROVED': return const Color(0xFF009688);
      default: return const Color(0xFF5F6368);
    }
  }

  Map<String, double> _calculateColumnWidths(double totalWidth) {
    const staticPrefixWidth = 84.0; // Slider + Checkbox space
    
    final Map<String, ({double min, double flex})> metrics = {
      'date': (min: 102.0, flex: 1.0),
      'picklist#': (min: 120.0, flex: 2.0),
      'status': (min: 140.0, flex: 2.0),
      'assignee': (min: 160.0, flex: 3.0),
      'location': (min: 200.0, flex: 4.0),
      'notes': (min: 150.0, flex: 2.0),
      'created_time': (min: 160.0, flex: 1.5),
      'modified_time': (min: 160.0, flex: 1.5),
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

  Widget _buildTableHeader(Map<String, double> columnWidths, List<Picklist> picklists) {
    return Container(
      height: 36, // Zoho style high density header
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          _buildConfigIcon(),
          const SizedBox(width: 12),
          _buildSelectAllCheckbox(picklists),
          const SizedBox(width: 12),
          ..._visibleColumns.map((colId) {
            return _buildHeaderCell(_columnLabels[colId]!, width: columnWidths[colId]!);
          }),
        ],
      ),
    );
  }

  Widget _buildVirtualRow(Picklist picklist, Map<String, double> columnWidths, double minWidth) {
    final isSelected = _selectedIds.contains(picklist.id);
    final isActive = widget.id == picklist.id;

    return InkWell(
      onTap: () {
        final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
        context.go('/$orgId/inventory/picklists/${picklist.id}');
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isActive 
              ? AppTheme.selectionActiveBg 
              : (isSelected ? const Color(0xFFF0F7FF) : Colors.transparent),
          border: const Border(bottom: BorderSide(color: AppTheme.bgDisabled)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            const SizedBox(width: 16), // Slider placeholder
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _toggleSelection(picklist.id ?? ''),
              child: _buildCheckboxWidget(isSelected),
            ),
            const SizedBox(width: 12),
            ..._visibleColumns.map((colId) {
              return _buildCell(picklist, colId, width: columnWidths[colId]!);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigIcon() {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
        surfaceTintColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
        elevation: const WidgetStatePropertyAll(8),
      ),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) controller.close();
            else controller.open();
          },
          child: const Icon(LucideIcons.sliders, size: 16, color: AppTheme.primaryBlue),
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: _showCustomizeColumnsDialog,
          style: _menuItemButtonStyle(),
          child: const Row(
            children: [
              Icon(LucideIcons.columns, size: 18),
              SizedBox(width: 12),
              Text('Customize Columns'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectAllCheckbox(List<Picklist> picklists) {
    final isAllSelected = picklists.isNotEmpty && _selectedIds.length == picklists.length;
    final isPartiallySelected = _selectedIds.isNotEmpty && _selectedIds.length < picklists.length;

    return InkWell(
      onTap: () => _toggleAll(picklists),
      child: _buildCheckboxWidget(isAllSelected, isPartially: isPartiallySelected),
    );
  }

  Widget _buildCheckboxWidget(bool isSelected, {bool isPartially = false}) {
    if (isSelected || isPartially) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Center(
          child: Icon(
            isPartially ? LucideIcons.minus : LucideIcons.check,
            size: 14,
            color: Colors.white,
          ),
        ),
      );
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppTheme.borderColor, width: 1.5),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        style: AppTheme.tableHeader.copyWith(
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCell(Picklist picklist, String colId, {double? width}) {
    Widget content;
    switch (colId) {
      case 'date':
        content = Text(
          DateFormat('dd-MM-yyyy').format(picklist.date ?? DateTime.now()),
          style: AppTheme.tableCell,
        );
        break;
      case 'picklist#':
        content = Text(
          picklist.picklistNumber,
          style: AppTheme.tableCell.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        );
        break;
      case 'status':
        final textColor = _getStatusColor(picklist.status);
        final displayStatus = _getFormattedStatus(picklist.status);
        content = Text(
          displayStatus,
          style: AppTheme.tableCell.copyWith(
            color: textColor,
            fontWeight: FontWeight.w400,
          ),
        );
        break;
      case 'assignee':
        content = Consumer(
          builder: (context, ref, _) {
            final usersAsync = ref.watch(allUsersProvider);
            final text = usersAsync.maybeWhen(
              data: (users) {
                final found = users.where((u) => u.id == picklist.assignee || u.fullName == picklist.assignee).firstOrNull;
                return found?.fullName ?? picklist.assignee ?? 'Unassigned';
              },
              orElse: () => picklist.assignee ?? 'Unassigned',
            );
            
            return Text(
              text,
              style: AppTheme.tableCell.copyWith(
                fontWeight: text == 'Unassigned' ? FontWeight.w400 : FontWeight.w600,
                color: text == 'Unassigned' ? AppTheme.textSecondary : AppTheme.textPrimary,
              ),
            );
          },
        );
        break;
      case 'location':
        content = Text(
          picklist.location ?? '-',
          style: AppTheme.tableCell.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );
        break;
      case 'notes':
        content = Text(
          picklist.notes ?? '-',
          style: AppTheme.tableCell,
        );
        break;
      case 'customer_name':
        content = Text(
          picklist.customerName ?? '-',
          style: AppTheme.tableCell,
        );
        break;
      case 'sales_order_number':
        content = InkWell(
          onTap: () {
            // Navigate to SO if needed
          },
          child: Text(
            picklist.salesOrderNumber != null ? '[${picklist.salesOrderNumber}]' : '-',
            style: AppTheme.tableCell.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w400,
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.primaryBlue.withValues(alpha: 0.3),
            ),
          ),
        );
        break;
      default:
        content = const Text('-');
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(child: content, alignment: Alignment.centerLeft),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.package, size: 48, color: AppTheme.bgDisabled),
          SizedBox(height: 16),
          Text(
            'No picklists found',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }
}

class NewCustomViewOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const NewCustomViewOverlay({super.key, required this.onClose});

  @override
  State<NewCustomViewOverlay> createState() => _NewCustomViewOverlayState();
}

class _NewCustomViewOverlayState extends State<NewCustomViewOverlay> {
  String _logic = 'AND';
  final List<String> _availableColumns = [
    'Date', 'Status', 'Assignee', 'Location', 'Notes', 'Customer Name', 'Sales Order#'
  ];
  final List<String> _selectedColumns = ['Picklist#'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Text('New Custom View', style: AppTheme.pageTitle.copyWith(fontSize: 18)),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(LucideIcons.x, size: 20, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Name*', style: TextStyle(color: Color(0xFFD93025), fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(
                        width: 400,
                        child: TextField(
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.borderColor)),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.borderColor)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryBlue)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(LucideIcons.star, size: 18, color: AppTheme.borderColor),
                      const SizedBox(width: 8),
                      const Text('Mark as Favorite', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text('Define the criteria ( if any )', style: AppTheme.sectionHeader.copyWith(fontSize: 16)),
                  const SizedBox(height: 24),
                  _buildCriteriaRow(1),
                  const SizedBox(height: 12),
                  _buildLogicSelector(),
                  const SizedBox(height: 12),
                  _buildCriteriaRow(2),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {},
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.plusCircle, size: 16, color: AppTheme.primaryBlue),
                        SizedBox(width: 8),
                        Text('Add Criterion', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text('Columns Preference:', style: AppTheme.sectionHeader.copyWith(fontSize: 14)),
                  const SizedBox(height: 24),
                  _buildColumnsPreferencePanes(),
                  const SizedBox(height: 48),
                  Text('Visibility Preference', style: AppTheme.sectionHeader.copyWith(fontSize: 16)),
                  const SizedBox(height: 24),
                  _buildVisibilityPreference(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                ZButton.primary(
                  label: 'Save',
                  onPressed: widget.onClose,
                ),
                const SizedBox(width: 12),
                ZButton.secondary(
                  label: 'Cancel',
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaRow(int index) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
            color: Colors.white,
          ),
          child: Text('$index', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ),
        Container(
          width: 200,
          height: 36,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.borderColor),
              bottom: BorderSide(color: AppTheme.borderColor),
              right: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          child: const Row(
            children: [
              SizedBox(width: 12),
              Text('Select a field', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Spacer(),
              Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.textSecondary),
              SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 200,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            children: [
              SizedBox(width: 12),
              Text('Select a comparator', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Spacer(),
              Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.textSecondary),
              SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const SizedBox(
          width: 400,
          height: 36,
          child: TextField(
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              fillColor: Color(0xFFF1F3F4),
              filled: true,
              border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.borderColor)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.borderColor)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Icon(LucideIcons.plus, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        const Icon(LucideIcons.trash2, size: 18, color: AppTheme.textSecondary),
      ],
    );
  }

  Widget _buildLogicSelector() {
    return Container(
      width: 80,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: PopupMenuButton<String>(
        onSelected: (val) => setState(() => _logic = val),
        offset: const Offset(0, 36),
        child: Row(
          children: [
            Text(_logic, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600, fontSize: 12)),
            const Spacer(),
            const Icon(LucideIcons.chevronDown, size: 12, color: AppTheme.primaryBlue),
          ],
        ),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'AND', child: Text('AND')),
          const PopupMenuItem(value: 'OR', child: Text('OR')),
        ],
      ),
    );
  }

  Widget _buildColumnsPreferencePanes() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AVAILABLE COLUMNS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: ZSearchField(hintText: 'Search'),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        children: _availableColumns.map((col) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.gripVertical, size: 14, color: AppTheme.borderColor),
                                const SizedBox(width: 12),
                                Text(col, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.checkCircle, size: 14, color: Color(0xFF1E8E3E)),
                  SizedBox(width: 8),
                  Text('SELECTED COLUMNS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView(
                  children: _selectedColumns.map((col) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.gripVertical, size: 14, color: AppTheme.borderColor),
                          const SizedBox(width: 12),
                          Text(col, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 4),
                          const Text('*', style: TextStyle(color: Color(0xFFD93025))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityPreference() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Share With', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildVisibilityOption('Only Me', LucideIcons.lock, false),
              const SizedBox(width: 16),
              _buildVisibilityOption('Only Selected Users & Roles', LucideIcons.user, true),
              const SizedBox(width: 16),
              _buildVisibilityOption('Everyone', LucideIcons.fileText, false),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AppTheme.borderColor)),
                  ),
                  child: const Row(
                    children: [
                      Text('Users', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 8),
                      Icon(LucideIcons.chevronDown, size: 14),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Select Users', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const Spacer(),
                const Icon(LucideIcons.plusCircle, size: 16, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text('Add Users', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 48),
          const Center(
            child: Text(
              'You haven\'t shared this Custom View with any users yet. Select the users or roles to share it with and provide their access permissions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityOption(String label, IconData icon, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: selected ? AppTheme.primaryBlue : AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? AppTheme.primaryBlue : AppTheme.borderColor, width: selected ? 5 : 1),
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Icon(icon, size: 14, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

/// side detail panel for picklists
class _PicklistDetailPanel extends ConsumerStatefulWidget {
  final String id;
  final VoidCallback onClose;

  const _PicklistDetailPanel({required this.id, required this.onClose});

  @override
  ConsumerState<_PicklistDetailPanel> createState() => _PicklistDetailPanelState();
}

class _PicklistDetailPanelState extends ConsumerState<_PicklistDetailPanel> {
  bool _showPdfView = false;
  bool _isAssociatedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final picklistAsync = ref.watch(picklistByIdProvider(widget.id));

    return Column(
      children: [
        // Panel Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              picklistAsync.when(
                data: (p) => Text(
                  p?.picklistNumber ?? 'Picklist Detail',
                  style: AppTheme.pageTitle.copyWith(fontSize: 18),
                ),
                loading: () => const Text('Loading...'),
                error: (_, __) => const Text('Error'),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(LucideIcons.messageSquare, size: 18, color: AppTheme.textSecondary),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(LucideIcons.x, size: 20, color: AppTheme.errorRed),
              ),
            ],
          ),
        ),

        // Action Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            color: Color(0xFFF8F9FA),
          ),
          child: Row(
            children: [
              _buildToolbarButton(LucideIcons.edit, 'Edit', onPressed: () {
                final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
                context.push('/$orgId/inventory/picklists/edit/${widget.id}?mode=edit');
              }),
              _buildToolbarDivider(),
              _buildPdfPrintDropdown(context),
              _buildToolbarDivider(),
              _buildToolbarButton(
                LucideIcons.trash2,
                'Delete',
                onPressed: () => _showDeleteConfirmation(context),
              ),
              _buildToolbarDivider(),
              _buildToolbarButton(
                LucideIcons.refreshCw,
                'Update Picklist',
                onPressed: () {
                  final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
                  context.push('/$orgId/inventory/picklists/edit/${widget.id}?mode=update');
                },
              ),
              _buildToolbarDivider(),
              _buildStatusDropdown(context),
            ],
          ),
        ),

        // Panel Content
        Expanded(
          child: picklistAsync.when(
            data: (p) {
              if (p == null) return const Center(child: Text('Picklist not found'));
              
              return Column(
                children: [
                  Expanded(
                    child: _showPdfView 
                      ? _PicklistPdfView(picklist: p) 
                      : _buildDetailContent(context, p),
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

  Widget _buildToolbarButton(IconData icon, String label, {VoidCallback? onPressed, bool hasDropdown = false}) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
            if (hasDropdown) ...[
              const SizedBox(width: 6),
              const Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.textSecondary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPdfPrintDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      onSelected: (value) {
        if (value == 'pdf') {
          // Trigger PDF download logic
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading PDF...'), duration: Duration(seconds: 1)),
          );
        } else if (value == 'print') {
          // Trigger Print logic
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem(
          value: 'pdf',
          icon: LucideIcons.fileText,
          label: 'Export as PDF',
        ),
        _buildPopupItem(
          value: 'print',
          icon: LucideIcons.printer,
          label: 'Print',
        ),
      ],
      child: _buildToolbarButton(LucideIcons.fileText, 'PDF/Print', hasDropdown: true),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 4,
      onSelected: (value) {
        ref.read(picklistsProvider.notifier).updatePicklistStatus(widget.id, value);
      },
      itemBuilder: (context) => [
        _buildPopupItem(
          value: 'DRAFT',
          icon: LucideIcons.fileEdit,
          label: 'Draft',
        ),
        _buildPopupItem(
          value: 'CONFIRMED',
          icon: LucideIcons.check,
          label: 'Confirmed',
        ),
        _buildPopupItem(
          value: 'ON_HOLD',
          icon: LucideIcons.pauseCircle,
          label: 'On Hold',
        ),
        _buildPopupItem(
          value: 'COMPLETED',
          icon: LucideIcons.checkCircle,
          label: 'Completed',
        ),
        _buildPopupItem(
          value: 'CANCELLED',
          icon: LucideIcons.xCircle,
          label: 'Cancelled',
        ),
      ],
      child: _buildToolbarButton(LucideIcons.settings, 'Set status', hasDropdown: true),
    );
  }

  PopupMenuItem<String> _buildPopupItem({
    required String value,
    required IconData icon,
    required String label,
  }) {
    bool isHovered = false;
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: StatefulBuilder(
        builder: (context, setState) {
          return MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
                borderRadius: isHovered ? BorderRadius.circular(6) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isHovered ? Colors.white : const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isHovered ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Picklist',
      message: 'Are you sure you want to delete this picklist? This action cannot be undone.',
      confirmLabel: 'Delete',
      variant: ZerpaiConfirmationVariant.danger,
    );

    if (confirmed) {
      await ref.read(picklistsProvider.notifier).deletePicklist(widget.id);
      if (context.mounted) {
        widget.onClose(); // Close the panel after deletion
      }
    }
  }

  Widget _buildToolbarDivider() {
    return Container(
      height: 16,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppTheme.borderColor,
    );
  }

  Widget _buildDetailContent(BuildContext context, Picklist p) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Associated Sales Orders Expandable
          _buildAssociatedSection(p),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Assignee Row
                Row(
                  children: [
                    const SizedBox(width: 100, child: Text('Assignee', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 250,
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Consumer(
                          builder: (context, ref, _) {
                            final usersAsync = ref.watch(allUsersProvider);
                            final assigneeName = usersAsync.maybeWhen(
                              data: (users) {
                                final found = users.where((u) => u.id == p.assignee || u.fullName == p.assignee).firstOrNull;
                                return found?.fullName ?? p.assignee ?? 'Unassigned';
                              },
                              orElse: () => p.assignee ?? 'Unassigned',
                            );
                            
                            return Row(
                              children: [
                                const SizedBox(width: 12),
                                Text(assigneeName, style: const TextStyle(fontSize: 13)),
                                const Spacer(),
                                if (p.assignee != null)
                                  const Icon(LucideIcons.x, size: 14, color: AppTheme.errorRed),
                                const SizedBox(width: 8),
                                const VerticalDivider(width: 1, color: AppTheme.borderColor),
                                const SizedBox(width: 8),
                                const Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 8),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),

                // Show PDF View Toggle - Moved here
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Show PDF View', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _showPdfView,
                        onChanged: (val) => setState(() => _showPdfView = val),
                        activeThumbColor: AppTheme.primaryBlue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Info Cards Grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildInfoBlock('Picklist', p.picklistNumber),
                      _buildInfoBlock('Expected Date', DateFormat('dd-MM-yyyy').format(p.date ?? DateTime.now())),
                      _buildInfoBlock('Location', p.location ?? 'ZABNIX PRIVATE LIMITED'),
                      _buildInfoBlock('Group', 'No Grouping'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Items Table
                const Text('Items', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 16),
                _buildItemsTable(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssociatedSection(Picklist p) {
    // Get unique sales orders from items
    final uniqueSOs = <String, String>{};
    for (final item in p.items) {
      if (item.salesOrderNumber != null && item.salesOrderId != null) {
        uniqueSOs[item.salesOrderId!] = item.salesOrderNumber!;
      }
    }
    final soCount = uniqueSOs.length;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isAssociatedExpanded = !_isAssociatedExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Associated sales orders  $soCount',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 13,
                      fontWeight: _isAssociatedExpanded ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isAssociatedExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_isAssociatedExpanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: Colors.white,
              child: soCount == 0
                  ? const Text('No associated sales orders', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))
                  : Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 2, child: Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary))),
                              Expanded(flex: 3, child: Text('Sales Order#', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary))),
                              Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary))),
                              Expanded(flex: 3, child: Text('Shipment Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary))),
                            ],
                          ),
                        ),
                        // Rows
                        ...uniqueSOs.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                            ),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(p.date != null ? DateFormat('dd-MM-yyyy').format(p.date!) : '23-04-2026', style: const TextStyle(fontSize: 13))),
                                Expanded(flex: 3, child: Text('[${e.value}]', style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlue))),
                                Expanded(flex: 2, child: Text('CONFIRMED', style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500))),
                                const Expanded(flex: 3, child: Text('', style: TextStyle(fontSize: 13))),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBlock(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildItemsTable(Picklist p) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                _buildTableHeaderCell('Items', flex: 4),
                _buildTableHeaderCell('Order#', flex: 2),
                _buildTableHeaderCell('Quantity to pick', flex: 2),
                _buildTableHeaderCell('Quantity Picked', flex: 2),
                _buildTableHeaderCell('Yet To Pick', flex: 2),
                _buildTableHeaderCell('Status', flex: 2),
              ],
            ),
          ),
          // Real rows from items
          if (p.items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: const Center(
                child: Text('No items in this picklist', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ),
            )
          else
            ...p.items.map((item) => Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderColor),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(LucideIcons.image, size: 16, color: AppTheme.borderColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName ?? 'Unknown Item',
                                  style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildTableCell(
                    item.salesOrderNumber != null ? '[${item.salesOrderNumber}]' : '-',
                    flex: 2,
                    isBlue: item.salesOrderNumber != null,
                  ),
                  _buildTableCell('${item.qtyToPick.toInt()}\npcs', flex: 2),
                  _buildTableCell(
                    '${item.qtyPicked.toInt()}',
                    flex: 2,
                    color: item.qtyPicked > 0 ? const Color(0xFF1E8E3E) : null,
                  ),
                  _buildTableCell('${item.yetToPick.toInt()}', flex: 2),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _buildItemStatusBadge(item.itemStatus),
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildItemStatusBadge(String status) {
    Color textColor;
    final s = status.trim();
    if (s == 'Completed') {
      textColor = const Color(0xFF1E8E3E); // Green
    } else if (s == 'In Progress') {
      textColor = const Color(0xFFE65100); // Orange
    } else if (s == 'On Hold') {
      textColor = const Color(0xFFD93025); // Red
    } else if (s == 'Force Complete') {
      textColor = const Color(0xFF3F51B5); // Indigo
    } else if (s == 'Approved') {
      textColor = const Color(0xFF009688); // Teal
    } else {
      textColor = const Color(0xFF5F6368); // Gray (Yet to Pick)
    }
    
    return Text(
      status,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: textColor),
    );
  }

  Widget _buildTableHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {required int flex, bool isBlue = false, Color? color}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isBlue ? AppTheme.primaryBlue : (color ?? AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _PicklistPdfView extends StatelessWidget {
  final Picklist picklist;

  const _PicklistPdfView({required this.picklist});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F0F0),
      padding: const EdgeInsets.all(40),
      child: Center(
        child: AspectRatio(
          aspectRatio: 0.707, // A4 ratio
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: Stack(
              children: [
                // Diagonal Banner
                Positioned(
                  top: 40,
                  left: -20,
                  child: Transform.rotate(
                    angle: -0.785398, // -45 degrees
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
                      color: _getPdfStatusColor(picklist.status),
                      child: Text(
                        _getFormattedStatus(picklist.status),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120,
                                height: 80,
                                color: Colors.black,
                                child: const Center(child: Text('LOGO', style: TextStyle(color: Colors.white))),
                              ),
                              const SizedBox(height: 16),
                              const Text('ZABNIX PRIVATE LIMITED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const Text('PERINTHALMANNA\nMALAPPURAM Kerala 679322\nIndia', style: TextStyle(fontSize: 10)),
                              const SizedBox(height: 8),
                              const Text('GSTIN 32AACCZ4912F1ZL', style: TextStyle(fontSize: 10)),
                              const Text('8086355500', style: TextStyle(fontSize: 10)),
                              const Text('zabnixprivatelimited@gmail.com', style: TextStyle(fontSize: 10)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('PICKLIST', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, letterSpacing: 2)),
                              const SizedBox(height: 8),
                              Text('Picklist# ${picklist.picklistNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // Info Summary Grid
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppTheme.borderColor),
                            bottom: BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            _buildPdfInfoBlock('Picklist Date', DateFormat('dd-MM-yyyy').format(picklist.date ?? DateTime.now())),
                            _buildPdfInfoBlock('Status', _getFormattedStatus(picklist.status)),
                            _buildPdfInfoBlock('Location', picklist.location ?? 'ZABNIX PRIVATE LIMITED'),
                            _buildPdfInfoBlock('Assignee', picklist.assignee ?? 'Unassigned'),
                            _buildPdfTotalBlock('TOTAL QTY', picklist.items.fold(0.0, (sum, item) => sum + item.qtyToPick).toStringAsFixed(2)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Document Table
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF333333),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Row(
                          children: [
                            _buildPdfHeaderCell('#', width: 30),
                            _buildPdfHeaderCell('ITEM & DESCRIPTION', flex: 4),
                            _buildPdfHeaderCell('ORDER #', flex: 2),
                            _buildPdfHeaderCell('STATUS', flex: 2),
                            _buildPdfHeaderCell('QUANTITY\nTO PICK', flex: 2, align: TextAlign.right),
                            _buildPdfHeaderCell('QUANTITY\nPICKED', flex: 2, align: TextAlign.right),
                            _buildPdfHeaderCell('QUANTITY\nREMAINING', flex: 2, align: TextAlign.right),
                          ],
                        ),
                      ),
                      
                      // Document Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPdfCell('1', width: 30),
                            _buildPdfCell('BATCH TRACK 3', flex: 4, fontWeight: FontWeight.bold),
                            _buildPdfCell('[pok00040', flex: 2),
                            _buildPdfCell('Yet to Start', flex: 2),
                            _buildPdfCell('15.00\npcs', flex: 2, align: TextAlign.right),
                            _buildPdfCell('0.00\npcs', flex: 2, align: TextAlign.right),
                            _buildPdfCell('15.00\npcs', flex: 2, align: TextAlign.right),
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
    );
  }

  Color _getPdfStatusColor(String status) {
    switch (status) {
      case 'COMPLETED': return const Color(0xFF1E8E3E);
      case 'IN_PROGRESS': return const Color(0xFF0088FF);
      case 'ON_HOLD': return const Color(0xFFD93025);
      case 'APPROVED': return const Color(0xFF009688);
      case 'FORCE_COMPLETE': return const Color(0xFF3F51B5);
      default: return const Color(0xFFC4C4C4);
    }
  }

  String _getFormattedStatus(String status) {
    return status.replaceAll('_', ' ');
  }

  Widget _buildPdfInfoBlock(String label, String value) {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPdfTotalBlock(String label, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      color: const Color(0xFFF1F3F4),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPdfHeaderCell(String text, {int? flex, double? width, TextAlign align = TextAlign.left}) {
    final child = Text(
      text,
      textAlign: align,
      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
    );
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex!, child: child);
  }

  Widget _buildPdfCell(String text, {int? flex, double? width, TextAlign align = TextAlign.left, FontWeight? fontWeight}) {
    final child = Text(
      text,
      textAlign: align,
      style: TextStyle(fontSize: 10, fontWeight: fontWeight),
    );
    if (width != null) return SizedBox(width: width, child: child);
    return Expanded(flex: flex!, child: child);
  }
}
