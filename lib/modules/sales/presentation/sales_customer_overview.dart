import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import '../models/sales_customer_model.dart';
import '../models/sales_customer_detail_context_model.dart';
import '../controllers/sales_order_controller.dart';
import '../../../shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';

part 'sections/sales_customer_overview_left_panel.dart';
part 'sections/sales_customer_overview_actions.dart';
part 'sections/sales_customer_overview_tab.dart';
part 'sections/sales_customer_overview_other_tabs.dart';

final salesCustomerPaymentTermsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      final lookupsService = LookupsApiService();
      return lookupsService.getPaymentTerms();
    });

class SalesCustomerOverviewScreen extends ConsumerStatefulWidget {
  final String id;
  final String? initialTab;
  const SalesCustomerOverviewScreen({
    super.key,
    required this.id,
    this.initialTab,
  });

  @override
  ConsumerState<SalesCustomerOverviewScreen> createState() =>
      _SalesCustomerOverviewScreenState();
}

class _SalesCustomerOverviewScreenState
    extends ConsumerState<SalesCustomerOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isPanelCollapsed = false;
  bool _isHoveringPanel = false;
  String? _editingField;
  String? _tempValue;

  static const _tabs = ['overview', 'comments', 'transactions', 'mails', 'statement'];

  void _state(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  String get _orgSystemId =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';

  Map<String, CurrencyOption> _buildCurrencyLookup(
    List<CurrencyOption> currencies,
  ) {
    final lookup = <String, CurrencyOption>{};
    for (final currency in currencies) {
      if (currency.id.isNotEmpty) {
        lookup[currency.id] = currency;
      }
      if (currency.code.isNotEmpty) {
        lookup[currency.code] = currency;
      }
    }
    return lookup;
  }

  Map<String, String> _buildPaymentTermsLookup(
    List<Map<String, dynamic>> terms,
  ) {
    final lookup = <String, String>{};
    for (final term in terms) {
      final id = (term['id'] ?? '').toString().trim();
      final label = (term['term_name'] ?? '').toString().trim();
      if (id.isNotEmpty && label.isNotEmpty) {
        lookup[id] = label;
      }
      if (label.isNotEmpty) {
        lookup[label] = label;
      }
    }
    return lookup;
  }

  @override
  void initState() {
    super.initState();
    final initialIndex = _tabs.indexOf(widget.initialTab ?? 'overview');
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant SalesCustomerOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialTab != widget.initialTab) {
      final nextIndex = _tabs.indexOf(widget.initialTab ?? 'overview');
      final resolvedIndex = nextIndex < 0 ? 0 : nextIndex;
      if (resolvedIndex != _tabController.index) {
        _tabController.animateTo(resolvedIndex);
      }
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final tab = _tabs[_tabController.index];
      context.go(
        context.namedLocation(
          AppRoutes.salesCustomersDetail,
          pathParameters: {'orgSystemId': _orgSystemId, 'id': widget.id},
          queryParameters: tab == 'overview' ? {} : {'tab': tab},
        ),
      );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);
    final customerDetailAsync = ref.watch(salesCustomerByIdProvider(widget.id));
    final customerDetailContextAsync = ref.watch(
      salesCustomerDetailContextProvider(widget.id),
    );
    final currenciesAsync = ref.watch(currenciesProvider(null));
    final paymentTermsAsync = ref.watch(salesCustomerPaymentTermsProvider);
    final currencyLookup = _buildCurrencyLookup(
      currenciesAsync.valueOrNull ?? defaultCurrencyOptions,
    );
    final paymentTermsLookup = _buildPaymentTermsLookup(
      paymentTermsAsync.valueOrNull ?? const <Map<String, dynamic>>[],
    );

    return ZerpaiLayout(
      pageTitle: 'Customer Details',
      enableBodyScroll: false,
      child: customersAsync.when(
        data: (customers) {
          final fallbackSelectedCustomer = customers.firstWhere(
            (c) => c.id == widget.id,
            orElse: () => customers.first,
          );

          final isExpanded = !_isPanelCollapsed || _isHoveringPanel;

          return customerDetailAsync.when(
            data: (customerDetail) => Row(
              children: [
                // Left Panel - Mini List
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isExpanded ? 280 : 60,
                  curve: Curves.easeInOut,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringPanel = true),
                    onExit: (_) => setState(() => _isHoveringPanel = false),
                    child: _buildLeftPanel(
                      customers,
                      customerDetail,
                      isExpanded,
                    ),
                  ),
                ),
                // Vertical Divider
                Container(width: 1, color: AppTheme.borderColor),
                // Right Panel - Details
                Expanded(
                  child: _buildRightPanel(
                    customerDetail,
                    customerDetailContext: customerDetailContextAsync.valueOrNull,
                    currencyLookup: currencyLookup,
                    paymentTermsLookup: paymentTermsLookup,
                  ),
                ),
              ],
            ),
            loading: () => Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isExpanded ? 280 : 60,
                  curve: Curves.easeInOut,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringPanel = true),
                    onExit: (_) => setState(() => _isHoveringPanel = false),
                    child: _buildLeftPanel(
                      customers,
                      fallbackSelectedCustomer,
                      isExpanded,
                    ),
                  ),
                ),
                Container(width: 1, color: AppTheme.borderColor),
                const Expanded(child: CustomerDetailSkeleton()),
              ],
            ),
            error: (err, stack) => Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isExpanded ? 280 : 60,
                  curve: Curves.easeInOut,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringPanel = true),
                    onExit: (_) => setState(() => _isHoveringPanel = false),
                    child: _buildLeftPanel(
                      customers,
                      fallbackSelectedCustomer,
                      isExpanded,
                    ),
                  ),
                ),
                Container(width: 1, color: AppTheme.borderColor),
                Expanded(
                  child: Center(
                    child: Text('Error loading customer details: $err'),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const CustomerDetailSkeleton(),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildRightPanel(
    SalesCustomer customer, {
    required SalesCustomerDetailContext? customerDetailContext,
    required Map<String, CurrencyOption> currencyLookup,
    required Map<String, String> paymentTermsLookup,
  }) {
    return Column(
      children: [
        _buildActionHeader(customer),
        // Tabs
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.primaryBlueDark,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryBlueDark,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Comments'),
              Tab(text: 'Transactions'),
              Tab(text: 'Mails'),
              Tab(text: 'Statement'),
            ],
          ),
        ),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverview(
                customer,
                customerDetailContext: customerDetailContext,
                currencyLookup: currencyLookup,
                paymentTermsLookup: paymentTermsLookup,
              ),
              _buildComments(customer, customerDetailContext),
              _buildTransactions(customer, customerDetailContext),
              _buildMails(customer, customerDetailContext),
              _buildStatement(customer, customerDetailContext),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionHeader(SalesCustomer customer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.email?.isNotEmpty == true
                      ? customer.email!
                      : 'No email',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _headerButton(
            'Edit',
            LucideIcons.edit2,
            onPressed: () => context.goNamed(
                  AppRoutes.salesCustomersEdit,
                  pathParameters: {
                    'orgSystemId': _orgSystemId,
                    'id': customer.id,
                  },
                ),
          ),
          const SizedBox(width: 8),
          _attachmentsButton(),
          const SizedBox(width: 8),
          _buildMoreDropdown(),
          const SizedBox(width: 12),
          _buildNewTransactionDropdown(),
          const SizedBox(width: 8),
          _headerButton(
            '',
            LucideIcons.x,
            isIconOnly: true,
            onPressed: () => context.goNamed(
                  AppRoutes.salesCustomers,
                  pathParameters: {'orgSystemId': _orgSystemId},
                ),
          ),
        ],
      ),
    );
  }
}

class TableCellWidget extends StatelessWidget {
  final String text;
  final bool isHeader;
  final TextAlign align;
  const TableCellWidget(
    this.text, {
    super.key,
    this.isHeader = false,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
          color: isHeader ? AppTheme.textBody : AppTheme.textPrimary,
        ),
      ),
    );
  }
}
