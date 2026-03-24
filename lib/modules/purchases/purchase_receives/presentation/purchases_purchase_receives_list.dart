import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

import '../models/purchases_purchase_receives_model.dart';
import '../providers/purchases_purchase_receives_provider.dart';

class PurchasesPurchaseReceivesListScreen extends ConsumerStatefulWidget {
  const PurchasesPurchaseReceivesListScreen({super.key});

  @override
  ConsumerState<PurchasesPurchaseReceivesListScreen> createState() =>
      _PurchasesPurchaseReceivesListScreenState();
}

class _PurchasesPurchaseReceivesListScreenState
    extends ConsumerState<PurchasesPurchaseReceivesListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final Set<String> _selectedIds = <String>{};
  final List<String> _visibleColumns = <String>[
    'date',
    'pr#',
    'po#',
    'vendor',
    'status',
    'billed',
    'qty',
  ];

  String _selectedView = 'All';

  final Map<String, String> _columnLabels = const <String, String>{
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receivesAsync = ref.watch(purchaseReceivesProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.slash): () {
          _searchFocus.requestFocus();
        },
      },
      child: ZerpaiLayout(
        pageTitle: 'Purchase Receives',
        enableBodyScroll: false,
        actions: [
          ZButton.primary(
            label: 'New Purchase Receive',
            onPressed: () => context.push(AppRoutes.purchaseReceivesCreate),
          ),
          _buildMoreMenu(),
        ],
        child: receivesAsync.when(
          data: (state) {
            final receives = _applyFilters(state.receives);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildToolbar(),
                const SizedBox(height: 16),
                if (state.error != null) ...[
                  _buildStatusBanner(state.error!),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: state.isLoading && state.receives.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _buildTable(receives),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  List<PurchaseReceive> _applyFilters(List<PurchaseReceive> source) {
    var list = List<PurchaseReceive>.from(source);
    final q = _searchCtrl.text.toLowerCase().trim();

    if (q.isNotEmpty) {
      list = list.where((receive) {
        return receive.purchaseReceiveNumber.toLowerCase().contains(q) ||
            (receive.purchaseOrderNumber ?? '').toLowerCase().contains(q) ||
            (receive.vendorName ?? '').toLowerCase().contains(q);
      }).toList();
    }

    switch (_selectedView) {
      case 'Received':
        list = list
            .where((receive) => receive.status.toLowerCase() == 'received')
            .toList();
        break;
      case 'Billed':
        list = list.where((receive) => receive.billed).toList();
        break;
      case 'Partially Billed':
        list = list
            .where(
              (receive) =>
                  !receive.billed &&
                  receive.status.toLowerCase() == 'received',
            )
            .toList();
        break;
      case 'In Transit':
        list = list
            .where((receive) => receive.status.toLowerCase() == 'in transit')
            .toList();
        break;
    }

    return list;
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _buildViewSelector(),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search in Purchase Receives ( / )',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.info, size: 16, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
      ),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
          child: Row(
            children: [
              Text(
                _selectedView == 'All'
                    ? 'All Purchase Receives'
                    : _selectedView,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
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
        _viewButton('All'),
        _viewButton('In Transit'),
        _viewButton('Received'),
        _viewButton('Billed'),
        _viewButton('Partially Billed'),
      ],
    );
  }

  MenuItemButton _viewButton(String label) {
    final isActive = _selectedView == label;
    return MenuItemButton(
      style: _menuStyle(isActive: isActive),
      onPressed: () => setState(() => _selectedView = label),
      child: Text(label),
    );
  }

  Widget _buildMoreMenu() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: MenuAnchor(
        style: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        ),
        builder: (context, controller, child) {
          return IconButton(
            onPressed: () => controller.isOpen ? controller.close() : controller.open(),
            icon: const Icon(
              LucideIcons.moreHorizontal,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          );
        },
        menuChildren: [
          MenuItemButton(
            style: _menuStyle(),
            onPressed: _showCustomizeColumnsDialog,
            child: const Row(
              children: [
                Icon(LucideIcons.columns, size: 18),
                SizedBox(width: 12),
                Text('Customize Columns'),
              ],
            ),
          ),
          MenuItemButton(
            style: _menuStyle(),
            onPressed: () => ref.read(purchaseReceivesProvider.notifier).refresh(),
            child: const Row(
              children: [
                Icon(LucideIcons.refreshCw, size: 18),
                SizedBox(width: 12),
                Text('Refresh List'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _menuStyle({bool isActive = false}) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (isActive) return const Color(0xFF3B82F6);
        if (states.contains(WidgetState.hovered)) {
          return const Color(0xFF3B82F6);
        }
        return Colors.white;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (isActive || states.contains(WidgetState.hovered)) {
          return Colors.white;
        }
        return const Color(0xFF374151);
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (isActive || states.contains(WidgetState.hovered)) {
          return Colors.white;
        }
        return const Color(0xFF3B82F6);
      }),
      minimumSize: const WidgetStatePropertyAll(Size(220, 42)),
      alignment: Alignment.centerLeft,
    );
  }

  void _showCustomizeColumnsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return SizedBox(
              width: 420,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customize Columns',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._columnLabels.entries.map((entry) {
                      final isVisible = _visibleColumns.contains(entry.key);
                      return CheckboxListTile(
                        value: isVisible,
                        activeColor: const Color(0xFF3B82F6),
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.value),
                        onChanged: (_) {
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
                      );
                    }),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ZButton.primary(
                          label: 'Save',
                          onPressed: () {
                            setState(() {});
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTable(List<PurchaseReceive> receives) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      children: [
                        const SizedBox(width: 12),
                        _buildSelectAllCheckbox(receives),
                        const SizedBox(width: 12),
                        ..._visibleColumns.map((colId) {
                          return _headerCell(
                            _columnLabels[colId] ?? '',
                            width: _getColumnWidth(colId, screenWidth),
                            align: colId == 'qty'
                                ? TextAlign.right
                                : TextAlign.left,
                          );
                        }),
                      ],
                    ),
                  ),
                  if (receives.isEmpty)
                    _buildEmptyState(screenWidth)
                  else
                    ...receives.map((receive) => _buildRow(receive, screenWidth)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _getColumnWidth(String colId, double screenWidth) {
    const staticWidth = 60.0;
    final metrics = <String, (double, double)>{
      'date': (102, 1),
      'pr#': (120, 2),
      'po#': (120, 2),
      'vendor': (180, 4),
      'status': (110, 1),
      'billed': (90, 1),
      'qty': (80, 1),
      'created_time': (160, 1.5),
      'modified_time': (160, 1.5),
    };
    double totalMin = staticWidth;
    double totalFlex = 0;
    for (final key in _visibleColumns) {
      final metric = metrics[key] ?? (150, 1.5);
      totalMin += metric.$1;
      totalFlex += metric.$2;
    }
    final metric = metrics[colId] ?? (150, 1.5);
    final extra = math.max(0.0, screenWidth - totalMin);
    return metric.$1 + (metric.$2 / totalFlex) * extra;
  }

  Widget _buildSelectAllCheckbox(List<PurchaseReceive> receives) {
    final allSelected =
        receives.isNotEmpty && _selectedIds.length == receives.length;
    final partial =
        _selectedIds.isNotEmpty && _selectedIds.length < receives.length;
    return InkWell(
      onTap: () => _toggleAll(receives),
      child: _checkbox(allSelected, partial: partial),
    );
  }

  void _toggleAll(List<PurchaseReceive> receives) {
    setState(() {
      if (_selectedIds.length == receives.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(
            receives
                .map((receive) => receive.id ?? receive.purchaseReceiveNumber),
          );
      }
    });
  }

  Widget _checkbox(bool selected, {bool partial = false}) {
    if (selected || partial) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFF0088FF),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Icon(
          partial ? LucideIcons.minus : LucideIcons.check,
          size: 14,
          color: Colors.white,
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

  Widget _headerCell(String text, {required double width, TextAlign? align}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          text,
          textAlign: align,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(PurchaseReceive receive, double width) {
    final id = receive.id ?? receive.purchaseReceiveNumber;
    final isSelected = _selectedIds.contains(id);
    return Container(
      constraints: BoxConstraints(minWidth: width),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F7FF) : Colors.transparent,
        border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const SizedBox(width: 12),
          InkWell(
            onTap: () => setState(() {
              if (isSelected) {
                _selectedIds.remove(id);
              } else {
                _selectedIds.add(id);
              }
            }),
            child: _checkbox(isSelected),
          ),
          const SizedBox(width: 12),
          ..._visibleColumns.map((colId) {
            return _buildCell(
              receive,
              colId,
              width: _getColumnWidth(colId, width),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCell(
    PurchaseReceive receive,
    String colId, {
    required double width,
  }) {
    String fmtDate(DateTime? value) =>
        value == null ? '-' : DateFormat('dd-MM-yyyy').format(value);
    String fmtDateTime(DateTime? value) => value == null
        ? '-'
        : DateFormat('dd-MM-yyyy hh:mm a').format(value);

    Widget child;
    TextAlign align = TextAlign.left;

    switch (colId) {
      case 'date':
        child = Text(fmtDate(receive.receivedDate));
        break;
      case 'pr#':
        child = Text(
          receive.purchaseReceiveNumber,
          style: const TextStyle(
            color: Color(0xFF0088FF),
            fontWeight: FontWeight.w500,
          ),
        );
        break;
      case 'po#':
        child = Text(
          receive.purchaseOrderNumber ?? '-',
          style: const TextStyle(color: Color(0xFF0088FF)),
        );
        break;
      case 'vendor':
        child = Text(receive.vendorName ?? '-');
        break;
      case 'status':
        child = Text(
          receive.status.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: receive.status.toLowerCase() == 'received'
                ? const Color(0xFF22A95E)
                : const Color(0xFF6B7280),
          ),
        );
        break;
      case 'billed':
        child = Center(
          child: Icon(
            Icons.circle,
            size: 8,
            color: receive.billed
                ? const Color(0xFF22A95E)
                : const Color(0xFFE5E7EB),
          ),
        );
        break;
      case 'qty':
        align = TextAlign.right;
        child = Text(
          receive.totalQuantity.toStringAsFixed(2),
          textAlign: TextAlign.right,
        );
        break;
      case 'created_time':
        child = Text(fmtDateTime(receive.createdAt));
        break;
      case 'modified_time':
        child = Text(fmtDateTime(receive.updatedAt));
        break;
      default:
        child = const Text('-');
    }

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DefaultTextStyle.merge(
          textAlign: align,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEmptyState(double width) {
    return SizedBox(
      width: width,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            Icon(
              LucideIcons.packageCheck,
              size: 32,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 12),
            Text(
              'No purchase receives yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Create a Purchase Receive from a vendor purchase order to start tracking goods receipts.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
