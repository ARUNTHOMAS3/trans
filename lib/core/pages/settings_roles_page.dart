import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/pages/settings_users_roles_support.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class SettingsRolesPage extends ConsumerStatefulWidget {
  const SettingsRolesPage({super.key});

  @override
  ConsumerState<SettingsRolesPage> createState() => _SettingsRolesPageState();
}

class _SettingsRolesPageState extends ConsumerState<SettingsRolesPage> {
  final ApiClient _apiClient = ApiClient();
  bool _loading = true;
  String? _error;
  List<SettingsRoleRecord> _roles = const <SettingsRoleRecord>[];

  String get _orgId => currentSettingsOrgId(ref);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _apiClient.get(
        'users/roles/catalog',
        queryParameters: {'org_id': _orgId},
      );
      if (!mounted) return;
      setState(() {
        _roles =
            (res.data as List<dynamic>? ?? const [])
                .whereType<Map>()
                .map(
                  (item) => SettingsRoleRecord.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
              ..sort(
                (a, b) =>
                    a.label.toLowerCase().compareTo(b.label.toLowerCase()),
              );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showNewRoleInfo() {
    ZerpaiToast.info(context, 'Custom role creation will be added next.');
  }

  @override
  Widget build(BuildContext context) {
    return SettingsUsersRolesShell(
      activeRoute: AppRoutes.settingsRoles,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: AppTheme.bodyText.copyWith(color: AppTheme.errorRed),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 10, 10),
                      child: Row(
                        children: [
                          Text(
                            'Roles',
                            style: AppTheme.pageTitle.copyWith(fontSize: 18),
                          ),
                          const Spacer(),
                          ZButton.primary(
                            label: 'New Role',
                            icon: LucideIcons.plus,
                            onPressed: _showNewRoleInfo,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    Expanded(child: _buildRolesTable()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRolesTable() {
    if (_roles.isEmpty) {
      return Center(
        child: Text(
          'No roles available.',
          style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 40,
        headingRowHeight: 40,
        dataRowMinHeight: 42,
        dataRowMaxHeight: 50,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        dividerThickness: 0.6,
        columns: const [
          DataColumn(
            label: Text(
              'Role Name',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Description',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
        rows: _roles
            .map(
              (role) => DataRow(
                onSelectChanged: (_) => context.go(AppRoutes.settingsUsers),
                cells: [
                  DataCell(
                    Text(
                      role.label,
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      role.description,
                      style: AppTheme.bodyText.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
