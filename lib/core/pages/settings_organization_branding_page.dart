import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

// TODO(auth): Remove _kDevOrgId fallback once auth is enabled.
const String _kDevOrgId = '00000000-0000-0000-0000-000000000002';

class SettingsOrganizationBrandingPage extends ConsumerStatefulWidget {
  const SettingsOrganizationBrandingPage({super.key});

  @override
  ConsumerState<SettingsOrganizationBrandingPage> createState() =>
      _SettingsOrganizationBrandingPageState();
}

class _SettingsOrganizationBrandingPageState
    extends ConsumerState<SettingsOrganizationBrandingPage> {
  static const List<_BrandingNavSection> _navSections =
      <_BrandingNavSection>[
        _BrandingNavSection(
          title: 'Organization Settings',
          blocks: <_BrandingNavBlock>[
            _BrandingNavBlock(
              title: 'Organization',
              items: <_BrandingNavEntry>[
                _BrandingNavEntry(
                  label: 'Profile',
                  route: AppRoutes.settingsOrgProfile,
                ),
                _BrandingNavEntry(
                  label: 'Branding',
                  route: AppRoutes.settingsOrgBranding,
                ),
                _BrandingNavEntry(label: 'Branches', route: AppRoutes.settingsBranches),
                _BrandingNavEntry(label: 'Warehouses', route: AppRoutes.settingsWarehouses),
                _BrandingNavEntry(label: 'Approvals'),
                _BrandingNavEntry(label: 'Manage Subscription'),
              ],
            ),
            _BrandingNavBlock(
              title: 'Users & Roles',
              items: <_BrandingNavEntry>[
                _BrandingNavEntry(label: 'Users'),
                _BrandingNavEntry(label: 'Roles'),
                _BrandingNavEntry(label: 'User Preferences'),
              ],
            ),
            _BrandingNavBlock(
              title: 'Taxes & Compliance',
              items: <_BrandingNavEntry>[
                _BrandingNavEntry(label: 'Taxes'),
                _BrandingNavEntry(label: 'Direct Taxes'),
                _BrandingNavEntry(label: 'e-Way Bills'),
                _BrandingNavEntry(label: 'e-Invoicing'),
                _BrandingNavEntry(label: 'MSME Settings'),
              ],
            ),
            _BrandingNavBlock(
              title: 'Setup & Configurations',
              items: <_BrandingNavEntry>[
                _BrandingNavEntry(label: 'General'),
                _BrandingNavEntry(label: 'Currencies'),
                _BrandingNavEntry(label: 'Reminders'),
                _BrandingNavEntry(label: 'Customer Portal'),
              ],
            ),
            _BrandingNavBlock(
              title: 'Customization',
              items: <_BrandingNavEntry>[
                _BrandingNavEntry(label: 'Transaction Number Series'),
                _BrandingNavEntry(label: 'PDF Templates'),
                _BrandingNavEntry(label: 'Email Notifications'),
                _BrandingNavEntry(label: 'SMS Notifications'),
                _BrandingNavEntry(label: 'Reporting Tags'),
                _BrandingNavEntry(label: 'Web Tabs'),
              ],
            ),
            _BrandingNavBlock(
              title: 'Automation',
              items: <_BrandingNavEntry>[
                _BrandingNavEntry(label: 'Workflow Rules'),
                _BrandingNavEntry(label: 'Workflow Actions'),
                _BrandingNavEntry(
                  label: 'Workflow Logs',
                  route: AppRoutes.auditLogs,
                ),
              ],
            ),
          ],
        ),
        _BrandingNavSection(
          title: 'Module Settings',
          blocks: <_BrandingNavBlock>[
            _BrandingNavBlock(
              title: 'General',
              items: <_BrandingNavEntry>[
                _BrandingNavEntry(
                  label: 'Customers and Vendors',
                  route: AppRoutes.salesCustomers,
                ),
                _BrandingNavEntry(
                  label: 'Items',
                  route: AppRoutes.itemsReport,
                ),
              ],
            ),
            _BrandingNavBlock(
              title: 'Inventory',
              items: <_BrandingNavEntry>[
                _BrandingNavEntry(
                  label: 'Assemblies',
                  route: AppRoutes.assemblies,
                ),
                _BrandingNavEntry(
                  label: 'Inventory Adjustments',
                  route: AppRoutes.inventoryAdjustments,
                ),
                _BrandingNavEntry(
                  label: 'Picklists',
                  route: AppRoutes.picklists,
                ),
                _BrandingNavEntry(
                  label: 'Packages',
                  route: AppRoutes.packages,
                ),
                _BrandingNavEntry(
                  label: 'Shipments',
                  route: AppRoutes.shipments,
                ),
                _BrandingNavEntry(
                  label: 'Transfer Orders',
                  route: AppRoutes.transferOrders,
                ),
              ],
            ),
          ],
        ),
      ];

  static const SweepGradient _kRainbowGradient = SweepGradient(
    colors: [
      Color(0xFFFF0000),
      Color(0xFFFFFF00),
      Color(0xFF00FF00),
      Color(0xFF00FFFF),
      Color(0xFF0000FF),
      Color(0xFFFF00FF),
      Color(0xFFFF0000),
    ],
  );

  static const List<_AccentOption> _accentOptions = <_AccentOption>[
    _AccentOption(label: 'Green', color: Color(0xFF22A95E)),
    _AccentOption(label: 'Blue', color: Color(0xFF3B82F6)),
    _AccentOption(label: 'Purple', color: Color(0xFF8B5CF6)),
    _AccentOption(label: 'Red', color: Color(0xFFEF4444)),
    _AccentOption(label: 'Orange', color: Color(0xFFF97316)),
  ];

  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _expandedBlocks = <String>{'Organization'};

  bool _isLoading = true;
  String? _error;
  String _organizationName = '';
  String? _existingLogoUrl;
  Uint8List? _logoBytes;
  String? _logoFileName;
  bool _isUploadingLogo = false;
  bool _isRemovingLogo = false;
  bool _isSaving = false;

  String _selectedAppearance = 'dark';
  Color _selectedAccentColor = const Color(0xFF22A95E);

  bool get _isDarkPane => _selectedAppearance != 'light';

  @override
  void initState() {
    super.initState();
    _loadBranding();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadBranding() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = ref.read(authUserProvider);
      final String orgId =
          (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final Response<dynamic>? res = await _safeGet(
        '/lookups/org/$orgId',
        useCache: false,
      );
      final Map<String, dynamic> data =
          res != null && res.success && res.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(res.data as Map<String, dynamic>)
          : <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _organizationName =
            (data['name'] ?? user?.orgName ?? '').toString().trim();
        final String logoUrl = (data['logo_url'] ?? '').toString().trim();
        _existingLogoUrl = logoUrl.isEmpty ? null : logoUrl;
        _selectedAppearance =
            (data['theme_mode'] ?? 'dark').toString();
        final String hex =
            (data['accent_color'] ?? '#22A95E').toString().replaceAll('#', '');
        final int? colorVal = int.tryParse('FF$hex', radix: 16);
        if (colorVal != null) _selectedAccentColor = Color(colorVal);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Response<dynamic>?> _safeGet(
    String path, {
    bool useCache = false,
  }) async {
    try {
      return await _apiClient.get(path, useCache: useCache);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickLogo() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final PlatformFile file = result.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null) return;

    if (!kIsWeb) {
      final List<int>? compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 80,
        minWidth: 480,
        minHeight: 480,
      );
      if (compressed != null) bytes = Uint8List.fromList(compressed);
    }

    setState(() {
      _logoBytes = bytes;
      _logoFileName = file.name;
    });
  }

  Future<void> _uploadLogo() async {
    if (_logoBytes == null || _logoFileName == null) return;
    setState(() => _isUploadingLogo = true);
    try {
      final user = ref.read(authUserProvider);
      final String orgId =
          (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'file': MultipartFile.fromBytes(
          _logoBytes!,
          filename: _logoFileName,
        ),
      });
      final Response<dynamic> res = await _apiClient.post(
        '/org/$orgId/logo',
        data: formData,
      );
      if (!mounted) return;
      if (res.success && res.data is Map) {
        final String newUrl =
            ((res.data as Map)['logo_url'] ?? '').toString().trim();
        setState(() {
          _existingLogoUrl = newUrl.isEmpty ? null : newUrl;
          _logoBytes = null;
          _logoFileName = null;
        });
        ZerpaiToast.success(context, 'Logo updated successfully');
      } else {
        ZerpaiToast.error(context, 'Failed to upload logo');
      }
    } catch (e) {
      if (mounted) ZerpaiToast.error(context, 'Logo upload failed');
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _removeLogo() async {
    setState(() => _isRemovingLogo = true);
    try {
      final user = ref.read(authUserProvider);
      final String orgId =
          (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final Response<dynamic> res = await _apiClient.delete('/org/$orgId/logo');
      if (!mounted) return;
      if (res.success) {
        setState(() {
          _existingLogoUrl = null;
          _logoBytes = null;
          _logoFileName = null;
        });
        ZerpaiToast.success(context, 'Logo removed');
      } else {
        ZerpaiToast.error(context, 'Failed to remove logo');
      }
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to remove logo');
    } finally {
      if (mounted) setState(() => _isRemovingLogo = false);
    }
  }

  Future<void> _saveBranding() async {
    setState(() => _isSaving = true);
    try {
      final user = ref.read(authUserProvider);
      final String orgId =
          (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final String accentHex =
          '#${_selectedAccentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      await _apiClient.post(
        '/lookups/org/$orgId/branding',
        data: <String, dynamic>{
          'accent_color': accentHex,
          'theme_mode': _selectedAppearance,
          'keep_branding': false,
        },
      );
      if (!mounted) return;
      ZerpaiToast.success(context, 'Branding saved.');
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to save branding.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openEntry(_BrandingNavEntry entry) {
    if (entry.route == null) {
      ZerpaiToast.info(context, '${entry.label} is not available yet');
      return;
    }
    context.go(entry.route!);
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

  // ─── Top bar ────────────────────────────────────────────────────────────────

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
                                Text(
                                  'All Settings',
                                  style: AppTheme.pageTitle,
                                ),
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
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      items: const <SettingsSearchItem>[],
                      onNoMatch: (_) {},
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space24),
              TextButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go(AppRoutes.home);
                },
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

  // ─── Sidebar ─────────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
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
            for (final block in section.blocks) _buildSidebarBlock(block),
            const SizedBox(height: AppTheme.space12),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarBlock(_BrandingNavBlock block) {
    final String currentPath = GoRouterState.of(
      context,
    ).uri.path.replaceFirst(RegExp(r'^/\d{10,20}'), '');
    final bool hasActiveChild =
        block.items.any((item) => item.route == currentPath);
    final bool isExpanded =
        _expandedBlocks.contains(block.title) || hasActiveChild;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedBlocks.remove(block.title);
                } else {
                  _expandedBlocks.add(block.title);
                }
              });
            },
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
                    .map((entry) => _buildSidebarEntry(entry, currentPath))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarEntry(_BrandingNavEntry entry, String currentPath) {
    final bool isActive = entry.route == currentPath;
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;

    return InkWell(
      onTap: () => _openEntry(entry),
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
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.label,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: isActive ? Colors.white : AppTheme.textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(AppTheme.space24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                color: AppTheme.warningOrange,
                size: 28,
              ),
              const SizedBox(height: AppTheme.space12),
              Text('Unable to load branding', style: AppTheme.sectionHeader),
              const SizedBox(height: AppTheme.space8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              ElevatedButton(
                onPressed: _loadBranding,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Branding', style: AppTheme.pageTitle),
                              const SizedBox(height: AppTheme.space4),
                              Text(
                                'Customize how Zerpai looks and feels for your organization.',
                                style: AppTheme.bodyText.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space24),
                    _buildLogoSection(),
                    const SizedBox(height: AppTheme.space24),
                    _buildAppearanceSection(),
                    const SizedBox(height: AppTheme.space24),
                    _buildAccentColorSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space20,
            vertical: AppTheme.space16,
          ),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: _isSaving ? null : _saveBranding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ref.watch(appBrandingProvider).accentColor,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
              const SizedBox(width: AppTheme.space12),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.settings),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Logo section ─────────────────────────────────────────────────────────

  Widget _buildLogoSection() {
    return _SectionCard(
      title: 'Organization Logo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This logo will be displayed in transaction PDFs and email notifications.',
            style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.space20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo preview
              Container(
                width: 160,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.borderLight,
                    style: BorderStyle.solid,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildLogoPreview(),
              ),
              const SizedBox(width: AppTheme.space24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferred Image Dimensions: 240 × 240 pixels @ 72 DPI',
                      style: AppTheme.captionText.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Supported Files: jpg, jpeg, png, gif, bmp',
                      style: AppTheme.captionText.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Maximum File Size: 1MB',
                      style: AppTheme.captionText.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed:
                              _isUploadingLogo ? null : _pickAndUploadLogo,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(
                              color: AppTheme.borderMid,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space16,
                              vertical: AppTheme.space10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: _isUploadingLogo
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(LucideIcons.upload, size: 15),
                          label: Text(
                            _existingLogoUrl != null || _logoBytes != null
                                ? 'Change Logo'
                                : 'Upload Logo',
                          ),
                        ),
                        if (_existingLogoUrl != null || _logoBytes != null) ...[
                          const SizedBox(width: AppTheme.space12),
                          TextButton(
                            onPressed:
                                (_isRemovingLogo || _isUploadingLogo)
                                ? null
                                : (_logoBytes != null
                                      ? _clearLocalLogo
                                      : _removeLogo),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.errorRed,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space12,
                                vertical: AppTheme.space10,
                              ),
                            ),
                            child: _isRemovingLogo
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Remove Logo'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPreview() {
    if (_logoBytes != null) {
      return Image.memory(_logoBytes!, fit: BoxFit.contain);
    }
    if (_existingLogoUrl != null) {
      return Image.network(
        _existingLogoUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(LucideIcons.image, size: 32, color: AppTheme.textMuted),
        ),
      );
    }
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.image, size: 28, color: AppTheme.textMuted),
          SizedBox(height: 6),
          Text(
            'No logo',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadLogo() async {
    await _pickLogo();
    if (_logoBytes != null) await _uploadLogo();
  }

  void _clearLocalLogo() {
    setState(() {
      _logoBytes = null;
      _logoFileName = null;
    });
  }

  // ─── Appearance section ───────────────────────────────────────────────────

  Widget _buildAppearanceSection() {
    return _SectionCard(
      title: 'Appearance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose how the sidebar looks for all users in your organization.',
            style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.space20),
          Row(
            children: [
              _buildAppearanceCard(
                key: 'dark',
                label: 'Dark Pane',
                sidebarColor: const Color(0xFF1F2633),
                contentColor: const Color(0xFFF9FAFB),
              ),
              const SizedBox(width: AppTheme.space16),
              _buildAppearanceCard(
                key: 'light',
                label: 'Light Pane',
                sidebarColor: const Color(0xFFF3F4F6),
                contentColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard({
    required String key,
    required String label,
    required Color sidebarColor,
    required Color contentColor,
  }) {
    final bool isSelected = _selectedAppearance == key;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedAppearance = key);
        ref.read(appBrandingProvider.notifier).apply(
          accentColor: _selectedAccentColor,
          isDarkPane: key != 'light',
        );
      },
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _selectedAccentColor
                : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Mini mockup
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: contentColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        color: sidebarColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 3,
                                horizontal: 6,
                              ),
                              height: 6,
                              decoration: BoxDecoration(
                                color: sidebarColor == const Color(0xFF1F2633)
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 8,
                                width: 60,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.black.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 6,
                                width: 40,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.black.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Moon / Sun overlay icon
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Icon(
                      key == 'dark' ? LucideIcons.moon : LucideIcons.sun,
                      size: 18,
                      color: key == 'dark'
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
            // Label row
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? _selectedAccentColor.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
                border: const Border(
                  top: BorderSide(color: AppTheme.borderLight),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    Icon(
                      LucideIcons.check,
                      size: 13,
                      color: _selectedAccentColor,
                    ),
                  if (isSelected) const SizedBox(width: 5),
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? _selectedAccentColor
                          : AppTheme.textSecondary,
                      letterSpacing: 0.5,
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

  // ─── Accent color section ─────────────────────────────────────────────────

  Widget _buildAccentColorSection() {
    return _SectionCard(
      title: 'Accent Color',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose the primary accent color used for buttons and active states.',
            style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.space20),
          Wrap(
            spacing: AppTheme.space12,
            runSpacing: AppTheme.space12,
            children: [
              ..._accentOptions.map((option) => _buildAccentSwatch(option)),
              _buildCustomColorSwatch(),
            ],
          ),
          if (_selectedAccentColor.computeLuminance() < 0.15) ...[
            const SizedBox(height: AppTheme.space16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    size: 16,
                    color: Color(0xFFF97316),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      'Consider selecting a lighter accent color to improve the readability of low-contrast text.',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwatchShell({
    required Color bgColor,
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
    Border? unselectedBorder,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 80,
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : unselectedBorder,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.3),
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            child,
            if (isSelected)
              const Positioned(
                top: 4,
                right: 6,
                child: Icon(LucideIcons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccentSwatch(_AccentOption option) {
    final bool isSelected = _selectedAccentColor == option.color;
    return _buildSwatchShell(
      bgColor: option.color,
      isSelected: isSelected,
      onTap: () {
        setState(() => _selectedAccentColor = option.color);
        ref.read(appBrandingProvider.notifier).apply(
          accentColor: option.color,
          isDarkPane: _isDarkPane,
        );
      },
      child: Text(
        option.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCustomColorSwatch() {
    final bool isCustom =
        !_accentOptions.any((o) => o.color == _selectedAccentColor);
    return _buildSwatchShell(
      bgColor: isCustom ? _selectedAccentColor : Colors.white,
      isSelected: isCustom,
      onTap: _openCustomColorPicker,
      unselectedBorder: Border.all(color: AppTheme.borderLight),
      child: isCustom
          ? const Text(
              'Custom',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _kRainbowGradient,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Pick',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }

  String _colorToHex(Color c) =>
      c.toARGB32().toRadixString(16).substring(2).toUpperCase();

  void _openCustomColorPicker() {
    Color tempColor = _selectedAccentColor;
    bool showSwatches = false;
    final hexCtrl = TextEditingController(text: '#${_colorToHex(tempColor)}');

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void applyHex(String val) {
            final clean = val.replaceAll('#', '').trim();
            if (clean.length == 6) {
              final colorVal = int.tryParse('FF$clean', radix: 16);
              if (colorVal != null) {
                setDialogState(() {
                  tempColor = Color(colorVal);
                });
              }
            }
          }

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 8,
            child: SizedBox(
              width: 360,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showSwatches) ...[
                      GestureDetector(
                        onTap: () =>
                            setDialogState(() => showSwatches = false),
                        child: const Row(
                          children: [
                            Icon(
                              LucideIcons.chevronLeft,
                              size: 15,
                              color: AppTheme.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      BlockPicker(
                        pickerColor: tempColor,
                        onColorChanged: (c) {
                          setDialogState(() {
                            tempColor = c;
                            hexCtrl.text = '#${_colorToHex(c)}';
                            showSwatches = false;
                          });
                        },
                        itemBuilder: (color, isSelected, onTap) =>
                            GestureDetector(
                          onTap: onTap,
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ] else ...[
                      ColorPicker(
                        pickerColor: tempColor,
                        onColorChanged: (c) {
                          setDialogState(() {
                            tempColor = c;
                            hexCtrl.text = '#${_colorToHex(c)}';
                          });
                        },
                        enableAlpha: false,
                        labelTypes: const [],
                        pickerAreaHeightPercent: 0.65,
                        displayThumbColor: true,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: hexCtrl,
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                              onSubmitted: applyHex,
                              onChanged: applyHex,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 38,
                            height: 36,
                            decoration: BoxDecoration(
                              color: tempColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () =>
                            setDialogState(() => showSwatches = true),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _kRainbowGradient,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Swatches',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const Icon(
                              LucideIcons.chevronRight,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tempColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              setState(() => _selectedAccentColor = tempColor);
                              ref
                                  .read(appBrandingProvider.notifier)
                                  .apply(
                                    accentColor: tempColor,
                                    isDarkPane: _isDarkPane,
                                  );
                            },
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).then((_) => hexCtrl.dispose());
  }
}

// ─── Section card wrapper ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.sectionHeader.copyWith(fontSize: 15),
          ),
          const SizedBox(height: AppTheme.space16),
          const Divider(color: AppTheme.borderLight, height: 1),
          const SizedBox(height: AppTheme.space20),
          child,
        ],
      ),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────

class _BrandingNavSection {
  final String title;
  final List<_BrandingNavBlock> blocks;
  const _BrandingNavSection({required this.title, required this.blocks});
}

class _BrandingNavBlock {
  final String title;
  final List<_BrandingNavEntry> items;
  const _BrandingNavBlock({required this.title, required this.items});
}

class _BrandingNavEntry {
  final String label;
  final String? route;
  const _BrandingNavEntry({required this.label, this.route});
}

class _AccentOption {
  final String label;
  final Color color;
  const _AccentOption({required this.label, required this.color});
}
