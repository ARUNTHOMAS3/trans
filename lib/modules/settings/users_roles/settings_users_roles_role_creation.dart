import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/pages/settings_users_roles_support.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/modules/settings/users_roles/providers/role_creation_provider.dart';

import 'models/role_permission_models.dart';
import 'providers/role_permission_scheme.dart';

// for kIsWeb
// for LogicalKeyboardKey

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

    return SettingsUsersRolesShell(
      activeRoute: AppRoutes.settingsRoles,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStickyHeader(context, state, notifier),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    bottom: 60,
                  ), // Space for sticky footer
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGeneralHeader(),
                      _buildGeneralView(state, notifier),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Divider(height: 1, color: AppTheme.borderLight),
                      ),
                      _buildSegmentedAccessHeader(),
                      _buildPermissionsView(state, notifier),
                    ],
                  ),
                ),
              ),
              _buildFooter(context, state),
            ],
          ),
          _buildChatWidget(),
        ],
      ),
    );
  }

  Widget _buildChatWidget() {
    return Positioned(
      bottom: 80,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFF0088FF),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          LucideIcons.messageCircle,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildStickyHeader(
    BuildContext context,
    RoleCreationState state,
    RoleCreationNotifier notifier,
  ) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Text(
            roleId == null ? 'New Role' : 'Edit Role',
            style: AppTheme.pageTitle.copyWith(
              fontSize: 18,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 32),
          // Centered Search Bar
          SizedBox(
            width: 380,
            height: 34,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search settings ( / )',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF999999),
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 14,
                  color: Color(0xFF999999),
                ),
                fillColor: const Color(0xFFF7F7F7),
                filled: true,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => context.go(AppRoutes.settingsRoles),
            icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF666666)),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF3F3F3),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Text(
        'GENERAL INFORMATION',
        style: AppTheme.bodyText.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.5,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildSegmentedAccessHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF3F3F3),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Text(
        'SEGMENTED ACCESS CONTROL',
        style: AppTheme.bodyText.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.5,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildGeneralView(
    RoleCreationState state,
    RoleCreationNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GeneralFormRow(
            label: 'Role Name',
            required: true,
            child: CustomTextField(
              controller: TextEditingController(text: state.roleName)
                ..selection = TextSelection.collapsed(
                  offset: state.roleName.length,
                ),
              onChanged: notifier.setRoleName,
              hintText: 'Enter role name',
            ),
          ),
          _GeneralFormRow(
            label: 'Description',
            child: CustomTextField(
              controller: TextEditingController(text: state.description)
                ..selection = TextSelection.collapsed(
                  offset: state.description.length,
                ),
              onChanged: notifier.setDescription,
              maxLines: 4,
              hintText: 'Max. 500 characters',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsView(
    RoleCreationState state,
    RoleCreationNotifier notifier,
  ) {
    final sections = RolePermissionScheme.getMetadata();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final section in sections)
                _PermissionSection(
                  section: section,
                  isExpanded: state.expandedSections.contains(section.title),
                  onToggle: () => notifier.toggleSection(section.title),
                  state: state,
                  notifier: notifier,
                ),
              _buildReportsSection(state, notifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsSection(
    RoleCreationState state,
    RoleCreationNotifier notifier,
  ) {
    final categories = RolePermissionScheme.getReportCategories();
    final isExpanded = state.expandedSections.contains('REPORTS');

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F7F7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              border: Border(bottom: BorderSide(color: Color(0xFFDDDDDD))),
            ),
            child: InkWell(
              onTap: () => notifier.toggleSection('REPORTS'),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 14,
                    color: const Color(0xFF999999),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'REPORTS',
                    style: AppTheme.bodyText.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: state.fullAccessReports,
                    onChanged: notifier.toggleFullAccessReports,
                    activeTrackColor: const Color(
                      0xFF0088FF,
                    ).withValues(alpha: 0.5),
                    activeThumbColor: const Color(0xFF0088FF),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Enable full access for all reports',
                    style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && !state.fullAccessReports) ...[
            _buildReportsHeader(notifier, categories),
            for (final cat in categories)
              _ReportRow(category: cat, state: state, notifier: notifier),
          ],
        ],
      ),
    );
  }

  Widget _buildReportsHeader(RoleCreationNotifier notifier, List<String> cats) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Particulars', style: _headerStyle)),
          _reportHeaderCell(
            'Full',
            () => notifier.selectAllReportsColumn('full_access', cats, true),
          ),
          _reportHeaderCell(
            'View',
            () => notifier.selectAllReportsColumn('view', cats, true),
          ),
          _reportHeaderCell(
            'Export',
            () => notifier.selectAllReportsColumn('export', cats, true),
          ),
          _reportHeaderCell(
            'Schedule',
            () => notifier.selectAllReportsColumn('schedule', cats, true),
          ),
          _reportHeaderCell(
            'Share',
            () => notifier.selectAllReportsColumn('share', cats, true),
          ),
        ],
      ),
    );
  }

  Widget _reportHeaderCell(String label, VoidCallback onSelect) {
    return SizedBox(
      width: 60,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: _headerStyle),
            InkWell(
              onTap: onSelect,
              child: const Text(
                'Select All',
                style: TextStyle(fontSize: 8, color: Color(0xFF0088FF)),
              ),
            ),
          ],
        ),
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ZButton.primary(
            label: 'Proceed',
            onPressed: state.roleName.isEmpty
                ? null
                : () {
                    ZerpaiToast.success(context, 'Role saved successfully.');
                    context.go(AppRoutes.settingsRoles);
                  },
          ),
          const SizedBox(width: 12),
          ZButton.secondary(
            label: 'Cancel',
            onPressed: () => context.go(AppRoutes.settingsRoles),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF333333),
    letterSpacing: 0,
  );
}

class _PermissionSection extends StatelessWidget {
  final PermissionSectionMeta section;
  final bool isExpanded;
  final VoidCallback onToggle;
  final RoleCreationState state;
  final RoleCreationNotifier notifier;

  const _PermissionSection({
    required this.section,
    required this.isExpanded,
    required this.onToggle,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMatrix = !section.rows.any((r) => r.isSettingsList);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F7F7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              border: Border(bottom: BorderSide(color: Color(0xFFDDDDDD))),
            ),
            child: InkWell(
              onTap: onToggle,
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 14,
                    color: const Color(0xFF999999),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    section.title,
                    style: AppTheme.bodyText.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            if (isMatrix) _buildTableHeader(),
            for (final row in section.rows)
              if (isMatrix)
                _PermissionRow(row: row, state: state, notifier: notifier)
              else
                _SettingsCheckboxRow(
                  row: row,
                  state: state,
                  notifier: notifier,
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'Particulars',
              style: SettingsUsersRolesRoleCreation._headerStyle,
            ),
          ),
          _headerCell('Full'),
          _headerCell('View'),
          _headerCell('Create'),
          _headerCell('Edit'),
          _headerCell('Delete'),
          _headerCell('Approve'),
          const SizedBox(
            width: 140,
            child: Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'Others',
                style: SettingsUsersRolesRoleCreation._headerStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String label) {
    return SizedBox(
      width: 60,
      child: Center(
        child: Text(label, style: SettingsUsersRolesRoleCreation._headerStyle),
      ),
    );
  }
}

class _PermissionRow extends StatefulWidget {
  final PermissionRowMeta row;
  final RoleCreationState state;
  final RoleCreationNotifier notifier;

  const _PermissionRow({
    required this.row,
    required this.state,
    required this.notifier,
  });

  @override
  State<_PermissionRow> createState() => _PermissionRowState();
}

class _PermissionRowState extends State<_PermissionRow> {
  final LayerLink _layerLink = LayerLink();
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeActions = widget.state.permissions[widget.row.key] ?? {};

    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Container(
            height: 32, // More compact
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0xFFF9F9F9) : Colors.white,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFEEEEEE)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      Text(
                        widget.row.label,
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      if (widget.row.infoTooltip != null) ...[
                        const SizedBox(width: 6),
                        ZTooltip(
                          message: widget.row.infoTooltip!,
                          child: const Icon(
                            LucideIcons.info,
                            size: 14,
                            color: Color(0xFFEBB111),
                          ), // Zoho yellow "i"
                        ),
                      ],
                      if (widget.row.tooltip != null) ...[
                        const SizedBox(width: 6),
                        ZTooltip(
                          message: widget.row.tooltip!,
                          child: const Icon(
                            LucideIcons.helpCircle,
                            size: 14,
                            color: Color(0xFFBBBBBB),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _checkCell(
                  activeActions.contains('full'),
                  () => widget.notifier.togglePermission(
                    widget.row.key,
                    'full',
                    widget.row.actions,
                    subRows: widget.row.subRows,
                  ),
                ),
                _checkCell(
                  activeActions.contains('view'),
                  () => widget.notifier.togglePermission(
                    widget.row.key,
                    'view',
                    widget.row.actions,
                  ),
                ),
                widget.row.actions.contains('create')
                    ? _checkCell(
                        activeActions.contains('create'),
                        () => widget.notifier.togglePermission(
                          widget.row.key,
                          'create',
                          widget.row.actions,
                        ),
                      )
                    : const SizedBox(width: 60),
                widget.row.actions.contains('edit')
                    ? _checkCell(
                        activeActions.contains('edit'),
                        () => widget.notifier.togglePermission(
                          widget.row.key,
                          'edit',
                          widget.row.actions,
                        ),
                      )
                    : const SizedBox(width: 60),
                widget.row.actions.contains('delete')
                    ? _checkCell(
                        activeActions.contains('delete'),
                        () => widget.notifier.togglePermission(
                          widget.row.key,
                          'delete',
                          widget.row.actions,
                        ),
                      )
                    : const SizedBox(width: 60),
                widget.row.actions.contains('approve')
                    ? _checkCell(
                        activeActions.contains('approve'),
                        () => widget.notifier.togglePermission(
                          widget.row.key,
                          'approve',
                          widget.row.actions,
                        ),
                      )
                    : const SizedBox(width: 60),
                SizedBox(
                  width: 140,
                  child: widget.row.overrides.isNotEmpty
                      ? CompositedTransformTarget(
                          link: _layerLink,
                          child: InkWell(
                            onTap: () => _showFlyout(context),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                'More Permissions',
                                style: AppTheme.bodyText.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
        // Render sub-rows (nested permissions)
        if (widget.row.subRows != null)
          ...widget.row.subRows!.map(
            (sub) => Padding(
              padding: const EdgeInsets.only(left: 20),
              child: _SettingsCheckboxRow(
                row: sub,
                state: widget.state,
                notifier: widget.notifier,
              ),
            ),
          ),
      ],
    );
  }

  Widget _checkCell(bool value, VoidCallback onTap) {
    return SizedBox(
      width: 60, // Fixed width for alignment
      child: Center(
        child: _ZohoCheckbox(value: value, onTap: onTap),
      ),
    );
  }

  void _showFlyout(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _MorePermissionsFlyout(
        layerLink: _layerLink,
        row: widget.row,
        state: widget.state,
        notifier: widget.notifier,
        onClose: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _SettingsCheckboxRow extends StatelessWidget {
  final PermissionRowMeta row;
  final RoleCreationState state;
  final RoleCreationNotifier notifier;

  const _SettingsCheckboxRow({
    required this.row,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final isChecked = state.permissions[row.key]?.contains('view') ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _ZohoCheckbox(
              value: isChecked,
              onTap: () => notifier.togglePermission(row.key, 'view', ['view']),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      row.label,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    if (row.tooltip != null) ...[
                      const SizedBox(width: 6),
                      ZTooltip(
                        message: row.tooltip!,
                        child: const Icon(
                          LucideIcons.helpCircle,
                          size: 14,
                          color: Color(0xFFBBBBBB),
                        ),
                      ),
                    ],
                  ],
                ),
                if (row.overrides.isNotEmpty && isChecked)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      children: [
                        for (final override in row.overrides)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ZohoCheckbox(
                                value:
                                    state.advancedOverrides[row
                                        .key]?[override] ??
                                    false,
                                onTap: () => notifier.toggleAdvancedOverride(
                                  row.key,
                                  override,
                                  !(state.advancedOverrides[row
                                          .key]?[override] ??
                                      false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                override,
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 12,
                                  color: const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String category;
  final RoleCreationState state;
  final RoleCreationNotifier notifier;

  const _ReportRow({
    required this.category,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final active = state.reportPermissions[category] ?? {};

    return Container(
      height: 32, // Density polish
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              category,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: const Color(0xFF111111),
              ),
            ),
          ),
          _checkCell(
            active.contains('full_access'),
            () => notifier.toggleReportPermission(category, 'full_access'),
          ),
          _checkCell(
            active.contains('view'),
            () => notifier.toggleReportPermission(category, 'view'),
          ),
          _checkCell(
            active.contains('export'),
            () => notifier.toggleReportPermission(category, 'export'),
          ),
          _checkCell(
            active.contains('schedule'),
            () => notifier.toggleReportPermission(category, 'schedule'),
          ),
          _checkCell(
            active.contains('share'),
            () => notifier.toggleReportPermission(category, 'share'),
          ),
        ],
      ),
    );
  }

  Widget _checkCell(bool value, VoidCallback onTap) {
    return SizedBox(
      width: 60, // Alignment polish
      child: Center(
        child: _ZohoCheckbox(value: value, onTap: onTap),
      ),
    );
  }
}

class _MorePermissionsFlyout extends StatelessWidget {
  final LayerLink layerLink;
  final PermissionRowMeta row;
  final RoleCreationState state;
  final RoleCreationNotifier notifier;
  final VoidCallback onClose;

  const _MorePermissionsFlyout({
    required this.layerLink,
    required this.row,
    required this.state,
    required this.notifier,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.transparent),
        ),
        CompositedTransformFollower(
          link: layerLink,
          offset: const Offset(-200, 24), // Offset to the left to avoid edge
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
            child: Container(
              width: 360, // Slightly wider for better text flow
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDDDDD)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'More Permissions',
                        style: AppTheme.bodyText.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Color(0xFF999999),
                        ),
                        splashRadius: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFEEEEEE)),
                  for (final override in row.overrides)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: _ZohoCheckbox(
                              value:
                                  state.advancedOverrides[row.key]?[override] ??
                                  false,
                              onTap: () => notifier.toggleAdvancedOverride(
                                row.key,
                                override,
                                !(state.advancedOverrides[row.key]?[override] ??
                                    false),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      override,
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 13,
                                        color: const Color(0xFF333333),
                                      ),
                                    ),
                                    if (row.overrideTooltips?[override] !=
                                        null) ...[
                                      const SizedBox(width: 4),
                                      ZTooltip(
                                        message:
                                            row.overrideTooltips![override]!,
                                        child: const Icon(
                                          LucideIcons.helpCircle,
                                          size: 12,
                                          color: Color(0xFFBBBBBB),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (row.overrideTooltips?[override] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      row.overrideTooltips![override]!,
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 11,
                                        color: const Color(0xFF888888),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF666666),
                    ),
                  ),
                  if (required)
                    const Text(
                      ' *',
                      style: TextStyle(color: AppTheme.errorRed, fontSize: 13),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 480, child: child),
        ],
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
        width: 14,
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
