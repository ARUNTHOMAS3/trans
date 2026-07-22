import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';

class EInvoicingPage extends ConsumerStatefulWidget {
  const EInvoicingPage({super.key});

  @override
  ConsumerState<EInvoicingPage> createState() => _EInvoicingPageState();
}

class _EInvoicingPageState extends ConsumerState<EInvoicingPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _optionalFieldsEnabled = false;
  bool _isEinvoicingDisabled = false;
  String? _activeGstin;
  bool _showCredentialsDialog = false;
  bool _showConfigureDialog = false;
  bool _showDisableWarningDialog = false;
  bool _showDisableEditsDialog = false;
  bool _showDisableEinvoicingDialog = false;
  bool _showProvideStartDateDialog = false;
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
        GoRouterState.of(context).pathParameters['orgSystemId'] ??
        '60034406004';
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

  void _openConfigureDialog() {
    setState(() {
      _showConfigureDialog = true;
    });
  }

  void _closeConfigureDialog() {
    setState(() {
      _showConfigureDialog = false;
    });
  }

  void _openDisableWarningDialog() {
    setState(() {
      _showDisableWarningDialog = true;
    });
  }

  void _closeDisableWarningDialog() {
    setState(() {
      _showDisableWarningDialog = false;
    });
  }

  void _openDisableEditsDialog() {
    setState(() {
      _showDisableEditsDialog = true;
    });
  }

  void _closeDisableEditsDialog() {
    setState(() {
      _showDisableEditsDialog = false;
    });
  }

  void _openDisableEinvoicingDialog() {
    setState(() {
      _showDisableEinvoicingDialog = true;
    });
  }

  void _closeDisableEinvoicingDialog() {
    setState(() {
      _showDisableEinvoicingDialog = false;
    });
  }

  void _openProvideStartDateDialog() {
    setState(() {
      _showProvideStartDateDialog = true;
    });
  }

  void _closeProvideStartDateDialog() {
    setState(() {
      _showProvideStartDateDialog = false;
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
                _EinvoicingTopBar(
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
                                isEinvoicingDisabled: _isEinvoicingDisabled,
                                onDisable: _openDisableEinvoicingDialog,
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
                                      0,
                                      20,
                                      0,
                                      40,
                                    ),
                                    child: _isEinvoicingDisabled
                                        ? _DisabledEinvoicingBody(
                                            onEnable:
                                                _openProvideStartDateDialog,
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                    ),
                                                child: ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxWidth: 820,
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const _PortalIntro(),
                                                      const SizedBox(
                                                        height: 28,
                                                      ),
                                                      _PreferenceTile(
                                                        label:
                                                            'Enable editing optional fields in pushed transactions.',
                                                        trailing: InkWell(
                                                          onTap: () {
                                                            if (_optionalFieldsEnabled) {
                                                              _openDisableEditsDialog();
                                                              return;
                                                            }
                                                            _openDisableWarningDialog();
                                                          },
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                999,
                                                              ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                _optionalFieldsEnabled
                                                                    ? 'Enabled'
                                                                    : 'Disabled',
                                                                style: AppTheme
                                                                    .bodyText
                                                                    .copyWith(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color: const Color(
                                                                        0xFF111827,
                                                                      ),
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                width: 10,
                                                              ),
                                                              IgnorePointer(
                                                                child: _ZohoSwitch(
                                                                  value:
                                                                      _optionalFieldsEnabled,
                                                                  onChanged:
                                                                      (
                                                                        bool
                                                                        value,
                                                                      ) {},
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      _PreferenceTile(
                                                        label:
                                                            'Configure optional fields for e-invoice push',
                                                        trailing: InkWell(
                                                          onTap:
                                                              _openConfigureDialog,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                LucideIcons
                                                                    .settings,
                                                                size: 18,
                                                                color: Color(
                                                                  0xFF2F80FF,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Text(
                                                                'Configure',
                                                                style: AppTheme
                                                                    .bodyText
                                                                    .copyWith(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color: const Color(
                                                                        0xFF2F80FF,
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
                                              ),
                                              const SizedBox(height: 46),
                                              _ConnectionStatusTable(
                                                rows: _rows,
                                                onConnectNow:
                                                    _openCredentialsDialog,
                                              ),
                                              const SizedBox(height: 88),
                                              const _WorkflowSection(),
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
                child: _EInvoicingCredentialsOverlay(
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
            if (_showConfigureDialog)
              Positioned.fill(
                child: _OptionalFieldsPreferenceOverlay(
                  onClose: _closeConfigureDialog,
                ),
              ),
            if (_showDisableWarningDialog)
              Positioned.fill(
                child: _DisableWarningOverlay(
                  onEnable: () {
                    setState(() {
                      _optionalFieldsEnabled = true;
                      _showDisableWarningDialog = false;
                    });
                  },
                  onClose: _closeDisableWarningDialog,
                ),
              ),
            if (_showDisableEditsDialog)
              Positioned.fill(
                child: _DisableEditsOverlay(
                  onDisable: () {
                    setState(() {
                      _optionalFieldsEnabled = false;
                      _showDisableEditsDialog = false;
                    });
                  },
                  onClose: _closeDisableEditsDialog,
                ),
              ),
            if (_showDisableEinvoicingDialog)
              Positioned.fill(
                child: _DisableEinvoicingOverlay(
                  onDisable: () {
                    setState(() {
                      _isEinvoicingDisabled = true;
                      _showDisableEinvoicingDialog = false;
                    });
                  },
                  onClose: _closeDisableEinvoicingDialog,
                ),
              ),
            if (_showProvideStartDateDialog)
              Positioned.fill(
                child: _ProvideStartDateOverlay(
                  onEnable: () {
                    setState(() {
                      _isEinvoicingDisabled = false;
                      _showProvideStartDateDialog = false;
                    });
                  },
                  onClose: _closeProvideStartDateDialog,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EinvoicingTopBar extends StatelessWidget {
  const _EinvoicingTopBar({
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
  const _PageHeader({
    required this.isEinvoicingDisabled,
    required this.onDisable,
  });

  final bool isEinvoicingDisabled;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 18, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'e-Invoicing',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1D2433),
                ),
              ),
              if (!isEinvoicingDisabled) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(color: Color(0xFF2BB24C)),
                  child: Text(
                    'ENABLED',
                    style: AppTheme.captionText.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          if (!isEinvoicingDisabled) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'E-invoice Generation Start Date',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 15,
                    color: const Color(0xFF6D7891),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '2023-08-01',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 18),
            SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: onDisable,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFD7DEE8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: const Icon(
                  LucideIcons.toggleLeft,
                  size: 17,
                  color: Color(0xFF8E97A6),
                ),
                label: Text(
                  'Disable',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 15,
                    color: const Color(0xFF444F5E),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DisabledEinvoicingBody extends StatelessWidget {
  const _DisabledEinvoicingBody({required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              children: [
                const SizedBox(height: 20),
                SizedBox(
                  width: 430,
                  height: 148,
                  child: CustomPaint(
                    painter: _DisabledEinvoicingIllustrationPainter(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enabling e-Invoicing for your Business',
                  style: AppTheme.pageTitle.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 15,
                        height: 1.6,
                        color: const Color(0xFF2F3136),
                      ),
                      children: [
                        const TextSpan(text: 'Starting '),
                        TextSpan(
                          text: '1 August 2023',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF202124),
                          ),
                        ),
                        const TextSpan(
                          text:
                              ', e-Invoicing is mandatory for businesses with a turnover of ',
                        ),
                        TextSpan(
                          text: '₹5 crores and above.',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF3D6E),
                          ),
                        ),
                        const TextSpan(text: ' Read our help document on '),
                        TextSpan(
                          text: 'e-Invoicing',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 15,
                            color: const Color(0xFF2F80FF),
                          ),
                        ),
                        const TextSpan(
                          text:
                              ' to learn how to generate e-Invoices in Zoho Inventory. If you\'re unsure about how to file e-Invoices, you can test e-Invoicing on the Sandbox System. Read our help document on the ',
                        ),
                        TextSpan(
                          text: 'e-Invoice Sandbox System',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 15,
                            color: const Color(0xFF2F80FF),
                          ),
                        ),
                        const TextSpan(text: ' to learn more.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: onEnable,
                  child: Container(
                    width: 134.38,
                    height: 32.32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2CB67D),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Enable e-Invoicing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 78),
        const _WorkflowSection(),
      ],
    );
  }
}

class _DisabledEinvoicingIllustrationPainter extends CustomPainter {
  const _DisabledEinvoicingIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pale = Paint()..color = const Color(0xFFF4F7FD);
    final Paint pale2 = Paint()..color = const Color(0xFFEEF3FB);
    final Paint blue = Paint()..color = const Color(0xFF3E8BFF);
    final Paint blueLight = Paint()..color = const Color(0xFFC9D7F0);
    final Paint blueStroke = Paint()
      ..color = const Color(0xFFA8B9D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final Paint green = Paint()..color = const Color(0xFF27B36A);
    final Paint line = Paint()
      ..color = const Color(0xFFD9E3F2)
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(122, 6, 136, 116),
        const Radius.circular(18),
      ),
      pale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(40, 60, 154, 96),
        const Radius.circular(18),
      ),
      pale2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(202, 58, 156, 98),
        const Radius.circular(18),
      ),
      pale2,
    );

    canvas.drawLine(const Offset(0, 154), const Offset(428, 154), line);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 106, 34, 46),
        const Radius.circular(6),
      ),
      blue,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(101, 74, 26, 50),
        const Radius.circular(13),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(103, 76, 22, 46),
        const Radius.circular(11),
      ),
      Paint()..color = const Color(0xFFD9E4F6),
    );

    for (final double y in <double>[118, 131]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(84, y, 16, 6),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.white,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(136, 28, 176, 110),
        const Radius.circular(12),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(136, 28, 176, 110),
        const Radius.circular(12),
      ),
      blueStroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(150, 43, 142, 13),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFF6F8FD),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(150, 64, 140, 56),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFFCFDFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(150, 64, 140, 56),
        const Radius.circular(8),
      ),
      Paint()
        ..color = const Color(0xFFD9E3F2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final double x in <double>[166, 200, 236]) {
      canvas.drawLine(Offset(x, 66), Offset(x, 118), line);
    }
    for (final double y in <double>[82, 100]) {
      canvas.drawLine(Offset(152, y), Offset(288, y), line);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(176, 46, 20, 4),
        const Radius.circular(2),
      ),
      blueLight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(244, 46, 16, 4),
        const Radius.circular(2),
      ),
      blueLight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(154, 144, 118, 8),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF9FB1CB),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(142, 150, 144, 6),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF8EA2C0),
    );

    canvas.drawCircle(const Offset(298, 20), 17, green);
    final TextPainter check = TextPainter(
      text: TextSpan(
        text: '✓',
        style: AppTheme.bodyText.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    check.paint(canvas, const Offset(291, 7));

    final Paint spark = Paint()
      ..color = const Color(0xFF27B36A)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(313, 6), const Offset(318, 2), spark);
    canvas.drawLine(const Offset(318, 14), const Offset(323, 12), spark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PortalIntro extends StatelessWidget {
  const _PortalIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect Zoho Inventory with the IRP',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'To connect Zoho Inventory with the Invoice Registration Portal (IRP), you need to generate a username and password by registering Zoho Corporation as your GST Suvidha Provider in the IRP.',
          style: AppTheme.bodyText.copyWith(
            fontSize: 15,
            height: 1.45,
            color: const Color(0xFF5D6880),
          ),
        ),
      ],
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    );
  }
}

class _ZohoSwitch extends StatelessWidget {
  const _ZohoSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 38,
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF2F80FF) : const Color(0xFFD9D9DE),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ConnectionStatusTable extends StatefulWidget {
  const _ConnectionStatusTable({
    required this.rows,
    required this.onConnectNow,
  });

  final List<_ConnectionRowData> rows;
  final ValueChanged<String> onConnectNow;

  @override
  State<_ConnectionStatusTable> createState() => _ConnectionStatusTableState();
}

class _ConnectionStatusTableState extends State<_ConnectionStatusTable> {
  String? _hoveredGstin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE6EBF2)),
          bottom: BorderSide(color: Color(0xFFE6EBF2)),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 42,
            color: const Color(0xFFF7F8FC),
            child: const Row(
              children: [
                _TableCell(flex: 8, child: _HeaderText(label: 'GSTIN')),
                _TableCell(flex: 8, child: _HeaderText(label: 'USERNAME')),
                _TableCell(flex: 8, child: _HeaderText(label: 'STATUS')),
                _TableCell(flex: 8, child: _HeaderText(label: 'ACTIONS')),
              ],
            ),
          ),
          for (final row in widget.rows)
            MouseRegion(
              onEnter: (_) {
                setState(() {
                  _hoveredGstin = row.gstin;
                });
              },
              onExit: (_) {
                setState(() {
                  if (_hoveredGstin == row.gstin) {
                    _hoveredGstin = null;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 48,
                decoration: BoxDecoration(
                  color: _hoveredGstin == row.gstin
                      ? const Color(0xFFF7FAFF)
                      : Colors.white,
                  border: const Border(
                    top: BorderSide(color: Color(0xFFE6EBF2)),
                  ),
                ),
                child: Row(
                  children: [
                    _TableCell(
                      flex: 8,
                      child: Text(
                        row.gstin,
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 15,
                          color: _hoveredGstin == row.gstin
                              ? const Color(0xFF1858D1)
                              : Colors.black,
                        ),
                      ),
                    ),
                    const _TableCell(flex: 8, child: SizedBox.shrink()),
                    _TableCell(
                      flex: 8,
                      child: Row(
                        children: [
                          Container(
                            width: 17,
                            height: 17,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4F5F),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.x,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Not Connected',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 15,
                              color: _hoveredGstin == row.gstin
                                  ? const Color(0xFF1858D1)
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TableCell(
                      flex: 8,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 24,
                          child: OutlinedButton(
                            onPressed: () => widget.onConnectNow(row.gstin),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _hoveredGstin == row.gstin
                                  ? const Color(0xFFF1F6FF)
                                  : const Color(0xFFF8F8F8),
                              side: const BorderSide(color: Color(0xFFD5D8E0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            child: Text(
                              'Connect Now',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: _hoveredGstin == row.gstin
                                    ? const Color(0xFF1858D1)
                                    : Colors.black,
                              ),
                            ),
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
    );
  }
}

class _EInvoicingCredentialsOverlay extends StatelessWidget {
  const _EInvoicingCredentialsOverlay({
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
      color: const Color(0xA61D2433),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 500,
          height: 463.18,
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
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Enter your IRP Credentials',
                        style: AppTheme.pageTitle.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1F2A3D),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      child: const Icon(
                        LucideIcons.x,
                        size: 18,
                        color: Color(0xFFFF4D5E),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF2)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'If you don\'t have GSP (GST Suvidha Provider) credentials, you need to register Zoho Corporation as your GST Suvidha Provider on the Invoice Registration Portal (IRP) to generate your username and password.',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 14,
                          height: 1.45,
                          color: const Color(0xFF394150),
                        ),
                      ),
                      const SizedBox(height: 18),
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
                          fillColor: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CredentialRow(
                        label: 'Password',
                        child: CustomTextField(
                          controller: passwordController,
                          height: 34,
                          obscureText: obscurePassword,
                          forceUppercase: false,
                          contentCase: ContentCase.none,
                          fillColor: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF1F2937),
                          ),
                          suffixWidget: InkWell(
                            onTap: onTogglePassword,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Icon(
                                obscurePassword
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
                                size: 14,
                                color: const Color(0xFF7C879C),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text.rich(
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
                                color: const Color(0xFF6E7891),
                              ),
                            ),
                            const TextSpan(
                              text:
                                  'Once Zoho Inventory is connected with the IRP, any user with e-Invoicing permission can perform actions related to e-Invoicing.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF2)),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                child: Row(
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

class _OptionalFieldsPreferenceOverlay extends StatefulWidget {
  const _OptionalFieldsPreferenceOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_OptionalFieldsPreferenceOverlay> createState() =>
      _OptionalFieldsPreferenceOverlayState();
}

class _OptionalFieldsPreferenceOverlayState
    extends State<_OptionalFieldsPreferenceOverlay> {
  static const List<String> _fieldNames = <String>[
    'Dispatch Address Street 2',
    'Shipping Address Street 2',
    'Customer Notes',
    'Sales Order#',
    'Project Name',
    'Branch Address Street 2',
    'Branch Address Phone',
    'Branch Address Email Address',
    'Billing Address Street 2',
    'Billing Address Email Address',
    'Billing Address Phone',
    'Item Batch Expiry Date',
    'Customer Business Trade Name',
    'Branch Business Trade Name',
    'Shipping Customer Business Trade Name',
    'Item Serial Number',
  ];

  late final List<bool> _selected = List<bool>.filled(
    _fieldNames.length,
    false,
  );
  int? _hoveredIndex;

  bool get _allSelected => _selected.every((bool value) => value);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xA61D2433),
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 500,
            height: 1015.49,
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
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Optional Fields Preference Settings',
                          style: AppTheme.pageTitle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1F2A3D),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: Color(0xFFFF4D5E),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE5EAF2),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select the optional fields you want to exclude from being pushed to the e-invoice portal for e-invoice generation.',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            height: 1.4,
                            color: const Color(0xFF5E6678),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE3E8F1)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8FAFD),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE3E8F1),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 128,
                                      child: Center(
                                        child: _PreferenceCheckbox(
                                          value: _allSelected,
                                          onChanged: (bool value) {
                                            setState(() {
                                              for (
                                                var i = 0;
                                                i < _selected.length;
                                                i++
                                              ) {
                                                _selected[i] = value;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      color: const Color(0xFFE3E8F1),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                        ),
                                        child: Text(
                                          'FIELD NAMES',
                                          style: AppTheme.captionText.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF6F7A91),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              for (
                                var index = 0;
                                index < _fieldNames.length;
                                index++
                              )
                                MouseRegion(
                                  onEnter: (_) {
                                    setState(() {
                                      _hoveredIndex = index;
                                    });
                                  },
                                  onExit: (_) {
                                    setState(() {
                                      if (_hoveredIndex == index) {
                                        _hoveredIndex = null;
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: _hoveredIndex == index
                                          ? const Color(0xFFF3F8FF)
                                          : Colors.white,
                                      border: const Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFE3E8F1),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 128,
                                          child: Center(
                                            child: _PreferenceCheckbox(
                                              value: _selected[index],
                                              onChanged: (bool value) {
                                                setState(() {
                                                  _selected[index] = value;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          color: const Color(0xFFE3E8F1),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                _fieldNames[index],
                                                style: AppTheme.bodyText
                                                    .copyWith(
                                                      fontSize: 14,
                                                      color:
                                                          _hoveredIndex == index
                                                          ? const Color(
                                                              0xFF1858D1,
                                                            )
                                                          : const Color(
                                                              0xFF3A3F4B,
                                                            ),
                                                    ),
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
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE5EAF2),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                  child: Row(
                    children: [
                      ZButton.primary(
                        label: 'Save',
                        onPressed: () {},
                        height: 34,
                        fontSize: 13,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      const SizedBox(width: 12),
                      ZButton.secondary(
                        label: 'Cancel',
                        onPressed: widget.onClose,
                        height: 34,
                        fontSize: 13,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
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
}

class _PreferenceCheckbox extends StatelessWidget {
  const _PreferenceCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Checkbox(
        value: value,
        onChanged: (bool? next) => onChanged(next ?? false),
        side: const BorderSide(color: Color(0xFFC7CFDB), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        activeColor: const Color(0xFF2F80FF),
        checkColor: Colors.white,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _DisableWarningOverlay extends StatelessWidget {
  const _DisableWarningOverlay({required this.onEnable, required this.onClose});

  final VoidCallback onEnable;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xA61D2433),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 600,
          height: 368.82,
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        LucideIcons.alertTriangle,
                        size: 26,
                        color: Color(0xFFF4A000),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Enable edits to pushed transactions?',
                        style: AppTheme.pageTitle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1F2A3D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF2)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Once you enable edits to transactions pushed to the Invoice Registration Portal (IRP), you can edit the following fields:',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        height: 1.45,
                        color: const Color(0xFF394150),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _WarningBulletText(
                            spans: <InlineSpan>[
                              TextSpan(
                                text:
                                    'Order Number, Due Date, Customer Notes, Additional Information, Custom Field(s), ',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E3338),
                                ),
                              ),
                              TextSpan(
                                text:
                                    'and Terms & Conditions in invoices and debit notes',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  color: const Color(0xFF2E3338),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _WarningBulletText(
                            spans: <InlineSpan>[
                              TextSpan(
                                text:
                                    'Reference#, Customer Notes, Additional Information, Custom Field(s), ',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E3338),
                                ),
                              ),
                              TextSpan(
                                text: 'and Terms & Conditions in credit notes',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  color: const Color(0xFF2E3338),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'However, the edited transactions will not be in sync with the transactions in the IRP.',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        height: 1.4,
                        color: const Color(0xFF394150),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF2)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(
                  children: [
                    ZButton.primary(
                      label: 'Enable',
                      onPressed: onEnable,
                      height: 34,
                      fontSize: 13,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    const SizedBox(width: 8),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: onClose,
                      height: 34,
                      fontSize: 13,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
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

class _DisableEditsOverlay extends StatelessWidget {
  const _DisableEditsOverlay({required this.onDisable, required this.onClose});

  final VoidCallback onDisable;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xA61D2433),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 500,
          height: 204.86,
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        LucideIcons.alertTriangle,
                        size: 26,
                        color: Color(0xFFF4A000),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Disable editing of pushed transactions?',
                        style: AppTheme.pageTitle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1F2A3D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF2)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Text(
                  'Once you disable, transactions that have been pushed to Invoice Registration Portal (IRP) cannot be edited in Zoho Inventory.',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 14,
                    height: 1.45,
                    color: const Color(0xFF394150),
                  ),
                ),
              ),
              const Spacer(),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF2)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(
                  children: [
                    ZButton.primary(
                      label: 'Disable',
                      onPressed: onDisable,
                      height: 34,
                      fontSize: 13,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    const SizedBox(width: 8),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: onClose,
                      height: 34,
                      fontSize: 13,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
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

class _DisableEinvoicingOverlay extends StatelessWidget {
  const _DisableEinvoicingOverlay({
    required this.onDisable,
    required this.onClose,
  });

  final VoidCallback onDisable;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xA61D2433),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 500,
          height: 184.07,
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        LucideIcons.alertTriangle,
                        size: 26,
                        color: Color(0xFFF4A000),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Disable E-Invoicing?',
                        style: AppTheme.pageTitle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1F2A3D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF2)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Text(
                  'You won\'t be able to push invoices to the IRP for e-Invoicing.',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 14,
                    height: 1.45,
                    color: const Color(0xFF394150),
                  ),
                ),
              ),
              const Spacer(),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF2)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(
                  children: [
                    ZButton.primary(
                      label: 'Cancel',
                      onPressed: onClose,
                      height: 34,
                      fontSize: 13,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    const SizedBox(width: 8),
                    ZButton.secondary(
                      label: 'Disable',
                      onPressed: onDisable,
                      height: 34,
                      fontSize: 13,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
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

class _ProvideStartDateOverlay extends StatefulWidget {
  const _ProvideStartDateOverlay({
    required this.onEnable,
    required this.onClose,
  });

  final VoidCallback onEnable;
  final VoidCallback onClose;

  @override
  State<_ProvideStartDateOverlay> createState() =>
      _ProvideStartDateOverlayState();
}

class _ProvideStartDateOverlayState extends State<_ProvideStartDateOverlay> {
  static const List<({String turnover, String startDate, bool info})>
  _turnovers = <({String turnover, String startDate, bool info})>[
    (
      turnover: 'Revenue > 500 crores',
      startDate: 'Any date after 01-10-2020',
      info: true,
    ),
    (
      turnover: 'Revenue > 100 crores',
      startDate: 'Any date after 01-01-2021',
      info: false,
    ),
    (
      turnover: 'Revenue > 50 crores',
      startDate: 'Any date after 01-04-2021',
      info: false,
    ),
    (
      turnover: 'Revenue > 20 crores',
      startDate: 'Any date after 01-04-2022',
      info: false,
    ),
    (
      turnover: 'Revenue > 10 crores',
      startDate: 'Any date after 01-10-2022',
      info: false,
    ),
    (
      turnover: 'Revenue > 5 crores',
      startDate: 'Any date after 01-08-2023',
      info: false,
    ),
  ];

  int _selectedIndex = 5;
  DateTime _selectedStartDate = DateTime(2023, 9, 2);
  final GlobalKey _startDateKey = GlobalKey();
  final LayerLink _startDateLayerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xA61D2433),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 700,
          height: 735.81,
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
                padding: const EdgeInsets.fromLTRB(24, 14, 20, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Provide the Start Date',
                        style: AppTheme.pageTitle.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1F2A3D),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: const Icon(
                        LucideIcons.x,
                        size: 18,
                        color: Color(0xFFFF4D5E),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF2)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              LucideIcons.file,
                              size: 14,
                              color: Color(0xFF2F80FF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Select the date (based on your business turnover) after which you want to generate e-invoices.',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 14,
                                height: 1.35,
                                color: const Color(0xFF394150),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE3E8F1)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFE3E8F1)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(
                                        'BUSINESS TURNOVER',
                                        style: AppTheme.captionText.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF6F7A91),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 216,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'START DATE',
                                        style: AppTheme.captionText.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF6F7A91),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            for (
                              var index = 0;
                              index < _turnovers.length;
                              index++
                            )
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _selectedIndex == index
                                        ? const Color(0xFFF5F7FC)
                                        : Colors.white,
                                    border: const Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFE3E8F1),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 10,
                                                left: 4,
                                              ),
                                              child: _TurnoverCheckIcon(
                                                selected:
                                                    _selectedIndex == index,
                                              ),
                                            ),
                                            Flexible(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      _turnovers[index]
                                                          .turnover,
                                                      style: AppTheme.bodyText
                                                          .copyWith(
                                                            fontSize: 14,
                                                            color: const Color(
                                                              0xFF2F3136,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                  if (_turnovers[index].info)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 6,
                                                          ),
                                                      child: ZTooltip(
                                                        message:
                                                            'e-Invoicing is mandatory for all businesses whose aggregate turnover exceeds Rs. 500 crores during the period 2017-2018 and 2018-2019.',
                                                        direction:
                                                            ZTooltipDirection
                                                                .right,
                                                        child: const Icon(
                                                          LucideIcons
                                                              .helpCircle,
                                                          size: 14,
                                                          color: Color(
                                                            0xFFB2B8C6,
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
                                      SizedBox(
                                        width: 216,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            _turnovers[index].startDate,
                                            style: AppTheme.bodyText.copyWith(
                                              fontSize: 14,
                                              color: const Color(0xFF3B3F46),
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
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                LucideIcons.info,
                                size: 15,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: const Color(0xFF394150),
                                  ),
                                  children: [
                                    const TextSpan(
                                      text:
                                          'The Central Board of Indirect Taxes and Customs (CBIC) has mandated e-Invoicing for businesses with an annual turnover greater than 5 crores starting 1 August 2023. ',
                                    ),
                                    TextSpan(
                                      text:
                                          'Learn how to get started with e-Invoicing',
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          '\nYou can test e-Invoicing in the Sandbox System to get familiarised with e-Invoicing. ',
                                    ),
                                    TextSpan(
                                      text:
                                          'Learn how to use the sandbox system',
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Start Date*',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 14,
                          color: const Color(0xFFFF3B30),
                        ),
                      ),
                      const SizedBox(height: 6),
                      CompositedTransformTarget(
                        link: _startDateLayerLink,
                        child: GestureDetector(
                          key: _startDateKey,
                          onTap: () async {
                            final DateTime? picked =
                                await ZerpaiDatePicker.show(
                                  context,
                                  initialDate: _selectedStartDate,
                                  firstDate: DateTime(2020, 10, 1),
                                  targetKey: _startDateKey,
                                  layerLink: _startDateLayerLink,
                                  dismissOnBackgroundTap: false,
                                );
                            if (picked != null) {
                              setState(() {
                                _selectedStartDate = picked;
                              });
                            }
                          },
                          child: Container(
                            width: 223,
                            height: 34,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFD8DEE9),
                              ),
                            ),
                            child: Text(
                              DateFormat(
                                'dd-MM-yyyy',
                              ).format(_selectedStartDate),
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 14,
                                color: const Color(0xFF394150),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF2)),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
                child: Row(
                  children: [
                    ZButton.primary(
                      label: 'Enable e-Invoicing',
                      onPressed: widget.onEnable,
                      height: 34,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    const SizedBox(width: 10),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: widget.onClose,
                      height: 34,
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

class _TurnoverCheckIcon extends StatelessWidget {
  const _TurnoverCheckIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color color = selected
        ? const Color(0xFF22A06B)
        : const Color(0xFFB9C9DF);
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
    );
  }
}

class _WarningBulletText extends StatelessWidget {
  const _WarningBulletText({required this.spans});

  final List<InlineSpan> spans;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF2E3338),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text.rich(TextSpan(children: spans))),
      ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9DEEA)),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 116,
          child: Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 14,
              color: const Color(0xFF2F3746),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _WorkflowSection extends StatelessWidget {
  const _WorkflowSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF9F9FB),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
      child: Center(
        child: Column(
          children: [
            Text(
              'How e-Invoicing works in Zoho Inventory',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF202124),
              ),
            ),
            const SizedBox(height: 34),
            const _WorkflowDiagram(),
            const SizedBox(height: 24),
            RichText(
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
                        ' to learn how you can generate e-Invoices in Zoho Inventory.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowDiagram extends StatelessWidget {
  const _WorkflowDiagram();

  @override
  Widget build(BuildContext context) {
    const double width = 1000;
    const double height = 250;

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
              left: 38,
              top: 8,
              child: _WorkflowStepBox(
                icon: LucideIcons.fileCheck2,
                iconColor: Color(0xFF9C6BFF),
                label:
                    'Select Invoice (with e-Way\nBill) / Credit Note/ Debit Note',
                width: 208,
              ),
            ),
            Positioned(
              left: 310,
              top: 8,
              child: _WorkflowStepBox(
                icon: LucideIcons.fileInput,
                iconColor: Color(0xFF1F8CFF),
                label: 'Push to IRP',
                width: 110,
              ),
            ),
            Positioned(
              left: 486,
              top: 8,
              child: _WorkflowStepBox(
                icon: LucideIcons.fileBadge2,
                iconColor: Color(0xFF17C37B),
                label: 'IRN Generated for e-Invoice',
                width: 190,
              ),
            ),
            Positioned(
              left: 742,
              top: 8,
              child: _WorkflowStepBox(
                icon: LucideIcons.send,
                iconColor: Color(0xFF2F80FF),
                label: 'Send e-Invoice',
                width: 126,
              ),
            ),
            Positioned(
              left: 180,
              top: 126,
              child: _WorkflowStepBox(
                icon: LucideIcons.xCircle,
                iconColor: Color(0xFFFF5A8B),
                label: 'Cancel\nWill be cancelled automatically in the IRP',
                width: 240,
                alignLeft: true,
              ),
            ),
            Positioned(
              left: 742,
              top: 126,
              child: _WorkflowStepBox(
                icon: LucideIcons.xCircle,
                iconColor: Color(0xFFFF5A8B),
                label:
                    'Mark as Cancelled\nYou will have to cancel in the GST portal',
                width: 234,
                alignLeft: true,
              ),
            ),
            Positioned(
              left: 462,
              top: 126,
              child: SizedBox(
                width: 92,
                child: Text(
                  'WITHIN 24 HOURS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A5568),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 608,
              top: 126,
              child: SizedBox(
                width: 92,
                child: Text(
                  'AFTER 24 HOURS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A5568),
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
    this.alignLeft = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final double width;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF4CA8FF), width: 1.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              textAlign: alignLeft ? TextAlign.left : TextAlign.center,
              maxLines: 2,
              style: AppTheme.captionText.copyWith(
                fontSize: 10.5,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF445165),
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
    const Color lineColor = Color(0xFF7FC6FF);
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    _dashedLine(canvas, paint, const Offset(246, 32), const Offset(310, 32));
    _dashedLine(canvas, paint, const Offset(420, 32), const Offset(486, 32));
    _dashedLine(canvas, paint, const Offset(676, 32), const Offset(742, 32));
    _dashedLine(canvas, paint, const Offset(581, 56), const Offset(581, 151));
    _dashedLine(canvas, paint, const Offset(420, 151), const Offset(742, 151));
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

class _HeaderText extends StatelessWidget {
  const _HeaderText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: AppTheme.captionText.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: const Color(0xFF6D7891),
          ),
        ),
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
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      ),
    );
  }
}

class _ConnectionRowData {
  const _ConnectionRowData({required this.gstin});

  final String gstin;
}
