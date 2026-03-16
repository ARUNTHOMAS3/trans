import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';

class ReportsCenterScreen extends StatefulWidget {
  const ReportsCenterScreen({super.key});

  @override
  State<ReportsCenterScreen> createState() => _ReportsCenterScreenState();
}

class _ReportsCenterScreenState extends State<ReportsCenterScreen> {
  String _selectedCategory = 'All Reports';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _sidebarCategories = [
    'Business Overview',
    'Sales',
    'Receivables',
    'Payments Received',
    'Recurring Invoices',
    'Payables',
    'Purchases and Expenses',
    'Taxes',
    'Banking',
    'Projects and Timesheet',
    'Accountant',
    'Currency',
    'Activity',
    'Automation',
  ];

  final Map<String, List<Map<String, String>>> _reportsMap = {
    'All Reports': [
      {
        'name': 'Profit and Loss',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Profit and Loss (Schedule III)',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Horizontal Profit and Loss',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Cash Flow Statement',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Balance Sheet',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Horizontal Balance Sheet',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Balance Sheet (Schedule III)',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Business Performance Ratios',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Movement of Equity',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Sales by Customer',
        'category': 'Sales',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Inventory Valuation Summary',
        'category': 'Inventory',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Sales by Item',
        'category': 'Sales',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Sales by Sales Person',
        'category': 'Sales',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Sales Summary',
        'category': 'Sales',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'AR Aging Summary',
        'category': 'Receivables',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Account Transactions',
        'category': 'Accountant',
        'created_by': 'System Generated',
        'last_visited': '21/02/2026 09:06 PM',
      },
    ],
    'Business Overview': [
      {
        'name': 'Profit and Loss',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Profit and Loss (Schedule III)',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Horizontal Profit and Loss',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Cash Flow Statement',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Balance Sheet',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Horizontal Balance Sheet',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Balance Sheet (Schedule III)',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Business Performance Ratios',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Movement of Equity',
        'category': 'Business Overview',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
    ],
    'Sales': [
      {
        'name': 'Sales by Customer',
        'category': 'Sales',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Sales by Item',
        'category': 'Sales',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Sales by Sales Person',
        'category': 'Sales',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Sales Summary',
        'category': 'Sales',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
    ],
    'Receivables': [
      {
        'name': 'AR Aging Summary',
        'category': 'Receivables',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Customer Balances',
        'category': 'Receivables',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
    ],
    'Accountant': [
      {
        'name': 'Account Transactions',
        'category': 'Accountant',
        'created_by': 'System Generated',
        'last_visited': '21/02/2026 09:06 PM',
      },
      {
        'name': 'Account Type Summary',
        'category': 'Accountant',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Account Type Transactions',
        'category': 'Accountant',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Day Book',
        'category': 'Accountant',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'General Ledger',
        'category': 'Accountant',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Detailed General Ledger',
        'category': 'Accountant',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Journal Report',
        'category': 'Accountant',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
      {
        'name': 'Trial Balance',
        'category': 'Accountant',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
    ],
    'Inventory': [
      {
        'name': 'Inventory Valuation Summary',
        'category': 'Inventory',
        'created_by': 'System Generated',
        'last_visited': '-',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'Reports Center',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Category Sidebar ---
            _buildCategorySidebar(),

            // --- Vertical Divider ---
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppTheme.borderColor,
            ),

            // --- Main Content ---
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySidebar() {
    return Container(
      width: 260,
      color: const Color(0xFFF9FAFB),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSidebarItem(
            'All Reports',
            LucideIcons.list,
            isSelected: _selectedCategory == 'All Reports',
          ),
          _buildSidebarItem(
            'Home',
            LucideIcons.home,
            isSelected: _selectedCategory == 'Home',
          ),
          _buildSidebarItem(
            'Favorites',
            LucideIcons.star,
            isSelected: _selectedCategory == 'Favorites',
          ),
          _buildSidebarItem(
            'Shared Reports',
            LucideIcons.users,
            isSelected: _selectedCategory == 'Shared',
          ),
          _buildSidebarItem(
            'Scheduled Reports',
            LucideIcons.clock,
            isSelected: _selectedCategory == 'Scheduled',
          ),

          const SizedBox(height: 16),
          _buildSidebarHeader('REPORT CATEGORY'),
          ..._sidebarCategories.map((cat) => _buildSidebarCategoryItem(cat)),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    String title,
    IconData icon, {
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 18,
        color: isSelected ? AppTheme.primaryBlue : const Color(0xFF6B7280),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? AppTheme.primaryBlue : const Color(0xFF374151),
        ),
      ),
      onTap: () => setState(() => _selectedCategory = title),
      dense: true,
      selected: isSelected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildSidebarCategoryItem(String title) {
    bool isSelected = _selectedCategory == title;
    return ListTile(
      leading: Icon(
        LucideIcons.folder,
        size: 18,
        color: isSelected ? AppTheme.primaryBlue : const Color(0xFF9CA3AF),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? AppTheme.primaryBlue : const Color(0xFF374151),
        ),
      ),
      onTap: () => setState(() => _selectedCategory = title),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildMainContent() {
    final reports = _reportsMap[_selectedCategory] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Search Bar Area ---
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: CustomTextField(
                    controller: _searchController,
                    hintText: 'Search reports',
                    prefixWidget: const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // --- Table Header ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Text(
                _selectedCategory,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${reports.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- Reports List ---
        Expanded(
          child: ListView(
            children: [
              _buildTableHeader(),
              if (reports.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Text('No reports found in this category'),
                  ),
                )
              else
                ...reports.map((report) => _buildReportRow(report)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text('REPORT NAME', style: _headerStyle),
          ),
          if (_selectedCategory == 'All Reports')
            const Expanded(
              flex: 2,
              child: Text('REPORT CATEGORY', style: _headerStyle),
            ),
          const Expanded(
            flex: 2,
            child: Text('CREATED BY', style: _headerStyle),
          ),
          const Expanded(
            flex: 2,
            child: Text('LAST VISITED', style: _headerStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(Map<String, String> report) {
    return InkWell(
      onTap: () {
        if (report['name'] == 'Account Transactions') {
          context.push(AppRoutes.accountantTransactionsReport, extra: {'accountId': 'all'});
        } else if (report['name'] == 'Daily Sales') {
          context.push(AppRoutes.reportDailySales);
        } else if (report['name'] == 'Profit and Loss') {
          context.push(AppRoutes.profitAndLoss);
        } else if (report['name'] == 'General Ledger') {
          context.push(AppRoutes.generalLedger);
        } else if (report['name'] == 'Trial Balance') {
          context.push(AppRoutes.trialBalance);
        } else if (report['name'] == 'Sales by Customer') {
          context.push(AppRoutes.salesByCustomer);
        } else if (report['name'] == 'Inventory Valuation Summary') {
          context.push(AppRoutes.inventoryValuation);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.star,
                    size: 16,
                    color: Color(0xFFD1D5DB),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    report['name']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedCategory == 'All Reports')
              Expanded(
                flex: 2,
                child: Text(
                  report['category'] ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            Expanded(
              flex: 2,
              child: Text(
                report['created_by']!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                report['last_visited']!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Color(0xFF6B7280),
    letterSpacing: 0.5,
  );
}
