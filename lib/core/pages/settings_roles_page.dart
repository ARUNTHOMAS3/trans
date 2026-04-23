import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/pages/settings_users_roles_support.dart';
import 'package:zerpai_erp/modules/auth/widgets/permission_wrapper.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

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
    context.goNamed(
      AppRoutes.settingsRoleCreate,
      pathParameters: {
        'orgSystemId':
            GoRouterState.of(context).pathParameters['orgSystemId'] ??
            '0000000000',
      },
    );
  }

  void _openRoleEdit(String id) {
    context.goNamed(
      AppRoutes.settingsRoleEdit,
      pathParameters: {
        'orgSystemId':
            GoRouterState.of(context).pathParameters['orgSystemId'] ??
            '0000000000',
        'id': id,
      },
    );
  }

  Future<void> _cloneRole(SettingsRoleRecord role) async {
    try {
      final detail = await _apiClient.get(
        'users/roles/${role.id}',
        queryParameters: {'org_id': _orgId},
      );
      final payload = Map<String, dynamic>.from(
        detail.data as Map<String, dynamic>? ?? const {},
      );
      final baseLabel = (payload['label'] ?? role.label).toString().trim();
      final cloneLabel = '$baseLabel Copy';
      await _apiClient.post(
        'users/roles',
        data: {
          'org_id': _orgId,
          'label': cloneLabel,
          'description': (payload['description'] ?? '').toString(),
          'permissions': payload['permissions'] is Map
              ? Map<String, dynamic>.from(payload['permissions'] as Map)
              : {},
        },
      );
      if (!mounted) return;
      ZerpaiToast.success(context, 'Role cloned successfully.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to clone role: $e');
    }
  }

  Future<void> _deleteRole(SettingsRoleRecord role) async {
    if (role.isDefault) {
      ZerpaiToast.error(
        context,
        'Default roles cannot be deleted.',
      );
      return;
    }
    try {
      await _apiClient.delete(
        'users/roles/${role.id}',
        queryParameters: {'org_id': _orgId},
      );
      if (!mounted) return;
      ZerpaiToast.success(context, 'Role deleted successfully.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to delete role: $e');
    }
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
              ? Skeletonizer(ignoreContainers: true, child: ZTableSkeleton(rows: 10, columns: 4))
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
                      padding: const EdgeInsets.fromLTRB(20, 14, 10, 10),
                      child: Row(
                        children: [
                          Text(
                            'Roles',
                            style: AppTheme.pageTitle.copyWith(fontSize: 18),
                          ),
                          const Spacer(),
                          ZButton.primary(
                            label: 'New Role',
                            onPressed: _showNewRoleInfo,
                          ).withModulePermission(
                            'users_roles',
                            action: 'view',
                            hideInsteadOfDisable: true,
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'ROLE NAME',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Expanded(
                flex: 9,
                child: Text(
                  'DESCRIPTION',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'USERS',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  'ACTIONS',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _roles.length,
            itemBuilder: (context, index) {
              final role = _roles[index];
              return Material(
                color: Colors.white,
                child: InkWell(
                  hoverColor: const Color(0xFFF7F9FC),
                  splashColor: const Color(0xFFF0F4FA),
                  highlightColor: const Color(0xFFF0F4FA),
                  onTap: () => _openRoleEdit(role.id),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Text(
                                role.label,
                                style: AppTheme.bodyText.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (role.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgLight,
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: AppTheme.borderLight),
                                  ),
                                  child: Text(
                                    'DEFAULT',
                                    style: AppTheme.captionText.copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 9,
                          child: Text(
                            role.description,
                            style: AppTheme.bodyText,
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            role.userCount.toString(),
                            style: AppTheme.bodyText.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.more_horiz,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            onSelected: (value) {
                              if (value == 'edit') _openRoleEdit(role.id);
                              if (value == 'clone') _cloneRole(role);
                              if (value == 'delete') _deleteRole(role);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'clone',
                                child: Text('Clone'),
                              ),
                              if (!role.isDefault)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).withModulePermission(
                  'users_roles',
                  action: 'view',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
