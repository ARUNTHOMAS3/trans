import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/auth/services/permission_service.dart';
import 'package:zerpai_erp/shared/widgets/settings_fixed_header_layout.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class SettingsBranchProfilePage extends ConsumerStatefulWidget {
  const SettingsBranchProfilePage({super.key, required this.branchId});

  final String branchId;

  @override
  ConsumerState<SettingsBranchProfilePage> createState() =>
      _SettingsBranchProfilePageState();
}

class _SettingsBranchProfilePageState
    extends ConsumerState<SettingsBranchProfilePage> {
  final ApiClient _apiClient = ApiClient();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _branch;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBranch();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBranch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _apiClient.get('branches/${widget.branchId}');
      if (!mounted) return;
      if (response.success && response.data is Map<String, dynamic>) {
        setState(() {
          _branch = Map<String, dynamic>.from(response.data as Map);
          _loading = false;
        });
        return;
      }
      setState(() {
        _error = 'Unable to load branch profile.';
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
                  SettingsNavigationSidebar(
                    currentPath: GoRouterState.of(context).uri.path,
                  ),
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
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '0000000000';
    final user = ref.watch(authUserProvider);
    final canEdit =
        user != null &&
        PermissionService.hasModuleAction(user, 'branches', action: 'edit');

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
                      onTap: () =>
                          context.go('/$orgSystemId/settings/branches'),
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
                                  ref.watch(authUserProvider)?.orgName
                                              .isNotEmpty ==
                                          true
                                      ? ref.watch(authUserProvider)!.orgName
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
                      onNoMatch: (q) {},
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space24),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : _loadBranch,
                icon: const Icon(LucideIcons.refreshCcw, size: 18),
              ),
              if (canEdit) ...[
                const SizedBox(width: AppTheme.space8),
                TextButton.icon(
                  onPressed: () => context.go(
                    '/$orgSystemId/settings/branches/${widget.branchId}/edit',
                  ),
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: AppTheme.space8),
              ],
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
    final d = _branch ?? const <String, dynamic>{};
    final branchName = (d['name'] ?? 'Branch').toString();

    return SettingsFixedHeaderLayout(
      maxWidth: double.infinity,
      headerPadding: const EdgeInsets.fromLTRB(
        AppTheme.space32,
        AppTheme.space24,
        AppTheme.space32,
        AppTheme.space16,
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        AppTheme.space32,
        0,
        AppTheme.space32,
        AppTheme.space32,
      ),
      header: _buildHeader(d, branchName),
      body: _buildContent(d),
    );
  }

  Widget _buildHeader(Map<String, dynamic> d, String branchName) {
    final isActive = d['is_active'] as bool? ?? true;
    final logoUrl = (d['logo_url'] ?? '').toString().trim();
    final hasLogo = logoUrl.isNotEmpty && logoUrl != 'null';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderLight),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasLogo
              ? Image.network(
                  logoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    LucideIcons.building2,
                    size: 24,
                    color: AppTheme.textMuted,
                  ),
                )
              : const Icon(
                  LucideIcons.building2,
                  size: 24,
                  color: AppTheme.textMuted,
                ),
        ),
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.accentGreen : Colors.transparent,
            border: Border.all(
              color: isActive ? AppTheme.accentGreen : AppTheme.textSecondary,
              width: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(branchName, style: AppTheme.pageTitle.copyWith(fontSize: 20)),
              const SizedBox(height: 2),
              Text(
                [
                  if ((d['branch_type'] ?? '').toString().isNotEmpty)
                    d['branch_type'].toString(),
                  if ((d['system_id'] ?? '').toString().isNotEmpty)
                    'ID: ${d['system_id']}',
                ].join(' · '),
                style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(Map<String, dynamic> d) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1100;
        final leftPanel = _buildLeftPanel(d);
        final rightPanel = _buildRightPanel(d);
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [rightPanel, const SizedBox(height: 32), leftPanel],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: leftPanel),
            const SizedBox(width: 60),
            Expanded(flex: 4, child: rightPanel),
          ],
        );
      },
    );
  }

  Widget _buildLeftPanel(Map<String, dynamic> d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Basic Information'),
        _buildInfoContent([
          _buildInfoRow('System ID', _tv(d['system_id'])),
          _buildInfoRow('Branch Code', _tv(d['branch_code'])),
          _buildInfoRow('Branch Type', _tv(d['branch_type'])),
          _buildInfoRow('Industry', _tv(d['industry'])),
          _buildInfoRow('Registered On', _tv(_formatDate(d['created_at']))),
          _buildInfoRow('Email', _tv(d['email'])),
          _buildInfoRow('Phone', _tv(d['phone'])),
          _buildInfoRow('Website', _tv(d['website'])),
          _buildInfoRow('PAN', _tv(d['pan'])),
        ]),
        const SizedBox(height: 32),
        _buildSectionTitle('Address'),
        _buildInfoContent([
          _buildInfoRow('Attention', _tv(d['attention'])),
          _buildInfoRow('Street', _tv(d['street'])),
          _buildInfoRow('Place', _tv(d['place'])),
          _buildInfoRow('City', _tv(d['city'])),
          _buildInfoRow('Pin Code', _tv(d['pincode'])),
          _buildInfoRow('State', _tv(d['state'])),
          _buildInfoRow('Country', _tv(d['country'])),
          _buildInfoRow(
            'District',
            _tv(d['district_name'] ?? d['district_id']),
          ),
          _buildInfoRow('Local Body Type', _tv(d['local_body_type'])),
          _buildInfoRow(
            'Local Body',
            _tv(d['local_body_name'] ?? d['local_body_id']),
          ),
          _buildInfoRow(
            'Assembly',
            _tv(d['assembly_name'] ?? d['assembly_code']),
          ),
          _buildInfoRow(
            'Ward',
            _tv(
              d['ward_display_name'] ?? d['ward_name'] ?? d['ward_id'],
            ),
          ),
        ]),
        if (_isTrue(d['has_separate_payment_stub_address'])) ...[
          const SizedBox(height: 32),
          _buildPaymentStubSection(d['payment_stub_address']),
        ],
      ],
    );
  }

  Widget _buildRightPanel(Map<String, dynamic> d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('GST Details'),
        _buildInfoContent([
          _buildInfoRow('GST Treatment', _tv(d['gst_treatment'])),
          _buildInfoRow('GSTIN', _tv(d['gstin'])),
          _buildInfoRow('Legal Name', _tv(d['gstin_legal_name'])),
          _buildInfoRow('Trade Name', _tv(d['gstin_trade_name'])),
          _buildInfoRow('GST Registered On', _tv(_formatDate(d['gstin_registered_on']))),
          _buildInfoRow('Reverse Charge', _tv(_boolLabel(d['gstin_reverse_charge']))),
          _buildInfoRow('Import / Export', _tv(_boolLabel(d['gstin_import_export']))),
          _buildInfoRow('Digital Services', _tv(_boolLabel(d['gstin_digital_services']))),
        ]),
        if (_isTrue(d['is_drug_registered'])) ...[
          const SizedBox(height: 32),
          _buildSectionTitle('Drug Licence'),
          _buildInfoContent([
            _buildInfoRow('Licence Type', _tv(d['drug_licence_type'])),
            _buildInfoRow('Licence 20', _tv(d['drug_licence_20'])),
            _buildInfoRow('Licence 21', _tv(d['drug_licence_21'])),
            _buildInfoRow('Licence 20B', _tv(d['drug_licence_20b'])),
            _buildInfoRow('Licence 21B', _tv(d['drug_licence_21b'])),
          ]),
        ],
        if (_isTrue(d['is_fssai_registered'])) ...[
          const SizedBox(height: 32),
          _buildSectionTitle('FSSAI'),
          _buildInfoContent([
            _buildInfoRow('FSSAI Number', _tv(d['fssai_number'])),
          ]),
        ],
        if (_isTrue(d['is_msme_registered'])) ...[
          const SizedBox(height: 32),
          _buildSectionTitle('MSME'),
          _buildInfoContent([
            _buildInfoRow('Registration Type', _tv(d['msme_registration_type'])),
            _buildInfoRow('MSME Number', _tv(d['msme_number'])),
            _buildInfoRow('MSME Type', _tv(d['msme_type'])),
          ]),
        ],
        const SizedBox(height: 32),
        _buildSectionTitle('Subscription'),
        _buildInfoContent([
          _buildInfoRow('From', _tv(d['subscription_from'])),
          _buildInfoRow('To', _tv(d['subscription_to'])),
          _buildInfoRow('Fiscal Year', _tv(d['fiscal_year'])),
          _buildInfoRow('Report Basis', _tv(d['report_basis'])),
        ]),
      ],
    );
  }

  Widget _buildPaymentStubSection(dynamic raw) {
    Map<String, dynamic> addr = const {};
    if (raw is Map<String, dynamic>) addr = raw;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Payment Stub Address'),
        _buildInfoContent([
          _buildInfoRow('Street', _tv(addr['street'])),
          _buildInfoRow('Place', _tv(addr['place'])),
          _buildInfoRow('City', _tv(addr['city'])),
          _buildInfoRow('Pin Code', _tv(addr['pincode'])),
          _buildInfoRow('State', _tv(addr['state'])),
          _buildInfoRow('Country', _tv(addr['country'])),
          _buildInfoRow(
            'District',
            _tv(addr['district_name'] ?? addr['district_id']),
          ),
          _buildInfoRow(
            'Local Body',
            _tv(addr['local_body_name'] ?? addr['local_body_id']),
          ),
          _buildInfoRow(
            'Assembly',
            _tv(addr['assembly_name'] ?? addr['assembly_code']),
          ),
          _buildInfoRow(
            'Ward',
            _tv(
              addr['ward_display_name'] ?? addr['ward_name'] ?? addr['ward_id'],
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildInfoContent(List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const SizedBox(height: 18), ...rows],
    );
  }

  Widget _buildInfoRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  String? _formatDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty || s == 'null') return null;
    try {
      final dt = DateTime.parse(s).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return s;
    }
  }

  Widget _tv(dynamic value) {
    final s = value?.toString().trim() ?? '';
    return Text(
      (s.isEmpty || s.toLowerCase() == 'null') ? 'n/a' : s,
      style: const TextStyle(
        fontSize: 13,
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String? _boolLabel(dynamic v) {
    if (v == null) return null;
    return (v as bool? ?? false) ? 'Yes' : 'No';
  }

  bool _isTrue(dynamic v) => v as bool? ?? false;
}
