import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/modules/settings/users_roles/providers/role_creation_provider.dart';

/// ---------------------------------------------------------------------------
/// MODELS (UI Metadata)
/// ---------------------------------------------------------------------------

class PermissionRowMeta {
  final String label;
  final String key;
  final List<String> actions;
  final List<String> overrides;

  PermissionRowMeta({
    required this.label,
    required this.key,
    this.actions = const ['view', 'create', 'edit', 'delete'],
    this.overrides = const [],
  });
}

class PermissionSectionMeta {
  final String title;
  final List<PermissionRowMeta> rows;
  PermissionSectionMeta({required this.title, required this.rows});
}

/// ---------------------------------------------------------------------------
/// PAGE COMPONENT
/// ---------------------------------------------------------------------------

class SettingsUsersRolesRoleCreation extends ConsumerWidget {
  const SettingsUsersRolesRoleCreation({super.key, this.roleId});

  final String? roleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleCreationProvider);
    final notifier = ref.read(roleCreationProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, ref, state, notifier),
          _buildTabHeader(state, notifier),
          Expanded(
            child: IndexedStack(
              index: state.activeTabIndex,
              children: [
                _buildGeneralTab(state, notifier),
                _buildSegmentedAccessTab(state, notifier),
              ],
            ),
          ),
          _buildFooter(context, state),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref,
      RoleCreationState state, RoleCreationNotifier notifier) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 20),
            onPressed: () => context.go(AppRoutes.settingsRoles),
          ),
          const SizedBox(width: 8),
          Text(
            roleId == null ? 'New Role' : 'Edit Role',
            style: AppTheme.pageTitle.copyWith(fontSize: 18),
          ),
          const Spacer(),
          SizedBox(
            width: 300,
            height: 36,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search settings ( / )',
                prefixIcon: const Icon(LucideIcons.search, size: 16),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
              ),
              onChanged: notifier.setSearch,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 20, color: AppTheme.errorRed),
            onPressed: () => context.go(AppRoutes.settingsRoles),
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeader(RoleCreationState state, RoleCreationNotifier notifier) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'General',
            isActive: state.activeTabIndex == 0,
            onTap: () => notifier.setTabIndex(0),
          ),
          const SizedBox(width: 32),
          _TabItem(
            label: 'Segmented Access Control',
            isActive: state.activeTabIndex == 1,
            onTap: () => notifier.setTabIndex(1),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab(RoleCreationState state, RoleCreationNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GeneralFormRow(
            label: 'Role Name',
            required: true,
            child: CustomTextField(
              controller: TextEditingController(text: state.roleName)
                ..selection = TextSelection.collapsed(offset: state.roleName.length),
              onChanged: notifier.setRoleName,
              hintText: 'Enter role name',
            ),
          ),
          const SizedBox(height: 24),
          _GeneralFormRow(
            label: 'Description',
            child: CustomTextField(
              controller: TextEditingController(text: state.description)
                ..selection = TextSelection.collapsed(offset: state.description.length),
              onChanged: notifier.setDescription,
              maxLines: 4,
              hintText: 'Max. 500 characters',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedAccessTab(
      RoleCreationState state, RoleCreationNotifier notifier) {
    final sections = _getMetadata();
    final query = state.searchQuery.toLowerCase();
    
    final filteredSections = sections.map((section) {
      final filteredRows = section.rows.where((row) {
        return row.label.toLowerCase().contains(query) || 
               section.title.toLowerCase().contains(query);
      }).toList();
      return PermissionSectionMeta(title: section.title, rows: filteredRows);
    }).where((section) => section.rows.isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildPermissionTable(state, notifier, filteredSections),
        const SizedBox(height: 48),
        _buildReportsSection(state, notifier),
      ],
    );
  }

  Widget _buildPermissionTable(RoleCreationState state,
      RoleCreationNotifier notifier, List<PermissionSectionMeta> sections) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          for (final section in sections) ...[
            _buildSectionHeader(state, notifier, section),
            for (final row in section.rows) _buildRow(state, notifier, row),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 36,
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Expanded(flex: 4, child: Text('PARTICULARS', style: _headerStyle)),
          _headerCell('FULL'),
          _headerCell('VIEW'),
          _headerCell('CREATE'),
          _headerCell('EDIT'),
          _headerCell('DELETE'),
          _headerCell('APPROVE'),
          _headerCell('OTHERS'),
        ],
      ),
    );
  }

  Widget _headerCell(String label) {
    return Expanded(
      flex: 1,
      child: Center(
        child: Text(label, style: _headerStyle),
      ),
    );
  }

  Widget _buildSectionHeader(RoleCreationState state, RoleCreationNotifier notifier, PermissionSectionMeta section) {
    final moduleKeys = section.rows.map((r) => r.key).toList();
    final moduleActionMap = { for (var r in section.rows) r.key : r.actions };
    
    // Check if ALL rows in this section have a specific permission enabled
    bool isAllChecked(String action) {
      if (section.rows.isEmpty) return false;
      return section.rows.every((r) => 
        (state.permissions[r.key] ?? {}).contains(action) || 
        (!r.actions.contains(action) && action != 'full')
      );
    }

    return Container(
      height: 36,
      width: double.infinity,
      color: const Color(0xFFE9ECEF),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              section.title.toUpperCase(),
              style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          _sectionCheckCell(isAllChecked('full'), (v) => notifier.toggleCategoryColumn(moduleKeys, 'full', v, moduleActionMap)),
          _sectionCheckCell(isAllChecked('view'), (v) => notifier.toggleCategoryColumn(moduleKeys, 'view', v, moduleActionMap)),
          _sectionCheckCell(isAllChecked('create'), (v) => notifier.toggleCategoryColumn(moduleKeys, 'create', v, moduleActionMap)),
          _sectionCheckCell(isAllChecked('edit'), (v) => notifier.toggleCategoryColumn(moduleKeys, 'edit', v, moduleActionMap)),
          _sectionCheckCell(isAllChecked('delete'), (v) => notifier.toggleCategoryColumn(moduleKeys, 'delete', v, moduleActionMap)),
          _sectionCheckCell(isAllChecked('approve'), (v) => notifier.toggleCategoryColumn(moduleKeys, 'approve', v, moduleActionMap)),
          const Expanded(child: SizedBox()), // No Select All for Others
        ],
      ),
    );
  }

  Widget _sectionCheckCell(bool value, Function(bool) onChanged) {
    return Expanded(
      flex: 1,
      child: Center(
        child: _ZohoCheckbox(value: value, onTap: () => onChanged(!value)),
      ),
    );
  }

  Widget _buildRow(
      RoleCreationState state, RoleCreationNotifier notifier, PermissionRowMeta row) {
    final activeActions = state.permissions[row.key] ?? {};
    
    return _HoverRow(
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(row.label, style: AppTheme.bodyText.copyWith(fontSize: 13)),
          ),
          _checkCell(activeActions.contains('full'),
              () => notifier.togglePermission(row.key, 'full', row.actions)),
          _checkCell(activeActions.contains('view'),
              () => notifier.togglePermission(row.key, 'view', row.actions)),
          row.actions.contains('create')
              ? _checkCell(activeActions.contains('create'),
                  () => notifier.togglePermission(row.key, 'create', row.actions))
              : const Expanded(child: SizedBox()),
          row.actions.contains('edit')
              ? _checkCell(activeActions.contains('edit'),
                  () => notifier.togglePermission(row.key, 'edit', row.actions))
              : const Expanded(child: SizedBox()),
          row.actions.contains('delete')
              ? _checkCell(activeActions.contains('delete'),
                  () => notifier.togglePermission(row.key, 'delete', row.actions))
              : const Expanded(child: SizedBox()),
          row.actions.contains('approve')
              ? _checkCell(activeActions.contains('approve'),
                  () => notifier.togglePermission(row.key, 'approve', row.actions))
              : const Expanded(child: SizedBox()),
          row.overrides.isNotEmpty ? _buildOthersMenu(state, notifier, row) : const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _checkCell(bool value, VoidCallback onTap) {
    return Expanded(
      flex: 1,
      child: Center(
        child: _ZohoCheckbox(value: value, onTap: onTap),
      ),
    );
  }

  Widget _buildOthersMenu(RoleCreationState state, RoleCreationNotifier notifier, PermissionRowMeta row) {
    final overrides = state.advancedOverrides[row.key] ?? {};
    
    return Expanded(
      flex: 1,
      child: Center(
        child: MenuAnchor(
          style: MenuStyle(
            padding: WidgetStateProperty.all(const EdgeInsets.all(16)),
            backgroundColor: WidgetStateProperty.all(Colors.white),
            elevation: WidgetStateProperty.all(8),
          ),
          menuChildren: [
            for (final override in row.overrides)
              _buildOverrideMenuItem(row.key, override, overrides[override] ?? false, notifier),
          ],
          builder: (context, controller, child) {
            return InkWell(
              onTap: () => controller.isOpen ? controller.close() : controller.open(),
              child: Text(
                'More Permissions',
                style: AppTheme.bodyText.copyWith(
                  color: const Color(0xFF0088FF),
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverrideMenuItem(String moduleKey, String label, bool value, RoleCreationNotifier notifier) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _ZohoCheckbox(value: value, onTap: () => notifier.toggleAdvancedOverride(moduleKey, label, !value)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTheme.bodyText.copyWith(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildReportsSection(RoleCreationState state, RoleCreationNotifier notifier) {
    final categories = ['SALES', 'PURCHASES', 'INVENTORY', 'ACCOUNTANT'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REPORTS', style: AppTheme.pageTitle.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(
          children: [
            Switch(
              value: state.fullAccessReports,
              onChanged: notifier.toggleFullAccessReports,
              activeTrackColor: const Color(0xFF0088FF).withValues(alpha: 0.5),
              activeColor: const Color(0xFF0088FF),
            ),
            const SizedBox(width: 12),
            const Text('Enable full access for all reports', style: TextStyle(fontSize: 13)),
          ],
        ),
        if (!state.fullAccessReports) ...[
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                _buildReportsHeader(notifier, categories),
                for (final cat in categories)
                  _buildReportRow(state, notifier, cat),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReportsHeader(RoleCreationNotifier notifier, List<String> cats) {
    return Container(
      height: 36,
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Expanded(flex: 4, child: Text('PARTICULARS', style: _headerStyle)),
          _reportHeaderCell('FULL ACCESS', () => notifier.selectAllReportsColumn('full_access', cats, true)),
          _reportHeaderCell('VIEW', () => notifier.selectAllReportsColumn('view', cats, true)),
          _reportHeaderCell('EXPORT', () => notifier.selectAllReportsColumn('export', cats, true)),
          _reportHeaderCell('SCHEDULE', () => notifier.selectAllReportsColumn('schedule', cats, true)),
          _reportHeaderCell('SHARE', () => notifier.selectAllReportsColumn('share', cats, true)),
        ],
      ),
    );
  }

  Widget _reportHeaderCell(String label, VoidCallback onSelect) {
    return Expanded(
      flex: 1,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: _headerStyle.copyWith(fontSize: 10)),
            InkWell(
              onTap: onSelect,
              child: const Text('Select All', style: TextStyle(fontSize: 9, color: Color(0xFF0088FF))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(RoleCreationState state, RoleCreationNotifier notifier, String cat) {
    final active = state.reportPermissions[cat] ?? {};
    return _HoverRow(
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(cat, style: AppTheme.bodyText.copyWith(fontSize: 13))),
          _checkCell(active.contains('full_access'), () => notifier.toggleReportPermission(cat, 'full_access')),
          _checkCell(active.contains('view'), () => notifier.toggleReportPermission(cat, 'view')),
          _checkCell(active.contains('export'), () => notifier.toggleReportPermission(cat, 'export')),
          _checkCell(active.contains('schedule'), () => notifier.toggleReportPermission(cat, 'schedule')),
          _checkCell(active.contains('share'), () => notifier.toggleReportPermission(cat, 'share')),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, RoleCreationState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ZButton.secondary(
            label: 'Cancel',
            onPressed: () => context.go(AppRoutes.settingsRoles),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: state.roleName.isEmpty ? null : () {
              ZerpaiToast.success(context, 'Role saved successfully.');
              context.go(AppRoutes.settingsRoles);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF28A745),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  List<PermissionSectionMeta> _getMetadata() {
    return [
      PermissionSectionMeta(title: 'CONTACTS', rows: [
        PermissionRowMeta(label: 'Customers', key: 'customers'),
        PermissionRowMeta(label: 'Vendors', key: 'vendors', overrides: [
          'Allow users to add, edit and delete vendor bank account details.'
        ]),
      ]),
      PermissionSectionMeta(title: 'ITEMS', rows: [
        PermissionRowMeta(label: 'Items', key: 'items', overrides: [
          'View cost price',
          'Manage item groups',
          'Assign Composite Items'
        ]),
        PermissionRowMeta(label: 'Composite Items', key: 'composite_items'),
        PermissionRowMeta(label: 'Price List', key: 'price_list', actions: ['view', 'create', 'edit', 'delete', 'approve']),
      ]),
      PermissionSectionMeta(title: 'SALES', rows: [
        PermissionRowMeta(label: 'Quotations', key: 'quotations'),
        PermissionRowMeta(label: 'Sales Orders', key: 'sales_orders', 
          actions: ['view', 'create', 'edit', 'delete', 'approve'],
          overrides: ['Edit and delete approved sales orders']
        ),
        PermissionRowMeta(label: 'Invoices', key: 'invoices', overrides: ['Write off invoices']),
        PermissionRowMeta(label: 'Payments Received', key: 'payments_received'),
      ]),
      PermissionSectionMeta(title: 'PURCHASES', rows: [
        PermissionRowMeta(label: 'Purchase Orders', key: 'purchase_orders', actions: ['view', 'create', 'edit', 'delete', 'approve']),
        PermissionRowMeta(label: 'Bills', key: 'bills', overrides: ['Edit and delete approved bills']),
        PermissionRowMeta(label: 'Payments Made', key: 'payments_made'),
      ]),
      PermissionSectionMeta(title: 'ACCOUNTANT', rows: [
        PermissionRowMeta(label: 'Chart of Accounts', key: 'chart_of_accounts'),
        PermissionRowMeta(label: 'Manual Journals', key: 'manual_journals', actions: ['view', 'create', 'edit', 'delete', 'approve']),
      ]),
      PermissionSectionMeta(title: 'SETTINGS', rows: [
        PermissionRowMeta(label: 'Organization Profile', key: 'org_profile', actions: ['view', 'edit']),
        PermissionRowMeta(label: 'Taxes', key: 'taxes'),
        PermissionRowMeta(label: 'Users & Roles', key: 'users_roles'),
      ]),
    ];
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Color(0xFF666666),
    letterSpacing: 0.5,
  );
}

/// ---------------------------------------------------------------------------
/// HELPER WIDGETS
/// ---------------------------------------------------------------------------

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF0088FF) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF0088FF) : AppTheme.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _GeneralFormRow extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const _GeneralFormRow({
    required this.label,
    this.required = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Text(label, style: AppTheme.bodyText.copyWith(fontSize: 13)),
                if (required)
                  const Text(' *', style: TextStyle(color: AppTheme.errorRed)),
              ],
            ),
          ),
        ),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _HoverRow extends StatefulWidget {
  final Widget child;
  const _HoverRow({required this.child});

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 32, // Exact 32px height for high density
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFF9F9F9) : Colors.white,
          border: const Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: widget.child,
      ),
    );
  }
}

class _ZohoCheckbox extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;

  const _ZohoCheckbox({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        width: 14, // Small 14px checkboxes
        height: 14,
        decoration: BoxDecoration(
          color: value ? const Color(0xFF0088FF) : Colors.white,
          border: Border.all(
            color: value ? const Color(0xFF0088FF) : const Color(0xFFCCCCCC),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: value
            ? const Icon(LucideIcons.check, size: 10, color: Colors.white)
            : null,
      ),
    );
  }
}
