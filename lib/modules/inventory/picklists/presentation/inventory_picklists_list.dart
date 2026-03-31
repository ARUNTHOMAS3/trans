import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../models/inventory_picklist_model.dart';
import '../providers/inventory_picklists_provider.dart';

class InventoryPicklistsListScreen extends ConsumerStatefulWidget {
  const InventoryPicklistsListScreen({super.key});

  @override
  ConsumerState<InventoryPicklistsListScreen> createState() => _InventoryPicklistsListScreenState();
}

class _InventoryPicklistsListScreenState extends ConsumerState<InventoryPicklistsListScreen> {
  String _selectedView = 'All';
  final Set<String> _selectedIds = {};
  List<String> _visibleColumns = [
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
                        const Icon(LucideIcons.list, size: 20, color: Color(0xFF6B7280)),
                        const SizedBox(width: 12),
                        const Text(
                          'Customize Columns',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_visibleColumns.length} of ${_columnLabels.length} Selected',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFFEF4444)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                        prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF9CA3AF)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
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
                                    const Icon(LucideIcons.gripVertical, size: 16, color: Color(0xFFD1D5DB)),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isVisible ? LucideIcons.checkSquare : LucideIcons.square,
                                      size: 18,
                                      color: isVisible ? const Color(0xFF0088FF) : const Color(0xFFD1D5DB),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isVisible ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
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
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Apply visible columns
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22A95E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6B7280),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
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
              data: (picklists) => _buildTable(picklists),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: WidgetStatePropertyAll(8),
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
                style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevronDown, size: 18, color: Color(0xFF0088FF)),
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
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        MenuItemButton(
          onPressed: () {},
          style: _menuItemButtonStyle(),
          child: const Row(
            children: [
              Icon(LucideIcons.plusCircle, size: 16, color: Color(0xFF0088FF)),
              SizedBox(width: 12),
              Text('New Custom View', style: TextStyle(color: Color(0xFF0088FF), fontSize: 13)),
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
          Icon(LucideIcons.star, size: 14, color: isActive ? Colors.white70 : const Color(0xFFD1D5DB)),
        ],
      ),
    );
  }

  Widget _buildActionIcons() {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF6B7280)),
          tooltip: 'Search',
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(LucideIcons.filter, size: 18, color: Color(0xFF6B7280)),
          tooltip: 'Filter',
        ),
      ],
    );
  }

  Widget _buildNewButton() {
    final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '0000000000';
    return ElevatedButton(
      onPressed: () => context.push('/$orgId/inventory/picklists/create'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF22A95E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.plus, size: 16),
          SizedBox(width: 6),
          Text(
            'New',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: MenuAnchor(
        alignmentOffset: const Offset(0, 4),
        style: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: WidgetStatePropertyAll(Colors.white),
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
          elevation: WidgetStatePropertyAll(8),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          )),
        ),
        builder: (context, controller, child) {
          return IconButton(
            onPressed: () {
              if (controller.isOpen) controller.close();
              else controller.open();
            },
            icon: const Icon(LucideIcons.moreHorizontal, size: 16, color: Color(0xFF6B7280)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          );
        },
        menuChildren: [
          SubmenuButton(
            menuStyle: const MenuStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.white),
              surfaceTintColor: WidgetStatePropertyAll(Colors.white),
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
              elevation: WidgetStatePropertyAll(8),
            ),
            style: _menuItemButtonStyle(isHeader: true),
            menuChildren: [
              _buildSortMenuItem('Date'),
              _buildSortMenuItem('Picklist#'),
              _buildSortMenuItem('Created Time', isActive: true),
              _buildSortMenuItem('Last Modified Time'),
            ],
            child: Row(
              children: [
                const Icon(LucideIcons.arrowUpDown, size: 16),
                const SizedBox(width: 12),
                const Text('Sort by', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const Spacer(),
                const Icon(LucideIcons.chevronRight, size: 16),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
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
        if (isActive) return const Color(0xFF0088FF);
        if (states.contains(WidgetState.hovered)) return const Color(0xFF0088FF);
        return isHeader ? Colors.transparent : Colors.white;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (isActive || states.contains(WidgetState.hovered)) return Colors.white;
        return const Color(0xFF374151);
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (isActive || states.contains(WidgetState.hovered)) return Colors.white;
        return const Color(0xFF0088FF);
      }),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      minimumSize: const WidgetStatePropertyAll(Size(240, 44)),
      alignment: Alignment.centerLeft,
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
    );
  }

  Widget _buildTable(List<Picklist> picklists) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Header
                Container(
                  constraints: BoxConstraints(minWidth: screenWidth),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      _buildConfigIcon(),
                      const SizedBox(width: 12),
                      _buildSelectAllCheckbox(picklists),
                      const SizedBox(width: 12),
                      ..._visibleColumns.map((colId) {
                        final width = _getCalculatedColumnWidth(colId, screenWidth);
                        return _buildHeaderCell(_columnLabels[colId]!, width: width);
                      }),
                    ],
                  ),
                ),
                // Table Body
                if (picklists.isEmpty)
                  _buildEmptyState(screenWidth)
                else
                  ...picklists.map((p) => _buildRow(p, screenWidth)),
              ],
            ),
          ),
        );
      },
    );
  }

  double _getCalculatedColumnWidth(String colId, double screenWidth) {
    const staticWidth = 84.0;
    final visibleCols = _visibleColumns;

    final Map<String, (double min, double flex)> metrics = {
      'date': (102.0, 1.0),
      'picklist#': (120.0, 2.0),
      'status': (140.0, 2.0),
      'assignee': (160.0, 3.0),
      'location': (200.0, 4.0),
      'notes': (150.0, 2.0),
      'created_time': (160.0, 1.5),
      'modified_time': (160.0, 1.5),
    };

    double totalMinWidth = staticWidth;
    double totalFlex = 0;

    for (final col in visibleCols) {
      final m = metrics[col] ?? (150.0, 1.5);
      totalMinWidth += m.$1;
      totalFlex += m.$2;
    }

    final extraSpace = math.max(0.0, screenWidth - totalMinWidth);
    final m = metrics[colId] ?? (150.0, 1.5);

    if (totalFlex == 0) return m.$1;
    return m.$1 + (m.$2 / totalFlex) * extraSpace;
  }

  Widget _buildConfigIcon() {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        elevation: WidgetStatePropertyAll(8),
      ),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) controller.close();
            else controller.open();
          },
          child: const Icon(LucideIcons.sliders, size: 16, color: Color(0xFF0088FF)),
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
          color: const Color(0xFF0088FF),
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
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
          fontFamily: 'Inter',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRow(Picklist picklist, double minWidth) {
    final isSelected = _selectedIds.contains(picklist.id);

    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F7FF) : Colors.transparent,
        border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
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
            final width = _getCalculatedColumnWidth(colId, minWidth);
            return _buildCell(picklist, colId, width: width);
          }),
        ],
      ),
    );
  }

  Widget _buildCell(Picklist picklist, String colId, {double? width}) {
    Widget content;
    switch (colId) {
      case 'date':
        content = Text(
          DateFormat('dd-MM-yyyy').format(picklist.date ?? DateTime.now()),
          style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937), fontFamily: 'Inter'),
        );
        break;
      case 'picklist#':
        content = Text(
          picklist.picklistNumber,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0088FF), fontWeight: FontWeight.w500, fontFamily: 'Inter'),
        );
        break;
      case 'status':
        final isCompleted = picklist.status == 'Completed';
        content = Text(
          picklist.status,
          style: TextStyle(
            fontSize: 13,
            color: isCompleted ? const Color(0xFF22A95E) : const Color(0xFF6B7280),
            fontFamily: 'Inter',
          ),
        );
        break;
      case 'assignee':
        content = Text(
          picklist.assignee ?? 'Unassigned',
          style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937), fontFamily: 'Inter'),
        );
        break;
      case 'location':
        content = Text(
          picklist.location ?? '-',
          style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937), fontFamily: 'Inter'),
        );
        break;
      default:
        content = const Text('-');
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: content,
    );
  }

  Widget _buildEmptyState(double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 64),
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.package, size: 48, color: Color(0xFFE5E7EB)),
          SizedBox(height: 16),
          Text(
            'No picklists found',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }
}
