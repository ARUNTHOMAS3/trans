import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/pages/settings_user_location_access_editor.dart';
import 'package:zerpai_erp/core/pages/settings_users_roles_support.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class SettingsUsersPage extends ConsumerStatefulWidget {
  const SettingsUsersPage({
    super.key,
    this.selectedUserId,
    this.initialTab = 'details',
  });

  final String? selectedUserId;
  final String initialTab;

  @override
  ConsumerState<SettingsUsersPage> createState() => _SettingsUsersPageState();
}

class _SettingsUsersPageState extends ConsumerState<SettingsUsersPage> {
  final ApiClient _apiClient = ApiClient();
  bool _loading = true;
  bool _detailLoading = false;
  String _statusFilter = 'all';
  String _activeTab = 'details';
  String? _error;
  List<SettingsUserRecord> _users = const <SettingsUserRecord>[];
  SettingsUserRecord? _selectedUser;
  List<dynamic> _activities = const <dynamic>[];

  String get _orgId => currentSettingsOrgId(ref);

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _apiClient.get(
        'users',
        queryParameters: {'org_id': _orgId, 'status': _statusFilter},
      );
      final users = (res.data as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                SettingsUserRecord.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
      if (widget.selectedUserId != null) {
        await _loadUserDetail(widget.selectedUserId!);
      } else {
        setState(() => _selectedUser = null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadUserDetail(String userId) async {
    setState(() => _detailLoading = true);
    try {
      final res = await _apiClient.get(
        'users/$userId',
        queryParameters: {'org_id': _orgId},
      );
      final user = SettingsUserRecord.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
      if (!mounted) return;
      setState(() {
        _selectedUser = user;
        _detailLoading = false;
      });
      if (_activeTab == 'activities') {
        await _loadActivities(userId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _detailLoading = false);
      ZerpaiToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _loadActivities(String userId) async {
    try {
      final res = await _apiClient.get(
        'users/$userId/activities',
        queryParameters: {'org_id': _orgId},
      );
      if (!mounted) return;
      setState(() => _activities = res.data as List<dynamic>? ?? const []);
    } catch (_) {
      if (!mounted) return;
      setState(() => _activities = const []);
    }
  }

  Future<void> _toggleStatus(SettingsUserRecord user) async {
    try {
      await _apiClient.patch(
        'users/${user.id}/status',
        data: {'org_id': _orgId, 'is_active': !user.isActive},
      );
      if (!mounted) return;
      ZerpaiToast.success(
        context,
        user.isActive ? 'User marked as inactive.' : 'User marked as active.',
      );
      await _load();
      if (widget.selectedUserId == user.id) {
        await _loadUserDetail(user.id);
      }
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteUser(SettingsUserRecord user) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: const Text('Delete User'),
            content: Text('Delete ${user.name}? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await _apiClient.delete('users/${user.id}?org_id=$_orgId');
      if (!mounted) return;
      ZerpaiToast.success(context, 'User deleted.');
      context.go(AppRoutes.settingsUsers);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _exportUsers() async {
    final csv = StringBuffer()..writeln('Name,Email,Role,Status');
    for (final user in _users) {
      csv.writeln(
        '"${user.name}","${user.email}","${user.roleLabel}","${user.statusLabel}"',
      );
    }
    await Clipboard.setData(ClipboardData(text: csv.toString()));
    if (!mounted) return;
    ZerpaiToast.success(context, 'User list copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    return SettingsUsersRolesShell(
      activeRoute: AppRoutes.settingsUsers,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Text(
                  _error!,
                  style: AppTheme.bodyText.copyWith(color: AppTheme.errorRed),
                ),
              )
            : widget.selectedUserId == null
            ? _buildListCard()
            : _buildDetailLayout(),
      ),
    );
  }

  Widget _buildListCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              children: [
                _buildStatusFilterMenu(),
                const Spacer(),
                ZButton.primary(
                  label: 'Invite User',
                  icon: LucideIcons.plus,
                  onPressed: () => context.go(AppRoutes.settingsUserInvite),
                ),
                const SizedBox(width: 10),
                _buildTopMenu(),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          _buildUsersTable(),
        ],
      ),
    );
  }

  Widget _buildDetailLayout() {
    return Row(
      children: [
        SizedBox(width: 360, child: _buildDetailListPane()),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.borderLight),
                right: BorderSide(color: AppTheme.borderLight),
                bottom: BorderSide(color: AppTheme.borderLight),
              ),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: _detailLoading || _selectedUser == null
                ? const Center(child: CircularProgressIndicator())
                : _buildDetailPane(_selectedUser!),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailListPane() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.fromBorderSide(BorderSide(color: AppTheme.borderLight)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          bottomLeft: Radius.circular(14),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Row(
              children: [
                _buildStatusFilterMenu(),
                const Spacer(),
                IconButton(
                  onPressed: () => context.go(AppRoutes.settingsUserInvite),
                  icon: const Icon(LucideIcons.plus, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildTopMenu(),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          Expanded(
            child: ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final selected = user.id == widget.selectedUserId;
                return InkWell(
                  onTap: () => context.go(
                    AppRoutes.settingsUserDetail.replaceFirst(':id', user.id),
                  ),
                  child: Container(
                    color: selected ? const Color(0xFFF5F7FF) : Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFF3E8FF),
                          child: Text(
                            user.name.isEmpty
                                ? 'U'
                                : user.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: AppTheme.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: AppTheme.bodyText),
                              const SizedBox(height: 6),
                              Text(
                                user.email,
                                style: AppTheme.bodyText.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPane(SettingsUserRecord user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 20, 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFF3E8FF),
                child: Text(
                  user.name.isEmpty
                      ? 'U'
                      : user.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.name,
                          style: AppTheme.pageTitle.copyWith(fontSize: 18),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F8EF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            user.statusLabel,
                            style: const TextStyle(
                              color: AppTheme.successGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email,
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Role: ${user.roleLabel}', style: AppTheme.bodyText),
                  ],
                ),
              ),
              ZButton.primary(
                label: 'Edit',
                icon: LucideIcons.pencil,
                onPressed: () => context.go(
                  AppRoutes.settingsUserEdit.replaceFirst(':id', user.id),
                ),
              ),
              const SizedBox(width: 10),
              _buildRowActionMenu(user),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () => context.go(AppRoutes.settingsUsers),
                icon: const Icon(LucideIcons.x, color: AppTheme.errorRed),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTabButton('details', 'More Details'),
              const SizedBox(width: 24),
              _buildTabButton('activities', 'Recent Activities'),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _activeTab == 'activities'
                ? _buildActivitiesPane()
                : _buildMoreDetailsPane(user),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreDetailsPane(SettingsUserRecord user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Text(
                  'Custom Fields',
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "You haven't added any custom field information.",
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Accessible Locations',
              style: AppTheme.pageTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => _openLocationAccessDialog(user),
              child: const Icon(
                LucideIcons.pencil,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(label: Text('Location')),
              DataColumn(label: Text('Type')),
            ],
            rows: user.accessibleLocations
                .map(
                  (location) => DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Text(location.name),
                            if (location.isDefaultBusiness ||
                                location.isDefaultWarehouse) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F8EF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  location.isWarehouse
                                      ? 'Warehouse Default'
                                      : 'Business Default',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.successGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      DataCell(Text(location.typeLabel)),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesPane() {
    if (_activities.isEmpty) {
      return Text(
        'No recent activities available for this user.',
        style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
      );
    }

    final formatter = DateFormat('dd-MM-yyyy\nhh:mm a');
    return Column(
      children: _activities.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final createdAt = DateTime.tryParse(
          (map['created_at'] ?? '').toString(),
        );
        final title = _activityTitle(map);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Text(
                createdAt == null ? '—' : formatter.format(createdAt),
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            Container(
              width: 2,
              height: 94,
              color: AppTheme.primaryBlue,
              margin: const EdgeInsets.symmetric(horizontal: 14),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Text(title, style: AppTheme.bodyText),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _activityTitle(Map<String, dynamic> activity) {
    final recordPk = (activity['record_pk'] ?? '').toString();
    final table = (activity['table_name'] ?? '').toString().replaceAll(
      '_',
      ' ',
    );
    final action = (activity['action'] ?? '').toString().toUpperCase();
    if (recordPk.isNotEmpty) {
      return '$table "$recordPk" $action';
    }
    return '$table $action';
  }

  Future<void> _openLocationAccessDialog(SettingsUserRecord user) async {
    final accessRes = await _apiClient.get(
      'users/${user.id}/location-access',
      queryParameters: {'org_id': _orgId},
    );
    if (!mounted) return;
    final data = Map<String, dynamic>.from(accessRes.data as Map);
    final locations =
        (data['available_locations'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) => SettingsLocationRecord.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
    Set<String> selected =
        ((data['accessible_outlet_ids'] as List<dynamic>? ?? const []).map(
          (item) => item.toString(),
        )).toSet();
    String? defaultBusiness = data['default_business_outlet_id']?.toString();
    String? defaultWarehouse = data['default_warehouse_outlet_id']?.toString();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => Dialog(
            alignment: Alignment.topCenter,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            insetPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Configure Location Access',
                            style: AppTheme.pageTitle.copyWith(fontSize: 18),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            LucideIcons.x,
                            size: 18,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Details',
                          style: AppTheme.pageTitle.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFFF3E8FF),
                              child: Text(
                                user.name.isEmpty
                                    ? 'U'
                                    : user.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: AppTheme.bodyText),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: AppTheme.bodyText.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Locations',
                          style: AppTheme.pageTitle.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select the locations for which this user can create and access transactions.',
                          style: AppTheme.bodyText.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SettingsLocationAccessEditor(
                          locations: locations,
                          selectedOutletIds: selected,
                          defaultBusinessOutletId: defaultBusiness,
                          defaultWarehouseOutletId: defaultWarehouse,
                          onChanged: (selectedOutletIds, business, warehouse) {
                            setDialogState(() {
                              selected = selectedOutletIds;
                              defaultBusiness = business;
                              defaultWarehouse = warehouse;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        ZButton.primary(
                          label: 'Save',
                          onPressed: () async {
                            await _apiClient.put(
                              'users/${user.id}/location-access',
                              data: {
                                'org_id': _orgId,
                                'accessible_outlet_ids': selected.toList(),
                                'default_business_outlet_id': defaultBusiness,
                                'default_warehouse_outlet_id': defaultWarehouse,
                              },
                            );
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ZerpaiToast.success(
                              context,
                              'Location access updated successfully.',
                            );
                            await _loadUserDetail(user.id);
                            await _load();
                          },
                        ),
                        const SizedBox(width: 10),
                        ZButton.secondary(
                          label: 'Cancel',
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String tab, String label) {
    final active = _activeTab == tab;
    return InkWell(
      onTap: () async {
        setState(() => _activeTab = tab);
        if (tab == 'activities' && _selectedUser != null) {
          await _loadActivities(_selectedUser!.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterMenu() {
    final MenuController controller = MenuController();
    final label = switch (_statusFilter) {
      'active' => 'Active',
      'inactive' => 'Inactive',
      _ => 'All Users',
    };
    return MenuAnchor(
      controller: controller,
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        surfaceTintColor: WidgetStateProperty.all(Colors.white),
        padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppTheme.borderLight),
        ),
      ),
      menuChildren: [
        for (final item in const <Map<String, String>>[
          {'label': 'All', 'value': 'all'},
          {'label': 'Inactive', 'value': 'inactive'},
          {'label': 'Active', 'value': 'active'},
        ])
          MenuItemButton(
            onPressed: () async {
              controller.close();
              setState(() => _statusFilter = item['value']!);
              await _load();
            },
            child: SizedBox(
              width: 220,
              child: Row(
                children: [
                  Expanded(child: Text(item['label']!)),
                  const Icon(
                    LucideIcons.star,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
      ],
      builder: (context, menuController, child) {
        return InkWell(
          onTap: () => menuController.isOpen
              ? menuController.close()
              : menuController.open(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTheme.pageTitle.copyWith(fontSize: 18)),
                const SizedBox(width: 6),
                const Icon(LucideIcons.chevronDown, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopMenu() {
    final MenuController controller = MenuController();
    return MenuAnchor(
      controller: controller,
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        surfaceTintColor: WidgetStateProperty.all(Colors.white),
        padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppTheme.borderLight),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            controller.close();
            _exportUsers();
          },
          child: const SizedBox(
            width: 140,
            child: Row(
              children: [
                Icon(LucideIcons.download, size: 16),
                SizedBox(width: 8),
                Text('Export'),
              ],
            ),
          ),
        ),
      ],
      builder: (context, menuController, child) {
        return IconButton(
          onPressed: () => menuController.isOpen
              ? menuController.close()
              : menuController.open(),
          icon: const Icon(LucideIcons.moreHorizontal),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppTheme.borderLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsersTable() {
    return Expanded(
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('User Details')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Status')),
          ],
          rows: _users
              .map(
                (user) => DataRow(
                  onSelectChanged: (_) => context.go(
                    AppRoutes.settingsUserDetail.replaceFirst(':id', user.id),
                  ),
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFF3E8FF),
                            child: Text(
                              user.name.isEmpty
                                  ? 'U'
                                  : user.name.substring(0, 1).toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: AppTheme.bodyText.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(user.roleLabel)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8EF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          user.statusLabel,
                          style: const TextStyle(
                            color: AppTheme.successGreen,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildRowActionMenu(SettingsUserRecord user) {
    final MenuController controller = MenuController();
    return MenuAnchor(
      controller: controller,
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        surfaceTintColor: WidgetStateProperty.all(Colors.white),
        padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppTheme.borderLight),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            controller.close();
            _toggleStatus(user);
          },
          child: Text(user.isActive ? 'Mark as Inactive' : 'Mark as Active'),
        ),
        MenuItemButton(
          onPressed: () {
            controller.close();
            _deleteUser(user);
          },
          child: const Text('Delete'),
        ),
      ],
      builder: (context, menuController, child) {
        return IconButton(
          onPressed: () => menuController.isOpen
              ? menuController.close()
              : menuController.open(),
          icon: const Icon(LucideIcons.moreHorizontal),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppTheme.borderLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}
