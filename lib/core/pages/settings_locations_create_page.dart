import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/widgets/settings_search_field.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

const String _kDevOrgId = '00000000-0000-0000-0000-000000000002';

const List<String> _indianStates = <String>[
  'Andaman and Nicobar Islands',
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chandigarh',
  'Chhattisgarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jammu and Kashmir',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Ladakh',
  'Lakshadweep',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Puducherry',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
];

// ─── Sidebar nav (mirrors settings_locations_page) ────────────────────────────

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
          _NavEntry(label: 'Locations', route: AppRoutes.settingsLocations),
          _NavEntry(label: 'Approvals'),
          _NavEntry(label: 'Manage Subscription'),
        ],
      ),
      _NavBlock(
        title: 'Users & Roles',
        items: <_NavEntry>[
          _NavEntry(label: 'Users'),
          _NavEntry(label: 'Roles'),
          _NavEntry(label: 'User Preferences'),
        ],
      ),
      _NavBlock(
        title: 'Taxes & Compliance',
        items: <_NavEntry>[
          _NavEntry(label: 'Taxes'),
          _NavEntry(label: 'Direct Taxes'),
          _NavEntry(label: 'e-Way Bills'),
          _NavEntry(label: 'e-Invoicing'),
          _NavEntry(label: 'MSME Settings'),
        ],
      ),
      _NavBlock(
        title: 'Setup & Configurations',
        items: <_NavEntry>[
          _NavEntry(label: 'General'),
          _NavEntry(label: 'Currencies'),
          _NavEntry(label: 'Reminders'),
          _NavEntry(label: 'Customer Portal'),
        ],
      ),
      _NavBlock(
        title: 'Customization',
        items: <_NavEntry>[
          _NavEntry(label: 'Transaction Number Series'),
          _NavEntry(label: 'PDF Templates'),
          _NavEntry(label: 'Email Notifications'),
          _NavEntry(label: 'SMS Notifications'),
          _NavEntry(label: 'Reporting Tags'),
          _NavEntry(label: 'Web Tabs'),
        ],
      ),
      _NavBlock(
        title: 'Automation',
        items: <_NavEntry>[
          _NavEntry(label: 'Workflow Rules'),
          _NavEntry(label: 'Workflow Actions'),
          _NavEntry(label: 'Workflow Logs', route: AppRoutes.auditLogs),
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
      _NavBlock(
        title: 'Inventory',
        items: <_NavEntry>[
          _NavEntry(label: 'Assemblies', route: AppRoutes.assemblies),
          _NavEntry(
            label: 'Inventory Adjustments',
            route: AppRoutes.inventoryAdjustments,
          ),
          _NavEntry(label: 'Picklists', route: AppRoutes.picklists),
          _NavEntry(label: 'Packages', route: AppRoutes.packages),
          _NavEntry(label: 'Shipments', route: AppRoutes.shipments),
          _NavEntry(label: 'Transfer Orders', route: AppRoutes.transferOrders),
        ],
      ),
    ],
  ),
];

// ─── Parent outlet option ──────────────────────────────────────────────────────

class _OutletOption {
  final String id;
  final String name;
  const _OutletOption({required this.id, required this.name});
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class SettingsLocationsCreatePage extends ConsumerStatefulWidget {
  final String? outletId;
  const SettingsLocationsCreatePage({super.key, this.outletId});

  @override
  ConsumerState<SettingsLocationsCreatePage> createState() =>
      _SettingsLocationsCreatePageState();
}

class _SettingsLocationsCreatePageState
    extends ConsumerState<SettingsLocationsCreatePage> {
  final ApiClient _apiClient = ApiClient();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Form controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _gstinCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _attentionCtrl = TextEditingController();
  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();
  final TextEditingController _faxCtrl = TextEditingController();
  final TextEditingController _websiteCtrl = TextEditingController();

  // State
  String _locationType = 'business';
  String _logoOption = 'same'; // 'same' | 'upload'
  String? _selectedState;
  bool _isChildLocation = false;
  String? _parentOutletId;
  String? _parentError;
  bool _isSaving = false;
  bool _isLoading = false;
  String _organizationName = '';
  List<_OutletOption> _outlets = [];
  final Set<String> _expandedBlocks = <String>{'Organization'};

  // Logo upload state
  PlatformFile? _logoPicked;
  String? _logoUrl; // URL after upload or loaded from existing

  bool get _isBusiness => _locationType == 'business';
  bool get _isEditing => widget.outletId != null;

  @override
  void initState() {
    super.initState();
    _loadOrgName();
    _loadOutlets();
    if (_isEditing) _loadExisting();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _nameCtrl.dispose();
    _gstinCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _attentionCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    _faxCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrgName() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.get('/lookups/org/$orgId');
      if (!mounted) return;
      if (res.success && res.data is Map<String, dynamic>) {
        setState(() {
          _organizationName =
              ((res.data as Map<String, dynamic>)['name'] ??
                      user?.orgName ??
                      '')
                  .toString()
                  .trim();
        });
      } else {
        setState(() => _organizationName = user?.orgName ?? '');
      }
    } catch (_) {}
  }

  Future<void> _loadOutlets() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.get(
        '/outlets',
        queryParameters: {'org_id': orgId},
      );
      if (!mounted) return;
      if (res.success && res.data is List) {
        final list = (res.data as List).cast<Map<String, dynamic>>();
        setState(() {
          _outlets = list
              .where((o) => o['id'] != widget.outletId)
              .map(
                (o) => _OutletOption(
                  id: o['id'].toString(),
                  name: o['name'].toString(),
                ),
              )
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/outlets/${widget.outletId}');
      if (!mounted) return;
      if (res.success && res.data is Map<String, dynamic>) {
        final d = res.data as Map<String, dynamic>;
        _nameCtrl.text = (d['name'] ?? '').toString();
        _gstinCtrl.text = (d['gstin'] ?? '').toString();
        _emailCtrl.text = (d['email'] ?? '').toString();
        _phoneCtrl.text = (d['phone'] ?? '').toString();
        _attentionCtrl.text = (d['attention'] ?? '').toString();
        _streetCtrl.text = (d['address'] ?? '').toString();
        _cityCtrl.text = (d['city'] ?? '').toString();
        _pincodeCtrl.text = (d['pincode'] ?? '').toString();
        _faxCtrl.text = (d['fax'] ?? '').toString();
        _websiteCtrl.text = (d['website'] ?? '').toString();
        final state = (d['state'] ?? '').toString();
        _selectedState = _indianStates.contains(state) ? state : null;
        final parentId = d['parent_outlet_id']?.toString();
        if (parentId != null && parentId.isNotEmpty) {
          _parentOutletId = parentId;
          _isChildLocation = true;
        }
        final logoUrl = d['logo_url']?.toString();
        if (logoUrl != null && logoUrl.isNotEmpty) {
          _logoUrl = logoUrl;
          _logoOption = 'upload';
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _logoPicked = result.files.first);
    }
  }

  Future<void> _save() async {
    final bool needsParent = !_isBusiness || _isChildLocation;
    final bool parentMissing = needsParent && _parentOutletId == null;
    if (parentMissing)
      setState(() => _parentError = 'Parent location is required');
    if (!_formKey.currentState!.validate() || parentMissing) return;

    setState(() => _isSaving = true);
    try {
      final user = ref.read(authUserProvider);
      final String orgId = (user?.orgId.isNotEmpty == true)
          ? user!.orgId
          : _kDevOrgId;

      // Upload logo if a new file was picked
      if (_logoPicked != null) {
        final url = await StorageService().uploadLocationLogo(_logoPicked!);
        if (url != null) _logoUrl = url;
      }

      final body = <String, dynamic>{
        'org_id': orgId,
        'name': _nameCtrl.text.trim(),
        'outlet_code': _nameCtrl.text.trim().toUpperCase().replaceAll(' ', '-'),
        'gstin': _gstinCtrl.text.trim().toUpperCase(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'attention': _attentionCtrl.text.trim(),
        'address': _streetCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _selectedState ?? '',
        'country': 'India',
        'pincode': _pincodeCtrl.text.trim(),
        'fax': _faxCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'location_type': _locationType,
        'parent_outlet_id': needsParent ? _parentOutletId : null,
        'logo_url': _logoOption == 'upload' ? _logoUrl : null,
        'is_active': true,
      };

      final res = _isEditing
          ? await _apiClient.patch('/outlets/${widget.outletId}', data: body)
          : await _apiClient.post('/outlets', data: body);

      if (!mounted) return;
      if (res.success) {
        ZerpaiToast.success(
          context,
          _isEditing ? 'Location updated' : 'Location added',
        );
        context.go(AppRoutes.settingsLocations);
      } else {
        ZerpaiToast.error(context, res.message ?? 'Failed to save location');
      }
    } catch (e) {
      if (mounted) ZerpaiToast.error(context, 'Failed to save location');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      useHorizontalPadding: false,
      useTopPadding: false,
      enableBodyScroll: false,
      searchFocusNode: _searchFocusNode,
      child: Container(
        color: AppTheme.bgLight,
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

  // ─── Top bar (mirrors list page) ───────────────────────────────────────────

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
                      onTap: () => context.go(AppRoutes.settingsLocations),
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
                                  _organizationName.isNotEmpty
                                      ? _organizationName
                                      : 'Your Organization',
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
                  backgroundColor: AppTheme.bgLight,
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

  // ─── Sidebar (mirrors list page, Locations stays highlighted) ──────────────

  Widget _buildSidebar() {
    // Treat any /settings/locations/* path as active for Locations
    final String rawPath = GoRouterState.of(context).uri.path;
    final String currentPath = rawPath.replaceFirst(RegExp(r'^/\d{10,20}'), '');
    final String activePath = currentPath.startsWith('/settings/locations')
        ? AppRoutes.settingsLocations
        : currentPath;

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space12,
          AppTheme.space20,
          AppTheme.space12,
          AppTheme.space24,
        ),
        children: [
          for (final section in _navSections) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.space4,
                bottom: AppTheme.space8,
              ),
              child: Text(
                section.title.toUpperCase(),
                style: AppTheme.captionText.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            for (final block in section.blocks)
              _buildSidebarBlock(block, activePath),
            const SizedBox(height: AppTheme.space12),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarBlock(_NavBlock block, String currentPath) {
    final bool hasActiveChild = block.items.any(
      (item) => item.route == currentPath,
    );
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
    final bool isActive = entry.route == currentPath;
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

  // ─── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Location' : 'Add Location',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.space24),
                _buildLocationTypeSelector(),
                const SizedBox(height: AppTheme.space24),
                _buildMainFields(),
                const SizedBox(height: AppTheme.space20),
                _buildAddressSection(),
                const SizedBox(height: AppTheme.space20),
                _buildBottomFields(),
                const SizedBox(height: AppTheme.space32),
                _buildActions(),
                const SizedBox(height: AppTheme.space48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Location type selector ────────────────────────────────────────────────

  Widget _buildLocationTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Location Type'),
        const SizedBox(height: AppTheme.space12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                type: 'business',
                title: 'Business Location',
                description:
                    'A Business Location represents your organization or office\'s '
                    'operational location. It is used to record transactions, assess '
                    'regional performance, and monitor stock levels for items stored at this location.',
              ),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: _buildTypeCard(
                type: 'warehouse',
                title: 'Warehouse Only Location',
                description:
                    'A Warehouse Only Location refers to where your items are stored. '
                    'It helps track and monitor stock levels for items stored at this location.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String type,
    required String title,
    required String description,
  }) {
    final bool isSelected = _locationType == type;
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;

    return InkWell(
      onTap: () => setState(() {
        _locationType = type;
        if (type == 'warehouse') _isChildLocation = false;
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accentColor : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Radio<String>(
                value: type,
                groupValue: _locationType,
                onChanged: (v) => setState(() {
                  _locationType = v ?? type;
                  if (v == 'warehouse') _isChildLocation = false;
                }),
                activeColor: accentColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: AppTheme.space10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main fields (type-aware) ──────────────────────────────────────────────

  Widget _buildMainFields() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;

    return _buildCard(
      children: [
        // Logo — Business only
        if (_isBusiness) ...[
          _buildLabel('Logo'),
          const SizedBox(height: AppTheme.space6),
          FormDropdown<String>(
            value: _logoOption,
            items: const ['same', 'upload'],
            displayStringForValue: (v) =>
                v == 'same' ? 'Same as Organization Logo' : 'Upload a New Logo',
            onChanged: (v) => setState(() => _logoOption = v ?? 'same'),
          ),
          if (_logoOption == 'upload') ...[
            const SizedBox(height: AppTheme.space12),
            _buildLogoUploadArea(),
          ],
          const SizedBox(height: AppTheme.space20),
        ],

        // Name — both
        _buildTextField(
          label: 'Name',
          required: true,
          controller: _nameCtrl,
          hint: 'e.g. Head Office, Mumbai Branch',
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
        ),

        // Business: "This is a Child Location" checkbox
        if (_isBusiness) ...[
          const SizedBox(height: AppTheme.space16),
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: _isChildLocation,
                  onChanged: (v) => setState(() {
                    _isChildLocation = v ?? false;
                    if (!_isChildLocation) _parentOutletId = null;
                  }),
                  activeColor: accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              const Text(
                'This is a Child Location',
                style: TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ],
          ),
          if (_isChildLocation) ...[
            const SizedBox(height: AppTheme.space16),
            _buildParentDropdown(required: true),
          ],
        ],

        // Warehouse: Parent Location always required
        if (!_isBusiness) ...[
          const SizedBox(height: AppTheme.space20),
          _buildParentDropdown(required: true),
        ],

        // GSTIN — Business only (required)
        if (_isBusiness) ...[
          const SizedBox(height: AppTheme.space20),
          _buildTextField(
            label: 'GSTIN',
            required: true,
            controller: _gstinCtrl,
            hint: '27ABCDE1234F2Z5',
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              final s = v?.trim().toUpperCase() ?? '';
              if (s.isEmpty) return 'GSTIN is required';
              final gstinRegex = RegExp(
                r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}Z[A-Z\d]{1}$',
              );
              if (!gstinRegex.hasMatch(s)) {
                return 'Enter a valid 15-character GSTIN (e.g. 27ABCDE1234F2Z5)';
              }
              return null;
            },
          ),
        ],

        // Primary Contact — required for Business, optional for Warehouse
        const SizedBox(height: AppTheme.space20),
        _buildTextField(
          label: 'Primary Contact',
          required: _isBusiness,
          controller: _emailCtrl,
          hint: 'contact@example.com',
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final s = v?.trim() ?? '';
            if (_isBusiness && s.isEmpty) return 'Primary contact is required';
            if (s.isNotEmpty) {
              final emailRegex = RegExp(
                r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
              );
              if (!emailRegex.hasMatch(s)) return 'Enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLogoUploadArea() {
    final bool hasPicked = _logoPicked != null;
    final bool hasExisting = _logoUrl != null && _logoUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: _pickLogo,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: hasPicked
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.checkCircle,
                              size: 18,
                              color: AppTheme.successGreen,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _logoPicked!.name,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )
                    : hasExisting
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.image,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Logo uploaded — tap to change',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.upload,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Upload your Location Logo',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          const Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This logo will be displayed in transaction PDFs and email notifications.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Dimensions: 240 × 240 pixels @ 72 DPI',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                Text(
                  'Supported files: jpg, jpeg, png, gif, bmp',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                Text(
                  'Maximum file size: 1MB',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentDropdown({required bool required}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Parent Location', required: required),
        const SizedBox(height: AppTheme.space6),
        FormDropdown<_OutletOption>(
          value: _outlets.where((o) => o.id == _parentOutletId).firstOrNull,
          items: _outlets,
          displayStringForValue: (o) => o.name,
          hint: 'Select parent location',
          errorText: _parentError,
          onChanged: (o) => setState(() {
            _parentOutletId = o?.id;
            _parentError = null;
          }),
        ),
      ],
    );
  }

  // ─── Address section ───────────────────────────────────────────────────────

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Address'),
        const SizedBox(height: AppTheme.space12),
        _buildCard(
          children: [
            _buildTextField(
              label: 'Attention',
              controller: _attentionCtrl,
              hint: 'Attention',
            ),
            const SizedBox(height: AppTheme.space12),
            _buildTextField(
              label: 'Street',
              controller: _streetCtrl,
              hint: 'Street address',
            ),
            const SizedBox(height: AppTheme.space12),
            _buildTextField(label: 'City', controller: _cityCtrl, hint: 'City'),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('State / Union Territory'),
                      const SizedBox(height: AppTheme.space6),
                      FormDropdown<String>(
                        value: _selectedState,
                        items: _indianStates,
                        displayStringForValue: (s) => s,
                        hint: 'Select state',
                        onChanged: (v) => setState(() => _selectedState = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: _buildTextField(
                    label: 'Pin Code',
                    controller: _pincodeCtrl,
                    hint: '560001',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return null;
                      if (!RegExp(r'^\d{6}$').hasMatch(s)) {
                        return 'Enter a valid 6-digit pin code';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            _buildLabel('Country'),
            const SizedBox(height: AppTheme.space6),
            _buildStaticDropdown('India'),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Phone',
                    controller: _phoneCtrl,
                    hint: '+91 98765 43210',
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return null;
                      final digits = s.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
                      if (!RegExp(r'^\d{7,15}$').hasMatch(digits)) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: _buildTextField(
                    label: 'Fax Number',
                    controller: _faxCtrl,
                    hint: 'Fax number',
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return null;
                      final digits = s.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
                      if (!RegExp(r'^\d{7,15}$').hasMatch(digits)) {
                        return 'Enter a valid fax number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ─── Bottom fields ─────────────────────────────────────────────────────────

  Widget _buildBottomFields() {
    return _buildCard(
      children: [
        _buildTextField(
          label: 'Website URL',
          controller: _websiteCtrl,
          hint: 'https://example.com',
          keyboardType: TextInputType.url,
          validator: (v) {
            final s = v?.trim() ?? '';
            if (s.isEmpty) return null;
            if (!RegExp(r'^https?://').hasMatch(s)) {
              return 'URL must start with http:// or https://';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppTheme.textBody,
        ),
        children: required
            ? const <TextSpan>[
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildStaticDropdown(String value) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          const Icon(
            LucideIcons.chevronDown,
            size: 14,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: AppTheme.space6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space12,
              vertical: AppTheme.space10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildActions() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    return Row(
      children: [
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space28,
              vertical: AppTheme.space12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _isEditing ? 'Update' : 'Save',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(width: AppTheme.space12),
        OutlinedButton(
          onPressed: () => context.go(AppRoutes.settingsLocations),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space24,
              vertical: AppTheme.space12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textBody,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
