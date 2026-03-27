import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import '../models/sales_order_model.dart';
import '../models/sales_payment_model.dart';
import '../models/sales_eway_bill_model.dart';
import '../models/sales_payment_link_model.dart';
import '../models/sales_customer_model.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

part 'sections/sales_generic_list_search_dialog.dart';
part 'sections/sales_generic_list_import_export_dialog.dart';
part 'sections/sales_generic_list_table.dart';
part 'sections/sales_generic_list_columns.dart';
part 'sections/sales_generic_list_filter.dart';
part 'sections/sales_generic_list_table_logic.dart';
part 'sections/sales_generic_list_ui.dart';

class ColumnDef {
  final String key;
  final String label;
  final bool isLocked;
  bool isVisible;

  ColumnDef({
    required this.key,
    required this.label,
    this.isLocked = false,
    this.isVisible = true,
  });
}

class SalesGenericListScreen extends ConsumerStatefulWidget {
  final String title;
  final String createRoute;
  final String? detailRoute;
  final List<String> columns;
  final ProviderBase<AsyncValue<List<dynamic>>>? provider;
  final String? initialSearchQuery;

  const SalesGenericListScreen({
    super.key,
    required this.title,
    required this.createRoute,
    this.detailRoute,
    required this.columns,
    this.provider,
    this.initialSearchQuery,
  });

  @override
  ConsumerState<SalesGenericListScreen> createState() =>
      _SalesGenericListScreenState();
}

class _SalesGenericListScreenState
    extends ConsumerState<SalesGenericListScreen> {
  // Store widths dynamically
  final Map<String, double> _columnWidths = {};

  // Dynamic columns
  late List<ColumnDef> _allColumns;
  late List<ColumnDef> _visibleColumns;

  // Track initial columns to detect changes for banner
  bool _columnsResized = false;
  // Selection
  final Set<String> _selectedIds = {};
  bool _selectAll = false;
  // View options
  bool _clipText = true;

  // Sorting state
  String _sortColumn = 'name';
  bool _isAscending = true;
  String? _hoverColumn;

  // Filter sidebar state
  String _selectedFilter = 'All Customers';
  final Set<String> _favoriteFilters = {'Active Customers'};

  // Overlay for view selection
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  // Scroll controller for horizontal table scroll
  final ScrollController _horizontalScrollController = ScrollController();

  String? _hoveredRowId;
  late final String _searchQuery;

  void _state(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _initializeColumns();
    _searchQuery = widget.initialSearchQuery?.trim().toLowerCase() ?? '';
  }

  @override
  void dispose() {
    _hideFilterMenu();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = widget.provider != null
        ? ref.watch(widget.provider!)
        : null;
    final filteredAsyncData = asyncData?.whenData(_applyGlobalSearchFilter);

    return ZerpaiLayout(
      pageTitle: widget.title,
      enableBodyScroll: false,
      onSearch: _openAdvancedSearchDialog,
      child: Column(
        children: [
          if (_columnsResized) _buildResizeBanner(),
          _buildHeaderActions(context),
          if (_selectedIds.isNotEmpty) _buildBulkActionsToolbar(),
          Expanded(
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Table content
                  Expanded(
                    child: filteredAsyncData == null
                        ? _buildEmptyState(context)
                        : filteredAsyncData.when(
                            data: (data) => data.isEmpty
                                ? _buildEmptyState(context)
                                : _buildTable(context, data),
                            loading: () => const TableSkeleton(),
                            error: (err, _) =>
                                Center(child: Text('Error: $err')),
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

  List<dynamic> _applyGlobalSearchFilter(List<dynamic> data) {
    if (_searchQuery.isEmpty) {
      return data;
    }
    return data.where(_matchesGlobalSearch).toList();
  }

  bool _matchesGlobalSearch(dynamic item) {
    final values = <String>[];

    void addValue(Object? value) {
      if (value == null) {
        return;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        values.add(text.toLowerCase());
      }
    }

    try {
      final map = item.toJson();
      if (map is Map<String, dynamic>) {
        for (final value in map.values) {
          addValue(value);
        }
      }
    } catch (_) {}

    if (item is SalesCustomer) {
      addValue(item.displayName);
      addValue(item.companyName);
      addValue(item.email);
      addValue(item.phone);
    } else if (item is SalesOrder) {
      addValue(item.saleNumber);
      addValue(item.reference);
      addValue(item.status);
      addValue(item.customer?.displayName);
    } else if (item is SalesPayment) {
      addValue(item.paymentNumber);
      addValue(item.reference);
      addValue(item.customerName);
      addValue(item.paymentMode);
    } else if (item is SalesEWayBill) {
      addValue(item.billNumber);
      addValue(item.status);
      addValue(item.vehicleNumber);
    } else if (item is SalesPaymentLink) {
      addValue(item.linkNumber);
      if (item.customer is Map<String, dynamic>) {
        addValue(item.customer?['display_name']);
        addValue(item.customer?['displayName']);
        addValue(item.customer?['name']);
      }
      addValue(item.status);
    }

    return values.any((value) => value.contains(_searchQuery));
  }

  Widget _buildTable(BuildContext context, List<dynamic> data) {
    // Sort local copy of data
    final sortedData = List<dynamic>.from(data);
    sortedData.sort((a, b) {
      dynamic valA = _getSortValue(a, _sortColumn);
      dynamic valB = _getSortValue(b, _sortColumn);

      if (valA == null && valB == null) return 0;
      if (valA == null) return 1;
      if (valB == null) return -1;

      int cmp;
      if (valA is num && valB is num) {
        cmp = valA.compareTo(valB);
      } else {
        cmp = valA.toString().toLowerCase().compareTo(
          valB.toString().toLowerCase(),
        );
      }
      return _isAscending ? cmp : -cmp;
    });

    return LayoutBuilder(
      builder: (ctx, constraints) {
        // Calculate required width
        double totalContentWidth = 40.0 + 40.0; // Checkbox + Settings
        for (var col in _visibleColumns) {
          totalContentWidth += _columnWidths[col.key] ?? 150.0;
        }

        // Ensure finite constraint for calculation
        final double parentWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : totalContentWidth;

        final double tableWidth = (totalContentWidth > parentWidth)
            ? totalContentWidth
            : parentWidth;

        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: Container(
              width: tableWidth,
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER
                  Container(
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.bgLight,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildCheckboxCell(
                          value: _selectAll,
                          onChanged: (v) => _toggleSelectAll(v, sortedData),
                        ),
                        // Settings Icon column
                        SizedBox(
                          width: 40,
                          child: MenuAnchor(
                            builder: (context, controller, child) {
                              return IconButton(
                                onPressed: () => controller.isOpen
                                    ? controller.close()
                                    : controller.open(),
                                icon: const Icon(
                                  LucideIcons.sliders,
                                  size: 16,
                                  color: AppTheme.primaryBlueDark,
                                ),
                                padding: EdgeInsets.zero,
                              );
                            },
                            menuChildren: [
                              MenuItemButton(
                                onPressed: _openCustomizeColumnsDialog,
                                child: const Text(
                                  'Customize Columns',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              MenuItemButton(
                                onPressed: () =>
                                    _state(() => _clipText = !_clipText),
                                child: Text(
                                  'Clip Text (${_clipText ? "On" : "Off"})',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),

                        ..._visibleColumns.map((col) {
                          return _buildHeaderCell(col);
                        }),
                      ],
                    ),
                  ),
                  // BODY
                  Expanded(
                    child: ListView.builder(
                      itemCount: sortedData.length,
                      itemBuilder: (context, index) {
                        final item = sortedData[index];
                        final id = _getItemId(item);
                        final isSelected =
                            id != null && _selectedIds.contains(id);

                        return MouseRegion(
                          onEnter: (_) => _state(() => _hoveredRowId = id),
                          onExit: (_) => _state(() => _hoveredRowId = null),
                          child: InkWell(
                            onTap: () {
                              final id = _getItemId(item);
                              if (id != null && widget.detailRoute != null) {
                                context.go(
                                  widget.detailRoute!.replaceAll(':id', id),
                                );
                              }
                            },
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.bgDisabled
                                    : _hoveredRowId == id
                                    ? AppTheme.bgLight
                                    : Colors.white,
                                border: const Border(
                                  bottom: BorderSide(color: AppTheme.bgDisabled),
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildCheckboxCell(
                                    value: isSelected,
                                    onChanged: (v) => _toggleSelectOne(id, v),
                                  ),
                                  // Right margin for settings alignment
                                  const SizedBox(width: 40),
                                  ..._visibleColumns.map((col) {
                                    return _buildDataCell(item, col);
                                  }),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
}
