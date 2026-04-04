import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/pages/settings_users_roles_support.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/z_table_helpers.dart';

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
  SettingsUserRecord? _selectedUser;
  String _activeTab = 'details';

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
      final res = await _apiClient.get('users', queryParameters: {'org_id': currentSettingsOrgId(ref)});
      final users = (res.data as List).map((e) => SettingsUserRecord.fromJson(e)).toList();
      setState(() {
        _users = users;
        _loading = false;
      });
      _updateSelectedUser();
    } catch (e) {
      setState(() => _loading = false);
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
        ? const Center(child: CircularProgressIndicator())
        : widget.selectedUserId == null ? _buildListOnly() : _buildMasterDetail(),
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
              const Spacer(),
              ZButton.primary(
                label: 'Invite User',
                icon: LucideIcons.plus,
                onPressed: () => context.go(AppRoutes.settingsUserInvite),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: _buildUsersTable()),
        ],
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
                  onPressed: () => context.go(AppRoutes.settingsUserInvite),
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

  Widget _buildTableRow(SettingsUserRecord user, {bool isLast = false}) {
    return ZTableHelpers.buildDataRow(
      onTap: () => context.go(AppRoutes.settingsUserDetail.replaceFirst(':id', user.id)),
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
            child: ZTableHelpers.buildStatusBadge(user.isActive),
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
          onTap: () => context.go(AppRoutes.settingsUserDetail.replaceFirst(':id', user.id)),
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
                onPressed: () => context.go(AppRoutes.settingsUserEdit.replaceFirst(':id', user.id)),
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
              if (user.accessibleLocations.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('All Locations Access'))
              else
                for (final loc in user.accessibleLocations)
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
