import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_data_table_shell.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_search_field.dart';
// import 'package:zerpai_erp/core/routing/app_routes.dart';

import '../models/inventory_picklist_model.dart';
import '../providers/inventory_picklists_provider.dart';

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
  ];

  final Map<String, String> _columnLabels = {
    'date': 'DATE',
    'picklist#': 'PICKLIST#',
    'status': 'STATUS',
    'assignee': 'ASSIGNEE',
    'location': 'LOCATION',
    'notes': 'NOTES',
    'created_time': 'CREATED TIME',
    'modified_time': 'LAST MODIFIED TIME',
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

  @override
  Widget build(BuildContext context) {
    final picklistsAsync = ref.watch(picklistsProvider);
    final isDetailOpen = widget.id != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          // Master List
          Expanded(
            flex: isDetailOpen ? 4 : 10,
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
              flex: 6,
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
        const Divider(height: 1, color: AppTheme.bgDisabled),
        MenuItemButton(
          onPressed: () {},
          style: _menuItemButtonStyle(),
          child: Row(
            children: [
              const Icon(LucideIcons.plusCircle, size: 16, color: AppTheme.primaryBlue),
              const SizedBox(width: 12),
              Text('New Custom View', style: AppTheme.bodyText.copyWith(color: AppTheme.primaryBlue, fontSize: 13)),
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

  Widget _buildVirtualizedTable(List<Picklist> picklists) {
    if (picklists.isEmpty) return _buildEmptyState();

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
                itemExtent: 52, // Fixed height for performance
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
      height: 44,
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
        height: 52,
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
        final isCompleted = picklist.status == 'Completed';
        content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isCompleted ? AppTheme.successBg : AppTheme.bgDisabled,
            borderRadius: BorderRadius.circular(AppTheme.space4),
          ),
          child: Text(
            picklist.status,
            style: AppTheme.captionText.copyWith(
              color: isCompleted ? AppTheme.successGreen : AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
        break;
      case 'assignee':
        content = Text(
          picklist.assignee ?? 'Unassigned',
          style: AppTheme.tableCell,
        );
        break;
      case 'location':
        content = Text(
          picklist.location ?? '-',
          style: AppTheme.tableCell,
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

/// side detail panel for picklists
class _PicklistDetailPanel extends ConsumerWidget {
  final String id;
  final VoidCallback onClose;

  const _PicklistDetailPanel({required this.id, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picklistAsync = ref.watch(picklistByIdProvider(id));

    return Column(
      children: [
        // Panel Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onClose,
                icon: const Icon(LucideIcons.arrowLeft, size: 20),
                tooltip: 'Back to List',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: picklistAsync.when(
                  data: (p) => Text(
                    p?.picklistNumber ?? 'Picklist Detail',
                    style: AppTheme.pageTitle,
                  ),
                  loading: () => const Text('Loading...'),
                  error: (_, __) => const Text('Error'),
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(LucideIcons.edit, size: 18)),
              IconButton(onPressed: () {}, icon: const Icon(LucideIcons.moreVertical, size: 18)),
            ],
          ),
        ),
        
        // Panel Content
        Expanded(
          child: picklistAsync.when(
            data: (p) {
              if (p == null) return const Center(child: Text('Picklist not found'));
              return _buildDetailContent(context, p);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailContent(BuildContext context, Picklist p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Date', DateFormat('dd-MM-yyyy').format(p.date ?? DateTime.now())),
          _buildInfoRow('Status', p.status),
          _buildInfoRow('Assignee', p.assignee ?? 'Unassigned'),
          _buildInfoRow('Location', p.location ?? '-'),
          if (p.notes != null) _buildInfoRow('Notes', p.notes!),
          const SizedBox(height: 32),
          const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Add a simple items table here if needed
          const Center(child: Text('Item list implementation in progress...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
