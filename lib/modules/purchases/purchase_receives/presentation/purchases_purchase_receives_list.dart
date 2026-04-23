import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import '../models/purchases_purchase_receives_model.dart';
import '../providers/purchase_receives_provider.dart';

class PurchasesPurchaseReceivesListScreen extends ConsumerStatefulWidget {
  const PurchasesPurchaseReceivesListScreen({super.key});

  @override
  ConsumerState<PurchasesPurchaseReceivesListScreen> createState() =>
      _PurchasesPurchaseReceivesListScreenState();
}

class _PurchasesPurchaseReceivesListScreenState
    extends ConsumerState<PurchasesPurchaseReceivesListScreen> {
  String _selectedView = 'All';
  final Set<String> _selectedIds = {};
  List<String> _visibleColumns = [
    'date',
    'pr#',
    'po#',
    'vendor',
    'status',
    'billed',
    'qty',
  ];

  List<String> _allColumns = [
    'date',
    'pr#',
    'po#',
    'vendor',
    'status',
    'billed',
    'qty',
    'created_time',
    'modified_time',
  ];

  final Map<String, String> _columnLabels = {
    'date': 'DATE',
    'pr#': 'PURCHASE RECEIVE#',
    'po#': 'PURCHASE ORDER#',
    'vendor': 'VENDOR NAME',
    'status': 'STATUS',
    'billed': 'BILLED',
    'qty': 'QUANTITY',
    'created_time': 'CREATED TIME',
    'modified_time': 'LAST MODIFIED TIME',
  };

  final List<String> _lockedColumns = [
    'date',
    'pr#',
    'status',
  ]; // Prevent these columns from being hidden

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

  void _toggleAll(List<PurchaseReceive> receives) {
    setState(() {
      if (_selectedIds.length == receives.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        for (final r in receives) {
          if (r.id != null) {
            _selectedIds.add(r.id!);
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.list,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Customize Columns',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_visibleColumns.length} of ${_columnLabels.length} Selected',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: ReorderableListView(
                        shrinkWrap: true,
                        buildDefaultDragHandles: false,
                        onReorder: (int oldIndex, int newIndex) {
                          setDialogState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final String item = _allColumns.removeAt(oldIndex);
                            _allColumns.insert(newIndex, item);

                            // Reorder visible columns to match the general order
                            _visibleColumns.sort(
                              (a, b) => _allColumns
                                  .indexOf(a)
                                  .compareTo(_allColumns.indexOf(b)),
                            );
                          });
                        },
                        children: _allColumns.map((colKey) {
                          final isVisible = _visibleColumns.contains(colKey);
                          final isLocked = _lockedColumns.contains(colKey);
                          final label = _columnLabels[colKey]!;

                          return InkWell(
                            key: ValueKey(colKey),
                            onTap: () {
                              if (isLocked) return;

                              setDialogState(() {
                                if (isVisible) {
                                  if (_visibleColumns.length > 1) {
                                    _visibleColumns.remove(colKey);
                                  }
                                } else {
                                  _visibleColumns.add(colKey);
                                  _visibleColumns.sort(
                                    (a, b) => _allColumns
                                        .indexOf(a)
                                        .compareTo(_allColumns.indexOf(b)),
                                  );
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isLocked
                                    ? const Color(0xFFF9FAFB)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  // Drag icon
                                  ReorderableDragStartListener(
                                    index: _allColumns.indexOf(colKey),
                                    child: const MouseRegion(
                                      cursor: SystemMouseCursors.grab,
                                      child: Icon(
                                        LucideIcons.gripVertical,
                                        size: 16,
                                        color: Color(0xFFD1D5DB),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // 🔒 LOCK OR CHECKBOX
                                  if (isLocked)
                                    const Icon(
                                      LucideIcons.lock,
                                      size: 18,
                                      color: Color(0xFF9CA3AF),
                                    )
                                  else
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: isVisible
                                            ? const Color(0xFF3B82F6)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isVisible
                                              ? const Color(0xFF3B82F6)
                                              : const Color(0xFFD1D5DB),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isVisible
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),

                                  const SizedBox(width: 12),

                                  // Label
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isLocked
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF1F2937),
                                      fontWeight: isVisible
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6B7280),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
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
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
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
    final receivesAsync = ref.watch(purchaseReceivesProvider);

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
            child: receivesAsync.when(
              data: (state) => _buildTable(state.receives),
              loading: _buildLoadingState,
              error: (err, stack) => ZErrorPlaceholder(
                error: err,
                message: 'Failed to load purchase receives',
                onRetry: () {
                  ref.read(purchaseReceivesProvider.notifier).fetchReceives();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final int skeletonColumns = math.max(5, _visibleColumns.length + 1);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ZTableSkeleton(rows: 10, columns: skeletonColumns),
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
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedView == 'All'
                    ? 'All Purchase Receives'
                    : _selectedView,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: Color(0xFF0088FF),
              ),
            ],
          ),
        );
      },
      menuChildren: [
        _buildViewMenuItem('All'),
        _buildViewMenuItem('In Transit'),
        _buildViewMenuItem('Received'),
        _buildViewMenuItem('Billed'),
        _buildViewMenuItem('Partially Billed'),
        const Divider(
          height: 1,
          indent: 0,
          endIndent: 0,
          color: Color(0xFFF3F4F6),
        ),
        MenuItemButton(
          onPressed: () {},
          style: _menuItemButtonStyle(),
          child: const Row(
            children: [
              Icon(LucideIcons.plusCircle, size: 16, color: Color(0xFF0088FF)),
              const SizedBox(width: 12),
              Text(
                'New Custom View',
                style: TextStyle(
                  color: Color(0xFF0088FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewMenuItem(String label) {
    final isActive = _selectedView == label;
    return MenuItemButton(
      onPressed: () {
        setState(() {
          _selectedView = label;
        });
      },
      style: _menuItemButtonStyle(isActive: isActive),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Icon(
            LucideIcons.star,
            size: 14,
            color: isActive ? Colors.white70 : const Color(0xFFD1D5DB),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcons() {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            LucideIcons.search,
            size: 18,
            color: Color(0xFF6B7280),
          ),
          tooltip: 'Search',
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            LucideIcons.filter,
            size: 18,
            color: Color(0xFF6B7280),
          ),
          tooltip: 'Filter',
        ),
      ],
    );
  }

  Widget _buildNewButton() {
    final orgId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '0000000000';
    return ElevatedButton(
      onPressed: () => context.pushNamed(
        AppRoutes.purchaseReceivesCreate,
        pathParameters: {'orgSystemId': orgId},
      ),
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
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ),
        builder: (context, controller, child) {
          return IconButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: const Icon(
              LucideIcons.moreHorizontal,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          );
        },
        menuChildren: [
          // Sort by Submenu
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
              _buildSortMenuItem('Purchase Receive#'),
              _buildSortMenuItem('Purchase Order#'),
              _buildSortMenuItem('Created Time', isActive: true),
              _buildSortMenuItem('Last Modified Time'),
            ],
            child: Row(
              children: [
                const Icon(LucideIcons.arrowUpDown, size: 16),
                const SizedBox(width: 12),
                const Text(
                  'Sort by',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                const Icon(LucideIcons.chevronRight, size: 16),
              ],
            ),
          ),

          _buildMenuItem(
            icon: LucideIcons.download,
            label: 'Import Purchase Receives',
            onPressed: () {},
          ),

          _buildMenuItem(
            icon: LucideIcons.upload,
            label: 'Export Purchase Receives',
            onPressed: () {},
          ),

          const Divider(
            height: 1,
            indent: 0,
            endIndent: 0,
            color: Color(0xFFF3F4F6),
          ),

          _buildMenuItem(
            icon: LucideIcons.settings,
            label: 'Preferences',
            onPressed: () {},
          ),

          const Divider(
            height: 1,
            indent: 0,
            endIndent: 0,
            color: Color(0xFFF3F4F6),
          ),

          _buildMenuItem(
            icon: LucideIcons.refreshCw,
            label: 'Refresh List',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return MenuItemButton(
      onPressed: onPressed,
      style: _menuItemButtonStyle(),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontSize: 14)),
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

  ButtonStyle _menuItemButtonStyle({
    bool isActive = false,
    bool isHeader = false,
  }) {
    return ButtonStyle(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (isActive) return const Color(0xFF3B82F6);
        if (states.contains(WidgetState.hovered))
          return const Color(0xFF3B82F6);
        return isHeader ? Colors.transparent : Colors.white;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (isActive || states.contains(WidgetState.hovered))
          return Colors.white;
        return const Color(0xFF374151);
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (isActive || states.contains(WidgetState.hovered))
          return Colors.white;
        return const Color(
          0xFF3B82F6,
        ); // Keep icons blue by default for a premium look
      }),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(240, 44)),
      alignment: Alignment.centerLeft,
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  Widget _buildTable(List<PurchaseReceive> receives) {
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
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8), // Minimal leading edge gap
                      _buildConfigIcon(),
                      const SizedBox(width: 12),
                      _buildSelectAllCheckbox(receives),
                      const SizedBox(width: 12),
                      ..._visibleColumns.map((colId) {
                        final label = _columnLabels[colId] ?? '';
                        final width = _getCalculatedColumnWidth(
                          colId,
                          screenWidth,
                        );
                        final isRightAlign = colId == 'qty';
                        return _buildHeaderCell(
                          label,
                          width: width,
                          align: isRightAlign
                              ? TextAlign.right
                              : TextAlign.left,
                        );
                      }),
                    ],
                  ),
                ),
                // Table Body
                if (receives.isEmpty)
                  _buildEmptyState(screenWidth)
                else
                  ...receives.map((receive) => _buildRow(receive, screenWidth)),
              ],
            ),
          ),
        );
      },
    );
  }

  double _getCalculatedColumnWidth(String colId, double screenWidth) {
    const staticWidth =
        84.0; // Padding, Config icon (16), gap(12), checkbox(18), gap(12), gap(12) + some safety
    final visibleCols = _visibleColumns;

    final Map<String, (double min, double flex)> metrics = {
      'date': (102.0, 1.0),
      'pr#': (120.0, 2.0),
      'po#': (120.0, 2.0),
      'vendor': (180.0, 4.0),
      'status': (110.0, 1.0),
      'billed': (90.0, 1.0),
      'qty': (80.0, 1.0),
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
            if (controller.isOpen)
              controller.close();
            else
              controller.open();
          },
          child: const Icon(
            LucideIcons.sliders,
            size: 16,
            color: Color(0xFF0088FF),
          ),
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
        MenuItemButton(
          onPressed: () {},
          style: _menuItemButtonStyle(),
          child: const Row(
            children: [
              Icon(LucideIcons.alignLeft, size: 18),
              SizedBox(width: 12),
              Text('Clip Text'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectAllCheckbox(List<PurchaseReceive> receives) {
    final isAllSelected =
        receives.isNotEmpty && _selectedIds.length == receives.length;
    final isPartiallySelected =
        _selectedIds.isNotEmpty && _selectedIds.length < receives.length;

    return InkWell(
      onTap: () => _toggleAll(receives),
      child: _buildCheckboxWidget(
        isAllSelected,
        isPartially: isPartiallySelected,
      ),
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

  Widget _buildHeaderCell(String text, {double? width, TextAlign? align}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        textAlign: align,
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

  Widget _buildConfigIconPlaceHolder() {
    return const SizedBox(width: 16); // Width of the sliders icon
  }

  Widget _buildRow(PurchaseReceive receive, double minWidth) {
    final isSelected = _selectedIds.contains(receive.id);

    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F7FF) : Colors.transparent,
        border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const SizedBox(width: 8), // Minimal leading edge gap
          _buildConfigIconPlaceHolder(),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _toggleSelection(receive.id ?? ''),
            child: _buildCheckboxWidget(isSelected),
          ),
          const SizedBox(width: 12),
          ..._visibleColumns.map((colId) {
            final width = _getCalculatedColumnWidth(colId, minWidth);
            return _buildCell(receive, colId, width: width);
          }),
        ],
      ),
    );
  }

  Widget _buildCell(PurchaseReceive receive, String colId, {double? width}) {
    final totalQty = receive.items.fold<double>(
      0,
      (prev, item) => prev + item.quantityToReceive,
    );

    Widget content;
    TextAlign align = TextAlign.left;

    switch (colId) {
      case 'date':
        content = Text(
          DateFormat(
            'dd-MM-yyyy',
          ).format(receive.receivedDate ?? DateTime.now()),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1F2937),
            fontFamily: 'Inter',
          ),
        );
        break;
      case 'pr#':
        content = Text(
          receive.purchaseReceiveNumber,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF0088FF),
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        );
        break;
      case 'po#':
        content = Text(
          receive.purchaseOrderNumber ?? '-',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF0088FF),
            fontFamily: 'Inter',
          ),
        );
        break;
      case 'vendor':
        content = Text(
          receive.vendorName ?? '-',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1F2937),
            fontFamily: 'Inter',
          ),
        );
        break;
      case 'status':
        content = Text(
          receive.status.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF22A95E),
            fontFamily: 'Inter',
            letterSpacing: 0.3,
          ),
        );
        break;
      case 'billed':
        content = const Center(
          child: Icon(Icons.circle, size: 8, color: Color(0xFFE5E7EB)),
        );
        break;
      case 'qty':
        align = TextAlign.right;
        content = Text(
          totalQty.toStringAsFixed(2),
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1F2937),
            fontFamily: 'Inter',
          ),
        );
        break;
      case 'created_time':
        content = Text(
          DateFormat(
            'dd-MM-yyyy hh:mm a',
          ).format(DateTime.now()), // Placeholder
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontFamily: 'Inter',
          ),
        );
        break;
      case 'modified_time':
        content = Text(
          DateFormat(
            'dd-MM-yyyy hh:mm a',
          ).format(DateTime.now()), // Placeholder
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontFamily: 'Inter',
          ),
        );
        break;
      default:
        content = const Text('-');
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DefaultTextStyle.merge(child: content, textAlign: align),
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
            'No purchase receives found',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
