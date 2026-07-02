import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';
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
              accent: AppTheme.successGreen,
              items: <_SettingsEntry>[
                _SettingsEntry(
                  label: 'Profile',
                  route: AppRoutes.settingsOrgProfile,
                ),
                _SettingsEntry(
                  label: 'Branding',
                  route: AppRoutes.settingsOrgBranding,
                ),
                _SettingsEntry(
                  label: 'Branches',
                  route: AppRoutes.settingsBranches,
                ),
                _SettingsEntry(
                  label: 'Warehouses',
                  route: AppRoutes.settingsWarehouses,
                ),
                _SettingsEntry(
                  label: 'Approvals',
                  route: AppRoutes.settingsGeneral,
                ),
                _SettingsEntry(
                  label: 'Manage Subscription',
                  route: AppRoutes.settingsGeneral,
                ),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Users & Roles',
              icon: LucideIcons.users,
              accent: AppTheme.errorRed,
              items: <_SettingsEntry>[
                _SettingsEntry(label: 'Users', route: AppRoutes.settingsUsers),
                _SettingsEntry(label: 'Roles', route: AppRoutes.settingsRoles),
                _SettingsEntry(
                  label: 'User Preferences',
                  route: AppRoutes.settingsGeneral,
                ),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Taxes & Compliance',
              icon: LucideIcons.receipt,
              accent: AppTheme.primaryBlue,
              items: <_SettingsEntry>[
                _SettingsEntry(label: 'Taxes', route: AppRoutes.settingsTaxes),
                _SettingsEntry(
                  label: 'Direct Taxes',
                  route: AppRoutes.settingsDirectTaxes,
                ),
                _SettingsEntry(
                  label: 'e-Way Bills',
                  route: AppRoutes.settingsEwayBills,
                ),
                _SettingsEntry(
                  label: 'e-Invoicing',
                  route: AppRoutes.settingsEinvoicing,
                ),
                _SettingsEntry(
                  label: 'MSME Settings',
                  route: AppRoutes.settingsMsme,
                ),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Setup & Configurations',
              icon: LucideIcons.slidersHorizontal,
              accent: AppTheme.warningOrange,
              items: <_SettingsEntry>[
                _SettingsEntry(
                  label: 'General',
                  route: AppRoutes.settingsGeneral,
                ),
                _SettingsEntry(
                  label: 'Currencies',
                  route: AppRoutes.settingsCurrencies,
                ),
                _SettingsEntry(
                  label: 'Reminders',
                  route: AppRoutes.settingsReminders,
                ),
                _SettingsEntry(
                  label: 'Customer Portal',
                  route: AppRoutes.settingsCustomerPortal,
                ),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Customization',
              icon: LucideIcons.palette,
              accent: AppTheme.warningOrange,
              items: <_SettingsEntry>[
                _SettingsEntry(
                  label: 'Transaction Number Series',
                  route: AppRoutes.settingsTransactionNumberSeries,
                ),
                _SettingsEntry(
                  label: 'PDF Templates',
                  route: AppRoutes.settingsPdfTemplates,
                ),
                _SettingsEntry(
                  label: 'Email Notifications',
                  route: AppRoutes.settingsEmailNotifications,
                ),
                _SettingsEntry(
                  label: 'SMS Notifications',
                  route: AppRoutes.settingsSmsNotifications,
                ),
                _SettingsEntry(
                  label: 'Reporting Tags',
                  route: AppRoutes.settingsReportingTags,
                ),
                _SettingsEntry(
                  label: 'Web Tabs',
                  route: AppRoutes.settingsWebTabs,
                ),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Automation',
              icon: LucideIcons.workflow,
              accent: AppTheme.errorRed,
              items: <_SettingsEntry>[
                _SettingsEntry(
                  label: 'Workflow Rules',
                  route: AppRoutes.settingsWorkflowRules,
                ),
                _SettingsEntry(
                  label: 'Workflow Actions',
                  route: AppRoutes.settingsWorkflowActions,
                ),
                _SettingsEntry(
                  label: 'Workflow Logs',
                  route: AppRoutes.settingsWorkflowLogs,
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
              accent: AppTheme.successGreen,
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
              accent: AppTheme.errorRed,
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
              accent: AppTheme.warningOrange,
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
              accent: AppTheme.successGreen,
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
              accent: AppTheme.successGreen,
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
              accent: AppTheme.successGreen,
              items: <_SettingsEntry>[
                _SettingsEntry(
                  label: 'Zoho Apps',
                  route: AppRoutes.settingsIntegrationsZoho,
                ),
                _SettingsEntry(
                  label: 'WhatsApp',
                  route: AppRoutes.settingsIntegrationsWhatsapp,
                ),
                _SettingsEntry(
                  label: 'SMS Integrations',
                  route: AppRoutes.settingsIntegrationsSms,
                ),
                _SettingsEntry(
                  label: 'Shipping',
                  route: AppRoutes.settingsIntegrationsShipping,
                ),
                _SettingsEntry(
                  label: 'Shopping Cart & POS',
                  route: AppRoutes.settingsIntegrationsPos,
                ),
                _SettingsEntry(
                  label: 'eCommerce',
                  route: AppRoutes.settingsIntegrationsEcommerce,
                ),
                _SettingsEntry(
                  label: 'Accounting',
                  route: AppRoutes.settingsIntegrationsAccounting,
                ),
                _SettingsEntry(
                  label: 'Sales & Marketing',
                  route: AppRoutes.settingsIntegrationsSalesMarketing,
                ),
                _SettingsEntry(
                  label: 'EDI',
                  route: AppRoutes.settingsIntegrationsEdi,
                ),
                _SettingsEntry(
                  label: 'Other Apps',
                  route: AppRoutes.settingsIntegrationsOtherApps,
                ),
                _SettingsEntry(
                  label: 'Marketplace',
                  route: AppRoutes.settingsIntegrationsMarketplace,
                ),
              ],
            ),
          ],
        ),
        _SettingsColumn(
          blocks: <_SettingsBlock>[
            _SettingsBlock(
              title: 'Developer Data',
              icon: LucideIcons.braces,
              accent: AppTheme.warningOrange,
              items: <_SettingsEntry>[
                _SettingsEntry(
                  label: 'Incoming Webhooks',
                  route: AppRoutes.settingsDeveloperIncomingWebhooks,
                ),
                _SettingsEntry(
                  label: 'Connections',
                  route: AppRoutes.settingsDeveloperConnections,
                ),
                _SettingsEntry(
                  label: 'API Usage',
                  route: AppRoutes.settingsDeveloperApiUsage,
                ),
                _SettingsEntry(
                  label: 'Data Management',
                  route: AppRoutes.settingsDeveloperDataManagement,
                ),
                _SettingsEntry(
                  label: 'Deluge Components Usage',
                  route: AppRoutes.settingsDeveloperDelugeComponents,
                ),
                _SettingsEntry(
                  label: 'Web Forms',
                  route: AppRoutes.settingsDeveloperWebForms,
                ),
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
    final visibleSections = _visibleSections(user);
    final filteredSections = _filteredSections(visibleSections);

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
            color: AppTheme.infoBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Icon(
            LucideIcons.settings2,
            color: AppTheme.warningOrange,
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

  List<_SettingsSection> _visibleSections(User? user) {
    final isBranchScopedUser = _isBranchScopedSettingsUser(user);
    if (!isBranchScopedUser) {
      return _sections;
    }

    return _sections
        .map((section) {
          final columns = section.columns
              .map((column) {
                final blocks = column.blocks
                    .map((block) {
                      final items = block.title == 'Organization'
                          ? block.items
                              .where((entry) => entry.label != 'Branches')
                              .toList()
                          : block.title == 'Users & Roles'
                          ? block.items
                              .where((entry) => entry.label != 'Roles')
                              .toList()
                          : block.items;
                      if (items.isEmpty) return null;
                      return _SettingsBlock(
                        title: block.title,
                        icon: block.icon,
                        accent: block.accent,
                        items: items,
                      );
                    })
                    .whereType<_SettingsBlock>()
                    .toList();
                if (blocks.isEmpty) return null;
                return _SettingsColumn(blocks: blocks);
              })
              .whereType<_SettingsColumn>()
              .toList();
          if (columns.isEmpty) return null;
          return _SettingsSection(title: section.title, columns: columns);
        })
        .whereType<_SettingsSection>()
        .toList();
  }

  List<_SettingsSection> _filteredSections(List<_SettingsSection> source) {
    if (_query.isEmpty) {
      return source;
    }

    return source
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
    final user = ref.read(authUserProvider);
    final resolvedRoute = entry.label == 'Profile'
        ? (_resolveBranchProfileRoute(user) ?? entry.route)
        : entry.route;
    if (resolvedRoute == null) {
      ZerpaiToast.info(context, '${entry.label} is not available yet');
      return;
    }
    context.go(resolvedRoute);
  }

  List<SettingsSearchItem> _buildSearchItems() {
    final sections = _visibleSections(ref.read(authUserProvider));
    final List<SettingsSearchItem> items = <SettingsSearchItem>[];

    for (final section in sections) {
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

bool _isBranchScopedSettingsUser(User? user) {
  if (user == null) return false;
  final role = user.role.trim().toLowerCase();
  final activeTenantType = (user.activeTenantType ?? '').trim().toUpperCase();
  return role == 'branch_admin' ||
      role == 'data_entry' ||
      activeTenantType == 'BRANCH' ||
      user.accessibleBranchIds.isNotEmpty;
}

String? _resolveBranchProfileRoute(User? user) {
  if (!_isBranchScopedSettingsUser(user)) return null;
  final branchId = ((user?.activeTenantType ?? '').trim().toUpperCase() ==
              'BRANCH'
          ? user?.activeTenantId?.trim()
          : null) ??
      user?.defaultBusinessBranchId?.trim() ??
      ((user?.accessibleBranchIds.isNotEmpty ?? false)
          ? user!.accessibleBranchIds.first.trim()
          : '');
  if (branchId.isEmpty) return null;
  return '/settings/branches/$branchId/profile';
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
