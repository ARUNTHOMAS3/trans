import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/modules/auth/widgets/permission_wrapper.dart';
import 'package:zerpai_erp/modules/settings/shared/settings_users_roles_support.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/auth/permission_resolver.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/shared/widgets/z_table_helpers.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

class SettingsUsersUserOverview extends ConsumerStatefulWidget {
  const SettingsUsersUserOverview({super.key, this.selectedUserId});

  final String? selectedUserId;

  @override
  ConsumerState<SettingsUsersUserOverview> createState() => _SettingsUsersUserOverviewState();
}

class _SettingsUsersUserOverviewState extends ConsumerState<SettingsUsersUserOverview> {
  final ApiClient _apiClient = ApiClient();
  bool _loading = true;
  List<SettingsUserRecord> _users = [];
  List<SettingsRoleRecord> _roles = [];
  SettingsUserRecord? _selectedUser;
  String _activeTab = 'details';
  String _activeUserView = 'users';
  final Map<String, String?> _pendingRoleByUserId = <String, String?>{};
  final Set<String> _savingUserIds = <String>{};

  String get _orgSystemId =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(SettingsUsersUserOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedUserId != oldWidget.selectedUserId) {
      _updateSelectedUser();
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        _apiClient.get('users', queryParameters: {'org_id': currentSettingsOrgId(ref)}),
        _apiClient.get(
          'users/roles/catalog',
          queryParameters: {'org_id': currentSettingsOrgId(ref)},
        ),
      ]);
      final users =
          (responses[0].data as List)
              .map((e) => SettingsUserRecord.fromJson(e))
              .toList();
      final roles =
          (responses[1].data as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((e) => SettingsRoleRecord.fromJson(Map<String, dynamic>.from(e)))
              .toList();
      final pending = <String, String?>{
        for (final user in users) user.id: user.role,
      };
      setState(() {
        _users = users;
        _roles = roles;
        _pendingRoleByUserId
          ..clear()
          ..addAll(pending);
        _loading = false;
      });
      _updateSelectedUser();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _resolveRoleLabel(String? roleId) {
    final normalized = (roleId ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return 'Unassigned';
    for (final role in _roles) {
      if (role.id.trim().toLowerCase() == normalized) {
        return role.label;
      }
    }
    return roleId ?? 'Unassigned';
  }

  Future<void> _saveUserRole(SettingsUserRecord user) async {
    final selectedRole = (_pendingRoleByUserId[user.id] ?? '').trim();
    if (selectedRole.isEmpty) {
      ZerpaiToast.error(context, 'Please select a role.');
      return;
    }
    setState(() => _savingUserIds.add(user.id));
    try {
      await _apiClient.put(
        '/users/${user.id}',
        data: {'org_id': currentSettingsOrgId(ref), 'role': selectedRole},
      );
      PermissionResolver.invalidateCache();
      if (!mounted) return;
      ZerpaiToast.success(context, 'Role updated for ${user.name}.');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to update role: $e');
    } finally {
      if (mounted) {
        setState(() => _savingUserIds.remove(user.id));
      }
    }
  }

  void _updateSelectedUser() {
    if (widget.selectedUserId != null) {
      setState(() {
        _selectedUser = _users.firstWhere((u) => u.id == widget.selectedUserId, orElse: () => _users.first);
      });
    } else {
      setState(() => _selectedUser = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsUsersRolesShell(
      activeRoute: AppRoutes.settingsUsers,
      child: _loading
          ? _buildLoadingState()
          : widget.selectedUserId == null
          ? _buildListOnly()
          : _buildMasterDetail(),
    );
  }

  Widget _buildLoadingState() {
    return widget.selectedUserId == null
        ? Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Row(
                  children: [
                    ZBone(width: 100, height: 28),
                    Spacer(),
                    ZBone(width: 120, height: 36),
                  ],
                ),
                const SizedBox(height: 24),
                const Expanded(child: ZTableSkeleton(rows: 8, columns: 3)),
              ],
            ),
          )
        : Row(
            children: [
              Container(
                width: 350,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: const Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ZBone(width: 120, height: 36),
                      ),
                    ),
                    Expanded(child: ZListSkeleton(itemCount: 8)),
                  ],
                ),
              ),
              const Expanded(child: ZDetailContentSkeleton()),
            ],
          );
  }

  Widget _buildListOnly() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Text('Users', style: AppTheme.pageTitle),
              const SizedBox(width: 16),
              _buildViewToggle(),
              const Spacer(),
              ZButton.primary(
                label: 'Invite User',
                icon: LucideIcons.plus,
                onPressed: () => context.goNamed(
                  AppRoutes.settingsUserInvite,
                  pathParameters: {'orgSystemId': _orgSystemId},
                ),
              ).withModulePermission(
                'settings.users.view',
                action: 'view',
                hideInsteadOfDisable: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _activeUserView == 'users'
                ? _buildUsersTable()
                : _buildRbacTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewToggleButton('users', 'Users View'),
          _buildViewToggleButton('rbac', 'RBAC View'),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(String key, String label) {
    final active = _activeUserView == key;
    return InkWell(
      onTap: () => setState(() => _activeUserView = key),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: active
              ? Border.all(color: AppTheme.borderLight)
              : Border.all(color: Colors.transparent),
        ),
        child: Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMasterDetail() {
    return Row(
      children: [
        Container(
          width: 350,
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ZButton.primary(
                  label: 'Invite User',
                  icon: LucideIcons.plus,
                  onPressed: () => context.goNamed(
                    AppRoutes.settingsUserInvite,
                    pathParameters: {'orgSystemId': _orgSystemId},
                  ),
                ).withModulePermission(
                  'settings.users.view',
                  action: 'view',
                  hideInsteadOfDisable: true,
                ),
              ),
              Expanded(child: _buildDenseUserList()),
            ],
          ),
        ),
        Expanded(
          child: _selectedUser == null
            ? const Center(child: Text('Select a user to view details'))
            : _buildDetailView(),
        ),
      ],
    );
  }

  Widget _buildUsersTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          ZTableHelpers.buildHeaderRow(
            children: const [
              Expanded(flex: 4, child: Text('NAME', style: ZTableHelpers.headerTextStyle)),
              Expanded(flex: 3, child: Text('ROLE', style: ZTableHelpers.headerTextStyle)),
              Expanded(flex: 2, child: Text('STATUS', style: ZTableHelpers.headerTextStyle)),
            ],
          ),
          for (int i = 0; i < _users.length; i++)
            _buildTableRow(_users[i], isLast: i == _users.length - 1),
        ],
      ),
    );
  }

  Widget _buildRbacTable() {
    if (_roles.isEmpty) {
      return const Center(child: Text('No roles available. Create roles first.'));
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          ZTableHelpers.buildHeaderRow(
            children: const [
              Expanded(flex: 3, child: Text('USER', style: ZTableHelpers.headerTextStyle)),
              Expanded(flex: 3, child: Text('EMAIL', style: ZTableHelpers.headerTextStyle)),
              Expanded(flex: 3, child: Text('ROLE', style: ZTableHelpers.headerTextStyle)),
              Expanded(flex: 1, child: Text('STATUS', style: ZTableHelpers.headerTextStyle)),
              Expanded(flex: 2, child: Text('ACTION', style: ZTableHelpers.headerTextStyle)),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final selectedRole = _pendingRoleByUserId[user.id] ?? user.role;
                final saving = _savingUserIds.contains(user.id);
                final changed =
                    selectedRole.trim().toLowerCase() !=
                    user.role.trim().toLowerCase();
                return ZTableHelpers.buildDataRow(
                  onTap: () {},
                  isLast: index == _users.length - 1,
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(flex: 3, child: Text(user.email)),
                      Expanded(
                        flex: 3,
                        child: FormDropdown<String>(
                          value: selectedRole,
                          items: _roles.map((role) => role.id).toList(),
                          hint: 'Select Role',
                          showSearch: true,
                          displayStringForValue: _resolveRoleLabel,
                          onChanged: saving
                              ? (_) {}
                              : (value) {
                                  setState(() => _pendingRoleByUserId[user.id] = value);
                                },
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ZTableHelpers.buildStatusBadge(user.isActive),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ZButton.primary(
                            label: saving ? 'Saving...' : 'Save',
                            onPressed: (!changed || saving)
                                ? null
                                : () => _saveUserRole(user),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(SettingsUserRecord user, {bool isLast = false}) {
    return ZTableHelpers.buildDataRow(
      onTap: () => context.goNamed(
        AppRoutes.settingsUserDetail,
        pathParameters: {'orgSystemId': _orgSystemId, 'id': user.id},
      ),
      isLast: isLast,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                ZTableHelpers.buildAvatar(user.name),
                const SizedBox(width: 12),
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(user.roleLabel, style: const TextStyle(color: AppTheme.primaryBlue)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ZTableHelpers.buildStatusBadge(user.isActive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDenseUserList() {
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final isSelected = user.id == widget.selectedUserId;
        return InkWell(
          onTap: () => context.goNamed(
            AppRoutes.settingsUserDetail,
            pathParameters: {'orgSystemId': _orgSystemId, 'id': user.id},
          ),
          child: Container(
            color: isSelected ? const Color(0xFFF0F4FF) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE9ECEF),
                  child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(user.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailView() {
    final user = _selectedUser!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFF0F4FF),
                child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: Color(0xFF0088FF))),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: AppTheme.pageTitle),
                    Text(user.email, style: const TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Role: ${user.roleLabel}', style: const TextStyle(color: Color(0xFF0088FF), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              ZButton.secondary(
                label: 'Edit',
                icon: LucideIcons.pencil,
                onPressed: () => context.goNamed(
                  AppRoutes.settingsUserEdit,
                  pathParameters: {'orgSystemId': _orgSystemId, 'id': user.id},
                ),
              ).withModulePermission(
                'settings.users.view',
                action: 'view',
                hideInsteadOfDisable: true,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        _buildTabs(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _activeTab == 'details' ? _buildMoreDetails(user) : _buildActivities(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderLight))),
      child: Row(
        children: [
          _buildTabItem('details', 'More Details'),
          const SizedBox(width: 32),
          _buildTabItem('activities', 'Recent Activities'),
        ],
      ),
    );
  }

  Widget _buildTabItem(String key, String label) {
    final isActive = _activeTab == key;
    return InkWell(
      onTap: () => setState(() => _activeTab = key),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isActive ? const Color(0xFF0088FF) : Colors.transparent, width: 2)),
        ),
        child: Text(label, style: TextStyle(color: isActive ? const Color(0xFF0088FF) : AppTheme.textSecondary, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildMoreDetails(SettingsUserRecord user) {
    final bool hasAssignedLocations = user.accessibleLocations.isNotEmpty;
    final List<SettingsLocationRecord> locationsToDisplay = hasAssignedLocations
        ? user.accessibleLocations
        : user.availableLocations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACCESSIBLE LOCATIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(border: Border.all(color: AppTheme.borderLight), borderRadius: BorderRadius.circular(4)),
          child: Column(
            children: [
              ZTableHelpers.buildHeaderRow(
                height: 36,
                children: const [
                  Expanded(child: Text('LOCATION NAME', style: ZTableHelpers.headerTextStyle)),
                  Text('TYPE', style: ZTableHelpers.headerTextStyle),
                ],
              ),
              if (locationsToDisplay.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No locations available for this user'),
                )
              else if (!hasAssignedLocations)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No explicit location access saved yet. Showing available locations.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              for (final loc in locationsToDisplay)
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
                    child: Row(
                      children: [
                        Expanded(child: Text(loc.name)),
                        Text(loc.typeLabel, style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivities() {
    return const Center(child: Text('Recent user activities will appear here.'));
  }
}
