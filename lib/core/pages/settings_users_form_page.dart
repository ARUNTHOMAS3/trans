import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/pages/settings_user_location_access_editor.dart';
import 'package:zerpai_erp/core/pages/settings_users_roles_support.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class SettingsUsersFormPage extends ConsumerStatefulWidget {
  const SettingsUsersFormPage({super.key, this.userId});

  final String? userId;

  bool get isEdit => userId != null && userId!.isNotEmpty;

  @override
  ConsumerState<SettingsUsersFormPage> createState() =>
      _SettingsUsersFormPageState();
}

class _SettingsUsersFormPageState extends ConsumerState<SettingsUsersFormPage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _submitted = false;
  String? _error;

  List<SettingsRoleRecord> _roles = const <SettingsRoleRecord>[];
  List<SettingsLocationRecord> _locations = const <SettingsLocationRecord>[];
  String? _selectedRole;
  Set<String> _selectedOutletIds = <String>{};
  String? _defaultBusinessOutletId;
  String? _defaultWarehouseOutletId;

  String get _orgId => currentSettingsOrgId(ref);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roleRes = await _apiClient.get(
        'users/roles/catalog',
        queryParameters: {'org_id': _orgId},
      );
      final outletRes = await _apiClient.get(
        'outlets',
        queryParameters: {'org_id': _orgId},
      );

      final roles = (roleRes.data as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                SettingsRoleRecord.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      final locations = (outletRes.data as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => SettingsLocationRecord.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.isActive)
          .toList();

      if (widget.isEdit) {
        final userRes = await _apiClient.get(
          'users/${widget.userId}',
          queryParameters: {'org_id': _orgId},
        );
        final user = SettingsUserRecord.fromJson(
          Map<String, dynamic>.from(userRes.data as Map),
        );
        _nameController.text = user.name;
        _emailController.text = user.email;
        _selectedRole = user.role;
        _selectedOutletIds = user.accessibleLocations.map((e) => e.id).toSet();
        _defaultBusinessOutletId = user.defaultBusinessOutletId;
        _defaultWarehouseOutletId = user.defaultWarehouseOutletId;
      } else {
        _selectedRole = roles.isEmpty ? null : roles.first.id;
      }

      if (!mounted) return;
      setState(() {
        _roles = roles;
        _locations = locations;
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

  bool get _nameInvalid => _submitted && _nameController.text.trim().isEmpty;
  bool get _emailInvalid =>
      _submitted &&
      !RegExp(
        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
      ).hasMatch(_emailController.text.trim());
  bool get _roleInvalid =>
      _submitted && (_selectedRole == null || _selectedRole!.isEmpty);
  bool get _locationsInvalid => _submitted && _selectedOutletIds.isEmpty;
  bool get _defaultBusinessInvalid =>
      _submitted &&
      _selectedOutletIds.isNotEmpty &&
      _defaultBusinessOutletId == null;

  void _handleCancel() {
    if (widget.isEdit) {
      context.go(
        AppRoutes.settingsUserDetail.replaceFirst(':id', widget.userId!),
      );
      return;
    }
    context.go(AppRoutes.settingsUsers);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (_nameInvalid ||
        _emailInvalid ||
        _roleInvalid ||
        _locationsInvalid ||
        _defaultBusinessInvalid) {
      ZerpaiToast.error(context, 'Please complete the required fields.');
      return;
    }

    final body = <String, dynamic>{
      'org_id': _orgId,
      'name': _nameController.text.trim(),
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _selectedRole,
      'location_access': <String, dynamic>{
        'accessible_outlet_ids': _selectedOutletIds.toList(),
        'default_business_outlet_id': _defaultBusinessOutletId,
        'default_warehouse_outlet_id': _defaultWarehouseOutletId,
      },
    };

    setState(() => _saving = true);
    try {
      final res = widget.isEdit
          ? await _apiClient.put('users/${widget.userId}', data: body)
          : await _apiClient.post('users', data: body);
      if (!mounted) return;
      final data = Map<String, dynamic>.from(res.data as Map);
      final userId = (data['id'] ?? widget.userId ?? '').toString();
      ZerpaiToast.success(
        context,
        widget.isEdit
            ? 'User updated successfully.'
            : 'User invited successfully.',
      );
      context.go(AppRoutes.settingsUserDetail.replaceFirst(':id', userId));
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  InputDecoration _inputDecoration({required String hint, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppTheme.primaryBlue),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppTheme.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppTheme.errorRed),
      ),
    );
  }

  Widget _buildRequiredLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: AppTheme.bodyText.copyWith(
          fontSize: 13,
          color: AppTheme.errorRed,
        ),
        children: const [
          TextSpan(
            text: '*',
            style: TextStyle(color: AppTheme.errorRed),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsUsersRolesShell(
      activeRoute: AppRoutes.settingsUsers,
      child: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: AppTheme.bodyText.copyWith(color: AppTheme.errorRed),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Container(
          margin: const EdgeInsets.only(top: AppTheme.space16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Text(
                  widget.isEdit ? 'Edit User' : 'Invite User',
                  style: AppTheme.pageTitle.copyWith(fontSize: 18),
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 510),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRequiredLabel('Name'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: _inputDecoration(
                              hint: 'Enter full name',
                              errorText: _nameInvalid
                                  ? 'Please enter the user name.'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildRequiredLabel('Email Address'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                              hint: 'Enter email address',
                              errorText: _emailInvalid
                                  ? 'Please enter a valid email address.'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildRequiredLabel('Role'),
                          const SizedBox(height: 8),
                          FormDropdown<String>(
                            value: _selectedRole,
                            items: _roles.map((role) => role.id).toList(),
                            hint: 'Select role',
                            errorText: _roleInvalid
                                ? 'Role is required.'
                                : null,
                            displayStringForValue: (id) {
                              final role = _roles
                                  .where((item) => item.id == id)
                                  .toList();
                              return role.isEmpty ? id : role.first.label;
                            },
                            onChanged: (value) =>
                                setState(() => _selectedRole = value),
                          ),
                          if (_selectedRole != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              () {
                                final matches = _roles
                                    .where((role) => role.id == _selectedRole)
                                    .map((role) => role.description)
                                    .toList();
                                return matches.isEmpty ? '' : matches.first;
                              }(),
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Restrict Access To',
                      style: AppTheme.pageTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Locations',
                          style: AppTheme.bodyText.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 2,
                      width: 80,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(height: 20),
                    SettingsLocationAccessEditor(
                      locations: _locations,
                      selectedOutletIds: _selectedOutletIds,
                      defaultBusinessOutletId: _defaultBusinessOutletId,
                      defaultWarehouseOutletId: _defaultWarehouseOutletId,
                      onChanged:
                          (
                            selectedOutletIds,
                            defaultBusiness,
                            defaultWarehouse,
                          ) {
                            setState(() {
                              _selectedOutletIds = selectedOutletIds;
                              _defaultBusinessOutletId = defaultBusiness;
                              _defaultWarehouseOutletId = defaultWarehouse;
                            });
                          },
                    ),
                    if (_locationsInvalid || _defaultBusinessInvalid) ...[
                      const SizedBox(height: 12),
                      Text(
                        _locationsInvalid
                            ? 'Select at least one accessible location.'
                            : 'Select a default business location.',
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.errorRed,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          ZButton.primary(label: 'Save', loading: _saving, onPressed: _save),
          const SizedBox(width: AppTheme.space10),
          ZButton.secondary(label: 'Cancel', onPressed: _handleCancel),
        ],
      ),
    );
  }
}
