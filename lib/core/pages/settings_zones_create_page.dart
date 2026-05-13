// ignore_for_file: unused_element, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/services/bin_locations_service.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class _NavSection {
  final String title;
  final List<_NavBlock> blocks;
  const _NavSection({required this.title, required this.blocks});
}

class _NavBlock {
  final String title;
  final List<_NavEntry> items;
  const _NavBlock({required this.title, required this.items});
}

class _NavEntry {
  final String label;
  final String? route;
  const _NavEntry({required this.label, this.route});
}

const List<_NavSection> _navSections = <_NavSection>[
  _NavSection(
    title: 'Organization Settings',
    blocks: <_NavBlock>[
      _NavBlock(
        title: 'Organization',
        items: <_NavEntry>[
          _NavEntry(label: 'Profile', route: AppRoutes.settingsOrgProfile),
          _NavEntry(label: 'Branding', route: AppRoutes.settingsOrgBranding),
          _NavEntry(label: 'Branches', route: AppRoutes.settingsBranches),
          _NavEntry(label: 'Warehouses', route: AppRoutes.settingsWarehouses),
          _NavEntry(label: 'Locations', route: AppRoutes.settingsLocations),
          _NavEntry(label: 'Approvals'),
          _NavEntry(label: 'Manage Subscription'),
        ],
      ),
    ],
  ),
  _NavSection(
    title: 'Module Settings',
    blocks: <_NavBlock>[
      _NavBlock(
        title: 'General',
        items: <_NavEntry>[
          _NavEntry(
            label: 'Customers and Vendors',
            route: AppRoutes.salesCustomers,
          ),
          _NavEntry(label: 'Items', route: AppRoutes.itemsReport),
        ],
      ),
    ],
  ),
];

class _ZoneLevelFormRow {
  final int level;
  final TextEditingController locationController;
  final TextEditingController delimiterController;
  final TextEditingController aliasController;
  final TextEditingController totalController;

  _ZoneLevelFormRow({
    required this.level,
    String location = '',
    String delimiter = '',
    String alias = '',
    String total = '',
  })  : locationController = TextEditingController(text: location),
        delimiterController = TextEditingController(text: delimiter),
        aliasController = TextEditingController(text: alias),
        totalController = TextEditingController(text: total);

  void dispose() {
    locationController.dispose();
    delimiterController.dispose();
    aliasController.dispose();
    totalController.dispose();
  }
}

class SettingsZonesCreatePage extends ConsumerStatefulWidget {
  final String? branchId;
  final String? branchName;
  final String? warehouseId;
  final String? warehouseName;

  const SettingsZonesCreatePage({
    super.key,
    this.branchId,
    this.branchName,
    this.warehouseId,
    this.warehouseName,
  });

  @override
  ConsumerState<SettingsZonesCreatePage> createState() =>
      _SettingsZonesCreatePageState();
}

class _SettingsZonesCreatePageState
    extends ConsumerState<SettingsZonesCreatePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _zoneNameController = TextEditingController();
  final Set<String> _expandedBlocks = <String>{'Organization'};
  final List<_ZoneLevelFormRow> _levels = <_ZoneLevelFormRow>[
    _ZoneLevelFormRow(level: 1),
  ];

  bool _isSaving = false;
  String _organizationName = '';
  String? _zoneNameError;
  bool _showCombinedLengthError = false;
  bool _showDelimiterLengthError = false;

  bool get _isWarehouseScope => (widget.warehouseId ?? '').trim().isNotEmpty;

  String get _currentScopeId =>
      _isWarehouseScope ? widget.warehouseId!.trim() : (widget.branchId ?? '').trim();

  String get _currentScopeName =>
      _isWarehouseScope ? (widget.warehouseName ?? '').trim() : (widget.branchName ?? '').trim();

  Map<String, String> _scopeQueryParameters({String? zoneName}) {
    final params = <String, String>{};
    if (_isWarehouseScope) {
      params['warehouseId'] = _currentScopeId;
      params['warehouseName'] = _currentScopeName;
    } else {
      params['branchId'] = _currentScopeId;
      params['branchName'] = _currentScopeName;
    }
    if (zoneName != null && zoneName.isNotEmpty) {
      params['zoneName'] = zoneName;
    }
    return params;
  }
  final Map<int, String> _locationErrors = <int, String>{};
  final Map<int, String> _delimiterErrors = <int, String>{};
  final Map<int, String> _aliasErrors = <int, String>{};
  final Map<int, String> _totalErrors = <int, String>{};

  @override
  void initState() {
    super.initState();
    final user = ref.read(authUserProvider);
    _organizationName =
        (user?.orgName ?? '').trim().isNotEmpty
            ? user!.orgName
            : 'Your Organization';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _zoneNameController.dispose();
    for (final level in _levels) {
      level.dispose();
    }
    super.dispose();
  }

  void _addLevel() {
    if (_levels.length >= 5) {
      ZerpaiToast.info(context, 'A zone can have at most five levels');
      return;
    }
    setState(() {
      _levels.add(_ZoneLevelFormRow(level: _levels.length + 1));
    });
  }

  void _removeLevel(int index) {
    if (_levels.length == 1) {
      return;
    }
    setState(() {
      _levels[index].dispose();
      _levels.removeAt(index);
      for (int i = 0; i < _levels.length; i++) {
        final current = _levels[i];
        _levels[i] = _ZoneLevelFormRow(
          level: i + 1,
          location: current.locationController.text,
          delimiter: current.delimiterController.text,
          alias: current.aliasController.text,
          total: current.totalController.text,
        );
        current.dispose();
      }
      _locationErrors.clear();
      _delimiterErrors.clear();
      _aliasErrors.clear();
      _totalErrors.clear();
    });
  }

  int get _combinedAliasAndDelimiterLength => _levels.fold<int>(
        0,
        (sum, level) =>
            sum +
            level.aliasController.text.trim().length +
            level.delimiterController.text.trim().length,
      );

  int get _totalCount {
    final List<int> totals = _levels
        .map((level) => int.tryParse(level.totalController.text.trim()) ?? 0)
        .where((value) => value > 0)
        .toList();
    if (totals.isEmpty) {
      return 0;
    }
    return totals.reduce((value, element) => value * element);
  }

  void _onLevelFieldChanged(int index) {
    setState(() {
      _locationErrors.remove(index);
      _delimiterErrors.remove(index);
      _aliasErrors.remove(index);
      _totalErrors.remove(index);
      if (_combinedAliasAndDelimiterLength <= 50) {
        _showCombinedLengthError = false;
      }
      if (_levels.every(
        (level) => level.delimiterController.text.trim().length <= 1,
      )) {
        _showDelimiterLengthError = false;
      }
    });
  }

  bool _validate() {
    bool valid = true;
    _zoneNameError = null;
    _showCombinedLengthError = false;
    _showDelimiterLengthError = false;
    _locationErrors.clear();
    _delimiterErrors.clear();
    _aliasErrors.clear();
    _totalErrors.clear();

    if (_zoneNameController.text.trim().isEmpty) {
      _zoneNameError = 'Zone name is required';
      valid = false;
    }

    for (int index = 0; index < _levels.length; index++) {
      final level = _levels[index];
      if (level.locationController.text.trim().isEmpty) {
        _locationErrors[index] = 'Location is required';
        valid = false;
      }
      if (level.delimiterController.text.trim().length > 1) {
        _delimiterErrors[index] = 'Delimiter must be a single character';
        _showDelimiterLengthError = true;
        valid = false;
      }
      if (level.aliasController.text.trim().isEmpty) {
        _aliasErrors[index] = 'Alias name is required';
        valid = false;
      }
      final int? total = int.tryParse(level.totalController.text.trim());
      if (total == null || total < 1) {
        _totalErrors[index] = 'Enter a valid total';
        valid = false;
      }
    }

    if (_combinedAliasAndDelimiterLength > 50) {
      _showCombinedLengthError = true;
      valid = false;
    }

    setState(() {});
    return valid;
  }

  Future<void> _save() async {
    if (!_validate()) {
      ZerpaiToast.error(context, 'Please fill the required zone details.');
      return;
    }
    setState(() => _isSaving = true);
    final user = ref.read(authUserProvider);
    final String orgId = (user?.orgId ?? '').trim();

    try {
      final createdZone = await BinLocationsService.instance.createZone(
        orgId: orgId.isNotEmpty
            ? orgId
            : '00000000-0000-0000-0000-000000000002',
        branchId: _currentScopeId,
        branchName: _currentScopeName,
        zoneName: _zoneNameController.text.trim(),
        levels: _levels
            .map(
              (level) => ZoneLevelRecord(
                level: level.level,
                location: level.locationController.text.trim(),
                delimiter: level.delimiterController.text.trim(),
                aliasName: level.aliasController.text.trim(),
                total: int.parse(level.totalController.text.trim()),
              ),
            )
            .toList(),
      );
      if (!mounted) return;
      ZerpaiToast.success(context, 'Bin location created');
      context.goNamed(
        AppRoutes.settingsZoneBins,
        pathParameters: {
          'orgSystemId':
              GoRouterState.of(context).pathParameters['orgSystemId'] ??
              '0000000000',
          'zoneId': createdZone.id,
        },
        queryParameters: _scopeQueryParameters(zoneName: createdZone.zoneName),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ZerpaiToast.error(context, 'Failed to create bin location');
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      useHorizontalPadding: false,
      useTopPadding: false,
      enableBodyScroll: false,
      searchFocusNode: _searchFocusNode,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSidebar(),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space32,
        AppTheme.space20,
        AppTheme.space32,
        AppTheme.space16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1560),
          child: Row(
            children: [
              SizedBox(
                width: 320,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.go(AppRoutes.settings),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: const Icon(
                          LucideIcons.chevronLeft,
                          size: 20,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3EE),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFED7C3),
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.settings2,
                              color: Color(0xFFF97316),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('All Settings', style: AppTheme.pageTitle),
                                const SizedBox(height: AppTheme.space4),
                                Text(
                                  _organizationName,
                                  style: AppTheme.bodyText,
                                  overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: AppTheme.space24),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 360,
                    height: 42,
                    child: SettingsSearchField(
                      items: const <SettingsSearchItem>[],
                      focusNode: _searchFocusNode,
                      controller: _searchController,
                      onQueryChanged: (_) {},
                      onNoMatch: (q) =>
                          ZerpaiToast.info(context, 'No settings matched "$q"'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space24),
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.settings),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  LucideIcons.x,
                  size: 16,
                  color: AppTheme.errorRed,
                ),
                label: const Text('Close Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return SettingsNavigationSidebar(
      currentPath: GoRouterState.of(context).uri.path,
    );
  }

  Widget _buildSidebarBlock(_NavBlock block, String currentPath) {
    final bool hasActiveChild = block.items.any((item) {
      if (item.route == AppRoutes.settingsLocations &&
          (currentPath == AppRoutes.settingsZones ||
              currentPath == AppRoutes.settingsZonesCreate ||
              currentPath.startsWith('/settings/zones/'))) {
        return true;
      }
      return item.route == currentPath;
    });
    final bool isExpanded =
        _expandedBlocks.contains(block.title) || hasActiveChild;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedBlocks.remove(block.title);
              } else {
                _expandedBlocks.add(block.title);
              }
            }),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space8,
                vertical: AppTheme.space10,
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      block.title,
                      style: AppTheme.bodyText.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.space28,
                right: AppTheme.space8,
                bottom: AppTheme.space6,
              ),
              child: Column(
                children: block.items
                    .map((e) => _buildSidebarEntry(e, currentPath))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarEntry(_NavEntry entry, String currentPath) {
    final bool isActive =
        entry.route == currentPath ||
        (entry.route == AppRoutes.settingsLocations &&
            (currentPath == AppRoutes.settingsZones ||
                currentPath == AppRoutes.settingsZonesCreate ||
                currentPath.startsWith('/settings/zones/')));
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;

    return InkWell(
      onTap: () {
        if (entry.route == null) {
          ZerpaiToast.info(context, '${entry.label} is not available yet');
          return;
        }
        context.go(entry.route!);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppTheme.space4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space10,
        ),
        decoration: BoxDecoration(
          color: isActive ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          entry.label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: isActive ? Colors.white : AppTheme.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1560),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.clipboardCheck,
                        size: 22,
                        color: AppTheme.textPrimary,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Create Bin Locations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.goNamed(
                          AppRoutes.settingsZones,
                          pathParameters: {
                            'orgSystemId':
                                GoRouterState.of(context)
                                    .pathParameters['orgSystemId'] ??
                                '0000000000',
                          },
                          queryParameters: _scopeQueryParameters(),
                        ),
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_showCombinedLengthError) ...[
                        _buildInlineErrorBanner(
                          message:
                              '• The total combined length of the Alias Name and Delimiter fields across all five levels must not exceed 50 characters.',
                          onClose: () => setState(
                            () => _showCombinedLengthError = false,
                          ),
                        ),
                      ],
                      if (_showDelimiterLengthError) ...[
                        _buildInlineErrorBanner(
                          message:
                              '• Please ensure that the "delimiter" has less than 1 characters.',
                          onClose: () => setState(
                            () => _showDelimiterLengthError = false,
                          ),
                        ),
                      ],
                      _buildZoneNameRow(),
                      const SizedBox(height: 20),
                      _buildLevelsTable(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              _isSaving ? 'Saving...' : 'Save',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () => context.goNamed(
                                      AppRoutes.settingsZones,
                                      pathParameters: {
                                        'orgSystemId':
                                            GoRouterState.of(context)
                                                    .pathParameters['orgSystemId'] ??
                                                '0000000000',
                                      },
                                      queryParameters: _scopeQueryParameters(),
                                    ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              side: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildZoneNameRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: RichText(
              text: const TextSpan(
                text: 'Zone Name',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w500,
                ),
                children: [TextSpan(text: '*')],
              ),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 420,
              child: TextField(
              controller: _zoneNameController,
              onChanged: (_) {
                if (_zoneNameError != null) {
                  setState(() => _zoneNameError = null);
                }
              },
              decoration: InputDecoration(
                hintText: 'Enter zone name',
                errorText: _zoneNameError,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.errorRed),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.errorRed),
                ),
              ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineErrorBanner({
    required String message,
    required VoidCallback onClose,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textBody,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                LucideIcons.x,
                size: 16,
                color: AppTheme.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelsTable() {
    const TextStyle headerStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
    );

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: const [
                SizedBox(width: 120, child: Text('Level', style: headerStyle)),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Location*',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(flex: 3, child: Text('Delimiter', style: headerStyle)),
                SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Alias Name*',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Total*',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
                SizedBox(width: 24),
              ],
            ),
          ),
          for (int i = 0; i < _levels.length; i++) _buildLevelRow(i),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                InkWell(
                  onTap: _addLevel,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.plusCircle,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'New Level',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textBody,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textBody,
                  ),
                ),
                const SizedBox(width: 120),
                Text(
                  _totalCount.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textBody,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRow(int index) {
    final _ZoneLevelFormRow level = _levels[index];

    InputDecoration buildDecoration(String hint, {String? error}) {
      return InputDecoration(
        hintText: hint,
        errorText: error,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppTheme.primaryBlue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppTheme.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppTheme.errorRed),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                level.level.toString(),
                style: const TextStyle(fontSize: 14, color: AppTheme.textBody),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: level.locationController,
              onChanged: (_) => _onLevelFieldChanged(index),
              decoration: buildDecoration(
                'Enter location',
                error: _locationErrors[index],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextField(
              controller: level.delimiterController,
              onChanged: (_) => _onLevelFieldChanged(index),
              decoration: buildDecoration(
                'Delimiter',
                error: _delimiterErrors[index],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextField(
              controller: level.aliasController,
              onChanged: (_) => _onLevelFieldChanged(index),
              decoration: buildDecoration(
                'Enter alias name',
                error: _aliasErrors[index],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextField(
              controller: level.totalController,
              onChanged: (_) => _onLevelFieldChanged(index),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: buildDecoration('0', error: _totalErrors[index]),
            ),
          ),
          SizedBox(
            width: 24,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: IconButton(
                onPressed:
                    _levels.length == 1 ? null : () => _removeLevel(index),
                icon: Icon(
                  LucideIcons.xCircle,
                  size: 16,
                  color: _levels.length == 1
                      ? AppTheme.borderColor
                      : AppTheme.errorRed,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
