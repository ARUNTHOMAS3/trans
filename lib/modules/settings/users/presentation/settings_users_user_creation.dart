import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/pages/settings_users_roles_support.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:collection/collection.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import '../providers/user_access_provider.dart';

// ─── Design tokens (local, matching HTML reference) ──────────────────────────

const _kRadiusSm = Radius.circular(6);
const _kRadiusMd = Radius.circular(12);
const _kRadiusXl = Radius.circular(24);

const _kSurfaceContainerLow = Color(0xFFF6F3F4);
const _kSurfaceContainerHigh = Color(0xFFEAE7EA);
const _kSurfaceContainerLowest = Color(0xFFFFFFFF);
const _kOutlineVariant = Color(0xFFB3B1B4);
const _kOnSurfaceVariant = Color(0xFF5F5F61);
const _kPrimaryContainer = Color(0xFFD6E3FF);
const _kOnPrimaryContainer = Color(0xFF00519E);

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
    Future.microtask(
      () => ref
          .read(userAccessProvider.notifier)
          .init(currentSettingsOrgId(ref)),
    );
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
          'outlet_ids': state.selectedOutletIds.toList(),
          'default_business_outlet_id': state.defaultBranchId,
          'default_warehouse_outlet_id': state.defaultWarehouseId,
        },
      };

      debugPrint('Saving user access: $payload');

      // TODO: call POST/PUT /users
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ZerpaiToast.success(context, 'User invited successfully.');
        context.go(AppRoutes.settingsUsers);
      }
    } catch (e) {
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
          ? const Center(child: CircularProgressIndicator())
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
    if (role.label.toLowerCase().contains('admin')) {
      return 'Unrestricted access to all modules.';
    }
    return null;
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
        .where((b) => state.selectedOutletIds.contains(b.id))
        .toList();
    final selectedWarehouses = state.warehouses
        .where((w) => state.selectedOutletIds.contains(w.id))
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
      decoration: BoxDecoration(
        color: _kSurfaceContainerLow,
        borderRadius: const BorderRadius.all(_kRadiusXl),
        border: Border.all(
            color: _kOutlineVariant.withValues(alpha: 0.15)),
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: tree panel
              Flexible(flex: 3, child: _buildTreePanel(state, notifier)),

              // Center: bridge column
              _buildBridgeColumn(state, notifier),

              // Right: associated values
              Flexible(
                flex: 2,
                child: _buildAssociatedValuesPanel(state, notifier),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tree panel (left) ───────────────────────────────────────────────────────

  Widget _buildTreePanel(UserAccessState state, UserAccessNotifier notifier) {
    final query = _locationSearchController.text.trim().toLowerCase();
    final allLocs = [...state.branches, ...state.warehouses];
    final allSelected = allLocs.isNotEmpty &&
        allLocs.every((l) => state.selectedOutletIds.contains(l.id));

    return Container(
      constraints: const BoxConstraints(minHeight: 500),
      color: _kSurfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar row + Select All
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.search,
                    size: 13, color: _kOnSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _locationSearchController,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Type to search Locations',
                      hintStyle: TextStyle(
                          fontSize: 13, color: _kOnSurfaceVariant),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Select All — checkbox + label
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
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(width: 5),
                      const Text(
                        'Select All',
                        style: TextStyle(fontSize: 12, color: _kOnSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tree items
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: Column(
              children: _buildNestedTree(state, notifier, null, 0),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bridge column (center) ──────────────────────────────────────────────────

  Widget _buildBridgeColumn(
      UserAccessState state, UserAccessNotifier notifier) {
    return SizedBox(
      width: 48,
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kSurfaceContainerLowest,
            shape: BoxShape.circle,
            border: Border.all(color: _kOutlineVariant.withValues(alpha: 0.5)),
          ),
          child: const Icon(Icons.arrow_forward,
              color: _kOnSurfaceVariant, size: 16),
        ),
      ),
    );
  }

  // ─── Associated Values panel (right) ─────────────────────────────────────────

  bool _locationsGroupExpanded = true;

  Widget _buildAssociatedValuesPanel(
      UserAccessState state, UserAccessNotifier notifier) {
    // Build ordered selected items (branches first, then their warehouses)
    final selectedItems = <SettingsLocationRecord>[];
    for (final b in state.branches) {
      if (state.selectedOutletIds.contains(b.id)) selectedItems.add(b);
      for (final w
          in state.warehouses.where((w) => w.parentOutletId == b.id)) {
        if (state.selectedOutletIds.contains(w.id)) selectedItems.add(w);
      }
    }
    for (final w in state.warehouses) {
      if (state.selectedOutletIds.contains(w.id) &&
          !selectedItems.contains(w)) {
        selectedItems.add(w);
      }
    }

    return Container(
      color: _kSurfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: _kSurfaceContainerLow,
              border: Border(
                  bottom: BorderSide(color: Color(0xFFE8E6E9))),
            ),
            child: Row(
              children: [
                // Blue circle checkmark icon
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      size: 12, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ASSOCIATED VALUES',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                if (selectedItems.isNotEmpty)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${selectedItems.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Locations group row ────────────────────────────────────
          if (selectedItems.isNotEmpty) ...[
            InkWell(
              onTap: () =>
                  setState(() => _locationsGroupExpanded = !_locationsGroupExpanded),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  children: [
                    Icon(
                      _locationsGroupExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 14,
                      color: _kOnSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Locations',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _kSurfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${selectedItems.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _kOnSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_locationsGroupExpanded)
              for (int i = 0; i < selectedItems.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: Text(
                    '${i + 1}. ${selectedItems[i].name}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
          ],

          if (selectedItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No locations selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: _kOnSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
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

    final children =
        allLocations.where((l) => l.parentOutletId == parentId).toList();

    final widgets = <Widget>[];
    for (int idx = 0; idx < children.length; idx++) {
      final child = children[idx];
      final matchesQuery =
          query.isEmpty || child.name.toLowerCase().contains(query);
      final hasMatchingDescendants = allLocations.any((l) =>
          l.parentOutletId == child.id &&
          l.name.toLowerCase().contains(query));

      if (matchesQuery || hasMatchingDescendants) {
        final subChildren =
            _buildNestedTree(state, notifier, child.id, depth + 1);
        widgets.add(
          _buildTreeRow(child, state, notifier,
              depth: depth,
              isExpanded: subChildren.isNotEmpty),
        );
        if (subChildren.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: _kPrimaryContainer.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
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
    final isSelected = state.selectedOutletIds.contains(loc.id);
    final hasChildren = state.warehouses
        .any((w) => w.parentOutletId == loc.id);

    return InkWell(
      borderRadius: const BorderRadius.all(_kRadiusSm),
      onTap: () => notifier.toggleOutlet(loc.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? _kPrimaryContainer.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: const BorderRadius.all(_kRadiusSm),
        ),
        child: Row(
          children: [
            // Expand/collapse chevron (visual only)
            if (hasChildren)
              Icon(
                isExpanded
                    ? LucideIcons.chevronDown
                    : LucideIcons.chevronRight,
                size: 14,
                color: isSelected
                    ? AppTheme.primaryBlue
                    : _kOutlineVariant,
              )
            else
              const SizedBox(width: 14),
            const SizedBox(width: 6),
            // Checkbox-style box
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(3)),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : _kOutlineVariant,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check,
                      size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : (depth == 0
                          ? FontWeight.w500
                          : FontWeight.w400),
                  color: isSelected
                      ? _kOnPrimaryContainer
                      : AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Footer ──────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
            top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => context.go(AppRoutes.settingsUsers),
            style: TextButton.styleFrom(
              foregroundColor: _kOnSurfaceVariant,
              textStyle: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w700),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          _saving
              ? Container(
                  width: 150,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.primaryBlueDark,
                      ],
                    ),
                    borderRadius: const BorderRadius.all(_kRadiusMd),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryBlue,
                          AppTheme.primaryBlueDark,
                        ],
                      ),
                      borderRadius: const BorderRadius.all(_kRadiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue
                              .withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Send Invitation',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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
