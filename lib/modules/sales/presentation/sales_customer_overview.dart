import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import '../models/sales_customer_model.dart';
import '../controllers/sales_order_controller.dart';
import '../../../shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

part 'sections/sales_customer_overview_left_panel.dart';
part 'sections/sales_customer_overview_actions.dart';
part 'sections/sales_customer_overview_tab.dart';
part 'sections/sales_customer_overview_other_tabs.dart';

class SalesCustomerOverviewScreen extends ConsumerStatefulWidget {
  final String id;
  const SalesCustomerOverviewScreen({super.key, required this.id});

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

  void _state(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);

    return ZerpaiLayout(
      pageTitle: 'Customer Details',
      enableBodyScroll: false,
      child: customersAsync.when(
        data: (customers) {
          final selectedCustomer = customers.firstWhere(
            (c) => c.id == widget.id,
            orElse: () => customers.first,
          );

          final isExpanded = !_isPanelCollapsed || _isHoveringPanel;

          return Row(
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
                    selectedCustomer,
                    isExpanded,
                  ),
                ),
              ),
              // Vertical Divider
              Container(width: 1, color: AppTheme.borderColor),
              // Right Panel - Details
              Expanded(child: _buildRightPanel(selectedCustomer)),
            ],
          );
        },
        loading: () => const DetailSkeleton(),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildRightPanel(SalesCustomer customer) {
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
              _buildOverview(customer),
              _buildComments(customer),
              _buildTransactions(customer),
              _buildMails(customer),
              _buildStatement(customer),
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
          _headerButton('Edit', LucideIcons.edit2),
          const SizedBox(width: 8),
          _attachmentsButton(),
          const SizedBox(width: 8),
          _buildMoreDropdown(),
          const SizedBox(width: 12),
          _buildNewTransactionDropdown(),
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
