// ignore_for_file: unused_element, unused_field

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

enum _AppearanceMode { dark, light }

class SettingsBrandingPage extends ConsumerStatefulWidget {
  const SettingsBrandingPage({super.key});

  @override
  ConsumerState<SettingsBrandingPage> createState() =>
      _SettingsBrandingPageState();
}

class _SettingsBrandingPageState extends ConsumerState<SettingsBrandingPage> {
  static const List<_BrandingNavSection> _navSections = <_BrandingNavSection>[
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
            _BrandingNavEntry(label: 'Items', route: AppRoutes.itemsReport),
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
          ],
        ),
      ],
    ),
  ];

  static const List<Color> _presetAccentColors = <Color>[
    Color(0xFF3B82F6), // Blue
    Color(0xFF22A95E), // Green (default)
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
  ];

  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _expandedBlocks = <String>{'Organization'};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  String _organizationName = '';
  String _orgId = '';

  // Logo
  Uint8List? _logoBytes;
  String? _existingLogoUrl;

  // Appearance
  _AppearanceMode _selectedAppearance = _AppearanceMode.dark;

  // Accent color — null means custom (not a preset)
  Color _selectedAccentColor = const Color(0xFF22A95E);

  // Branding toggle
  bool _keepZerpaiBranding = false;

  @override
  void initState() {
    super.initState();
    _loadBranding();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String get _effectiveOrgId {
    final user = ref.read(authUserProvider);
    return user?.orgId.trim() ?? '';
  }

  Future<void> _loadBranding() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authUserProvider);
      final String orgId = _effectiveOrgId;
      if (orgId.isEmpty) {
        if (mounted) {
          setState(() => _organizationName = user?.orgName.trim() ?? '');
        }
        return;
      }
      _orgId = orgId;

      final res = await _apiClient.get('/lookups/org/$orgId', useCache: false);

      if (!mounted) return;

      final Map<String, dynamic> data =
          res.success && res.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(res.data as Map<String, dynamic>)
          : <String, dynamic>{};

      setState(() {
        _organizationName =
            (data['name'] ?? user?.orgName ?? '').toString().trim();
        final String logoUrl = (data['logo_url'] ?? '').toString().trim();
        _existingLogoUrl = logoUrl.isEmpty ? null : logoUrl;

        final String accentHex = (data['accent_color'] ?? '').toString().trim();
        if (accentHex.isNotEmpty) {
          try {
            _selectedAccentColor = Color(
              int.parse(accentHex.replaceFirst('#', '0xFF')),
            );
          } catch (_) {}
        }

        final String themeMode =
            (data['theme_mode'] ?? 'dark').toString().toLowerCase();
        _selectedAppearance = themeMode == 'light'
            ? _AppearanceMode.light
            : _AppearanceMode.dark;

        _keepZerpaiBranding = data['keep_branding'] == true;
      });

      // Apply to the live branding provider immediately so the sidebar
      // reflects the saved settings as soon as the page loads.
      ref.read(appBrandingProvider.notifier).apply(
            accentColor: _selectedAccentColor,
            isDarkPane: _selectedAppearance == _AppearanceMode.dark,
          );
    } catch (_) {
      if (mounted) {
        final user = ref.read(authUserProvider);
        setState(() => _organizationName = user?.orgName.trim() ?? '');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBranding() async {
    final String orgId = _orgId.isNotEmpty ? _orgId : _effectiveOrgId;
    if (orgId.isEmpty) {
      if (mounted) {
        ZerpaiToast.error(
          context,
          'Organization context is missing. Please sign in again.',
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final String accentHex =
          '#${_selectedAccentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      await _apiClient.post(
        '/lookups/org/$orgId/branding',
        data: <String, dynamic>{
          'accent_color': accentHex,
          'theme_mode': _selectedAppearance == _AppearanceMode.dark
              ? 'dark'
              : 'light',
          'keep_branding': _keepZerpaiBranding,
        },
      );
      if (mounted) ZerpaiToast.success(context, 'Branding settings saved');
    } catch (_) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to save branding settings');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickLogo() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final PlatformFile file = result.files.first;
    if (file.bytes == null) return;

    if (file.bytes!.lengthInBytes > 1 * 1024 * 1024) {
      if (mounted) {
        ZerpaiToast.error(
          context,
          'Logo file must not exceed 1 MB. Please choose a smaller image.',
        );
      }
      return;
    }

    final String ext = (file.extension ?? 'jpg').toLowerCase();
    CompressFormat? format;
    if (ext == 'png') format = CompressFormat.png;
    if (ext == 'webp') format = CompressFormat.webp;
    if (ext == 'jpg' || ext == 'jpeg') format = CompressFormat.jpeg;

    Uint8List bytes = file.bytes!;
    if (!kIsWeb && format != null && bytes.lengthInBytes > 200 * 1024) {
      bytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 240,
        minHeight: 240,
        quality: 85,
        format: format,
      );
    }

    if (!mounted) return;
    setState(() => _logoBytes = bytes);

    await _uploadLogo(bytes, file.name);
  }

  Future<void> _uploadLogo(Uint8List bytes, String fileName) async {
    final String orgId = _orgId.isNotEmpty ? _orgId : _effectiveOrgId;
    if (orgId.isEmpty) {
      if (mounted) {
        ZerpaiToast.error(
          context,
          'Organization context is missing. Please sign in again.',
        );
      }
      return;
    }

    setState(() => _isUploadingLogo = true);
    try {
      final String base64 = Uri.dataFromBytes(bytes).toString();
      await _apiClient.post(
        '/lookups/org/$orgId/logo',
        data: <String, dynamic>{'logo_data': base64, 'file_name': fileName},
      );
      if (mounted) ZerpaiToast.success(context, 'Logo uploaded successfully');
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to upload logo');
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  void _removeLogo() {
    setState(() {
      _logoBytes = null;
      _existingLogoUrl = null;
    });
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'All Settings',
                                  style: AppTheme.pageTitle.copyWith(
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  _organizationName.isEmpty
                                      ? 'Your Organization'
                                      : _organizationName,
                                  style: AppTheme.bodyText.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
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
                child: SizedBox(
                  height: 44,
                  child: SettingsSearchField(
                    items: const <SettingsSearchItem>[],
                    focusNode: _searchFocusNode,
                    controller: _searchController,
                    onQueryChanged: (_) {},
                    onNoMatch: (_) {},
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
                icon: const Icon(LucideIcons.x, size: 16, color: AppTheme.errorRed),
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

  Widget _buildSidebarBlock(_BrandingNavBlock block, String currentPath) {
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
    final Color activeColor = ref.watch(appBrandingProvider).accentColor;

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
          color: isActive ? activeColor : Colors.transparent,
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

  Widget _buildBody() {
    return Skeletonizer(
      enabled: _isLoading,
      ignoreContainers: true,
      child: _isLoading ? const ZFormSkeleton(rows: 20) : _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space32,
              AppTheme.space28,
              AppTheme.space32,
              AppTheme.space24,
            ),
            child: SizedBox(
              width: 620,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo ──────────────────────────────────────────
                  Text('Organization Logo', style: AppTheme.sectionHeader),
                  const SizedBox(height: AppTheme.space16),
                  Container(
                    color: Colors.white,
                    child: _buildLogoSection(),
                  ),
                  const SizedBox(height: AppTheme.space28),

                  // ── Appearance ────────────────────────────────────
                  Text('Appearance', style: AppTheme.sectionHeader),
                  const SizedBox(height: AppTheme.space16),
                  Row(
                    children: [
                      _buildAppearanceTile(
                        mode: _AppearanceMode.dark,
                        label: 'Dark Pane',
                      ),
                      const SizedBox(width: AppTheme.space16),
                      _buildAppearanceTile(
                        mode: _AppearanceMode.light,
                        label: 'Light Pane',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space28),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  const SizedBox(height: AppTheme.space28),

                  // ── Accent Color ──────────────────────────────────
                  Text('Accent Color', style: AppTheme.sectionHeader),
                  const SizedBox(height: AppTheme.space16),
                  Wrap(
                    spacing: AppTheme.space12,
                    runSpacing: AppTheme.space12,
                    children: [
                      ..._presetAccentColors.map(_buildColorSwatch),
                      _buildCustomColorSwatch(),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space16),
                  _buildAccentColorNote(),
                  const SizedBox(height: AppTheme.space28),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  const SizedBox(height: AppTheme.space28),

                  // ── Keep Branding ─────────────────────────────────
                  _buildBrandingToggle(),
                  const SizedBox(height: AppTheme.space24),
                ],
              ),
            ),
          ),
        ),

        // ── Fixed bottom bar ──────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.borderLight)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space32,
            vertical: AppTheme.space16,
          ),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: _isSaving ? null : _saveBranding,
                style: ElevatedButton.styleFrom(
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

  // ---------------------------------------------------------------------------
  // Logo section
  // ---------------------------------------------------------------------------

  Widget _buildLogoSection() {
    final bool hasLogo = _logoBytes != null || _existingLogoUrl != null;

    Widget imageChild;
    if (_isUploadingLogo) {
      imageChild = const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_logoBytes != null) {
      imageChild = ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.memory(
          _logoBytes!,
          fit: BoxFit.contain,
          width: 250,
          height: 96,
        ),
      );
    } else if (_existingLogoUrl != null) {
      imageChild = ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.network(
          _existingLogoUrl!,
          fit: BoxFit.contain,
          width: 250,
          height: 96,
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.imageOff,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'Logo unavailable',
                  style: AppTheme.captionText.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      imageChild = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.upload, color: AppTheme.textSecondary, size: 20),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Click to upload logo',
            style: AppTheme.captionText.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            SizedBox(
              width: 250,
              height: 96,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DashedBorderPainter(
                        color: AppTheme.borderColor,
                        radius: 6,
                      ),
                      child: InkWell(
                        onTap: _isUploadingLogo ? null : _pickLogo,
                        borderRadius: BorderRadius.circular(6),
                        child: Center(child: imageChild),
                      ),
                    ),
                  ),
                  if (hasLogo && !_isUploadingLogo)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: GestureDetector(
                        onTap: _removeLogo,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: const Icon(
                            LucideIcons.trash2,
                            size: 13,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.space20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This logo will be displayed in transaction PDFs and email notifications.',
                    style: AppTheme.bodyText,
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Preferred image dimensions: 240 × 240 pixels @ 72 DPI',
                    style: AppTheme.captionText.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Supported files: jpg, jpeg, png, gif, bmp',
                    style: AppTheme.captionText.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Maximum file size: 1 MB',
                    style: AppTheme.captionText.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (hasLogo && !_isUploadingLogo) ...[
                    const SizedBox(height: AppTheme.space10),
                    GestureDetector(
                      onTap: _removeLogo,
                      child: Text(
                        'Remove Logo',
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.primaryBlue,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildAppearanceTile({
    required _AppearanceMode mode,
    required String label,
  }) {
    final bool isSelected = _selectedAppearance == mode;
    final bool isDark = mode == _AppearanceMode.dark;
    final Color accent = _selectedAccentColor;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedAppearance = mode);
        ref
            .read(appBrandingProvider.notifier)
            .setDarkPane(mode == _AppearanceMode.dark);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 160,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Row(
            children: [
              // Sidebar preview
              Container(
                width: 36,
                color: isDark ? const Color(0xFF2C3E50) : Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 3,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 3,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 3,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              // Content preview
              Expanded(
                child: Container(
                  color: isDark ? const Color(0xFFF8F9FA) : Colors.white,
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isDark ? LucideIcons.moon : LucideIcons.sun,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: AppTheme.captionText.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSwatch(Color color) {
    final bool isSelected = _selectedAccentColor == color;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedAccentColor = color);
        ref.read(appBrandingProvider.notifier).setAccentColor(color);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 64,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(LucideIcons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }

  Widget _buildCustomColorSwatch() {
    final bool isCustom = !_presetAccentColors.contains(_selectedAccentColor);

    return GestureDetector(
      onTap: () async {
        // Show a simple color picker dialog
        await showDialog<void>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.4),
          builder: (ctx) => _CustomColorDialog(
            initialColor: _selectedAccentColor,
            onColorSelected: (color) {
              setState(() => _selectedAccentColor = color);
              ref.read(appBrandingProvider.notifier).setAccentColor(color);
            },
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 64,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[
              Color(0xFFEF4444),
              Color(0xFF8B5CF6),
              Color(0xFF3B82F6),
              Color(0xFF22A95E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: isCustom
              ? Border.all(color: Colors.white, width: 2)
              : null,
          boxShadow: isCustom
              ? [
                  BoxShadow(
                    color: _selectedAccentColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: const Icon(LucideIcons.pipette, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildAccentColorNote() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.infoBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.info,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: AppTheme.space10),
          Expanded(
            child: Text(
              'These preferences will be applied to this organization across '
              'transaction PDFs, customer portal, and email notifications.',
              style: AppTheme.captionText.copyWith(
                color: AppTheme.primaryBlue,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Branding toggle
  // ---------------------------------------------------------------------------

  Widget _buildBrandingToggle() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "I'd like to keep Zerpai branding for this organization",
                  style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Switch.adaptive(
                value: _keepZerpaiBranding,
                activeThumbColor: AppTheme.accentGreen,
                onChanged: (value) =>
                    setState(() => _keepZerpaiBranding = value),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Retain non-obtrusive Zerpai branding, which will be visible to your '
            'customers in places like transactional emails and PDFs.',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom color picker dialog
// ---------------------------------------------------------------------------

class _CustomColorDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const _CustomColorDialog({
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late Color _selected;
  final TextEditingController _hexController = TextEditingController();

  static const List<Color> _palette = <Color>[
    Color(0xFF3B82F6),
    Color(0xFF22A95E),
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialColor;
    _hexController.text =
        '#${_selected.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _applyHex(String value) {
    try {
      final String cleaned = value.replaceFirst('#', '');
      if (cleaned.length == 6) {
        setState(() {
          _selected = Color(int.parse('0xFF$cleaned'));
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 320,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Custom Accent Color', style: AppTheme.sectionHeader),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, size: 18),
                    color: AppTheme.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space16),
              // Preview
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _selected,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              // Palette grid
              Wrap(
                spacing: AppTheme.space10,
                runSpacing: AppTheme.space10,
                children: _palette.map((color) {
                  final bool isSelected = _selected == color;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selected = color;
                        _hexController.text =
                            '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              LucideIcons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.space16),
              // Hex input
              TextField(
                controller: _hexController,
                decoration: InputDecoration(
                  labelText: 'Hex color code',
                  hintText: '#22A95E',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(10),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _selected,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                onChanged: _applyHex,
              ),
              const SizedBox(height: AppTheme.space20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onColorSelected(_selected);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Dashed border painter
// ---------------------------------------------------------------------------

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  static const double _dashWidth = 5;
  static const double _dashSpace = 4;
  static const double _strokeWidth = 1.2;

  const _DashedBorderPainter({
    this.color = const Color(0xFFD1D5DB),
    this.radius = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final Path extracted = metric.extractPath(
          distance,
          distance + _dashWidth,
        );
        canvas.drawPath(extracted, paint);
        distance += _dashWidth + _dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
