import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';

class EWayBillsPage extends ConsumerStatefulWidget {
  const EWayBillsPage({super.key});

  @override
  ConsumerState<EWayBillsPage> createState() => _EWayBillsPageState();
}

class _ConnectionRowData {
  const _ConnectionRowData({required this.gstin});

  final String gstin;
}

class _EWayBillsPageState extends ConsumerState<EWayBillsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _activeGstin;
  bool _showCredentialsDialog = false;
  bool _showDisableDialog = false;
  bool _isDisabled = false;
  bool _obscurePassword = true;

  static const List<_ConnectionRowData> _rows = <_ConnectionRowData>[
    _ConnectionRowData(gstin: '32AACCZ4912F1ZL'),
    _ConnectionRowData(gstin: '3425EFN4587G457'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _withOrgPrefix(String route) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    return '/$orgSystemId$route';
  }

  void _focusSearch() {
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  void _openCredentialsDialog(String gstin) {
    setState(() {
      _activeGstin = gstin;
      _showCredentialsDialog = true;
      _obscurePassword = true;
      _usernameController.clear();
      _passwordController.clear();
    });
  }

  void _closeCredentialsDialog() {
    setState(() {
      _showCredentialsDialog = false;
      _activeGstin = null;
    });
  }

  void _openDisableDialog() {
    setState(() {
      _showDisableDialog = true;
    });
  }

  void _closeDisableDialog() {
    setState(() {
      _showDisableDialog = false;
    });
  }

  void _disableEWayBills() {
    setState(() {
      _showDisableDialog = false;
      _showCredentialsDialog = false;
      _activeGstin = null;
      _isDisabled = true;
    });
  }

  void _enableEWayBills() {
    setState(() {
      _isDisabled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final orgName = orgSettings?.name.trim().isNotEmpty == true
        ? orgSettings!.name.trim()
        : 'Your Organization';

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.slash): _focusSearch,
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FBFF),
        body: Stack(
          children: [
            Column(
              children: [
                _EWayBillsTopBar(
                  orgName: orgName,
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  onBack: () => context.go(_withOrgPrefix(AppRoutes.settings)),
                  onClose: () => context.go(_withOrgPrefix(AppRoutes.home)),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsNavigationSidebar(
                        currentPath: GoRouterState.of(context).uri.path,
                      ),
                      Expanded(
                        child: Container(
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PageHeader(
                                isDisabled: _isDisabled,
                                onAction: _isDisabled
                                    ? _enableEWayBills
                                    : _openDisableDialog,
                              ),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFE6EBF2),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      24,
                                      16,
                                      32,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (!_isDisabled) ...[
                                          const _PortalIntro(),
                                          const SizedBox(height: 28),
                                          _ConnectionStatusTable(
                                            rows: _rows,
                                            onConnectNow:
                                                _openCredentialsDialog,
                                          ),
                                          const SizedBox(height: 96),
                                        ] else
                                          const SizedBox(height: 8),
                                        _EWayBillsWorkflowSection(
                                          compactDisabledState: _isDisabled,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showCredentialsDialog && _activeGstin != null)
              Positioned.fill(
                child: _EWayBillCredentialsOverlay(
                  gstin: _activeGstin!,
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  onTogglePassword: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  onClose: _closeCredentialsDialog,
                ),
              ),
            if (_showDisableDialog)
              Positioned.fill(
                child: _DisableEWayBillsOverlay(
                  onCancel: _closeDisableDialog,
                  onDisable: _disableEWayBills,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EWayBillsTopBar extends StatelessWidget {
  const _EWayBillsTopBar({
    required this.orgName,
    required this.searchController,
    required this.searchFocusNode,
    required this.onBack,
    required this.onClose,
  });

  final String orgName;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6EBF2))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 54,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFFE6EBF2))),
            ),
            child: Transform.rotate(
              angle: -0.2,
              child: const Icon(
                LucideIcons.receipt,
                size: 24,
                color: Color(0xFFEF5B67),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _HeaderIconButton(icon: LucideIcons.chevronLeft, onTap: onBack),
          const SizedBox(width: 12),
          SizedBox(
            width: 260,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Settings',
                  style: AppTheme.pageTitle.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1D2433),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  orgName,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF556274),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 16,
                    color: const Color(0xFF344054),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search settings ( / )',
                    hintStyle: AppTheme.bodyText.copyWith(
                      fontSize: 16,
                      color: const Color(0xFF50617A),
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: AppTheme.primaryBlue,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onClose,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Close Settings',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 15,
                      color: const Color(0xFF141D2A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.x, size: 16, color: Color(0xFFFF667A)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD9DFEA)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1C2739)),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.isDisabled, required this.onAction});

  final bool isDisabled;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 18, 10),
      child: Row(
        children: [
          Text(
            'e-Way Bills',
            style: AppTheme.pageTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D2433),
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFD7DEE8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              foregroundColor: const Color(0xFF444F5E),
            ),
            child: Text(
              isDisabled ? 'Enable' : 'Disable',
              style: AppTheme.bodyText.copyWith(
                fontSize: 15,
                color: const Color(0xFF444F5E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EWayBillsWorkflowSection extends StatelessWidget {
  const _EWayBillsWorkflowSection({required this.compactDisabledState});

  final bool compactDisabledState;

  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: compactDisabledState
          ? Alignment.topCenter
          : const Alignment(-0.12, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(child: _QuickOverviewLink()),
          SizedBox(height: compactDisabledState ? 26 : 22),
          Center(
            child: Text(
              'How e-Way Bills work in Zoho Inventory',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF202124),
              ),
            ),
          ),
          SizedBox(height: compactDisabledState ? 38 : 34),
          const Center(child: _WorkflowDiagram()),
          const SizedBox(height: 26),
          Center(
            child: RichText(
              text: TextSpan(
                style: AppTheme.bodyText.copyWith(
                  fontSize: 15,
                  color: const Color(0xFF2C2F33),
                ),
                children: [
                  const TextSpan(text: 'Read our '),
                  TextSpan(
                    text: 'help document',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 15,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' to learn how you can set up and generate e-Way Bills in Zoho Inventory.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (compactDisabledState) {
      return Padding(padding: const EdgeInsets.only(top: 6), child: content);
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
      child: content,
    );
  }
}

class _PortalIntro extends StatelessWidget {
  const _PortalIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect Zoho Inventory with the e-Way Bill portal',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF121926),
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: AppTheme.bodyText.copyWith(
              fontSize: 15,
              height: 1.55,
              color: const Color(0xFF3B4758),
            ),
            children: [
              const TextSpan(
                text:
                    'Before you can connect Zoho Inventory with the e-Way Bill portal, you need the Username and Password generated by registering Zoho Corporation as your GST Suvidha Provider in the e-Way Bill portal. ',
              ),
              TextSpan(
                text: 'Learn More',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 15,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConnectionStatusTable extends StatelessWidget {
  const _ConnectionStatusTable({
    required this.rows,
    required this.onConnectNow,
  });

  final List<_ConnectionRowData> rows;
  final ValueChanged<String> onConnectNow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'e-Way Bill Connection Status',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE6EBF2)),
          ),
          child: Column(
            children: [
              const _TableHeaderRow(),
              for (final row in rows)
                _TableDataRow(data: row, onConnectNow: onConnectNow),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: const Color(0xFFF9FAFD),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _TableCell(flex: 28, child: _HeaderText(label: 'GSTIN')),
          _TableCell(flex: 28, child: _HeaderText(label: 'USERNAME')),
          _TableCell(flex: 22, child: _HeaderText(label: 'STATUS')),
          _TableCell(
            flex: 22,
            child: Align(
              alignment: Alignment.centerRight,
              child: _HeaderText(label: 'ACTIONS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableDataRow extends StatefulWidget {
  const _TableDataRow({required this.data, required this.onConnectNow});

  final _ConnectionRowData data;
  final ValueChanged<String> onConnectNow;

  @override
  State<_TableDataRow> createState() => _TableDataRowState();
}

class _TableDataRowState extends State<_TableDataRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFF7FAFF) : Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE8EDF5))),
        ),
        child: Row(
          children: [
            _TableCell(
              flex: 28,
              child: Text(
                widget.data.gstin,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
            const _TableCell(flex: 28, child: SizedBox.shrink()),
            _TableCell(
              flex: 22,
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE14B61),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Not Connected',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            _TableCell(
              flex: 22,
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => widget.onConnectNow(widget.data.gstin),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(122, 30),
                    maximumSize: const Size(122, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    side: BorderSide(
                      color: _isHovered
                          ? const Color(0xFFBFD4FF)
                          : const Color(0xFFD8DEE8),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: _isHovered
                        ? const Color(0xFFFCFDFF)
                        : Colors.white,
                  ),
                  child: Text(
                    'Connect Now',
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      color: _isHovered
                          ? AppTheme.primaryBlue
                          : const Color(0xFF1C2431),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EWayBillCredentialsOverlay extends StatelessWidget {
  const _EWayBillCredentialsOverlay({
    required this.gstin,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onClose,
  });

  final String gstin;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xA81D2433),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 500,
          height: 458.18,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: const Color(0xFFF9F9FB),
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Enter the e-Way Bill Portal Credentials',
                        style: AppTheme.pageTitle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1B2432),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onClose,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: Color(0xFFFF5D64),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF2)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            height: 1.45,
                            color: const Color(0xFF3A4657),
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  'If you don\'t have the credentials, you need to Register Zoho Corporation as Your GST Suvidha Provider in the e-Way Bill Portal to generate the username and password. ',
                            ),
                            TextSpan(
                              text: 'Learn More',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(42, 18, 42, 0),
                        child: Column(
                          children: [
                            _CredentialRow(
                              label: 'GSTIN',
                              child: _ReadOnlyCredentialField(value: gstin),
                            ),
                            const SizedBox(height: 10),
                            _CredentialRow(
                              label: 'Username',
                              child: CustomTextField(
                                controller: usernameController,
                                height: 34,
                                forceUppercase: false,
                                contentCase: ContentCase.none,
                                textStyle: AppTheme.bodyText.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _CredentialRow(
                              label: 'Password',
                              child: CustomTextField(
                                controller: passwordController,
                                height: 34,
                                obscureText: obscurePassword,
                                forceUppercase: false,
                                contentCase: ContentCase.none,
                                textStyle: AppTheme.bodyText.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF1F2937),
                                ),
                                fillColor: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                suffixWidget: InkWell(
                                  onTap: onTogglePassword,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Icon(
                                      LucideIcons.eye,
                                      size: 14,
                                      color: const Color(0xFF7C879C),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text.rich(
                          TextSpan(
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12,
                              height: 1.45,
                              color: const Color(0xFF6E7891),
                            ),
                            children: [
                              TextSpan(
                                text: 'Note: ',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF68738D),
                                ),
                              ),
                              const TextSpan(
                                text:
                                    'Once Zoho Inventory is connected with the e-Way Bill Portal, any user with Generate e-Way Bills permission can generate e-Way Bills.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF2)),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ZButton.primary(
                      label: 'Save & Validate',
                      onPressed: () {},
                      height: 36,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    const SizedBox(width: 8),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: onClose,
                      height: 36,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisableEWayBillsOverlay extends StatelessWidget {
  const _DisableEWayBillsOverlay({
    required this.onCancel,
    required this.onDisable,
  });

  final VoidCallback onCancel;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xA81D2433),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 500,
          height: 163.79,
          margin: const EdgeInsets.only(top: 0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF4D6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.alertTriangle,
                        size: 24,
                        color: Color(0xFFEE9B00),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'You\'re about to disable e-Way Bills in Zoho Inventory. Are you sure you want to disable?',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 16,
                            height: 1.55,
                            color: const Color(0xFF2A3342),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF2)),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                child: Row(
                  children: [
                    ZButton.primary(
                      label: 'Cancel',
                      onPressed: onCancel,
                      height: 36,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: onDisable,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5F5F5),
                          side: const BorderSide(color: AppTheme.borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: Text(
                          'Disable',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 14,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyCredentialField extends StatelessWidget {
  const _ReadOnlyCredentialField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        value,
        style: AppTheme.bodyText.copyWith(
          fontSize: 13,
          color: const Color(0xFF4A5568),
        ),
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 86,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: const Color(0xFF2F3746),
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTheme.captionText.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: const Color(0xFF6D7891),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({required this.flex, required this.child});

  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: child);
  }
}

class _QuickOverviewLink extends StatelessWidget {
  const _QuickOverviewLink();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryBlue, width: 1.4),
          ),
          child: const Icon(
            LucideIcons.play,
            size: 8,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Get a quick overview of e-Way Bill',
          style: AppTheme.bodyText.copyWith(
            fontSize: 15,
            color: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }
}

class _WorkflowDiagram extends StatelessWidget {
  const _WorkflowDiagram();

  @override
  Widget build(BuildContext context) {
    const double width = 870;
    const double height = 210;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: const [
            Positioned.fill(
              child: CustomPaint(painter: _WorkflowConnectorPainter()),
            ),
            Positioned(
              left: 48,
              top: 8,
              child: _WorkflowStepBox(
                icon: LucideIcons.receipt,
                iconColor: AppTheme.primaryBlue,
                label: 'SELECT INVOICE/ CREDIT\nNOTE/ DELIVERY CHALLAN',
                width: 198,
              ),
            ),
            Positioned(
              left: 278,
              top: 8,
              child: _WorkflowStepBox(
                icon: LucideIcons.filePlus,
                iconColor: Color(0xFF44C151),
                label: 'CREATE NEW\nE-WAY BILL',
                width: 134,
              ),
            ),
            Positioned(
              left: 440,
              top: 8,
              child: _WorkflowStepBox(
                icon: LucideIcons.fileText,
                iconColor: Color(0xFFFF6B57),
                label: 'ENTER PART A AND\nPART B DETAILS',
                width: 160,
              ),
            ),
            Positioned(
              left: 630,
              top: 8,
              child: _WorkflowStepBox(
                icon: LucideIcons.receipt,
                iconColor: Color(0xFF44C151),
                label: 'SAVE AND GENERATE\nE-WAY BILL',
                width: 170,
              ),
            ),
            Positioned(
              left: 278,
              top: 124,
              child: _WorkflowStepBox(
                icon: LucideIcons.badgeCheck,
                iconColor: AppTheme.primaryBlue,
                label: 'ASSOCIATE\nE-WAY BILL',
                width: 126,
              ),
            ),
            Positioned(
              left: 432,
              top: 124,
              child: _WorkflowStepBox(
                icon: LucideIcons.pencil,
                iconColor: Color(0xFFFF6B57),
                label: 'ENTER YOUR E-WAY\nBILL NUMBER',
                width: 164,
              ),
            ),
            Positioned(
              left: 624,
              top: 124,
              child: _WorkflowStepBox(
                icon: LucideIcons.search,
                iconColor: AppTheme.primaryBlue,
                label: 'FETCH E-WAY BILL DETAILS\nFROM PORTAL',
                width: 200,
              ),
            ),
            Positioned(
              left: 280,
              top: 174,
              child: SizedBox(
                width: 128,
                child: Text(
                  'If you\'ve generated an e-Way Bill\nfrom the EWB Portal, you can\nassociate it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF808A98),
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowStepBox extends StatelessWidget {
  const _WorkflowStepBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.width,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF31A3FF), width: 1.4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              style: AppTheme.captionText.copyWith(
                fontSize: 10,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF768292),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowConnectorPainter extends CustomPainter {
  const _WorkflowConnectorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const Color lineColor = Color(0xFF8FD0FF);
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    _dashedLine(canvas, paint, const Offset(246, 27), const Offset(278, 27));
    _dashedLine(canvas, paint, const Offset(412, 27), const Offset(440, 27));
    _dashedLine(canvas, paint, const Offset(600, 27), const Offset(630, 27));

    _dashedLine(canvas, paint, const Offset(147, 46), const Offset(147, 143));
    _dashedLine(canvas, paint, const Offset(147, 143), const Offset(278, 143));
    _dashedLine(canvas, paint, const Offset(404, 143), const Offset(432, 143));
    _dashedLine(canvas, paint, const Offset(596, 143), const Offset(624, 143));
  }

  void _dashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    const double dash = 4;
    const double gap = 3;
    final double total = (end - start).distance;
    final Offset direction = (end - start) / total;
    double progress = 0;
    while (progress < total) {
      final double next = math.min(progress + dash, total);
      canvas.drawLine(
        start + direction * progress,
        start + direction * next,
        paint,
      );
      progress += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
