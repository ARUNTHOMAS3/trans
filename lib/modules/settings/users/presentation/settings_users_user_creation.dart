import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/utils/console_error_reporter.dart';
import 'package:zerpai_erp/core/pages/settings_users_roles_support.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:collection/collection.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import '../providers/user_access_provider.dart';

// ─── Design tokens (local, matching HTML reference) ──────────────────────────

const _kRadiusSm = Radius.circular(6);
const _kRadiusXl = Radius.circular(24);

const _kSurfaceContainerLow = Color(0xFFF6F3F4);
const _kSurfaceContainerHigh = Color(0xFFEAE7EA);
const _kSurfaceContainerLowest = Color(0xFFFFFFFF);
const _kOutlineVariant = Color(0xFFB3B1B4);
const _kOnSurfaceVariant = Color(0xFF5F5F61);

// ─────────────────────────────────────────────────────────────────────────────

class SettingsUsersUserCreation extends ConsumerStatefulWidget {
  const SettingsUsersUserCreation({super.key, this.userId});

  final String? userId;

  @override
  ConsumerState<SettingsUsersUserCreation> createState() =>
      _SettingsUsersUserCreationState();
}

class _SettingsUsersUserCreationState
    extends ConsumerState<SettingsUsersUserCreation> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _locationSearchController =
      TextEditingController();
  String? _selectedRoleId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final userData = await ref.read(userAccessProvider.notifier).init(
            currentSettingsOrgId(ref),
            userId: widget.userId,
          );

      if (!mounted || userData == null) return;

      _nameController.text =
          (userData['name'] ?? userData['full_name'] ?? '').toString();
      _emailController.text = (userData['email'] ?? '').toString();
      _selectedRoleId = (userData['role'] ?? '').toString();
      if (mounted) setState(() {});
    });
    _locationSearchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationSearchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoleId == null || _selectedRoleId!.trim().isEmpty) {
      ZerpaiToast.error(context, 'Please select a role.');
      return;
    }

    final state = ref.read(userAccessProvider);
    if (!ref.read(userAccessProvider.notifier).isValid) {
      ZerpaiToast.error(context, 'Please select default Branch and Warehouse.');
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = {
        'org_id': currentSettingsOrgId(ref),
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRoleId,
        'location_access': {
          'branch_ids': state.selectedBranchIds.toList(),
          'default_business_branch_id': state.defaultBranchId,
          'default_warehouse_branch_id': state.defaultWarehouseId,
        },
      };

      debugPrint('Saving user access: $payload');

      if (widget.userId == null) {
        await ref.read(apiClientProvider).post('/users', data: payload);
      } else {
        await ref
            .read(apiClientProvider)
            .put('/users/${widget.userId}', data: payload);
      }

      if (mounted) {
        ZerpaiToast.success(
          context,
          widget.userId == null
              ? 'User invited successfully.'
              : 'User updated successfully.',
        );
        context.go(AppRoutes.settingsUsers);
      }
    } catch (e, st) {
      ConsoleErrorReporter.log(
        'SettingsUsersUserCreation._save',
        error: e,
        stackTrace: st,
      );
      if (mounted) ZerpaiToast.error(context, 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userAccessProvider);
    final notifier = ref.read(userAccessProvider.notifier);

    return SettingsUsersRolesShell(
      activeRoute: AppRoutes.settingsUsers,
      child: state.isLoading
          ? _buildLoadingScaffold()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(40, 28, 40, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Back navigation ────────────────────────────
                          _buildBackNav(),
                          const SizedBox(height: 20),

                          // ── Page heading ───────────────────────────────
                          _buildPageHeader(),
                          const SizedBox(height: 32),

                          // ── Form fields ────────────────────────────────
                          _buildFormFields(state),
                          const SizedBox(height: 32),

                          // ── Restrict Access To ─────────────────────────
                          _buildRestrictAccessSection(state, notifier),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
    );
  }

  Widget _buildLoadingScaffold() {
    return Skeletonizer(
      ignoreContainers: true,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(40, 28, 40, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ZBone(width: 14, height: 14),
                      SizedBox(width: 6),
                      ZBone(width: 96, height: 14),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const ZBone(width: 180, height: 30),
                  const SizedBox(height: 8),
                  const ZBone(width: 420, height: 16),
                  const SizedBox(height: 32),
                  const ZFormSkeleton(rows: 3),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const ZBone(width: 140, height: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(height: 1, color: AppTheme.borderLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      ZBone(width: 110, height: 34),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: ZBone(height: 36)),
                      SizedBox(width: 8),
                      Expanded(child: ZBone(height: 36)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(minHeight: 450, maxHeight: 600),
                    decoration: BoxDecoration(
                      color: _kSurfaceContainerLow,
                      borderRadius: const BorderRadius.all(_kRadiusXl),
                      border: Border.all(
                        color: _kOutlineVariant.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: ZListSkeleton(itemCount: 7),
                        )),
                        SizedBox(
                          width: 48,
                          child: Center(child: ZBone(width: 32, height: 32, borderRadius: 16)),
                        ),
                        Expanded(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: ZListSkeleton(itemCount: 6),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ZBone(width: 96, height: 36),
                SizedBox(width: 12),
                ZBone(width: 96, height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Back navigation ────────────────────────────────────────────────────────

  Widget _buildBackNav() {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.settingsUsers),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.arrowLeft,
              size: 14, color: AppTheme.primaryBlue),
          const SizedBox(width: 6),
          Text(
            'Back to Users',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Page header ────────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.userId == null ? 'Invite New User' : 'Edit User',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Configure access and organizational boundaries for the new team member.',
          style: TextStyle(
            fontSize: 13.5,
            color: _kOnSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ─── Form fields ────────────────────────────────────────────────────────────

  Widget _buildFormFields(UserAccessState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormRow(
          'Name',
          CustomTextField(
            controller: _nameController,
            hintText: '',
            validator: (v) => v?.isEmpty == true ? 'Required' : null,
          ),
          required: true,
        ),
        const SizedBox(height: 16),
        _buildFormRow(
          'Email Address',
          CustomTextField(
            controller: _emailController,
            hintText: '',
            validator: (v) => v?.isEmpty == true ? 'Required' : null,
          ),
          required: true,
        ),
        const SizedBox(height: 16),
        _buildFormRow(
          'Role',
          FormDropdown<SettingsRoleRecord>(
            value: state.roles
                .firstWhereOrNull((r) => r.id == _selectedRoleId),
            items: state.roles,
            displayStringForValue: (r) => r.label,
            onChanged: (v) => setState(() => _selectedRoleId = v?.id),
            hint: 'Select a role',
          ),
          required: true,
          subtitle: _selectedRoleId != null
              ? _roleSubtitle(state, _selectedRoleId!)
              : null,
        ),
      ],
    );
  }

  String? _roleSubtitle(UserAccessState state, String roleId) {
    final role = state.roles.firstWhereOrNull((r) => r.id == roleId);
    if (role == null) return null;
    final description = role.description.trim();
    return description.isEmpty ? null : description;
  }

  Widget _buildFormRow(
    String label,
    Widget child, {
    bool required = false,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kOnSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: child,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: _kOnSurfaceVariant),
          ),
        ],
      ],
    );
  }

  // ─── Restrict Access To ──────────────────────────────────────────────────────

  Widget _buildRestrictAccessSection(
    UserAccessState state,
    UserAccessNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section heading with divider
        Row(
          children: [
            const Text(
              'Restrict Access To',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 1,
                color: _kOutlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tab bar
        _buildTabBar(),
        const SizedBox(height: 16),

        // Defaults row
        _buildDefaultsRow(state, notifier),
        const SizedBox(height: 16),

        // Dual-pane card
        _buildDualPane(state, notifier),
      ],
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        _buildTab('Locations', LucideIcons.mapPin, active: true),
      ],
    );
  }

  Widget _buildTab(String label, IconData icon, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? AppTheme.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: active ? AppTheme.primaryBlue : _kOnSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? AppTheme.primaryBlue : _kOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Defaults row ────────────────────────────────────────────────────────────

  Widget _buildDefaultsRow(
      UserAccessState state, UserAccessNotifier notifier) {
    final selectedBranches = state.branches
        .where((b) => state.selectedBranchIds.contains(b.id))
        .toList();
    final selectedWarehouses = state.warehouses
        .where((w) => state.selectedBranchIds.contains(w.id))
        .toList();

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        const Text(
          "User's Default Business Location :",
          style: TextStyle(fontSize: 12.5, color: Color(0xFF444444)),
        ),
        _InlineDropdownTrigger<SettingsLocationRecord>(
          value: state.branches
              .firstWhereOrNull((b) => b.id == state.defaultBranchId),
          items: selectedBranches,
          displayString: (b) => b.name,
          hint: 'None',
          onChanged: (v) => notifier.setDefaultBranch(v?.id),
        ),
        const SizedBox(width: 12),
        const Text(
          "User's Default Warehouse Location :",
          style: TextStyle(fontSize: 12.5, color: Color(0xFF444444)),
        ),
        _InlineDropdownTrigger<SettingsLocationRecord>(
          value: state.warehouses
              .firstWhereOrNull((w) => w.id == state.defaultWarehouseId),
          items: selectedWarehouses,
          displayString: (w) => w.name,
          hint: 'None',
          onChanged: (v) => notifier.setDefaultWarehouse(v?.id),
        ),
      ],
    );
  }

  // ─── Dual-pane card ──────────────────────────────────────────────────────────

  Widget _buildDualPane(UserAccessState state, UserAccessNotifier notifier) {
    return Container(
      constraints: const BoxConstraints(minHeight: 450, maxHeight: 600),
      decoration: BoxDecoration(
        color: _kSurfaceContainerLow,
        borderRadius: const BorderRadius.all(_kRadiusXl),
        border: Border.all(color: _kOutlineVariant.withValues(alpha: 0.15)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(_kRadiusXl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: tree panel
            Expanded(flex: 3, child: _buildTreePanel(state, notifier)),

            // Center: bridge column
            _buildBridgeColumn(state, notifier),

            // Right: associated values
            Expanded(
              flex: 2,
              child: _buildAssociatedValuesPanel(state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tree panel (left) ───────────────────────────────────────────────────────

  Widget _buildTreePanel(UserAccessState state, UserAccessNotifier notifier) {
    final query = _locationSearchController.text.trim().toLowerCase();
    final allLocs = [...state.branches, ...state.warehouses];
    final allSelected = allLocs.isNotEmpty &&
        allLocs.every((l) => state.selectedBranchIds.contains(l.id));

    return Container(
      color: _kSurfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search bar row + Select All
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.search,
                    size: 14, color: _kOnSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _locationSearchController,
                    onChanged: (v) => setState(() {}),
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Type to search locations...',
                      hintStyle:
                          TextStyle(fontSize: 13, color: _kOnSurfaceVariant),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const VerticalDivider(width: 24, indent: 12, endIndent: 12),
                GestureDetector(
                  onTap: () {
                    if (allSelected) {
                      notifier.toggleAll(false);
                    } else {
                      final ids = allLocs
                          .where((l) =>
                              query.isEmpty ||
                              l.name.toLowerCase().contains(query))
                          .map((l) => l.id)
                          .toList();
                      notifier.selectVisible(ids);
                    }
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: allSelected,
                          activeColor: AppTheme.primaryBlue,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(color: _kOutlineVariant),
                          onChanged: (_) {
                            if (allSelected) {
                              notifier.toggleAll(false);
                            } else {
                              final ids = allLocs
                                  .where((l) =>
                                      query.isEmpty ||
                                      l.name.toLowerCase().contains(query))
                                  .map((l) => l.id)
                                  .toList();
                              notifier.selectVisible(ids);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Select All',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tree items with Scrolling
          Expanded(
            child: state.isLoading
                ? Skeletonizer(
                    ignoreContainers: true,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: ZListSkeleton(itemCount: 7),
                    ),
                  )
                : state.branches.isEmpty && state.warehouses.isEmpty
                    ? _buildEmptyState('No locations found.')
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        child: Column(
                          children: _buildNestedTree(state, notifier, null, 0),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.mapPinOff,
              size: 32, color: _kOnSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(fontSize: 13, color: _kOnSurfaceVariant)),
        ],
      ),
    );
  }

  // ─── Bridge column (center) ──────────────────────────────────────────────────

  Widget _buildBridgeColumn(
      UserAccessState state, UserAccessNotifier notifier) {
    return Container(
      width: 48,
      decoration: const BoxDecoration(
        color: _kSurfaceContainerLow,
        border: Border.symmetric(
          vertical: BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _kOutlineVariant.withValues(alpha: 0.5)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: const Icon(LucideIcons.arrowRight,
              color: AppTheme.primaryBlue, size: 14),
        ),
      ),
    );
  }

  // ─── Associated Values panel (right) ─────────────────────────────────────────

  bool _locationsGroupExpanded = true;

  Widget _buildAssociatedValuesPanel(
      UserAccessState state, UserAccessNotifier notifier) {
    final selectedItems = <SettingsLocationRecord>[];
    for (final b in state.branches) {
      if (state.selectedBranchIds.contains(b.id)) selectedItems.add(b);
      for (final w
          in state.warehouses.where((w) => w.parentBranchId == b.id)) {
        if (state.selectedBranchIds.contains(w.id)) selectedItems.add(w);
      }
    }
    for (final w in state.warehouses) {
      if (state.selectedBranchIds.contains(w.id) &&
          !selectedItems.contains(w)) {
        selectedItems.add(w);
      }
    }

    return Container(
      color: _kSurfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: _kSurfaceContainerLow,
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text(
                  'ASSOCIATED VALUES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (selectedItems.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${selectedItems.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Selected Items List
          Expanded(
            child: selectedItems.isEmpty
                ? Center(
                    child: Text(
                      'No entries added yet.',
                      style: TextStyle(
                          fontSize: 12,
                          color: _kOnSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      InkWell(
                        onTap: () => setState(() =>
                            _locationsGroupExpanded = !_locationsGroupExpanded),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          color: _kSurfaceContainerLow.withValues(alpha: 0.3),
                          child: Row(
                            children: [
                              Icon(
                                _locationsGroupExpanded
                                    ? LucideIcons.chevronUp
                                    : LucideIcons.chevronDown,
                                size: 14,
                                color: _kOnSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              const Text('Locations',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text('${selectedItems.length}',
                                  style: const TextStyle(
                                      fontSize: 12, color: _kOnSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                      if (_locationsGroupExpanded)
                        ...selectedItems.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final loc = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: Color(0xFFF5F5F5))),
                            ),
                            child: Row(
                              children: [
                                Text('$idx.',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: _kOnSurfaceVariant,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    loc.name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      notifier.toggleBranch(loc.id),
                                  icon: const Icon(LucideIcons.x,
                                      size: 14, color: AppTheme.errorRed),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Nested tree builder ─────────────────────────────────────────────────────

  List<Widget> _buildNestedTree(
    UserAccessState state,
    UserAccessNotifier notifier,
    String? parentId,
    int depth,
  ) {
    final query = _locationSearchController.text.trim().toLowerCase();
    final allLocations = [...state.branches, ...state.warehouses];

    // Find children for this parentId
    final children =
        allLocations.where((l) => l.parentBranchId == parentId).toList();

    // If we're at root (parentId == null) and there's a disconnect in the tree 
    // (warehouses pointing to a branch that doesn't exist in data), 
    // we should still show them eventually. But for now, standard tree logic.

    final widgets = <Widget>[];
    for (final child in children) {
      final matchesQuery =
          query.isEmpty || child.name.toLowerCase().contains(query);
      
      // Check if any sub-items match query
      final subChildren = _buildNestedTree(state, notifier, child.id, depth + 1);
      final hasMatchingDescendants = subChildren.isNotEmpty;

      if (matchesQuery || hasMatchingDescendants) {
        widgets.add(
          _buildTreeRow(child, state, notifier,
              depth: depth, isExpanded: subChildren.isNotEmpty),
        );
        if (subChildren.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                      left: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
                ),
                child: Column(children: subChildren),
              ),
            ),
          );
        }
      }
    }
    return widgets;
  }

  Widget _buildTreeRow(
    SettingsLocationRecord loc,
    UserAccessState state,
    UserAccessNotifier notifier, {
    required int depth,
    bool isExpanded = false,
  }) {
    final isSelected = state.selectedBranchIds.contains(loc.id);
    final hasChildren = [...state.branches, ...state.warehouses]
        .any((l) => l.parentBranchId == loc.id);

    return InkWell(
      onTap: () => notifier.toggleBranch(loc.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            // Indent
            SizedBox(width: depth * 12),
            // Expand/collapse icon (visual)
            if (hasChildren)
              Icon(
                isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                size: 14,
                color: _kOnSurfaceVariant,
              )
            else
              const SizedBox(width: 14),
            const SizedBox(width: 4),
            // Custom Checkbox
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryBlue : _kOutlineVariant,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  loc.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
            if (loc.isWarehouse)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _kSurfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('WH',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space32,
        vertical: AppTheme.space16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space24,
                vertical: AppTheme.space12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
          ),
          const SizedBox(width: AppTheme.space12),
          OutlinedButton(
            onPressed: _saving ? null : () => context.go(AppRoutes.settingsUsers),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.borderLight),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space24,
                vertical: AppTheme.space12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hover card helper ────────────────────────────────────────────────────────

class _HoverCard extends StatefulWidget {
  const _HoverCard({required this.child});
  final Widget Function(bool hovered) child;

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.child(_hovered),
    );
  }
}

// ─── Inline dropdown trigger ──────────────────────────────────────────────────

class _InlineDropdownTrigger<T> extends StatefulWidget {
  const _InlineDropdownTrigger({
    required this.value,
    required this.items,
    required this.displayString,
    required this.hint,
    required this.onChanged,
  });

  final T? value;
  final List<T> items;
  final String Function(T) displayString;
  final String hint;
  final ValueChanged<T?> onChanged;

  @override
  State<_InlineDropdownTrigger<T>> createState() =>
      _InlineDropdownTriggerState<T>();
}

class _InlineDropdownTriggerState<T>
    extends State<_InlineDropdownTrigger<T>> {
  final _key = GlobalKey();
  OverlayEntry? _overlayEntry;

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    _overlayEntry = OverlayEntry(
      builder: (_) => _DropdownOverlay<T>(
        anchorOffset: offset,
        anchorSize: size,
        items: widget.items,
        selectedValue: widget.value,
        displayString: widget.displayString,
        onSelected: (v) {
          widget.onChanged(v);
          _removeOverlay();
        },
        onDismiss: _removeOverlay,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.value != null
        ? widget.displayString(widget.value as T)
        : widget.hint;

    return GestureDetector(
      key: _key,
      onTap: _showOverlay,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: widget.value != null
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.arrow_drop_down,
              size: 16, color: Color(0xFF555555)),
        ],
      ),
    );
  }
}

// ─── Dropdown overlay with search ────────────────────────────────────────────

class _DropdownOverlay<T> extends StatefulWidget {
  const _DropdownOverlay({
    required this.anchorOffset,
    required this.anchorSize,
    required this.items,
    required this.selectedValue,
    required this.displayString,
    required this.onSelected,
    required this.onDismiss,
  });

  final Offset anchorOffset;
  final Size anchorSize;
  final List<T> items;
  final T? selectedValue;
  final String Function(T) displayString;
  final ValueChanged<T?> onSelected;
  final VoidCallback onDismiss;

  @override
  State<_DropdownOverlay<T>> createState() => _DropdownOverlayState<T>();
}

class _DropdownOverlayState<T> extends State<_DropdownOverlay<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((item) =>
            _query.isEmpty ||
            widget.displayString(item).toLowerCase().contains(_query))
        .toList();

    const dropdownWidth = 260.0;
    const itemHeight = 36.0;
    const searchBarHeight = 38.0;
    const maxListHeight = 200.0;
    final listHeight = (filtered.isEmpty
            ? 44.0
            : (filtered.length * itemHeight).clamp(0.0, maxListHeight))
        .toDouble();
    final totalHeight = searchBarHeight + listHeight;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: widget.anchorOffset.dx,
          top: widget.anchorOffset.dy + widget.anchorSize.height + 4,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: dropdownWidth,
              height: totalHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(_kRadiusSm),
                border: Border.all(color: const Color(0xFFDDDDDD)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: searchBarHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppTheme.primaryBlue, width: 1.5),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.search,
                            size: 13, color: _kOnSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'Search',
                              hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: _kOnSurfaceVariant),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'NO RESULTS FOUND',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _kOnSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: filtered.length,
                            itemExtent: itemHeight,
                            itemBuilder: (_, i) {
                              final item = filtered[i];
                              final isSelected =
                                  item == widget.selectedValue;
                              return InkWell(
                                onTap: () => widget.onSelected(item),
                                child: Container(
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.displayString(item),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isSelected
                                                ? Colors.white
                                                : AppTheme.textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(Icons.check,
                                            size: 14,
                                            color: Colors.white),
                                    ],
                                  ),
                                ),
                              );
                            },
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
