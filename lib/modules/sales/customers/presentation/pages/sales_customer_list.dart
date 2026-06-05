import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/providers/pricelist_provider.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_more_menu.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/widgets/tables/z_module_table.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class SalesCustomerListScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;

  const SalesCustomerListScreen({super.key, this.initialSearchQuery});

  @override
  ConsumerState<SalesCustomerListScreen> createState() =>
      _SalesCustomerListScreenState();
}

class _SalesCustomerListScreenState extends ConsumerState<SalesCustomerListScreen> {
  static const List<String> _customerViews = <String>['All Customers', 'Active', 'Inactive'];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _horizontalScrollController = ScrollController();
  final Set<String> _selectedIds = <String>{};
  List<SalesCustomer> _currentRows = const <SalesCustomer>[];
  bool _wrapText = false;
  String _sortKey = 'name';
  bool _sortAscending = true;
  String? _hoveredCustomerId;
  late List<ColumnConfig> _columnConfigs;
  static const String _columnsPrefKey = 'sales_customers_table_columns_config';
  static const String _wrapPrefKey = 'sales_customers_table_wrap_text';

  @override
  void initState() {
    super.initState();
    _columnConfigs = _defaultColumns();
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
    }
    _restorePrefs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  List<ColumnConfig> _defaultColumns() => [
        ColumnConfig(id: 'name', label: 'NAME', orderIndex: 0, isVisible: true, isLocked: true),
        ColumnConfig(id: 'customer_number', label: 'CUSTOMER NUMBER', orderIndex: 1, isVisible: true),
        ColumnConfig(id: 'first_name', label: 'FIRST NAME', orderIndex: 2, isVisible: false),
        ColumnConfig(id: 'last_name', label: 'LAST NAME', orderIndex: 3, isVisible: false),
        ColumnConfig(id: 'company_name', label: 'COMPANY NAME', orderIndex: 4, isVisible: true),
        ColumnConfig(id: 'email', label: 'EMAIL', orderIndex: 5, isVisible: true),
        ColumnConfig(id: 'phone', label: 'PHONE', orderIndex: 6, isVisible: true),
        ColumnConfig(id: 'mobile_phone', label: 'MOBILE PHONE', orderIndex: 7, isVisible: false),
        ColumnConfig(id: 'website', label: 'WEBSITE', orderIndex: 8, isVisible: false),
        ColumnConfig(id: 'payment_terms', label: 'PAYMENT TERMS', orderIndex: 9, isVisible: false),
        ColumnConfig(id: 'gst_registration_number', label: 'GST REGISTRATION NUMBER', orderIndex: 10, isVisible: false),
        ColumnConfig(id: 'gst_treatment', label: 'GST TREATMENT', orderIndex: 11, isVisible: true),
        ColumnConfig(id: 'credit_limit', label: 'CREDIT LIMIT', orderIndex: 12, isVisible: false),
        ColumnConfig(id: 'place_of_supply', label: 'PLACE OF SUPPLY', orderIndex: 13, isVisible: false),
        ColumnConfig(id: 'receivables', label: 'RECEIVABLES', orderIndex: 14, isVisible: false),
        ColumnConfig(id: 'receivables_bcy', label: 'RECEIVABLES (BCY)', orderIndex: 15, isVisible: false),
        ColumnConfig(id: 'unused_credits', label: 'UNUSED CREDITS', orderIndex: 16, isVisible: false),
        ColumnConfig(id: 'unused_credits_bcy', label: 'UNUSED CREDITS (BCY)', orderIndex: 17, isVisible: false),
        ColumnConfig(id: 'status', label: 'STATUS', orderIndex: 18, isVisible: false),
        ColumnConfig(id: 'source', label: 'SOURCE', orderIndex: 19, isVisible: true),
        ColumnConfig(id: 'adgf', label: 'ADGF', orderIndex: 20, isVisible: false),
        ColumnConfig(id: 'demo_advanced_reporting_tag', label: 'DEMO ADVACED REPORTING TAG', orderIndex: 21, isVisible: false),
        ColumnConfig(id: 'schedule', label: 'SCHEDULE', orderIndex: 22, isVisible: false),
        ColumnConfig(id: 'actions', label: 'ACTIONS', orderIndex: 23, isVisible: true, isLocked: true),
      ];

  List<ColumnConfig> _mergeWithDefaultColumns(List<ColumnConfig> savedColumns) {
    final defaults = _defaultColumns();
    final savedById = {for (final c in savedColumns) c.id: c};
    final merged = <ColumnConfig>[];

    for (final d in defaults) {
      final s = savedById[d.id];
      if (s == null) {
        merged.add(d);
      } else {
        merged.add(
          ColumnConfig(
            id: d.id,
            label: d.label,
            orderIndex: s.orderIndex,
            isVisible: s.isVisible,
            isLocked: d.isLocked,
          ),
        );
      }
    }

    return merged..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  Future<void> _restorePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawColumns = prefs.getString(_columnsPrefKey);
    final rawWrap = prefs.getBool(_wrapPrefKey);
    if (!mounted) return;

    if (rawColumns != null && rawColumns.isNotEmpty) {
      try {
        final rows = List<Map<String, dynamic>>.from(jsonDecode(rawColumns));
        if (rows.isNotEmpty) {
          setState(() {
            final saved = rows.map(ColumnConfig.fromJson).toList();
            _columnConfigs = _mergeWithDefaultColumns(saved);
          });
        }
      } catch (_) {
        // Keep defaults.
      }
    }

    if (rawWrap != null) {
      setState(() => _wrapText = rawWrap);
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wrapPrefKey, _wrapText);
    final serialized = jsonEncode(_columnConfigs.map((e) => e.toJson()).toList());
    await prefs.setString(_columnsPrefKey, serialized);
  }

  List<ColumnConfig> get _visibleColumns => _columnConfigs
      .where((c) => c.isVisible)
      .toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  List<SalesCustomer> _applySearch(List<SalesCustomer> input, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return input;
    return input.where((c) {
      return c.displayName.toLowerCase().contains(q) ||
          (c.customerNumber ?? '').toLowerCase().contains(q) ||
          (c.companyName ?? '').toLowerCase().contains(q) ||
          (c.email ?? '').toLowerCase().contains(q) ||
          (c.phone ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<SalesCustomer> _applySort(List<SalesCustomer> input) {
    final list = [...input];
    int compareText(String a, String b) =>
        _sortAscending ? a.compareTo(b) : b.compareTo(a);

    list.sort((a, b) {
      switch (_sortKey) {
        case 'name':
          return compareText(a.displayName.toLowerCase(), b.displayName.toLowerCase());
        case 'customer_number':
          return compareText((a.customerNumber ?? '').toLowerCase(), (b.customerNumber ?? '').toLowerCase());
        case 'company_name':
          return compareText((a.companyName ?? '').toLowerCase(), (b.companyName ?? '').toLowerCase());
        case 'email':
          return compareText((a.email ?? '').toLowerCase(), (b.email ?? '').toLowerCase());
        case 'phone':
          return compareText((a.phone ?? a.mobilePhone ?? '').toLowerCase(), (b.phone ?? b.mobilePhone ?? '').toLowerCase());
        case 'mobile_phone':
          return compareText((a.mobilePhone ?? '').toLowerCase(), (b.mobilePhone ?? '').toLowerCase());
        case 'first_name':
          return compareText((a.firstName ?? '').toLowerCase(), (b.firstName ?? '').toLowerCase());
        case 'last_name':
          return compareText((a.lastName ?? '').toLowerCase(), (b.lastName ?? '').toLowerCase());
        case 'website':
          return compareText((a.website ?? '').toLowerCase(), (b.website ?? '').toLowerCase());
        case 'payment_terms':
          return compareText((a.paymentTerms ?? '').toLowerCase(), (b.paymentTerms ?? '').toLowerCase());
        case 'gst_registration_number':
          return compareText((a.gstin ?? '').toLowerCase(), (b.gstin ?? '').toLowerCase());
        case 'status':
          return compareText(a.isActive ? 'active' : 'inactive', b.isActive ? 'active' : 'inactive');
        case 'gst_treatment':
          return compareText((a.gstTreatment ?? '').toLowerCase(), (b.gstTreatment ?? '').toLowerCase());
        case 'place_of_supply':
          return compareText((a.placeOfSupply ?? '').toLowerCase(), (b.placeOfSupply ?? '').toLowerCase());
        case 'credit_limit':
        case 'receivables':
        case 'receivables_bcy':
        case 'unused_credits':
        case 'unused_credits_bcy':
        case 'adgf':
        case 'demo_advanced_reporting_tag':
        case 'schedule':
        case 'source':
          return compareText('user', 'user');
        default:
          return 0;
      }
    });
    return list;
  }

  void _toggleSort(String key) {
    setState(() {
      if (_sortKey == key) {
        _sortAscending = !_sortAscending;
      } else {
        _sortKey = key;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);
    final query = _searchController.text;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.slash): () {
          _searchFocusNode.requestFocus();
        },
      },
      child: ZerpaiLayout(
        pageTitle: '',
        enableBodyScroll: false,
        useHorizontalPadding: false,
        useTopPadding: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _selectedIds.isNotEmpty
                ? _buildSelectionRibbon(context)
                : _buildTopBanner(context),
            Expanded(
              child: customersAsync.when(
                loading: () => _buildListSkeleton(context),
                error: (e, _) => Center(child: Text('Failed to load customers: $e')),
                data: (customers) {
                  final filtered = _applySort(_applySearch(customers, query));
                  _currentRows = filtered;
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No customers found'));
                  }
                  return _buildTable(context, filtered);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: const [
              Skeleton(width: 220, height: 34, borderRadius: 6),
              Spacer(),
              Skeleton(width: 140, height: 32, borderRadius: 6),
              SizedBox(width: 12),
              Skeleton(width: 88, height: 32, borderRadius: 6),
              SizedBox(width: 4),
              Skeleton(width: 32, height: 32, borderRadius: 6),
            ],
          ),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: TableSkeleton(rows: 10, columns: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBanner(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          MenuAnchor(
            style: MenuStyle(
              backgroundColor: const WidgetStatePropertyAll(Colors.white),
              surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
              elevation: const WidgetStatePropertyAll(8),
              shape: const WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            builder: (context, controller, child) => InkWell(
              onTap: () => controller.isOpen ? controller.close() : controller.open(),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'All Customers',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF4F7FF5)),
                  ],
                ),
              ),
            ),
            menuChildren: _customerViews
                .map(
                  (view) => MenuItemButton(
                    onPressed: () {},
                    child: SizedBox(width: 220, child: Text(view)),
                  ),
                )
                .toList(),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Text('View Customer Stats'),
          ),
          const SizedBox(width: 12),
          ZButton.primary(
            onPressed: () => context.push(AppRoutes.salesCustomersCreate),
            icon: Icons.add,
            label: 'New',
          ),
          const SizedBox(width: 4),
          ZTableMoreMenu(
            width: 32,
            height: 32,
            menuChildren: [
              SubmenuButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                menuChildren: [
                  _buildSortMenuItem('Name', 'name'),
                  _buildSortMenuItem('Customer Number', 'customer_number'),
                  _buildSortMenuItem('Company Name', 'company_name'),
                  _buildSortMenuItem('Email', 'email'),
                  _buildSortMenuItem('Phone', 'phone'),
                  _buildSortMenuItem('GST Treatment', 'gst_treatment'),
                  _buildSortMenuItem('Status', 'status'),
                ],
                child: const Text('Sort by'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                onPressed: () {},
                child: const Text('Import Customers'),
              ),
              SubmenuButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                menuChildren: [
                  MenuItemButton(
                    style: ZTableMoreMenu.menuItemButtonStyle(),
                    onPressed: () {},
                    child: const Text('Export Customers'),
                  ),
                  MenuItemButton(
                    style: ZTableMoreMenu.menuItemButtonStyle(),
                    onPressed: () {},
                    child: const Text('Export Current View'),
                  ),
                ],
                child: const Text('Export'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                onPressed: () {},
                child: const Text('Preferences'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                onPressed: () {},
                child: const Text('Refresh List'),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildSortMenuItem(String label, String fieldKey) {
    final isSelected = _sortKey == fieldKey;
    return MenuItemButton(
      style: ZTableMoreMenu.menuItemButtonStyle(isActive: isSelected),
      onPressed: () => _toggleSort(fieldKey),
      child: Row(
        children: [
          Text(label),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openBulkUpdateDialog(BuildContext context) async {
    final selectedCustomers = _currentRows
        .where((row) => _selectedIds.contains(row.id))
        .toList();
    if (selectedCustomers.isEmpty) return;

    final payload = await showDialog<_CustomerBulkUpdatePayload>(
      context: context,
      builder: (_) =>
          _CustomerBulkUpdateDialog(selectedCount: selectedCustomers.length),
    );
    if (!mounted || payload == null || payload.isEmpty) return;

    final controller = ref.read(salesOrderControllerProvider.notifier);
    final result = await controller.bulkUpdateCustomers(
      selectedCustomers.map((c) => c.id).toList(),
      payload.toRequestMap(),
    );
    final successCount = (result['updatedCount'] as num?)?.toInt() ?? 0;
    final failedCount = (result['failedCount'] as num?)?.toInt() ?? 0;

    if (!mounted) return;
    setState(() => _selectedIds.clear());
    if (failedCount == 0) {
      ZerpaiToast.success(context, 'Updated $successCount customer(s).');
      return;
    }
    ZerpaiToast.info(
      context,
      'Updated $successCount; failed $failedCount.',
    );
  }

  Widget _buildSelectionRibbon(BuildContext context) {
    final plainButtonStyle = OutlinedButton.styleFrom(
      foregroundColor: AppTheme.textPrimary,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFD1D5DB)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    );
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8F8),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: () => _openBulkUpdateDialog(context),
            style: plainButtonStyle,
            child: const Text('Bulk Update'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {},
            style: plainButtonStyle,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.print_outlined, size: 16),
                SizedBox(width: 6),
                Text('Print'),
              ],
            ),
          ),
          const VerticalDivider(width: 20, indent: 12, endIndent: 12),
          OutlinedButton(
            onPressed: () {},
            style: plainButtonStyle,
            child: const Text('Mark as Inactive'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {},
            style: plainButtonStyle,
            child: const Text('Merge'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {},
            style: plainButtonStyle,
            child: const Text('Associate Templates'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {},
            style: plainButtonStyle,
            child: const Text('Request GST Information'),
          ),
          const SizedBox(width: 8),
          MenuAnchor(
            builder: (context, controller, child) => OutlinedButton(
              onPressed: () => controller.isOpen ? controller.close() : controller.open(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                minimumSize: const Size(38, 38),
              ),
              child: const Icon(Icons.more_horiz, size: 18),
            ),
            menuChildren: [
              MenuItemButton(
                onPressed: () {},
                child: const SizedBox(width: 180, child: Text('Delete')),
              ),
            ],
          ),
          const VerticalDivider(width: 20, indent: 12, endIndent: 12),
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFE6EEF9),
            child: Text(
              '${_selectedIds.length}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Selected'),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _selectedIds.clear()),
            child: const Row(
              children: [
                Text('Esc'),
                SizedBox(width: 4),
                Icon(Icons.close, size: 16, color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<SalesCustomer> customers) {
    final orgSystemId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
    return LayoutBuilder(
      builder: (context, constraints) {
        final allSelected = customers.isNotEmpty && _selectedIds.length == customers.length;
        final visibleWidth = _visibleColumns
            .map((c) => _columnWidth(c.id))
            .fold<double>(0, (sum, w) => sum + w);
        // controls: left inset + header menu + spacer + checkbox
        final controlsWidth = 0 + 28 + 8 + 36;
        final tableWidth = math.max(constraints.maxWidth, visibleWidth + controlsWidth);
        return Scrollbar(
          controller: _horizontalScrollController,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: ZModuleTable<SalesCustomer>(
                  rows: customers,
                  visibleColumns: _visibleColumns,
                  rowId: (row) => row.id,
                  horizontalInset: 0,
                  allSelected: allSelected,
                  isSelected: (id) => _selectedIds.contains(id),
                  wrapText: _wrapText,
                  sortKey: _sortKey,
                  sortAscending: _sortAscending,
                  headerBuilder: (context, column) => Text(
                    column.id == 'actions' ? '' : column.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  onHeaderTap: (key) {
                    if (key != 'actions') _toggleSort(key);
                  },
                  onHoveredRowChanged: (id) {
                    if (_hoveredCustomerId == id) return;
                    setState(() => _hoveredCustomerId = id);
                  },
                  onAllSelectedChanged: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedIds
                          ..clear()
                          ..addAll(customers.map((e) => e.id));
                      } else {
                        _selectedIds.clear();
                      }
                    });
                  },
                  onRowSelectChanged: (id, selected) {
                    setState(() {
                      if (selected) {
                        _selectedIds.add(id);
                      } else {
                        _selectedIds.remove(id);
                      }
                    });
                  },
                  onWrapTextChanged: (val) async {
                    setState(() => _wrapText = val);
                    await _savePrefs();
                  },
                  onCustomizeColumns: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => ColumnCustomizerDialog(
                        columns: _columnConfigs,
                        onSave: (items) async {
                          setState(() => _columnConfigs = items);
                          Navigator.of(context).pop();
                          await _savePrefs();
                        },
                      ),
                    );
                  },
                  columnWidthBuilder: _columnWidth,
                  cellBuilder: (context, customer, column) =>
                      _buildDataCell(context, column, customer, orgSystemId),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataCell(
    BuildContext context,
    ColumnConfig column,
    SalesCustomer customer,
    String orgSystemId,
  ) {
    String textFor(String id) {
      switch (id) {
        case 'name':
          return customer.displayName;
        case 'customer_number':
          return customer.customerNumber ?? '';
        case 'first_name':
          return customer.firstName ?? '';
        case 'last_name':
          return customer.lastName ?? '';
        case 'company_name':
          return customer.companyName ?? '';
        case 'email':
          return customer.email ?? '';
        case 'phone':
          return customer.phone ?? customer.mobilePhone ?? '';
        case 'mobile_phone':
          return customer.mobilePhone ?? '';
        case 'website':
          return customer.website ?? '';
        case 'payment_terms':
          return customer.paymentTerms ?? '';
        case 'gst_registration_number':
          return customer.gstin ?? '';
        case 'gst_treatment':
          return customer.gstTreatment ?? '';
        case 'credit_limit':
          return _formatAmount(customer.creditLimit);
        case 'place_of_supply':
          return customer.placeOfSupply ?? '';
        case 'receivables':
          return _formatAmount(customer.receivables);
        case 'receivables_bcy':
          return _formatAmount(customer.receivables);
        case 'unused_credits':
          return '-';
        case 'unused_credits_bcy':
          return '-';
        case 'status':
          return customer.isActive ? 'active' : 'inactive';
        case 'source':
          return 'User';
        case 'adgf':
        case 'demo_advanced_reporting_tag':
        case 'schedule':
          return '-';
        default:
          return '';
      }
    }

    if (column.id == 'actions') {
      final show = _hoveredCustomerId == customer.id;
      return Align(
        alignment: Alignment.centerLeft,
        child: show
            ? IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                onPressed: () => context.pushNamed(
                  AppRoutes.salesCustomersEdit,
                  pathParameters: {'orgSystemId': orgSystemId, 'id': customer.id},
                ),
              )
            : const SizedBox(width: 16, height: 16),
      );
    }

    final text = textFor(column.id);
    final isName = column.id == 'name';
    final child = Text(
      text,
      maxLines: _wrapText ? 2 : 1,
      overflow: _wrapText ? TextOverflow.ellipsis : TextOverflow.clip,
      style: TextStyle(
        fontSize: 14,
        fontWeight: isName ? FontWeight.w500 : FontWeight.w400,
        color: isName ? const Color(0xFF2563EB) : AppTheme.textPrimary,
      ),
    );

    return isName
        ? InkWell(
            onTap: () => context.goNamed(
              AppRoutes.salesCustomersDetail,
              pathParameters: {'orgSystemId': orgSystemId, 'id': customer.id},
            ),
            child: child,
          )
        : child;
  }

  double _columnWidth(String id) {
    switch (id) {
      case 'name':
        return 210;
      case 'customer_number':
        return 170;
      case 'first_name':
      case 'last_name':
        return 140;
      case 'company_name':
        return 220;
      case 'email':
        return 240;
      case 'phone':
        return 150;
      case 'mobile_phone':
        return 150;
      case 'website':
        return 190;
      case 'payment_terms':
        return 160;
      case 'gst_registration_number':
        return 210;
      case 'gst_treatment':
        return 220;
      case 'credit_limit':
      case 'receivables':
      case 'receivables_bcy':
      case 'unused_credits':
      case 'unused_credits_bcy':
        return 170;
      case 'place_of_supply':
        return 170;
      case 'status':
        return 110;
      case 'source':
        return 110;
      case 'adgf':
      case 'demo_advanced_reporting_tag':
      case 'schedule':
        return 220;
      case 'actions':
        return 90;
      default:
        return 160;
    }
  }

  String _formatAmount(double? value) {
    if (value == null) return '-';
    return '₹ ${value.toStringAsFixed(2)}';
  }
}

class _ScopedPriceListOption {
  final String id;
  final String name;
  final String scope; // SELF | BRANCH
  final bool selectable;

  const _ScopedPriceListOption({
    required this.id,
    required this.name,
    required this.scope,
    required this.selectable,
  });
}

class _CustomerBulkUpdatePayload {
  final String? customerType;
  final double? creditLimit;
  final String? currencyId;
  final String? paymentTerms;
  final String? customerLanguage;
  final String? priceListId;
  final String? placeOfSupply;
  final String? gstTreatment;

  const _CustomerBulkUpdatePayload({
    this.customerType,
    this.creditLimit,
    this.currencyId,
    this.paymentTerms,
    this.customerLanguage,
    this.priceListId,
    this.placeOfSupply,
    this.gstTreatment,
  });

  bool get isEmpty =>
      customerType == null &&
      creditLimit == null &&
      currencyId == null &&
      paymentTerms == null &&
      customerLanguage == null &&
      priceListId == null &&
      placeOfSupply == null &&
      gstTreatment == null;

  Map<String, dynamic> toRequestMap() {
    final map = <String, dynamic>{};
    if (customerType != null && customerType!.isNotEmpty) {
      map['customerType'] = customerType!.toLowerCase();
    }
    if (creditLimit != null) map['creditLimit'] = creditLimit;
    if (currencyId != null && currencyId!.isNotEmpty) map['currencyId'] = currencyId;
    if (paymentTerms != null && paymentTerms!.isNotEmpty) {
      map['paymentTerms'] = paymentTerms;
    }
    if (customerLanguage != null && customerLanguage!.isNotEmpty) {
      map['customerLanguage'] = customerLanguage;
    }
    if (priceListId != null && priceListId!.isNotEmpty) map['priceListId'] = priceListId;
    if (placeOfSupply != null && placeOfSupply!.isNotEmpty) {
      map['placeOfSupply'] = placeOfSupply;
    }
    if (gstTreatment != null && gstTreatment!.isNotEmpty) {
      map['gstTreatment'] = _mapGstTreatmentForApi(gstTreatment!);
    }
    return map;
  }

  static String _mapGstTreatmentForApi(String label) {
    const map = <String, String>{
      'Registered Business - Regular': 'registered business',
      'Registered Business - Composition': 'registered business',
      'Unregistered Business': 'unregistered_business',
      'Consumer': 'consumer',
      'Overseas': 'overseas',
      'Special Economic Zone': 'overseas',
      'Deemed Export': 'overseas',
      'Tax Deductor': 'consumer',
      'SEZ Developer': 'overseas',
      'Input Service Distributor': 'registered business',
    };
    return map[label] ?? 'consumer';
  }
}

class _CustomerBulkUpdateDialog extends ConsumerStatefulWidget {
  final int selectedCount;

  const _CustomerBulkUpdateDialog({required this.selectedCount});

  @override
  ConsumerState<_CustomerBulkUpdateDialog> createState() =>
      _CustomerBulkUpdateDialogState();
}

class _CustomerBulkUpdateDialogState
    extends ConsumerState<_CustomerBulkUpdateDialog> {
  final TextEditingController _creditLimitController = TextEditingController();
  bool _saving = false;
  String? _customerType;
  String? _currencyId;
  String? _paymentTerms;
  String? _customerLanguage;
  String? _priceListId;
  String? _branchPriceListId;
  String? _placeOfSupply;
  String? _gstTreatment;

  List<CurrencyOption> _currencies = const <CurrencyOption>[];
  List<Map<String, dynamic>> _paymentTermsList = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _priceLists = const <Map<String, dynamic>>[];
  List<Map<String, String>> _states = const <Map<String, String>>[];

  static const List<String> _languages = <String>[
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Malayalam',
    'Marathi',
    'Gujarati',
  ];

  static const List<String> _gstOptions = <String>[
    'Registered Business - Regular',
    'Registered Business - Composition',
    'Unregistered Business',
    'Consumer',
    'Overseas',
    'Special Economic Zone',
    'Deemed Export',
    'Tax Deductor',
    'SEZ Developer',
    'Input Service Distributor',
  ];

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    final lookupsService = LookupsApiService();
    final pricesNotifier = ref.read(priceListNotifierProvider.notifier);
    await pricesNotifier.fetchPriceLists();

    final currenciesFuture = ref.read(currenciesProvider(null).future);
    final countriesFuture = ref.read(countriesProvider(null).future);
    final termsFuture = lookupsService.getPaymentTerms();
    final priceListsFuture = lookupsService.getPriceLists();

    final currencies = await currenciesFuture;
    final countries = await countriesFuture;
    final terms = await termsFuture;
    final priceLists = await priceListsFuture;

    List<Map<String, String>> states = const <Map<String, String>>[];
    final india = countries.cast<Map<String, String>?>().firstWhere(
      (c) => c?['id'] == 'IN' || c?['name'] == 'India',
      orElse: () => null,
    );
    final indiaId = india?['id'];
    if (indiaId != null && indiaId.isNotEmpty) {
      states = await ref.read(statesProvider(indiaId).future);
    }

    if (!mounted) return;
    setState(() {
      _currencies = currencies;
      _paymentTermsList = terms;
      _priceLists = priceLists;
      _states = states;
    });
  }

  _CustomerBulkUpdatePayload _buildPayload() {
    final creditLimitText = _creditLimitController.text.trim();
    final selectedScopedPriceListId = _branchPriceListId ?? _priceListId;
    return _CustomerBulkUpdatePayload(
      customerType: _customerType,
      creditLimit: creditLimitText.isEmpty ? null : double.tryParse(creditLimitText),
      currencyId: _currencyId,
      paymentTerms: _paymentTerms,
      customerLanguage: _customerLanguage,
      priceListId: selectedScopedPriceListId,
      placeOfSupply: _placeOfSupply,
      gstTreatment: _gstTreatment,
    );
  }

  _ScopedPriceListOption? get _selectedScopedPriceListOption {
    if (_branchPriceListId != null && _branchPriceListId!.isNotEmpty) {
      return _scopedPriceListOptions.cast<_ScopedPriceListOption?>().firstWhere(
        (o) => o?.id == _branchPriceListId && o?.scope == 'BRANCH',
        orElse: () => null,
      );
    }
    if (_priceListId != null && _priceListId!.isNotEmpty) {
      return _scopedPriceListOptions.cast<_ScopedPriceListOption?>().firstWhere(
        (o) => o?.id == _priceListId && o?.scope == 'SELF',
        orElse: () => null,
      );
    }
    return null;
  }

  List<_ScopedPriceListOption> get _scopedPriceListOptions {
    final self = _selfScopedPriceLists
        .map(
          (p) => _ScopedPriceListOption(
            id: (p['id'] ?? '').toString(),
            name: _priceListDisplayName(p),
            scope: 'SELF',
            selectable: true,
          ),
        )
        .where((o) => o.id.isNotEmpty)
        .toList();
    final branch = _branchScopedPriceLists
        .map(
          (p) => _ScopedPriceListOption(
            id: (p['id'] ?? '').toString(),
            name: _priceListDisplayName(p),
            scope: 'BRANCH',
            selectable: true,
          ),
        )
        .where((o) => o.id.isNotEmpty)
        .toList();

    final options = <_ScopedPriceListOption>[];
    if (self.isNotEmpty) {
      options.add(
        const _ScopedPriceListOption(
          id: '__header_self__',
          name: 'Price List',
          scope: 'SELF',
          selectable: false,
        ),
      );
      options.addAll(self);
    }
    if (branch.isNotEmpty) {
      options.add(
        const _ScopedPriceListOption(
          id: '__header_branch__',
          name: 'Branch Price List',
          scope: 'BRANCH',
          selectable: false,
        ),
      );
      options.addAll(branch);
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Text(
                    'Bulk Update - Customers (${widget.selectedCount})',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Column(
                  children: [
                    _buildCustomerTypeRow(),
                    _buildCreditLimitRow(),
                    _buildDropdownRow<CurrencyOption>(
                      label: 'Currency',
                      value: _currencies.cast<CurrencyOption?>().firstWhere(
                        (c) => c?.id == _currencyId,
                        orElse: () => null,
                      ),
                      items: _currencies,
                      display: (item) => item.label,
                      onChanged: (value) => setState(() => _currencyId = value?.id),
                    ),
                    _buildDropdownRow<Map<String, dynamic>>(
                      label: 'Payment Terms',
                      value: _paymentTermsList.cast<Map<String, dynamic>?>().firstWhere(
                        (t) =>
                            (t?['id']?.toString() ?? '') == _paymentTerms ||
                            (t?['term_name']?.toString() ?? '') == _paymentTerms,
                        orElse: () => null,
                      ),
                      items: _paymentTermsList,
                      display: (item) => item['term_name']?.toString() ?? '',
                      onChanged: (value) => setState(
                        () => _paymentTerms = value?['id']?.toString() ??
                            value?['term_name']?.toString(),
                      ),
                    ),
                    _buildDropdownRow<String>(
                      label: 'Customer Language',
                      value: _customerLanguage,
                      items: _languages,
                      display: (item) => item,
                      labelSuffix: const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: ZTooltip(
                          message:
                              'Sets the communication language for customer-facing documents.',
                        ),
                      ),
                      onChanged: (value) => setState(() => _customerLanguage = value),
                    ),
                    _buildDropdownRow<_ScopedPriceListOption>(
                      label: 'Price List',
                      value: _selectedScopedPriceListOption,
                      items: _scopedPriceListOptions,
                      display: (item) => item.name,
                      isItemEnabled: (item) => item.selectable,
                      itemBuilder: (item, isSelected, isHovered) {
                        if (!item.selectable) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              item.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Text(item.name),
                        );
                      },
                      onChanged: (value) => setState(() {
                        if (value == null || !value.selectable) return;
                        if (value.scope == 'BRANCH') {
                          _branchPriceListId = value.id;
                          _priceListId = null;
                        } else {
                          _priceListId = value.id;
                          _branchPriceListId = null;
                        }
                      }),
                    ),
                    _buildDropdownRow<Map<String, String>>(
                      label: 'Place of Supply / Source of Supply',
                      value: _states.cast<Map<String, String>?>().firstWhere(
                        (s) => s?['id'] == _placeOfSupply,
                        orElse: () => null,
                      ),
                      items: _states,
                      display: (item) => item['name'] ?? '',
                      helperText:
                          "This is not applicable for contacts that has 'Overseas' as GST treatment.",
                      onChanged: (value) =>
                          setState(() => _placeOfSupply = value?['id']),
                    ),
                    _buildDropdownRow<String>(
                      label: 'GST Treatment',
                      value: _gstTreatment,
                      items: _gstOptions,
                      display: (item) => item,
                      hintText: 'Select a GST treatment',
                      onChanged: (value) => setState(() => _gstTreatment = value),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  ZButton.primary(
                    label: 'Update Fields',
                    onPressed: _saving
                        ? null
                        : () async {
                            final payload = _buildPayload();
                            if (payload.isEmpty) {
                              Navigator.of(context).pop();
                              return;
                            }
                            setState(() => _saving = true);
                            Navigator.of(context).pop(payload);
                          },
                  ),
                  const SizedBox(width: 10),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditLimitRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 170,
            child: Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Credit Limit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: CustomTextField(
              controller: _creditLimitController,
              hintText: '0',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              height: 36,
              prefixWidget: Container(
                width: 42,
                alignment: Alignment.center,
                child: const Text(
                  'INR',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTypeRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 170,
            child: Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Customer Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: RadioGroup<String>(
                groupValue: _customerType,
                onChanged: (value) => setState(() => _customerType = value),
                child: Row(
                  children: [
                    const Radio<String>(value: 'Business'),
                    const Text('Business'),
                    const SizedBox(width: 14),
                    const Radio<String>(value: 'Individual'),
                    const Text('Individual'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _selfScopedPriceLists => _priceLists
      .where(_isSalesPriceList)
      .where((p) => _resolvePriceScope(p) == 'SELF')
      .toList();

  List<Map<String, dynamic>> get _branchScopedPriceLists => _priceLists
      .where(_isSalesPriceList)
      .where((p) => _resolvePriceScope(p) == 'BRANCH')
      .toList();

  bool _isSalesPriceList(Map<String, dynamic> json) {
    final status = (json['status']?.toString() ?? '').toLowerCase();
    final transactionType =
        (json['transaction_type'] ?? json['transactionType'] ?? '')
            .toString()
            .toLowerCase();
    final active = status.isEmpty || status == 'active';
    final sales = transactionType.isEmpty || transactionType == 'sales';
    return active && sales;
  }

  String _resolvePriceScope(Map<String, dynamic> json) {
    final raw = (json['price_scope'] ?? json['priceScope'] ?? '')
        .toString()
        .toUpperCase()
        .trim();
    if (raw == 'BRANCH') return 'BRANCH';
    if (raw == 'SELF') return 'SELF';
    // Backward-safe fallback for older payloads missing scope
    final name = _priceListDisplayName(json).toLowerCase();
    if (name.contains('branch')) return 'BRANCH';
    return 'SELF';
  }

  String _priceListDisplayName(Map<String, dynamic> item) =>
      item['name']?.toString() ??
      item['priceListName']?.toString() ??
      item['displayName']?.toString() ??
      '';

  Widget _buildDropdownRow<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T value) display,
    required ValueChanged<T?> onChanged,
    bool Function(T item)? isItemEnabled,
    Widget Function(T item, bool isSelected, bool isHovered)? itemBuilder,
    String? hintText,
    String? helperText,
    Widget? labelSuffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (labelSuffix != null) labelSuffix,
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormDropdown<T>(
                  value: value,
                  items: items,
                  hint: hintText ?? 'Select',
                  onChanged: onChanged,
                  isItemEnabled: isItemEnabled,
                  itemBuilder: itemBuilder,
                  displayStringForValue: display,
                  showSearch: true,
                  height: 36,
                  fillColor: Colors.white,
                ),
                if (helperText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    helperText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
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
}
