import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';

  static const List<_SettingsSection> _sections = <_SettingsSection>[
    _SettingsSection(
      title: 'Organization Settings',
      columns: <_SettingsColumn>[
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Organization',
              icon: LucideIcons.building2,
              accent: Color(0xFF27C59A),
              items: <_SettingsEntry>[
                _SettingsEntry(
                  label: 'Profile',
                  route: AppRoutes.settingsOrgProfile,
                ),
                _SettingsEntry(
                  label: 'Branding',
                  route: AppRoutes.settingsOrgBranding,
                ),
                _SettingsEntry(label: 'Branches', route: AppRoutes.settingsBranches),
                _SettingsEntry(label: 'Warehouses', route: AppRoutes.settingsWarehouses),
                _SettingsEntry(label: 'Approvals'),
                _SettingsEntry(label: 'Manage Subscription'),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Users & Roles',
              icon: LucideIcons.users,
              accent: Color(0xFFEF4444),
              items: <_SettingsEntry>[
                _SettingsEntry(label: 'Users', route: AppRoutes.settingsUsers),
                _SettingsEntry(label: 'Roles', route: AppRoutes.settingsRoles),
                _SettingsEntry(label: 'User Preferences'),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Taxes & Compliance',
              icon: LucideIcons.receipt,
              accent: Color(0xFF3B82F6),
              items: <_SettingsEntry>[
                _SettingsEntry(label: 'Taxes'),
                _SettingsEntry(label: 'Direct Taxes'),
                _SettingsEntry(label: 'e-Way Bills'),
                _SettingsEntry(label: 'e-Invoicing'),
                _SettingsEntry(label: 'MSME Settings'),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Setup & Configurations',
              icon: LucideIcons.slidersHorizontal,
              accent: Color(0xFFF59E0B),
              items: <_SettingsEntry>[
                _SettingsEntry(label: 'General'),
                _SettingsEntry(label: 'Currencies'),
                _SettingsEntry(label: 'Reminders'),
                _SettingsEntry(label: 'Customer Portal'),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Customization',
              icon: LucideIcons.palette,
              accent: Color(0xFFF97316),
              items: <_SettingsEntry>[
                _SettingsEntry(label: 'Transaction Number Series'),
                _SettingsEntry(label: 'PDF Templates'),
                _SettingsEntry(label: 'Email Notifications'),
                _SettingsEntry(label: 'SMS Notifications'),
                _SettingsEntry(label: 'Reporting Tags'),
                _SettingsEntry(label: 'Web Tabs'),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Automation',
              icon: LucideIcons.workflow,
              accent: Color(0xFFEF4444),
              items: <_SettingsEntry>[
                _SettingsEntry(label: 'Workflow Rules'),
                _SettingsEntry(label: 'Workflow Actions'),
                _SettingsEntry(
                  label: 'Workflow Logs',
                  route: AppRoutes.auditLogs,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    _SettingsSection(
      title: 'Module Settings',
      columns: <_SettingsColumn>[
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'General',
              icon: LucideIcons.settings2,
              accent: Color(0xFF27C59A),
              items: <_SettingsEntry>[
                _SettingsEntry(
                  label: 'Customers and Vendors',
                  route: AppRoutes.salesCustomers,
                ),
                _SettingsEntry(label: 'Items', route: AppRoutes.itemsReport),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Inventory',
              icon: LucideIcons.package,
              accent: Color(0xFFEF4444),
              items: <_SettingsEntry>[
                _SettingsEntry(
                  label: 'Assemblies',
                  route: AppRoutes.assemblies,
                ),
                _SettingsEntry(
                  label: 'Inventory Adjustments',
                  route: AppRoutes.inventoryAdjustments,
                ),
                _SettingsEntry(label: 'Picklists', route: AppRoutes.picklists),
                _SettingsEntry(label: 'Packages', route: AppRoutes.packages),
                _SettingsEntry(label: 'Shipments', route: AppRoutes.shipments),
                _SettingsEntry(
                  label: 'Transfer Orders',
                  route: AppRoutes.transferOrders,
                ),
              ],
            ),
            _SettingsBlock(
              title: 'Online Payments',
              icon: LucideIcons.creditCard,
              accent: Color(0xFFF59E0B),
              items: <_SettingsEntry>[
                _SettingsEntry(
                  label: 'Customer Payments',
                  route: AppRoutes.salesPaymentsReceived,
                ),
                _SettingsEntry(
                  label: 'Vendor Payments',
                  route: AppRoutes.paymentsMade,
                ),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Sales',
              icon: LucideIcons.shoppingCart,
              accent: Color(0xFF27C59A),
              items: <_SettingsEntry>[
                _SettingsEntry(
                  label: 'Retainer Invoices',
                  route: AppRoutes.salesRetainerInvoices,
                ),
                _SettingsEntry(
                  label: 'Sales Orders',
                  route: AppRoutes.salesOrders,
                ),
                _SettingsEntry(
                  label: 'Delivery Challans',
                  route: AppRoutes.salesDeliveryChallans,
                ),
                _SettingsEntry(
                  label: 'Invoices',
                  route: AppRoutes.salesInvoices,
                ),
                _SettingsEntry(
                  label: 'Payments Received',
                  route: AppRoutes.salesPaymentsReceived,
                ),
                _SettingsEntry(
                  label: 'Sales Returns',
                  route: AppRoutes.salesReturns,
                ),
                _SettingsEntry(
                  label: 'Credit Notes',
                  route: AppRoutes.salesCreditNotes,
                ),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Purchases',
              icon: LucideIcons.shoppingBag,
              accent: Color(0xFF22C55E),
              items: <_SettingsEntry>[
                _SettingsEntry(
                  label: 'Purchase Orders',
                  route: AppRoutes.purchaseOrders,
                ),
                _SettingsEntry(label: 'Purchase Receives'),
                _SettingsEntry(label: 'Bills', route: AppRoutes.bills),
                _SettingsEntry(
                  label: 'Payments Made',
                  route: AppRoutes.paymentsMade,
                ),
                _SettingsEntry(
                  label: 'Vendor Credits',
                  route: AppRoutes.vendorCredits,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    _SettingsSection(
      title: 'Extension and Developer Data',
      columns: <_SettingsColumn>[
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Integrations & Marketplace',
              icon: LucideIcons.plugZap,
              accent: Color(0xFF27C59A),
              items: <_SettingsEntry>[
                _SettingsEntry(label: 'Zoho Apps'),
                _SettingsEntry(label: 'WhatsApp'),
                _SettingsEntry(label: 'SMS Integrations'),
                _SettingsEntry(label: 'Shipping'),
                _SettingsEntry(label: 'Shopping Cart & POS'),
                _SettingsEntry(label: 'eCommerce'),
                _SettingsEntry(
                  label: 'Accounting',
                  route: AppRoutes.accountantSettings,
                ),
                _SettingsEntry(label: 'Sales & Marketing'),
                _SettingsEntry(label: 'EDI'),
                _SettingsEntry(label: 'Other Apps'),
                _SettingsEntry(label: 'Marketplace'),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Developer Data',
              icon: LucideIcons.braces,
              accent: Color(0xFFF59E0B),
              items: <_SettingsEntry>[
                _SettingsEntry(label: 'Incoming Webhooks'),
                _SettingsEntry(label: 'Connections'),
                _SettingsEntry(label: 'API Usage'),
                _SettingsEntry(label: 'Data Management'),
                _SettingsEntry(label: 'Deluge Components Usage'),
                _SettingsEntry(label: 'Web Forms'),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider);
    final organizationName = user?.orgName.trim().isNotEmpty == true
        ? user!.orgName
        : 'Your Organization';
    final filteredSections = _filteredSections();

    return ZerpaiLayout(
      pageTitle: '',
      useHorizontalPadding: false,
      useTopPadding: false,
      searchFocusNode: _searchFocusNode,
      child: Container(
        color: AppTheme.bgLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(context, organizationName),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space32,
                AppTheme.space24,
                AppTheme.space32,
                AppTheme.space32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: filteredSections.isEmpty
                      ? _buildEmptyState()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: filteredSections
                              .map(_buildSettingsSection)
                              .toList(),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String organizationName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space32,
        AppTheme.space20,
        AppTheme.space32,
        AppTheme.space16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 980;
              final header = _buildHeaderIdentity(organizationName);
              final search = _buildSearchField();
              final close = _buildCloseButton(context);

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    const SizedBox(height: AppTheme.space16),
                    search,
                    const SizedBox(height: AppTheme.space16),
                    Align(alignment: Alignment.centerRight, child: close),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 3, child: header),
                  const SizedBox(width: AppTheme.space24),
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: AppTheme.space24),
                  close,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIdentity(String organizationName) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3EE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFED7C3)),
          ),
          child: const Icon(
            LucideIcons.settings2,
            color: Color(0xFFF97316),
            size: 22,
          ),
        ),
        const SizedBox(width: AppTheme.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('All Settings', style: AppTheme.pageTitle),
              const SizedBox(height: AppTheme.space4),
              Text(organizationName, style: AppTheme.bodyText),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 44,
      child: SettingsSearchField(
        items: _buildSearchItems(),
        focusNode: _searchFocusNode,
        controller: _searchController,
        onQueryChanged: (value) =>
            setState(() => _query = value.trim().toLowerCase()),
        onNoMatch: (rawQuery) =>
            ZerpaiToast.info(context, 'No settings matched "$rawQuery"'),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(AppRoutes.home);
      },
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        backgroundColor: AppTheme.bgLight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(LucideIcons.x, size: 16, color: AppTheme.errorRed),
      label: const Text('Close Settings'),
    );
  }

  Widget _buildSettingsSection(_SettingsSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space32),
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: AppTheme.sectionHeader.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppTheme.space20),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1200
                  ? 5
                  : width >= 980
                  ? 4
                  : width >= 720
                  ? 3
                  : width >= 480
                  ? 2
                  : 1;
              final spacing = AppTheme.space16;
              final itemWidth = (width - ((columns - 1) * spacing)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: section.columns
                    .map(
                      (column) => SizedBox(
                        width: itemWidth.clamp(240.0, 320.0),
                        child: _buildColumnCard(column),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColumnCard(_SettingsColumn column) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int index = 0; index < column.blocks.length; index++) ...[
            _buildBlock(column.blocks[index]),
            if (index != column.blocks.length - 1)
              const SizedBox(height: AppTheme.space18),
          ],
        ],
      ),
    );
  }

  Widget _buildBlock(_SettingsBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space10,
            vertical: AppTheme.space10,
          ),
          decoration: BoxDecoration(
            color: block.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(block.icon, size: 18, color: block.accent),
              const SizedBox(width: AppTheme.space10),
              Expanded(
                child: Text(
                  block.title,
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        ...block.items.map(_buildGroupEntry),
      ],
    );
  }

  Widget _buildGroupEntry(_SettingsEntry entry) {
    return InkWell(
      onTap: () => _openEntry(entry),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space8,
          vertical: AppTheme.space10,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.label,
                style: AppTheme.bodyText.copyWith(fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.infoBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              LucideIcons.searchX,
              color: AppTheme.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            'No settings matched your search',
            style: AppTheme.sectionHeader,
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Try a different keyword to find the setting you need.',
            style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  List<_SettingsSection> _filteredSections() {
    if (_query.isEmpty) {
      return _sections;
    }

    return _sections
        .map((section) {
          final columns = section.columns
              .map((column) {
                final blocks = column.blocks
                    .map((block) {
                      final blockMatches =
                          section.title.toLowerCase().contains(_query) ||
                          block.title.toLowerCase().contains(_query);
                      final items = block.items
                          .where(
                            (entry) =>
                                blockMatches ||
                                entry.label.toLowerCase().contains(_query),
                          )
                          .toList();
                      if (items.isEmpty) {
                        return null;
                      }
                      return _SettingsBlock(
                        title: block.title,
                        icon: block.icon,
                        accent: block.accent,
                        items: items,
                      );
                    })
                    .whereType<_SettingsBlock>()
                    .toList();

                if (blocks.isEmpty) {
                  return null;
                }

                return _SettingsColumn(blocks: blocks);
              })
              .whereType<_SettingsColumn>()
              .toList();

          if (columns.isEmpty) {
            return null;
          }

          return _SettingsSection(title: section.title, columns: columns);
        })
        .whereType<_SettingsSection>()
        .toList();
  }

  void _openEntry(_SettingsEntry entry) {
    if (entry.route == null) {
      ZerpaiToast.info(context, '${entry.label} is not available yet');
      return;
    }
    context.go(entry.route!);
  }

  List<SettingsSearchItem> _buildSearchItems() {
    final List<SettingsSearchItem> items = <SettingsSearchItem>[];

    for (final section in _sections) {
      for (final column in section.columns) {
        for (final block in column.blocks) {
          for (final entry in block.items) {
            if (!_isSettingsSearchEntry(entry)) {
              continue;
            }
            items.add(
              SettingsSearchItem(
                group: block.title,
                label: entry.label,
                subtitle: section.title,
                keywords: <String>[section.title, block.title],
                onSelected: () => _openEntry(entry),
              ),
            );
          }
        }
      }
    }

    return items;
  }

  bool _isSettingsSearchEntry(_SettingsEntry entry) {
    if (entry.route == null) {
      return true;
    }
    return entry.route == AppRoutes.settings ||
        entry.route == AppRoutes.settingsOrgProfile ||
        entry.route!.startsWith('${AppRoutes.settings}/');
  }
}

class _SettingsSection {
  final String title;
  final List<_SettingsColumn> columns;

  const _SettingsSection({required this.title, required this.columns});
}

class _SettingsColumn {
  final List<_SettingsBlock> blocks;

  const _SettingsColumn({required this.blocks});
}

class _SettingsBlock {
  final String title;
  final IconData icon;
  final Color accent;
  final List<_SettingsEntry> items;

  const _SettingsBlock({
    required this.title,
    required this.icon,
    required this.accent,
    required this.items,
  });
}

class _SettingsEntry {
  final String label;
  final String? route;
  const _SettingsEntry({required this.label, this.route});
}
