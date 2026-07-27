import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/core/services/api_client.dart';

enum EmailNotificationsSection {
  senderPreferences,
  emailInsights,
  customerReviewNotification,
}

class EmailNotificationsPage extends ConsumerStatefulWidget {
  const EmailNotificationsPage({
    super.key,
    this.initialSection = EmailNotificationsSection.senderPreferences,
    this.initialTemplateName,
    this.initialEditTemplateName,
    this.initialEditIsNew = false,
  });

  final EmailNotificationsSection initialSection;
  final String? initialTemplateName;
  final String? initialEditTemplateName;
  final bool initialEditIsNew;

  @override
  ConsumerState<EmailNotificationsPage> createState() =>
      _EmailNotificationsPageState();
}

class _EmailNotificationsPageState
    extends ConsumerState<EmailNotificationsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  static const _EmailTemplateConfig _defaultTemplateConfig =
      _EmailTemplateConfig(
        name: 'Customer Review Notification',
        description: 'Sent when requested for customer review',
        subject: '%CompanyName% has invited you to review their service',
      );
  late EmailNotificationsSection _section;
  late _EmailTemplateConfig _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    _selectedTemplate =
        _emailTemplateForName(widget.initialTemplateName) ??
        _defaultTemplateConfig;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (GoRouterState.of(context).uri.queryParameters['dialog']) {
        case 'authenticate':
          _showAuthenticateDialog();
        case 'new-sender':
          _showNewSenderDialog();
        case 'signature':
          _showSignatureDialog();
      }
    });
  }

  @override
  void didUpdateWidget(covariant EmailNotificationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection ||
        oldWidget.initialTemplateName != widget.initialTemplateName ||
        oldWidget.initialEditTemplateName != widget.initialEditTemplateName ||
        oldWidget.initialEditIsNew != widget.initialEditIsNew) {
      _section = widget.initialSection;
      _selectedTemplate =
          _emailTemplateForName(widget.initialTemplateName) ??
          _defaultTemplateConfig;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _withOrgPrefix(String route) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    return '/$orgSystemId$route';
  }

  String _routeWithTemplate(String route, String? templateName) {
    final query = templateName == null || templateName.isEmpty
        ? const <String, String>{}
        : <String, String>{'template': templateName};
    return _routeWithQuery(route, query);
  }

  String _routeWithQuery(String route, Map<String, String> query) {
    return Uri(path: _withOrgPrefix(route), queryParameters: query).toString();
  }

  String _currentSectionRoute() {
    switch (_section) {
      case EmailNotificationsSection.senderPreferences:
        return AppRoutes.settingsEmailNotifications;
      case EmailNotificationsSection.emailInsights:
        return AppRoutes.settingsEmailInsights;
      case EmailNotificationsSection.customerReviewNotification:
        return AppRoutes.settingsCustomerReviewNotification;
    }
  }

  String _currentStateRoute({String? dialog}) {
    final query = <String, String>{};
    if (_section == EmailNotificationsSection.customerReviewNotification &&
        _selectedTemplate.name != _defaultTemplateConfig.name) {
      query['template'] = _selectedTemplate.name;
    }
    if (dialog != null) query['dialog'] = dialog;
    return _routeWithQuery(_currentSectionRoute(), query);
  }

  void _clearDialogRoute() {
    if (mounted) context.go(_currentStateRoute());
  }

  void _focusSearch() {
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  void _openSection(EmailNotificationsSection section) {
    setState(() {
      _section = section;
      if (section == EmailNotificationsSection.customerReviewNotification) {
        _selectedTemplate = _defaultTemplateConfig;
      }
    });
    final route = section == EmailNotificationsSection.senderPreferences
        ? AppRoutes.settingsEmailNotifications
        : section == EmailNotificationsSection.emailInsights
        ? AppRoutes.settingsEmailInsights
        : AppRoutes.settingsCustomerReviewNotification;
    context.go(_withOrgPrefix(route));
  }

  void _openTemplate(_EmailTemplateConfig template) {
    setState(() {
      _section = EmailNotificationsSection.customerReviewNotification;
      _selectedTemplate = template;
    });
    context.go(
      _routeWithTemplate(
        AppRoutes.settingsCustomerReviewNotification,
        template.name,
      ),
    );
  }

  Future<void> _showAuthenticateDialog() async {
    if (GoRouterState.of(context).uri.queryParameters['dialog'] !=
        'authenticate') {
      context.go(_currentStateRoute(dialog: 'authenticate'));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAuthenticateDialog();
      });
      return;
    }
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x992A3140),
      builder: (dialogContext) {
        return const _AuthenticateDomainDialog();
      },
    );
    _clearDialogRoute();
  }

  Future<void> _showNewSenderDialog() async {
    if (GoRouterState.of(context).uri.queryParameters['dialog'] !=
        'new-sender') {
      context.go(_currentStateRoute(dialog: 'new-sender'));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showNewSenderDialog();
      });
      return;
    }
    final orgEmail = ref.read(orgSettingsProvider).asData?.value?.email?.trim();
    final emailOptions = orgEmail == null || orgEmail.isEmpty
        ? const <String>[]
        : <String>[orgEmail];
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x992A3140),
      builder: (dialogContext) {
        return _AddAdditionalContactDialog(emailOptions: emailOptions);
      },
    );
    _clearDialogRoute();
  }

  Future<void> _showSignatureDialog() async {
    if (GoRouterState.of(context).uri.queryParameters['dialog'] !=
        'signature') {
      context.go(_currentStateRoute(dialog: 'signature'));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSignatureDialog();
      });
      return;
    }
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x992A3140),
      builder: (dialogContext) => const _SignatureSettingsDialog(),
    );
    _clearDialogRoute();
  }

  List<SettingsSearchItem> _buildSearchItems() {
    return [
      SettingsSearchItem(
        group: 'Customization',
        label: 'Email Notifications',
        subtitle: 'All Settings',
        keywords: const <String>['emails', 'sender', 'preference'],
        onSelected: () =>
            context.go(_withOrgPrefix(AppRoutes.settingsEmailNotifications)),
      ),
      SettingsSearchItem(
        group: 'Emails',
        label: 'Sender Email Preferences',
        subtitle: 'Preferences',
        keywords: const <String>['sender', 'domain', 'authenticate'],
        onSelected: () =>
            _openSection(EmailNotificationsSection.senderPreferences),
      ),
      SettingsSearchItem(
        group: 'Emails',
        label: 'Email Insights',
        subtitle: 'Preferences',
        keywords: const <String>['insights'],
        onSelected: () => _openSection(EmailNotificationsSection.emailInsights),
      ),
      SettingsSearchItem(
        group: 'Emails',
        label: 'Customer Review Notification',
        subtitle: 'Templates',
        keywords: const <String>['template', 'customer', 'review'],
        onSelected: () =>
            _openSection(EmailNotificationsSection.customerReviewNotification),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final orgName = orgSettings?.name.trim().isNotEmpty == true
        ? orgSettings!.name.trim()
        : 'ZERPAI ERP';
    final currentPath = GoRouterState.of(context).uri.path;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.slash): _focusSearch,
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        body: Column(
          children: [
            _EmailNotificationsHeader(
              orgName: orgName,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              searchItems: _buildSearchItems(),
              onBack: () => context.go(_withOrgPrefix(AppRoutes.settings)),
              onClose: () => context.go(_withOrgPrefix(AppRoutes.home)),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsNavigationSidebar(currentPath: currentPath),
                  _EmailSectionNavigation(
                    activeSection: _section,
                    activeTemplateName: _selectedTemplate.name,
                    onSectionSelected: _openSection,
                    onTemplateSelected: _openTemplate,
                  ),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_section) {
      case EmailNotificationsSection.senderPreferences:
        return _EmailNotificationsContent(
          onNewSender: _showNewSenderDialog,
          onAuthenticateNow: _showAuthenticateDialog,
        );
      case EmailNotificationsSection.emailInsights:
        return const _EmailInsightsContent();
      case EmailNotificationsSection.customerReviewNotification:
        return _CustomerReviewNotificationContent(
          template: _selectedTemplate,
          initialEditTemplateName: widget.initialEditTemplateName,
          initialEditIsNew: widget.initialEditIsNew,
          onSignature: _showSignatureDialog,
        );
    }
  }
}

class _EmailNotificationsHeader extends StatelessWidget {
  const _EmailNotificationsHeader({
    required this.orgName,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchItems,
    required this.onBack,
    required this.onClose,
  });

  final String orgName;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<SettingsSearchItem> searchItems;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F3),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book_outlined,
              color: Color(0xFFFF5D5D),
              size: 26,
            ),
          ),
          Container(
            width: 1,
            height: 46,
            margin: const EdgeInsets.only(left: 14, right: 14),
            color: AppTheme.borderLight,
          ),
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 34,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD8DDF0)),
              ),
              child: const Icon(
                LucideIcons.chevronLeft,
                size: 20,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Settings',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                orgName,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 340,
            child: SettingsSearchField(
              controller: searchController,
              focusNode: searchFocusNode,
              items: searchItems,
            ),
          ),
          const SizedBox(width: 18),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Text(
                    'Close Settings',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.close, size: 15, color: Color(0xFFFF5C73)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailSectionNavigation extends StatefulWidget {
  const _EmailSectionNavigation({
    required this.activeSection,
    required this.activeTemplateName,
    required this.onSectionSelected,
    required this.onTemplateSelected,
  });

  final EmailNotificationsSection activeSection;
  final String activeTemplateName;
  final ValueChanged<EmailNotificationsSection> onSectionSelected;
  final ValueChanged<_EmailTemplateConfig> onTemplateSelected;

  @override
  State<_EmailSectionNavigation> createState() =>
      _EmailSectionNavigationState();
}

class _EmailSectionNavigationState extends State<_EmailSectionNavigation> {
  final ScrollController _scrollController = ScrollController();

  static const List<_EmailTemplateConfig> _templateItems =
      <_EmailTemplateConfig>[
        _EmailTemplateConfig(
          name: 'Customer Review Notification',
          description: 'Sent when requested for customer review',
          subject: '%CompanyName% has invited you to review their service',
        ),
        _EmailTemplateConfig(
          name: 'Item Notification',
          description: 'Sent when item notification is triggered',
          subject: '%CompanyName% has sent an item notification',
        ),
        _EmailTemplateConfig(
          name: 'Picklist Notification',
          description: 'Sent when picklist notification is triggered',
          subject: '%CompanyName% has sent a picklist notification',
        ),
        _EmailTemplateConfig(
          name: 'Batch Notification',
          description: 'Sent when batch notification is triggered',
          subject: '%CompanyName% has sent a batch notification',
        ),
        _EmailTemplateConfig(
          name: 'Task Notification',
          description: 'Sent when task notification is triggered',
          subject: '%CompanyName% has sent a task notification',
        ),
      ];

  static const List<_EmailTemplateConfig> _salesItems = <_EmailTemplateConfig>[
    _EmailTemplateConfig(
      name: 'Customer Notification',
      description: 'Sent when customer notification is triggered',
      subject: '%CompanyName% has sent a customer notification',
    ),
    _EmailTemplateConfig(
      name: 'Transfer Order Notification',
      description: 'Sent when transfer order notification is triggered',
      subject: '%CompanyName% has sent a transfer order notification',
    ),
    _EmailTemplateConfig(
      name: 'Customer Statement',
      description: 'Sent when customer statement is triggered',
      subject: '%CompanyName% has sent a customer statement',
    ),
    _EmailTemplateConfig(
      name: 'Retainer Invoice Notification',
      description: 'Sent when retainer invoice notification is triggered',
      subject: '%CompanyName% has sent a retainer invoice notification',
    ),
    _EmailTemplateConfig(
      name: 'Sales Order Notification',
      description: 'Sent when sales order notification is triggered',
      subject: '%CompanyName% has sent a sales order notification',
    ),
    _EmailTemplateConfig(
      name: 'Delivery Challan Notification',
      description: 'Sent when delivery challan notification is triggered',
      subject: '%CompanyName% has sent a delivery challan notification',
    ),
    _EmailTemplateConfig(
      name: 'Shipment Notification',
      description: 'Sent when shipment notification is triggered',
      subject: '%CompanyName% has sent a shipment notification',
    ),
    _EmailTemplateConfig(
      name: 'Delivery Notification',
      description: 'Sent when delivery notification is triggered',
      subject: '%CompanyName% has sent a delivery notification',
    ),
    _EmailTemplateConfig(
      name: 'Invoice Notification',
      description: 'Sent when invoice notification is triggered',
      subject: '%CompanyName% has sent an invoice notification',
    ),
    _EmailTemplateConfig(
      name: 'Sales Return Notification',
      description: 'Sent when sales return notification is triggered',
      subject: '%CompanyName% has sent a sales return notification',
    ),
    _EmailTemplateConfig(
      name: 'Credit Note Notification',
      description: 'Sent when credit note notification is triggered',
      subject: '%CompanyName% has sent a credit note notification',
    ),
    _EmailTemplateConfig(
      name: 'Customer Portal Invitation',
      description: 'Sent when customer portal invitation is triggered',
      subject: '%CompanyName% has sent a customer portal invitation',
    ),
    _EmailTemplateConfig(
      name: 'Customer Portal Link',
      description: 'Sent when customer portal link is triggered',
      subject: '%CompanyName% has sent a customer portal link',
    ),
  ];

  static const List<_EmailTemplateConfig> _purchaseItems =
      <_EmailTemplateConfig>[
        _EmailTemplateConfig(
          name: 'Vendor Statement',
          description: 'Sent when vendor statement is triggered',
          subject: '%CompanyName% has sent a vendor statement',
        ),
        _EmailTemplateConfig(
          name: 'Vendor Credit Notification',
          description: 'Sent when vendor credit notification is triggered',
          subject: '%CompanyName% has sent a vendor credit notification',
        ),
        _EmailTemplateConfig(
          name: 'Vendor Portal Invitation',
          description: 'Sent when vendor portal invitation is triggered',
          subject: '%CompanyName% has sent a vendor portal invitation',
        ),
        _EmailTemplateConfig(
          name: 'Expense Notification',
          description: 'Sent when expense notification is triggered',
          subject: '%CompanyName% has sent an expense notification',
        ),
        _EmailTemplateConfig(
          name: 'Purchase Order Notification',
          description: 'Sent when purchase order notification is triggered',
          subject: '%CompanyName% has sent a purchase order notification',
        ),
        _EmailTemplateConfig(
          name: 'Bill Notification',
          description: 'Sent when bill notification is triggered',
          subject: '%CompanyName% has sent a bill notification',
        ),
      ];

  static const List<_EmailTemplateConfig> _customerPaymentItems =
      <_EmailTemplateConfig>[
        _EmailTemplateConfig(
          name: 'Payment Thank-you',
          description: 'Sent when payment thank-you is triggered',
          subject: '%CompanyName% has sent a payment thank-you',
        ),
        _EmailTemplateConfig(
          name: 'Retainer Payment Thank you',
          description: 'Sent when retainer payment thank you is triggered',
          subject: '%CompanyName% has sent a retainer payment thank you',
        ),
      ];

  static const List<_EmailTemplateConfig> _vendorPaymentItems =
      <_EmailTemplateConfig>[
        _EmailTemplateConfig(
          name: 'Payment Initiated',
          description: 'Sent when payment initiated is triggered',
          subject: '%CompanyName% has sent a payment initiated notification',
        ),
        _EmailTemplateConfig(
          name: 'Payment Success',
          description: 'Sent when payment success is triggered',
          subject: '%CompanyName% has sent a payment success notification',
        ),
        _EmailTemplateConfig(
          name: 'Payment Failure',
          description: 'Sent when payment failure is triggered',
          subject: '%CompanyName% has sent a payment failure notification',
        ),
        _EmailTemplateConfig(
          name: 'Payment Made Notification',
          description: 'Sent when payment made notification is triggered',
          subject: '%CompanyName% has sent a payment made notification',
        ),
      ];

  static _EmailTemplateConfig? findTemplate(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final group in <List<_EmailTemplateConfig>>[
      _templateItems,
      _salesItems,
      _purchaseItems,
      _customerPaymentItems,
      _vendorPaymentItems,
    ]) {
      for (final item in group) {
        if (item.name == name) return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Text(
                'Emails',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 12, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PREFERENCES',
                    style: AppTheme.captionText.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF60708D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _EmailNavItem(
                    'Sender Email Preferences',
                    active:
                        widget.activeSection ==
                        EmailNotificationsSection.senderPreferences,
                    onTap: () => widget.onSectionSelected(
                      EmailNotificationsSection.senderPreferences,
                    ),
                  ),
                  _EmailNavItem(
                    'Email Insights',
                    active:
                        widget.activeSection ==
                        EmailNotificationsSection.emailInsights,
                    onTap: () => widget.onSectionSelected(
                      EmailNotificationsSection.emailInsights,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(label: 'TEMPLATES'),
                  ..._templateItems.map(
                    (item) => _EmailNavItem(
                      item.name,
                      active:
                          widget.activeSection ==
                              EmailNotificationsSection
                                  .customerReviewNotification &&
                          widget.activeTemplateName == item.name,
                      onTap: () => widget.onTemplateSelected(item),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(label: 'SALES'),
                  ..._salesItems.map(
                    (item) => _EmailNavItem(
                      item.name,
                      active:
                          widget.activeSection ==
                              EmailNotificationsSection
                                  .customerReviewNotification &&
                          widget.activeTemplateName == item.name,
                      onTap: () => widget.onTemplateSelected(item),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(label: 'PURCHASES'),
                  ..._purchaseItems.map(
                    (item) => _EmailNavItem(
                      item.name,
                      active:
                          widget.activeSection ==
                              EmailNotificationsSection
                                  .customerReviewNotification &&
                          widget.activeTemplateName == item.name,
                      onTap: () => widget.onTemplateSelected(item),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(label: 'CUSTOMER PAYMENTS'),
                  ..._customerPaymentItems.map(
                    (item) => _EmailNavItem(
                      item.name,
                      active:
                          widget.activeSection ==
                              EmailNotificationsSection
                                  .customerReviewNotification &&
                          widget.activeTemplateName == item.name,
                      onTap: () => widget.onTemplateSelected(item),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(label: 'VENDOR PAYMENTS'),
                  ..._vendorPaymentItems.map(
                    (item) => _EmailNavItem(
                      item.name,
                      active:
                          widget.activeSection ==
                              EmailNotificationsSection
                                  .customerReviewNotification &&
                          widget.activeTemplateName == item.name,
                      onTap: () => widget.onTemplateSelected(item),
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: AppTheme.captionText.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF60708D),
        ),
      ),
    );
  }
}

class _EmailNavItem extends StatelessWidget {
  const _EmailNavItem(this.label, {this.active = false, this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF3F4F8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: const Color(0xFF20304A),
          ),
        ),
      ),
    );
  }
}

class _EmailInsightsContent extends StatefulWidget {
  const _EmailInsightsContent();

  @override
  State<_EmailInsightsContent> createState() => _EmailInsightsContentState();
}

class _EmailInsightsContentState extends State<_EmailInsightsContent> {
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              'Email Insights',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 670),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Track the emails sent to your customers',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF232B3A),
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.82,
                            alignment: Alignment.centerRight,
                            child: Switch(
                              value: _enabled,
                              onChanged: (value) {
                                setState(() {
                                  _enabled = value;
                                });
                              },
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFF3B7CFF),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: const Color(0xFFD9D9D9),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              trackOutlineColor:
                                  WidgetStateProperty.resolveWith<Color?>(
                                    (states) => Colors.transparent,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: const Color(0xFFE5E8EF),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'By enabling Email Insights, you can:',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6F7891),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _InsightBullet(
                      text:
                          'Track the emails that are sent for Invoices and Sales Orders.',
                    ),
                    const SizedBox(height: 16),
                    const _InsightBullet(
                      text:
                          'View the time when the email was opened, in the transaction list and details page.',
                    ),
                    const SizedBox(height: 16),
                    const _InsightBullet(
                      text:
                          "View the list of transactions viewed via email by the customer, when you filter by 'Client Viewed'.",
                    ),
                    const SizedBox(height: 72),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Note:',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF31394D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '- If you enable Email Insights, the emails sent from your Zoho Inventory organization will be tracked to know when your customer has viewed them.',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              height: 1.65,
                              color: const Color(0xFF424A5E),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '- If the email you sent has multiple recipients, the corresponding transaction will be marked as viewed when any one of them opens it.',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              height: 1.65,
                              color: const Color(0xFF424A5E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightBullet extends StatelessWidget {
  const _InsightBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check, size: 18, color: Color(0xFF4D9B50)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodyText.copyWith(
              fontSize: 14,
              height: 1.5,
              color: const Color(0xFF232B3A),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailTemplateConfig {
  const _EmailTemplateConfig({
    required this.name,
    required this.description,
    required this.subject,
  });

  final String name;
  final String description;
  final String subject;
}

_EmailTemplateConfig? _emailTemplateForName(String? name) {
  return _EmailSectionNavigationState.findTemplate(name);
}

class _CustomerReviewNotificationContent extends StatefulWidget {
  const _CustomerReviewNotificationContent({
    required this.template,
    required this.initialEditTemplateName,
    required this.initialEditIsNew,
    required this.onSignature,
  });

  final _EmailTemplateConfig template;
  final String? initialEditTemplateName;
  final bool initialEditIsNew;
  final VoidCallback onSignature;

  @override
  State<_CustomerReviewNotificationContent> createState() =>
      _CustomerReviewNotificationContentState();
}

class _CustomerReviewNotificationContentState
    extends State<_CustomerReviewNotificationContent> {
  final ApiClient _apiClient = ApiClient();
  int? _hoveredIndex;
  bool _isEditingTemplate = false;
  bool _isNewTemplate = false;
  String? _originalTemplateName;
  late final TextEditingController _templateNameController;
  late final TextEditingController _subjectController;
  late List<Map<String, dynamic>> _templatesList;

  @override
  void initState() {
    super.initState();
    _templateNameController = TextEditingController(text: 'Default');
    _subjectController = TextEditingController(text: widget.template.subject);
    _templatesList = [];
    _loadTemplates();
    _isEditingTemplate =
        widget.initialEditIsNew || widget.initialEditTemplateName != null;
    _isNewTemplate = widget.initialEditIsNew;
    _originalTemplateName = widget.initialEditTemplateName;
    if (widget.initialEditIsNew) {
      _templateNameController.clear();
      _subjectController.clear();
    } else if (widget.initialEditTemplateName != null) {
      _templateNameController.text = widget.initialEditTemplateName!;
      final initialIndex = _templatesList.indexWhere(
        (item) => item['name'] == widget.initialEditTemplateName,
      );
      if (initialIndex != -1) {
        _subjectController.text =
            _templatesList[initialIndex]['subject'] as String? ?? '';
      }
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final response = await _apiClient.get(
        'settings-customization/email-notification-templates',
        queryParameters: {'module': widget.template.name},
        useCache: false,
      );
      final rows = (response.data as List? ?? const []).whereType<Map>().map((
        raw,
      ) {
        final row = Map<String, dynamic>.from(raw);
        return <String, dynamic>{
          'id': row['id']?.toString(),
          'name': row['event_code']?.toString() ?? '',
          'isDefault': false,
          'subject': row['subject_template']?.toString() ?? '',
          'body': row['body_template']?.toString() ?? '',
        };
      }).toList();
      if (mounted) setState(() => _templatesList = rows);
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to load email templates');
    }
  }

  @override
  void didUpdateWidget(covariant _CustomerReviewNotificationContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final editStateChanged =
        oldWidget.initialEditTemplateName != widget.initialEditTemplateName ||
        oldWidget.initialEditIsNew != widget.initialEditIsNew;
    if (oldWidget.template.name != widget.template.name) {
      _subjectController.text = widget.template.subject;
      _isEditingTemplate = false;
      _hoveredIndex = null;
      _templatesList = [];
      _loadTemplates();
    }
    if (editStateChanged) {
      _isEditingTemplate =
          widget.initialEditIsNew || widget.initialEditTemplateName != null;
      _isNewTemplate = widget.initialEditIsNew;
      _originalTemplateName = widget.initialEditTemplateName;
    }
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _openEditRoute({String? templateName, required bool isNew}) {
    final uri = GoRouterState.of(context).uri;
    final query = <String, String>{...uri.queryParameters};
    query['mode'] = isNew ? 'new' : 'edit';
    if (templateName == null || templateName.isEmpty) {
      query.remove('item');
    } else {
      query['item'] = templateName;
    }
    context.go(uri.replace(queryParameters: query).toString());
  }

  void _closeEditRoute() {
    final uri = GoRouterState.of(context).uri;
    final query = <String, String>{...uri.queryParameters}
      ..remove('mode')
      ..remove('item');
    context.go(uri.replace(queryParameters: query).toString());
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditingTemplate) {
      bool currentIsDefault = false;
      if (!_isNewTemplate && _originalTemplateName != null) {
        final idx = _templatesList.indexWhere(
          (t) => t['name'] == _originalTemplateName,
        );
        if (idx != -1) {
          currentIsDefault = _templatesList[idx]['isDefault'] as bool? ?? false;
        }
      }

      return _CustomerReviewNotificationEditContent(
        templateTitle: widget.template.name,
        templateNameController: _templateNameController,
        subjectController: _subjectController,
        isNew: _isNewTemplate,
        isDefault: currentIsDefault,
        onClose: () {
          setState(() {
            _isEditingTemplate = false;
          });
          _closeEditRoute();
        },
        onSave: (name, subject, isDefault) async {
          final cleanName = name.trim().isEmpty ? 'Untitled' : name.trim();
          final cleanSubject = subject.trim();
          try {
            final existingIndex = _templatesList.indexWhere(
              (item) => item['name'] == _originalTemplateName,
            );
            final existingId = existingIndex == -1
                ? null
                : _templatesList[existingIndex]['id']?.toString();
            final payload = {
              'module': widget.template.name,
              'event_code': cleanName,
              'subject_template': cleanSubject,
              'body_template': existingIndex == -1
                  ? ''
                  : _templatesList[existingIndex]['body']?.toString() ?? '',
              'is_active': true,
            };
            if (_isNewTemplate || existingId == null || existingId.isEmpty) {
              await _apiClient.post(
                'settings-customization/email-notification-templates',
                data: payload,
              );
            } else {
              await _apiClient.patch(
                'settings-customization/email-notification-templates/$existingId',
                data: payload,
              );
            }
            await _loadTemplates();
            if (!mounted) return;
            setState(() => _isEditingTemplate = false);
            _closeEditRoute();
            ZerpaiToast.success(context, 'Template saved successfully');
          } catch (_) {
            if (mounted) ZerpaiToast.error(context, 'Failed to save template');
          }
        },
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.template.name,
                        style: AppTheme.pageTitle.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.template.description,
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF2E3443),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.template.name != 'Customer Review Notification' &&
                    widget.template.name != 'Customer Portal Invitation' &&
                    widget.template.name != 'Vendor Portal Invitation') ...[
                  InkWell(
                    onTap: () {
                      _openEditRoute(isNew: true);
                      setState(() {
                        _templateNameController.text = '';
                        _subjectController.text = '';
                        _isNewTemplate = true;
                        _isEditingTemplate = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF29B765),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+ New',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 300,
                          child: Text(
                            'NAME',
                            style: AppTheme.captionText.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6F7891),
                            ),
                          ),
                        ),
                        Text(
                          'SUBJECT AND CONTENT',
                          style: AppTheme.captionText.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6F7891),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_templatesList.isEmpty) ...[
                    Container(
                      height: 180,
                      alignment: Alignment.center,
                      child: Text(
                        'There are no templates for this module',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ] else ...[
                    Column(
                      children: List.generate(_templatesList.length, (index) {
                        final item = _templatesList[index];
                        final isHovered = _hoveredIndex == index;
                        return MouseRegion(
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
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(color: AppTheme.borderLight),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 300,
                                  child: Row(
                                    children: [
                                      Text(
                                        item['name'] as String,
                                        style: AppTheme.bodyText.copyWith(
                                          fontSize: 13,
                                          color: AppTheme.primaryBlue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (item['isDefault'] as bool) ...[
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3F8EDE),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                          child: Text(
                                            'DEFAULT',
                                            style: AppTheme.captionText
                                                .copyWith(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['subject'] as String,
                                        style: AppTheme.bodyText.copyWith(
                                          fontSize: 13,
                                          color: const Color(0xFF222B39),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () {
                                          _openEditRoute(
                                            templateName:
                                                item['name'] as String,
                                            isNew: false,
                                          );
                                          setState(() {
                                            _templateNameController.text =
                                                item['name'] as String;
                                            _originalTemplateName =
                                                item['name'] as String;
                                            _isNewTemplate = false;
                                            _isEditingTemplate = true;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            'Show Mail Content',
                                            style: AppTheme.bodyText.copyWith(
                                              fontSize: 13,
                                              color: AppTheme.primaryBlue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 32,
                                  child: AnimatedOpacity(
                                    opacity: isHovered ? 1 : 0,
                                    duration: const Duration(milliseconds: 120),
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: _HoverSuccessMenu(
                                        onEdit: () {
                                          _openEditRoute(
                                            templateName:
                                                item['name'] as String,
                                            isNew: false,
                                          );
                                          setState(() {
                                            _templateNameController.text =
                                                item['name'] as String;
                                            _originalTemplateName =
                                                item['name'] as String;
                                            _isNewTemplate = false;
                                            _isEditingTemplate = true;
                                          });
                                        },
                                        onClone:
                                            (widget.template.name ==
                                                    'Customer Review Notification' ||
                                                widget.template.name ==
                                                    'Customer Portal Invitation' ||
                                                widget.template.name ==
                                                    'Vendor Portal Invitation')
                                            ? null
                                            : () {
                                                final newName =
                                                    '${item['name']} Copy';
                                                final newClone = {
                                                  'name': newName,
                                                  'isDefault': false,
                                                  'subject': item['subject'],
                                                };
                                                setState(() {
                                                  _templatesList.add(newClone);
                                                  _templateNameController.text =
                                                      newName;
                                                  _originalTemplateName =
                                                      newName;
                                                  _isNewTemplate = false;
                                                  _isEditingTemplate = true;
                                                });
                                                _openEditRoute(
                                                  templateName: newName,
                                                  isNew: false,
                                                );
                                                ZerpaiToast.success(
                                                  context,
                                                  'Template cloned successfully',
                                                );
                                              },
                                        onDelete:
                                            (widget.template.name ==
                                                    'Customer Review Notification' ||
                                                widget.template.name ==
                                                    'Customer Portal Invitation' ||
                                                widget.template.name ==
                                                    'Vendor Portal Invitation')
                                            ? null
                                            : () async {
                                                final id = item['id']
                                                    ?.toString();
                                                if (id == null || id.isEmpty)
                                                  return;
                                                try {
                                                  await _apiClient.delete(
                                                    'settings-customization/email-notification-templates/$id',
                                                  );
                                                  if (!mounted) return;
                                                  setState(
                                                    () => _templatesList
                                                        .removeAt(index),
                                                  );
                                                  ZerpaiToast.deleted(
                                                    context,
                                                    item['name'] as String,
                                                  );
                                                } catch (_) {
                                                  if (mounted)
                                                    ZerpaiToast.error(
                                                      context,
                                                      'Failed to delete template',
                                                    );
                                                }
                                              },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: widget.onSignature,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 107.26,
                          height: 32.32,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFC8CDD8)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Edit Signature',
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12,
                              color: const Color(0xFF2E3443),
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

class _CustomerReviewNotificationEditContent extends StatefulWidget {
  const _CustomerReviewNotificationEditContent({
    required this.templateTitle,
    required this.templateNameController,
    required this.subjectController,
    required this.onClose,
    required this.onSave,
    this.isNew = false,
    this.isDefault = false,
  });

  final String templateTitle;
  final TextEditingController templateNameController;
  final TextEditingController subjectController;
  final VoidCallback onClose;
  final void Function(String name, String subject, bool isDefault) onSave;
  final bool isNew;
  final bool isDefault;

  @override
  State<_CustomerReviewNotificationEditContent> createState() =>
      _CustomerReviewNotificationEditContentState();
}

class _CustomerReviewNotificationEditContentState
    extends State<_CustomerReviewNotificationEditContent> {
  bool _isDefault = false;
  String? _selectedFromEmail;
  List<String> _selectedCcEmails = <String>[];
  List<String> _selectedBccEmails = <String>[];
  static const List<_PlaceholderItem> _placeholderItems = <_PlaceholderItem>[
    _PlaceholderItem('PORTAL', 'Portal URL', '%PortalURL%'),
    _PlaceholderItem('PORTAL', 'Portal Name', '%PortalName%'),
    _PlaceholderItem(
      'PORTAL',
      'Invitation Accept URL',
      '%InvitationAcceptURL%',
    ),
    _PlaceholderItem('CONTACT PERSON', 'Company Name', '%CompanyName%'),
    _PlaceholderItem('CONTACT PERSON', 'Salutation', '%Salutation%'),
    _PlaceholderItem('CONTACT PERSON', 'FirstName', '%FirstName%'),
    _PlaceholderItem('CONTACT PERSON', 'LastName', '%LastName%'),
    _PlaceholderItem('CONTACT PERSON', 'EmailID', '%EmailID%'),
    _PlaceholderItem('CONTACT PERSON', 'Department', '%Department%'),
    _PlaceholderItem('CONTACT PERSON', 'Designation', '%Designation%'),
    _PlaceholderItem('ORGANIZATION', 'Name', '%OrgName%'),
    _PlaceholderItem('ORGANIZATION', 'User', '%UserName%'),
    _PlaceholderItem('ORGANIZATION', 'User Role', '%UserRole%'),
    _PlaceholderItem('ORGANIZATION', 'Email', '%OrgEmail%'),
    _PlaceholderItem('ORGANIZATION', 'Phone#', '%OrgPhone%'),
    _PlaceholderItem('ORGANIZATION', 'Fax#', '%OrgFax%'),
    _PlaceholderItem('ORGANIZATION', 'Website', '%OrgWebsite%'),
    _PlaceholderItem('ORGANIZATION', 'Label 1', '%Label1%'),
    _PlaceholderItem('ORGANIZATION', 'Value 1', '%Value1%'),
    _PlaceholderItem('ORGANIZATION', 'Logo', '%OrgLogo%'),
    _PlaceholderItem('ORGANIZATION', 'Signature', '%Signature%'),
    _PlaceholderItem('ORGANIZATION', 'Company GSTIN', '%CompanyGSTIN%'),
  ];
  static const Set<String> _itemStyleEditorTemplates = <String>{
    'Item Notification',
    'Picklist Notification',
    'Batch Notification',
    'Task Notification',
    'Customer Notification',
    'Transfer Order Notification',
    'Customer Statement',
    'Retainer Invoice Notification',
    'Sales Order Notification',
    'Delivery Challan Notification',
    'Shipment Notification',
    'Delivery Notification',
    'Invoice Notification',
    'Sales Return Notification',
    'Credit Note Notification',
    'Customer Portal Invitation',
    'Customer Portal Link',
    'Vendor Statement',
    'Vendor Credit Notification',
    'Vendor Portal Invitation',
    'Expense Notification',
    'Purchase Order Notification',
    'Bill Notification',
    'Payment Thank-you',
    'Retainer Payment Thank you',
    'Payment Initiated',
    'Payment Success',
    'Payment Failure',
    'Payment Made Notification',
  };
  static const List<String> _textStyleItems = <String>[
    'Normal Text',
    'Heading 1',
    'Heading 2',
    'Heading 3',
    'Heading 4',
    'Heading 5',
    'Heading 6',
  ];
  static const List<String> _signatureFontFamilyItems = <String>[
    'Calibri',
    'Courier New',
    'Georgia',
    'Serif',
    'Roboto',
    'Times New Roman',
    'Trebuchet MS',
    'Arial',
    'Tahoma',
    'Verdana',
    'Comic Sans MS',
  ];
  static const List<String> _signatureFontSizeItems = <String>[
    '10px',
    '13px',
    '16px',
    '18px',
    '24px',
    '32px',
    '48px',
  ];

  String _selectedTextStyle = 'Normal Text';
  String _selectedFontSize = '16px';
  String _selectedFontFamily = 'Arial';
  TextAlign _contentAlignment = TextAlign.left;
  Color _selectedTextColor = const Color(0xFF1C2434);
  Color _selectedHighlightColor = Colors.transparent;
  bool _bold = false;
  bool _italic = false;
  bool _underline = false;
  bool _strike = false;

  String _lastEditorText = '';
  _EditorListMode _activeListMode = _EditorListMode.none;
  _PlaceholderItem? _selectedPlaceholder;
  late final _StyledTextEditingController _plainEditorController;
  late final ScrollController _plainEditorScrollController;
  late final TextEditingController _logoController;
  late final TextEditingController _heroTitleController;
  late final TextEditingController _heroSubtitleController;
  late final TextEditingController _greetingController;
  late final TextEditingController _bodyLineOneController;
  late final TextEditingController _bodyLineTwoController;
  late final TextEditingController _buttonLabelController;
  late final TextEditingController _closingLabelController;
  late final TextEditingController _closingNameController;
  late final FocusNode _logoFocusNode;
  late final FocusNode _heroTitleFocusNode;
  late final FocusNode _heroSubtitleFocusNode;
  late final FocusNode _greetingFocusNode;
  late final FocusNode _bodyLineOneFocusNode;
  late final FocusNode _bodyLineTwoFocusNode;
  late final FocusNode _buttonLabelFocusNode;
  late final FocusNode _closingLabelFocusNode;
  late final FocusNode _closingNameFocusNode;

  @override
  void initState() {
    super.initState();
    _isDefault = false;
    _plainEditorController = _StyledTextEditingController()
      ..text = _initialEditorText();
    _plainEditorScrollController = ScrollController();
    final bool isBlank =
        widget.isNew || widget.templateTitle == 'Customer Review Notification';
    _logoController = TextEditingController(text: isBlank ? '' : '%OrgLogo%');
    _heroTitleController = TextEditingController(
      text: isBlank ? '' : 'Rate our service',
    );
    _heroSubtitleController = TextEditingController(
      text: isBlank ? '' : 'Help us to serve you better',
    );
    _greetingController = TextEditingController(
      text: isBlank ? '' : 'Hi %FirstName%,',
    );
    _bodyLineOneController = TextEditingController(
      text: isBlank
          ? ''
          : '%CompanyName% would like to know how much you like being their client.',
    );
    _bodyLineTwoController = TextEditingController(
      text: isBlank
          ? ''
          : '"It was a pleasure doing business with you. Your suggestions would be of great value. If you wish to write about your experience with us, kindly click on the link below."',
    );
    _buttonLabelController = TextEditingController(
      text: isBlank ? '' : 'Click to Rate',
    );
    _closingLabelController = TextEditingController(
      text: isBlank ? '' : 'Your Sincerely,',
    );
    _closingNameController = TextEditingController(
      text: isBlank ? '' : '%UserName%',
    );
    _logoFocusNode = FocusNode();
    _heroTitleFocusNode = FocusNode();
    _heroSubtitleFocusNode = FocusNode();
    _greetingFocusNode = FocusNode();
    _bodyLineOneFocusNode = FocusNode();
    _bodyLineTwoFocusNode = FocusNode();
    _buttonLabelFocusNode = FocusNode();
    _closingLabelFocusNode = FocusNode();
    _closingNameFocusNode = FocusNode();
    _plainEditorController.typingStyle = _currentEditorTypingStyle();
    _lastEditorText = _plainEditorController.text;
    _plainEditorController.addListener(_handleEditorChanged);
  }

  @override
  void dispose() {
    _plainEditorController.removeListener(_handleEditorChanged);
    _plainEditorController.dispose();
    _plainEditorScrollController.dispose();
    _logoController.dispose();
    _heroTitleController.dispose();
    _heroSubtitleController.dispose();
    _greetingController.dispose();
    _bodyLineOneController.dispose();
    _bodyLineTwoController.dispose();
    _buttonLabelController.dispose();
    _closingLabelController.dispose();
    _closingNameController.dispose();
    _logoFocusNode.dispose();
    _heroTitleFocusNode.dispose();
    _heroSubtitleFocusNode.dispose();
    _greetingFocusNode.dispose();
    _bodyLineOneFocusNode.dispose();
    _bodyLineTwoFocusNode.dispose();
    _buttonLabelFocusNode.dispose();
    _closingLabelFocusNode.dispose();
    _closingNameFocusNode.dispose();
    super.dispose();
  }

  String _initialEditorText() {
    if (widget.isNew ||
        widget.templateTitle == 'Customer Review Notification') {
      return '';
    }
    if (_itemStyleEditorTemplates.contains(widget.templateTitle)) {
      return 'fwe';
    }

    return [
      '%OrgLogo%',
      '',
      'Rate our service',
      'Help us to serve you better',
      '',
      'Hi %FirstName%,',
      '',
      '%CompanyName% would like to know how much you like being their client.',
      '',
      '"It was a pleasure doing business with you. Your suggestions would be of great value. If you wish to write about your experience with us, kindly click on the link below."',
      '',
      'Click to Rate',
      '',
      'Your Sincerely,',
      '%UserName%',
    ].join('\n');
  }

  void _insertPlaceholderItem(_PlaceholderItem item) {
    final String text = _plainEditorController.text;
    final TextSelection selection = _plainEditorController.selection;
    final int start = selection.isValid && selection.start >= 0
        ? selection.start
        : text.length;
    final int end = selection.isValid && selection.end >= 0
        ? selection.end
        : text.length;
    final String nextText = text.replaceRange(start, end, item.token);
    setState(() {
      _selectedPlaceholder = item;
      _plainEditorController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: start + item.token.length),
      );
    });
  }

  TextStyle _fontFamilyStyleFor(String fontFamily, TextStyle baseStyle) {
    if (fontFamily == 'Roboto') {
      return GoogleFonts.roboto(textStyle: baseStyle);
    }

    return baseStyle.copyWith(
      fontFamily: fontFamily == 'Arial' ? null : fontFamily,
    );
  }

  double _resolvedFontSize() {
    return double.tryParse(_selectedFontSize.replaceAll('px', '').trim()) ?? 16;
  }

  TextStyle _currentEditorTypingStyle() {
    final TextStyle baseStyle = AppTheme.bodyText.copyWith(
      fontSize: _resolvedFontSize(),
      fontWeight: _bold ? FontWeight.w700 : FontWeight.w400,
      fontStyle: _italic ? FontStyle.italic : FontStyle.normal,
      decoration: _underline
          ? TextDecoration.underline
          : _strike
          ? TextDecoration.lineThrough
          : TextDecoration.none,
      color: _selectedTextColor,
      backgroundColor: _selectedHighlightColor,
      height: 1.45,
    );
    return _applyTextStylePreset(
      _fontFamilyStyleFor(_selectedFontFamily, baseStyle),
    );
  }

  TextStyle _applyTextStylePreset(TextStyle style) {
    switch (_selectedTextStyle) {
      case 'Heading 1':
        return style.copyWith(fontSize: 28, fontWeight: FontWeight.w700);
      case 'Heading 2':
        return style.copyWith(fontSize: 24, fontWeight: FontWeight.w700);
      case 'Heading 3':
        return style.copyWith(fontSize: 20, fontWeight: FontWeight.w600);
      case 'Heading 4':
        return style.copyWith(fontSize: 18, fontWeight: FontWeight.w600);
      case 'Heading 5':
        return style.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
      case 'Heading 6':
        return style.copyWith(fontSize: 15, fontWeight: FontWeight.w600);
      case 'Normal Text':
      default:
        return style;
    }
  }

  void _applySelectionOrTyping(
    TextStyle Function(TextStyle current) transform,
  ) {
    if (_plainEditorController.hasActiveSelection) {
      _plainEditorController.applyStyleToSelection(transform);
    }
    _refreshTypingStyle();
  }

  void _refreshTypingStyle() {
    _plainEditorController.typingStyle = _currentEditorTypingStyle();
  }

  void _handleEditorChanged() {
    final String currentText = _plainEditorController.text;
    _plainEditorController.syncStyleRuns(
      oldText: _lastEditorText,
      newText: currentText,
    );
    _lastEditorText = currentText;
  }

  void _replaceSelectionText(String replacement) {
    final String text = _plainEditorController.text;
    final TextSelection selection = _plainEditorController.selection;
    final int start = selection.isValid && selection.start >= 0
        ? selection.start
        : text.length;
    final int end = selection.isValid && selection.end >= 0
        ? selection.end
        : text.length;
    final String nextText = text.replaceRange(start, end, replacement);
    _plainEditorController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  void _transformSelectedLines(
    String Function(String line, int index) transform,
  ) {
    final String text = _plainEditorController.text;
    final TextSelection selection = _plainEditorController.selection;
    final int start = selection.isValid && selection.start >= 0
        ? selection.start
        : 0;
    final int end = selection.isValid && selection.end >= 0
        ? selection.end
        : text.length;

    int lineStart = text.lastIndexOf('\n', start > 0 ? start - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;
    int lineEnd = text.indexOf('\n', end);
    lineEnd = lineEnd == -1 ? text.length : lineEnd;

    final String block = text.substring(lineStart, lineEnd);
    final List<String> lines = block.split('\n');
    final String updatedBlock = List<String>.generate(
      lines.length,
      (index) => transform(lines[index], index),
    ).join('\n');

    final String nextText = text.replaceRange(lineStart, lineEnd, updatedBlock);
    _plainEditorController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection(
        baseOffset: lineStart,
        extentOffset: lineStart + updatedBlock.length,
      ),
    );
  }

  void _applyIndentChange(bool increase) {
    _transformSelectedLines((line, _) {
      if (increase) {
        return '  $line';
      }
      return line.startsWith('  ')
          ? line.substring(2)
          : line.startsWith(' ')
          ? line.substring(1)
          : line;
    });
  }

  void _applyAlignment(TextAlign align) {
    setState(() => _contentAlignment = align);
  }

  void _applyBulletedList(bool ordered) {
    final _EditorListMode nextMode = ordered
        ? _EditorListMode.ordered
        : _EditorListMode.bullet;

    if (!_plainEditorController.hasActiveSelection) {
      setState(() {
        _activeListMode = nextMode;
      });

      final String text = _plainEditorController.text;
      final TextSelection selection = _plainEditorController.selection;
      final int cursor = selection.isValid && selection.baseOffset >= 0
          ? selection.baseOffset
          : text.length;
      int lineStart = text.lastIndexOf('\n', cursor > 0 ? cursor - 1 : 0);
      lineStart = lineStart == -1 ? 0 : lineStart + 1;
      int lineEnd = text.indexOf('\n', cursor);
      lineEnd = lineEnd == -1 ? text.length : lineEnd;
      final String line = text.substring(lineStart, lineEnd);
      if (line.trim().isEmpty) {
        final String marker = ordered ? '1. ' : '\u2022 ';
        final String nextText = text.replaceRange(lineStart, lineEnd, marker);
        _plainEditorController.value = TextEditingValue(
          text: nextText,
          selection: TextSelection.collapsed(
            offset: (lineStart + marker.length).clamp(0, nextText.length),
          ),
        );
        _lastEditorText = nextText;
      }
      return;
    }

    setState(() {
      _activeListMode = nextMode;
    });
    _transformSelectedLines((line, index) {
      final String indent = RegExp(r'^\s*').firstMatch(line)?.group(0) ?? '';
      String content = line.substring(indent.length);
      content = content.replaceFirst(RegExp(r'^(?:-|\*|\u2022)\s+'), '');
      content = content.replaceFirst(RegExp(r'^\d+\.\s+'), '');

      if (ordered) {
        return '$indent${index + 1}. $content';
      }
      return '${indent}\u2022 $content';
    });
  }

  void _insertImageTag(String url) {
    if (url.trim().isEmpty) return;
    _replaceSelectionText('<img src="${url.trim()}" alt="image" />');
  }

  void _insertLinkTag(String text, String url) {
    final String cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;
    final String label = text.trim().isEmpty ? cleanUrl : text.trim();
    _replaceSelectionText('<a href="$cleanUrl">$label</a>');
  }

  void _insertVideoTag() {
    _replaceSelectionText('<video controls src=""></video>');
  }

  Widget _buildRichEditorSurface({required double height}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF6F7FB),
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                _ToolbarDropdown(
                  label: _selectedTextStyle,
                  items: _textStyleItems,
                  onSelected: (value) {
                    setState(() {
                      _selectedTextStyle = value;
                    });
                    _applySelectionOrTyping(_applyTextStylePreset);
                  },
                ),
                const _ToolbarDivider(horizontal: 10),
                _ToolbarText(
                  label: 'B',
                  bold: true,
                  active: _bold,
                  onTap: () {
                    setState(() {
                      _bold = !_bold;
                    });
                    _applySelectionOrTyping(
                      (current) => current.copyWith(
                        fontWeight: _bold ? FontWeight.w700 : FontWeight.w400,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 18),
                _ToolbarText(
                  label: 'I',
                  italic: true,
                  active: _italic,
                  onTap: () {
                    setState(() {
                      _italic = !_italic;
                    });
                    _applySelectionOrTyping(
                      (current) => current.copyWith(
                        fontStyle: _italic
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 18),
                _ToolbarText(
                  label: 'U',
                  underline: true,
                  active: _underline,
                  onTap: () {
                    setState(() {
                      _underline = !_underline;
                      if (_underline) _strike = false;
                    });
                    _applySelectionOrTyping(
                      (current) => current.copyWith(
                        decoration: _underline
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 18),
                _ToolbarText(
                  label: 'S',
                  strike: true,
                  active: _strike,
                  onTap: () {
                    setState(() {
                      _strike = !_strike;
                      if (_strike) _underline = false;
                    });
                    _applySelectionOrTyping(
                      (current) => current.copyWith(
                        decoration: _strike
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    );
                  },
                ),
                const _ToolbarDivider(horizontal: 10),
                _SignatureColorDropdown(
                  isHighlight: false,
                  color: _selectedTextColor,
                  onApply: (color) {
                    setState(() {
                      _selectedTextColor = color;
                    });
                    _applySelectionOrTyping(
                      (current) => current.copyWith(color: color),
                    );
                  },
                ),
                const SizedBox(width: 18),
                _SignatureColorDropdown(
                  isHighlight: true,
                  color: _selectedHighlightColor == Colors.transparent
                      ? Colors.black
                      : _selectedHighlightColor,
                  onDoubleTap: () {
                    setState(() {
                      _selectedHighlightColor = Colors.transparent;
                    });
                    _applySelectionOrTyping(
                      (current) =>
                          current.copyWith(backgroundColor: Colors.transparent),
                    );
                  },
                  onApply: (color) {
                    setState(() {
                      _selectedHighlightColor = color;
                    });
                    _applySelectionOrTyping(
                      (current) => current.copyWith(backgroundColor: color),
                    );
                  },
                ),
                const _ToolbarDivider(horizontal: 10),
                _SignatureFontSizeDropdown(
                  label: _selectedFontSize,
                  items: _signatureFontSizeItems,
                  onSelected: (value) {
                    setState(() {
                      _selectedFontSize = value;
                    });
                    _applySelectionOrTyping(
                      (current) =>
                          current.copyWith(fontSize: _resolvedFontSize()),
                    );
                  },
                ),
                const _ToolbarDivider(horizontal: 10),
                _SignatureFontFamilyDropdown(
                  label: _selectedFontFamily,
                  items: _signatureFontFamilyItems,
                  textStyleBuilder: (fontFamily, baseStyle) =>
                      _fontFamilyStyleFor(fontFamily, baseStyle),
                  onSelected: (value) {
                    setState(() {
                      _selectedFontFamily = value;
                    });
                    _applySelectionOrTyping(
                      (current) =>
                          _fontFamilyStyleFor(_selectedFontFamily, current),
                    );
                  },
                ),
                const SizedBox(width: 10),
                _SignatureInlineToolbarTools(
                  onIndentChange: _applyIndentChange,
                  onAlignChange: _applyAlignment,
                  onListChange: _applyBulletedList,
                  onImageInsert: _insertImageTag,
                  onLinkInsert: _insertLinkTag,
                  onVideoInsert: _insertVideoTag,
                ),
                const Spacer(),
                _PlaceholderToolbarDropdown(
                  value: _selectedPlaceholder,
                  items: _placeholderItems,
                  onSelected: _insertPlaceholderItem,
                ),
              ],
            ),
          ),
          SizedBox(
            height: height,
            child: Container(
              color: Colors.white,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderLight)),
                ),
                child: TextField(
                  controller: _plainEditorController,
                  scrollController: _plainEditorScrollController,
                  inputFormatters: [
                    _EditorListFormatter(
                      getMode: () => _activeListMode,
                      onModeChanged: (mode) => _activeListMode = mode,
                    ),
                  ],
                  maxLines: null,
                  expands: true,
                  textAlign: _contentAlignment,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  style: _currentEditorTypingStyle(),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    contentPadding: EdgeInsets.fromLTRB(18, 14, 18, 14),
                    border: InputBorder.none,
                    hoverColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_itemStyleEditorTemplates.contains(widget.templateTitle)) {
      return _buildItemNotificationEditor(context);
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 68,
            padding: const EdgeInsets.fromLTRB(22, 0, 18, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.templateTitle} - Default',
                    style: AppTheme.pageTitle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: widget.onClose,
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 24,
                      color: Color(0xFF7B7B7B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF3FF),
                      border: Border(
                        left: BorderSide(color: AppTheme.primaryBlue, width: 3),
                        bottom: BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add the Communication Languages for your organization to send emails in multiple languages to your customers and vendors. Once done, create new templates to use the feature.',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF2E3443),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 215,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Template Name*',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: const Color(0xFFFF3B30),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CustomTextField(
                            controller: widget.templateNameController,
                            height: 38,
                            contentCase: ContentCase.none,
                            forceUppercase: false,
                            fillColor: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF2E3443),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (const <String>{
                    'Vendor Credit Notification',
                    'Customer Statement',
                    'Retainer Invoice Notification',
                    'Sales Order Notification',
                    'Invoice Notification',
                    'Sales Return Notification',
                    'Credit Note Notification',
                    'Vendor Statement',
                    'Purchase Order Notification',
                    'Payment Thank-you',
                    'Payment Initiated',
                    'Payment Success',
                    'Payment Failure',
                    'Payment Made Notification',
                  }.contains(widget.templateTitle)) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 215,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'From',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF2E3443),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 38,
                                  child: FormDropdown<String>(
                                    value: _selectedFromEmail,
                                    allowClear: true,
                                    items: const <String>[],
                                    hint: 'Select email',
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedFromEmail = value;
                                      });
                                    },
                                    allowCustomValue: true,
                                    showSearch: true,
                                    forceUppercase: false,
                                    fillColor: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    textStyle: AppTheme.bodyText.copyWith(
                                      fontSize: 13,
                                      color: const Color(0xFF2E3443),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'This email address will be used as the from address while sending . Other users can choose their email address if they wish to change it.',
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 215,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Subject*',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: const Color(0xFFFF3B30),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CustomTextField(
                            controller: widget.subjectController,
                            height: 38,
                            contentCase: ContentCase.none,
                            forceUppercase: false,
                            fillColor: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF2E3443),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                    child: _buildRichEditorSurface(height: 458),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                    child: Container(height: 1, color: AppTheme.borderLight),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isDefault = !_isDefault;
                            });
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _isDefault
                                  ? const Color(0xFF3B7CFF)
                                  : Colors.white,
                              border: Border.all(
                                color: _isDefault
                                    ? const Color(0xFF3B7CFF)
                                    : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: _isDefault
                                ? const Icon(
                                    Icons.check,
                                    size: 11,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Set this to default',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF2E3443),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                    child: Row(
                      children: [
                        ZButton.primary(
                          label: 'Save',
                          onPressed: () => widget.onSave(
                            widget.templateNameController.text,
                            widget.subjectController.text,
                            _isDefault,
                          ),
                          height: 35,
                          fontSize: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        const SizedBox(width: 8),
                        ZButton.secondary(
                          label: 'Cancel',
                          onPressed: widget.onClose,
                          height: 35,
                          fontSize: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                      ],
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

  Widget _buildItemNotificationEditor(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 68,
            padding: const EdgeInsets.fromLTRB(22, 0, 18, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.templateTitle} - Default*',
                    style: AppTheme.pageTitle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: widget.onClose,
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 24,
                      color: Color(0xFF7B7B7B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 215,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Template Name*',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: const Color(0xFFFF3B30),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CustomTextField(
                            controller: widget.templateNameController,
                            height: 38,
                            contentCase: ContentCase.none,
                            forceUppercase: false,
                            fillColor: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF2E3443),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (const <String>{
                      'Shipment Notification',
                      'Retainer Payment Thank you',
                      'Customer Statement',
                      'Retainer Invoice Notification',
                      'Sales Order Notification',
                      'Invoice Notification',
                      'Sales Return Notification',
                      'Credit Note Notification',
                      'Vendor Statement',
                      'Purchase Order Notification',
                      'Payment Thank-you',
                      'Payment Initiated',
                      'Payment Success',
                      'Payment Failure',
                      'Payment Made Notification',
                    }.contains(widget.templateTitle)) ...[
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 215,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Cc',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF2E3443),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: FormDropdown<String>(
                              value: null,
                              multiSelect: true,
                              selectedValues: _selectedCcEmails,
                              items: const <String>[],
                              hint: 'Select emails',
                              onChanged: (value) {},
                              onSelectedValuesChanged: (values) {
                                setState(() {
                                  _selectedCcEmails = values;
                                });
                              },
                              allowClear: true,
                              showSearch: true,
                              fillColor: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              textStyle: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: const Color(0xFF2E3443),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 215,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Bcc',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF2E3443),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: FormDropdown<String>(
                              value: null,
                              multiSelect: true,
                              selectedValues: _selectedBccEmails,
                              items: const <String>[],
                              hint: 'Select emails',
                              onChanged: (value) {},
                              onSelectedValuesChanged: (values) {
                                setState(() {
                                  _selectedBccEmails = values;
                                });
                              },
                              allowClear: true,
                              showSearch: true,
                              fillColor: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              textStyle: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: const Color(0xFF2E3443),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (const <String>{
                      'Vendor Credit Notification',
                      'Customer Statement',
                      'Retainer Invoice Notification',
                      'Sales Order Notification',
                      'Invoice Notification',
                      'Sales Return Notification',
                      'Credit Note Notification',
                      'Vendor Statement',
                      'Purchase Order Notification',
                      'Payment Thank-you',
                      'Payment Initiated',
                      'Payment Success',
                      'Payment Failure',
                      'Payment Made Notification',
                    }.contains(widget.templateTitle)) ...[
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 215,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'From',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF2E3443),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 38,
                                  child: FormDropdown<String>(
                                    value: _selectedFromEmail,
                                    allowClear: true,
                                    items: const <String>[],
                                    hint: 'Select email',
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedFromEmail = value;
                                      });
                                    },
                                    allowCustomValue: true,
                                    showSearch: true,
                                    forceUppercase: false,
                                    fillColor: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    textStyle: AppTheme.bodyText.copyWith(
                                      fontSize: 13,
                                      color: const Color(0xFF2E3443),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'This email address will be used as the from address while sending . Other users can choose their email address if they wish to change it.',
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 215,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Subject*',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: const Color(0xFFFF3B30),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CustomTextField(
                            controller: widget.subjectController,
                            height: 38,
                            contentCase: ContentCase.none,
                            forceUppercase: false,
                            fillColor: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF2E3443),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildRichEditorSurface(height: 458),
                    const SizedBox(height: 30),
                    Container(height: 1, color: AppTheme.borderLight),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isDefault = !_isDefault;
                              });
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _isDefault
                                    ? const Color(0xFF3B7CFF)
                                    : Colors.white,
                                border: Border.all(
                                  color: _isDefault
                                      ? const Color(0xFF3B7CFF)
                                      : const Color(0xFFCBD5E1),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: _isDefault
                                  ? const Icon(
                                      Icons.check,
                                      size: 11,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Set this to default',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF2E3443),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        ZButton.primary(
                          label: 'Save',
                          onPressed: () => widget.onSave(
                            widget.templateNameController.text,
                            widget.subjectController.text,
                            _isDefault,
                          ),
                          height: 35,
                          fontSize: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        const SizedBox(width: 8),
                        ZButton.secondary(
                          label: 'Cancel',
                          onPressed: widget.onClose,
                          height: 35,
                          fontSize: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'This template will be available only while setting up Email Alerts for Workflows',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF7A849A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledTextRun {
  const _StyledTextRun({
    required this.start,
    required this.end,
    required this.style,
  });

  final int start;
  final int end;
  final TextStyle style;

  int get length => end - start;

  _StyledTextRun copyWith({int? start, int? end, TextStyle? style}) {
    return _StyledTextRun(
      start: start ?? this.start,
      end: end ?? this.end,
      style: style ?? this.style,
    );
  }
}

enum _EditorListMode { none, bullet, ordered }

class _EditorListFormatter extends TextInputFormatter {
  _EditorListFormatter({required this.getMode, required this.onModeChanged});

  final _EditorListMode Function() getMode;
  final ValueChanged<_EditorListMode> onModeChanged;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final TextSelection oldSelection = oldValue.selection;
    final TextSelection newSelection = newValue.selection;

    if (!oldSelection.isValid ||
        !oldSelection.isCollapsed ||
        !newSelection.isValid ||
        !newSelection.isCollapsed ||
        newValue.text.length != oldValue.text.length + 1 ||
        newSelection.baseOffset != oldSelection.baseOffset + 1) {
      return newValue;
    }

    final int insertOffset = oldSelection.baseOffset;
    if (insertOffset < 0 || insertOffset >= newValue.text.length) {
      return newValue;
    }
    if (newValue.text.substring(insertOffset, insertOffset + 1) != '\n') {
      return newValue;
    }

    final int lineStart =
        oldValue.text.lastIndexOf(
          '\n',
          insertOffset > 0 ? insertOffset - 1 : 0,
        ) +
        1;
    final String lineBeforeEnter = oldValue.text.substring(
      lineStart,
      insertOffset,
    );

    final RegExp bulletPattern = RegExp(r'^(\s*)(?:-|\*|\u2022)\s?(.*)$');
    final RegExp orderedPattern = RegExp(r'^(\s*)(\d+)\.\s?(.*)$');
    final RegExpMatch? bulletMatch = bulletPattern.firstMatch(lineBeforeEnter);
    final RegExpMatch? orderedMatch = orderedPattern.firstMatch(
      lineBeforeEnter,
    );

    if (bulletMatch != null) {
      final String indent = bulletMatch.group(1) ?? '';
      final String content = bulletMatch.group(2) ?? '';
      if (content.trim().isEmpty) {
        onModeChanged(_EditorListMode.none);
        final String text = newValue.text.replaceRange(
          lineStart,
          insertOffset + 1,
          '',
        );
        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(
            offset: lineStart.clamp(0, text.length),
          ),
        );
      }

      onModeChanged(_EditorListMode.bullet);
      final String marker = '\n${indent}\u2022 ';
      final String text = newValue.text.replaceRange(
        newSelection.baseOffset,
        newSelection.baseOffset,
        marker,
      );
      final int nextOffset = (newSelection.baseOffset + marker.length).clamp(
        0,
        text.length,
      );
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: nextOffset),
      );
    }

    if (orderedMatch != null) {
      final String indent = orderedMatch.group(1) ?? '';
      final int currentNumber = int.tryParse(orderedMatch.group(2) ?? '1') ?? 1;
      final String content = orderedMatch.group(3) ?? '';
      if (content.trim().isEmpty) {
        onModeChanged(_EditorListMode.none);
        final String text = newValue.text.replaceRange(
          lineStart,
          insertOffset + 1,
          '',
        );
        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(
            offset: lineStart.clamp(0, text.length),
          ),
        );
      }

      onModeChanged(_EditorListMode.ordered);
      final String marker = '\n$indent${currentNumber + 1}. ';
      final String text = newValue.text.replaceRange(
        newSelection.baseOffset,
        newSelection.baseOffset,
        marker,
      );
      final int nextOffset = (newSelection.baseOffset + marker.length).clamp(
        0,
        text.length,
      );
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: nextOffset),
      );
    }

    final _EditorListMode mode = getMode();
    if (mode == _EditorListMode.none) {
      return newValue;
    }

    final String marker = mode == _EditorListMode.ordered ? '1. ' : '\u2022 ';
    final String text = newValue.text.replaceRange(
      newSelection.baseOffset,
      newSelection.baseOffset,
      marker,
    );
    final int nextOffset = (newSelection.baseOffset + marker.length).clamp(
      0,
      text.length,
    );
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
  }
}

class _StyledTextEditingController extends TextEditingController {
  TextStyle typingStyle = const TextStyle();
  final List<_StyledTextRun> _runs = <_StyledTextRun>[];
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  bool get hasActiveSelection =>
      selection.isValid &&
      !selection.isCollapsed &&
      selection.end > selection.start;

  void syncStyleRuns({required String oldText, required String newText}) {
    if (oldText == newText) {
      return;
    }

    int prefix = 0;
    while (prefix < oldText.length &&
        prefix < newText.length &&
        oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix++;
    }

    int oldSuffix = oldText.length;
    int newSuffix = newText.length;
    while (oldSuffix > prefix &&
        newSuffix > prefix &&
        oldText.codeUnitAt(oldSuffix - 1) ==
            newText.codeUnitAt(newSuffix - 1)) {
      oldSuffix--;
      newSuffix--;
    }

    final int removedLength = oldSuffix - prefix;
    final int insertedLength = newSuffix - prefix;

    if (removedLength > 0) {
      _deleteRange(prefix, oldSuffix);
    }
    if (insertedLength > 0) {
      _insertRange(prefix, insertedLength, typingStyle);
    }

    _normalizeRuns();
  }

  void _deleteRange(int start, int end) {
    final int removedLength = end - start;
    final List<_StyledTextRun> nextRuns = <_StyledTextRun>[];

    for (final _StyledTextRun run in _runs) {
      if (run.end <= start) {
        nextRuns.add(run);
        continue;
      }
      if (run.start >= end) {
        nextRuns.add(
          run.copyWith(
            start: run.start - removedLength,
            end: run.end - removedLength,
          ),
        );
        continue;
      }

      if (run.start < start) {
        nextRuns.add(run.copyWith(end: start));
      }
      if (run.end > end) {
        nextRuns.add(run.copyWith(start: start, end: run.end - removedLength));
      }
    }

    _runs
      ..clear()
      ..addAll(nextRuns.where((run) => run.length > 0));
  }

  void _insertRange(int offset, int length, TextStyle style) {
    final List<_StyledTextRun> nextRuns = <_StyledTextRun>[];

    for (final _StyledTextRun run in _runs) {
      if (run.end <= offset) {
        nextRuns.add(run);
      } else if (run.start >= offset) {
        nextRuns.add(
          run.copyWith(start: run.start + length, end: run.end + length),
        );
      } else {
        nextRuns.add(run.copyWith(end: offset));
        nextRuns.add(
          run.copyWith(start: offset + length, end: run.end + length),
        );
      }
    }

    nextRuns.add(
      _StyledTextRun(start: offset, end: offset + length, style: style),
    );

    nextRuns.sort((a, b) => a.start.compareTo(b.start));
    _runs
      ..clear()
      ..addAll(nextRuns.where((run) => run.length > 0));
  }

  void _normalizeRuns() {
    if (_runs.isEmpty) {
      return;
    }

    _runs.sort((a, b) => a.start.compareTo(b.start));
    final List<_StyledTextRun> merged = <_StyledTextRun>[];

    for (final _StyledTextRun run in _runs) {
      if (merged.isEmpty) {
        merged.add(run);
        continue;
      }

      final _StyledTextRun last = merged.last;
      if (last.end == run.start && _sameStyle(last.style, run.style)) {
        merged[merged.length - 1] = last.copyWith(end: run.end);
      } else {
        merged.add(run);
      }
    }

    _runs
      ..clear()
      ..addAll(merged.where((run) => run.length > 0));
  }

  void applyStyleToSelection(TextStyle Function(TextStyle current) transform) {
    if (!hasActiveSelection || text.isEmpty) {
      return;
    }

    final int start = selection.start;
    final int end = selection.end;
    final List<_StyledTextRun> coverage = <_StyledTextRun>[];
    int cursor = 0;

    for (final _StyledTextRun run in _runs) {
      if (cursor < run.start) {
        coverage.add(
          _StyledTextRun(start: cursor, end: run.start, style: typingStyle),
        );
      }
      coverage.add(run);
      cursor = run.end;
    }

    if (cursor < text.length) {
      coverage.add(
        _StyledTextRun(start: cursor, end: text.length, style: typingStyle),
      );
    }

    if (coverage.isEmpty) {
      coverage.add(
        _StyledTextRun(start: 0, end: text.length, style: typingStyle),
      );
    }

    final List<_StyledTextRun> nextRuns = <_StyledTextRun>[];
    for (final _StyledTextRun run in coverage) {
      if (run.end <= start || run.start >= end) {
        nextRuns.add(run);
        continue;
      }

      if (run.start < start) {
        nextRuns.add(run.copyWith(end: start));
      }

      final int midStart = run.start < start ? start : run.start;
      final int midEnd = run.end > end ? end : run.end;
      nextRuns.add(
        _StyledTextRun(
          start: midStart,
          end: midEnd,
          style: transform(run.style),
        ),
      );

      if (run.end > end) {
        nextRuns.add(run.copyWith(start: end));
      }
    }

    _runs
      ..clear()
      ..addAll(nextRuns.where((run) => run.length > 0));
    _normalizeRuns();
    notifyListeners();
  }

  bool _sameStyle(TextStyle a, TextStyle b) {
    return a.fontFamily == b.fontFamily &&
        a.fontSize == b.fontSize &&
        a.fontWeight == b.fontWeight &&
        a.fontStyle == b.fontStyle &&
        a.decoration == b.decoration &&
        a.color == b.color &&
        a.backgroundColor == b.backgroundColor &&
        a.height == b.height;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_isDisposed) {
      return TextSpan(style: style, text: text);
    }
    final String fullText = text;
    if (fullText.isEmpty) {
      return TextSpan(style: style, text: '');
    }

    if (_runs.isEmpty) {
      return TextSpan(style: style ?? typingStyle, text: fullText);
    }

    final List<InlineSpan> children = <InlineSpan>[];
    int cursor = 0;

    for (final _StyledTextRun run in _runs) {
      final int start = run.start.clamp(cursor, fullText.length);
      if (start > cursor) {
        children.add(
          TextSpan(
            text: fullText.substring(cursor, start),
            style: style ?? typingStyle,
          ),
        );
      }

      final int safeEnd = run.end.clamp(start, fullText.length);
      if (safeEnd > start) {
        children.add(
          TextSpan(text: fullText.substring(start, safeEnd), style: run.style),
        );
      }
      cursor = safeEnd;
    }

    if (cursor < fullText.length) {
      children.add(
        TextSpan(text: fullText.substring(cursor), style: style ?? typingStyle),
      );
    }

    return TextSpan(style: style ?? typingStyle, children: children);
  }
}

class _SignatureSettingsDialog extends StatefulWidget {
  const _SignatureSettingsDialog();

  @override
  State<_SignatureSettingsDialog> createState() =>
      _SignatureSettingsDialogState();
}

class _SignatureSettingsDialogState extends State<_SignatureSettingsDialog> {
  static const List<_PlaceholderItem> _signaturePlaceholderItems =
      <_PlaceholderItem>[
        _PlaceholderItem('PORTAL', 'Portal URL', '%PortalURL%'),
        _PlaceholderItem('PORTAL', 'Portal Name', '%PortalName%'),
        _PlaceholderItem(
          'PORTAL',
          'Invitation Accept URL',
          '%InvitationAcceptURL%',
        ),
        _PlaceholderItem('CONTACT PERSON', 'Company Name', '%CompanyName%'),
        _PlaceholderItem('CONTACT PERSON', 'Salutation', '%Salutation%'),
        _PlaceholderItem('CONTACT PERSON', 'FirstName', '%FirstName%'),
        _PlaceholderItem('CONTACT PERSON', 'LastName', '%LastName%'),
        _PlaceholderItem('CONTACT PERSON', 'EmailID', '%EmailID%'),
        _PlaceholderItem('CONTACT PERSON', 'Department', '%Department%'),
        _PlaceholderItem('CONTACT PERSON', 'Designation', '%Designation%'),
        _PlaceholderItem('ORGANIZATION', 'Name', '%OrgName%'),
        _PlaceholderItem('ORGANIZATION', 'User', '%UserName%'),
        _PlaceholderItem('ORGANIZATION', 'User Role', '%UserRole%'),
        _PlaceholderItem('ORGANIZATION', 'Email', '%OrgEmail%'),
        _PlaceholderItem('ORGANIZATION', 'Phone#', '%OrgPhone%'),
        _PlaceholderItem('ORGANIZATION', 'Fax#', '%OrgFax%'),
        _PlaceholderItem('ORGANIZATION', 'Website', '%OrgWebsite%'),
        _PlaceholderItem('ORGANIZATION', 'Label 1', '%Label1%'),
        _PlaceholderItem('ORGANIZATION', 'Value 1', '%Value1%'),
        _PlaceholderItem('ORGANIZATION', 'Logo', '%OrgLogo%'),
        _PlaceholderItem('ORGANIZATION', 'Signature', '%Signature%'),
        _PlaceholderItem('ORGANIZATION', 'Company GSTIN', '%CompanyGSTIN%'),
      ];
  static const List<String> _textStyleItems = <String>[
    'Normal Text',
    'Heading 1',
    'Heading 2',
    'Heading 3',
    'Heading 4',
    'Heading 5',
    'Heading 6',
  ];
  static const List<String> _signatureFontFamilyItems = <String>[
    'Calibri',
    'Courier New',
    'Georgia',
    'Serif',
    'Roboto',
    'Times New Roman',
    'Trebuchet MS',
    'Arial',
    'Tahoma',
    'Verdana',
    'Comic Sans MS',
  ];
  static const List<String> _signatureFontSizeItems = <String>[
    '10px',
    '13px',
    '16px',
    '18px',
    '24px',
    '32px',
    '48px',
  ];

  final _StyledTextEditingController _editorController =
      _StyledTextEditingController();
  final ScrollController _editorScrollController = ScrollController();
  String _lastEditorText = '';
  _PlaceholderItem? _selectedPlaceholder;
  String _selectedTextStyle = 'Normal Text';
  String _selectedFontSize = '16px';
  String _selectedFontFamily = 'Arial';
  TextAlign _editorTextAlign = TextAlign.left;
  Color _selectedTextColor = const Color(0xFF1C2434);
  Color _selectedHighlightColor = Colors.transparent;
  bool _bold = false;
  bool _italic = false;
  bool _underline = false;
  bool _strike = false;
  _EditorListMode _activeListMode = _EditorListMode.none;

  @override
  void initState() {
    super.initState();
    _editorController.typingStyle = _currentEditorTypingStyle();
    _lastEditorText = _editorController.text;
    _editorController.addListener(_handleEditorChanged);
  }

  @override
  void dispose() {
    _editorController.removeListener(_handleEditorChanged);
    _editorScrollController.dispose();
    _editorController.dispose();
    super.dispose();
  }

  TextStyle _fontFamilyStyleFor(String fontFamily, TextStyle baseStyle) {
    if (fontFamily == 'Roboto') {
      return GoogleFonts.roboto(textStyle: baseStyle);
    }

    return baseStyle.copyWith(
      fontFamily: fontFamily == 'Arial' ? null : fontFamily,
    );
  }

  double _resolvedFontSize() {
    return double.tryParse(_selectedFontSize.replaceAll('px', '').trim()) ?? 16;
  }

  TextStyle _currentEditorTypingStyle() {
    final TextStyle baseStyle = AppTheme.bodyText.copyWith(
      fontSize: _resolvedFontSize(),
      fontWeight: _bold ? FontWeight.w700 : FontWeight.w400,
      fontStyle: _italic ? FontStyle.italic : FontStyle.normal,
      decoration: _underline
          ? TextDecoration.underline
          : _strike
          ? TextDecoration.lineThrough
          : TextDecoration.none,
      color: _selectedTextColor,
      backgroundColor: _selectedHighlightColor,
      height: 1.45,
    );
    return _applyTextStylePreset(
      _fontFamilyStyleFor(_selectedFontFamily, baseStyle),
    );
  }

  TextStyle _applyTextStylePreset(TextStyle style) {
    switch (_selectedTextStyle) {
      case 'Heading 1':
        return style.copyWith(fontSize: 28, fontWeight: FontWeight.w700);
      case 'Heading 2':
        return style.copyWith(fontSize: 24, fontWeight: FontWeight.w700);
      case 'Heading 3':
        return style.copyWith(fontSize: 20, fontWeight: FontWeight.w600);
      case 'Heading 4':
        return style.copyWith(fontSize: 18, fontWeight: FontWeight.w600);
      case 'Heading 5':
        return style.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
      case 'Heading 6':
        return style.copyWith(fontSize: 15, fontWeight: FontWeight.w600);
      case 'Normal Text':
      default:
        return style;
    }
  }

  void _applySelectionOrTyping(
    TextStyle Function(TextStyle current) transform,
  ) {
    if (_editorController.hasActiveSelection) {
      _editorController.applyStyleToSelection(transform);
    }
    _refreshTypingStyle();
  }

  void _refreshTypingStyle() {
    _editorController.typingStyle = _currentEditorTypingStyle();
  }

  void _handleEditorChanged() {
    final String currentText = _editorController.text;
    _editorController.syncStyleRuns(
      oldText: _lastEditorText,
      newText: currentText,
    );
    _lastEditorText = currentText;
  }

  void _insertPlaceholderItem(_PlaceholderItem item) {
    final text = _editorController.text;
    final selection = _editorController.selection;
    final start = selection.isValid && selection.start >= 0
        ? selection.start
        : text.length;
    final end = selection.isValid && selection.end >= 0
        ? selection.end
        : text.length;
    final nextText = text.replaceRange(start, end, item.token);
    setState(() {
      _selectedPlaceholder = item;
      _editorController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: start + item.token.length),
      );
    });
  }

  void _replaceSelectionText(String replacement) {
    final String text = _editorController.text;
    final TextSelection selection = _editorController.selection;
    final int start = selection.isValid && selection.start >= 0
        ? selection.start
        : text.length;
    final int end = selection.isValid && selection.end >= 0
        ? selection.end
        : text.length;
    final String nextText = text.replaceRange(start, end, replacement);
    _editorController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  void _transformSelectedLines(
    String Function(String line, int index) transform,
  ) {
    final String text = _editorController.text;
    final TextSelection selection = _editorController.selection;
    final int start = selection.isValid && selection.start >= 0
        ? selection.start
        : 0;
    final int end = selection.isValid && selection.end >= 0
        ? selection.end
        : text.length;

    int lineStart = text.lastIndexOf('\n', start > 0 ? start - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;
    int lineEnd = text.indexOf('\n', end);
    lineEnd = lineEnd == -1 ? text.length : lineEnd;

    final String block = text.substring(lineStart, lineEnd);
    final List<String> lines = block.split('\n');
    final String updatedBlock = List<String>.generate(
      lines.length,
      (index) => transform(lines[index], index),
    ).join('\n');

    final String nextText = text.replaceRange(lineStart, lineEnd, updatedBlock);
    _editorController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection(
        baseOffset: lineStart,
        extentOffset: lineStart + updatedBlock.length,
      ),
    );
  }

  void _applyIndentChange(bool increase) {
    _transformSelectedLines((line, _) {
      if (increase) {
        return '  $line';
      }
      return line.startsWith('  ')
          ? line.substring(2)
          : line.startsWith(' ')
          ? line.substring(1)
          : line;
    });
  }

  void _applyAlignment(TextAlign align) {
    setState(() => _editorTextAlign = align);
  }

  void _applyBulletedList(bool ordered) {
    final _EditorListMode nextMode = ordered
        ? _EditorListMode.ordered
        : _EditorListMode.bullet;

    if (!_editorController.hasActiveSelection) {
      setState(() {
        _activeListMode = nextMode;
      });

      final String text = _editorController.text;
      final TextSelection selection = _editorController.selection;
      final int cursor = selection.isValid && selection.baseOffset >= 0
          ? selection.baseOffset
          : text.length;
      int lineStart = text.lastIndexOf('\n', cursor > 0 ? cursor - 1 : 0);
      lineStart = lineStart == -1 ? 0 : lineStart + 1;
      int lineEnd = text.indexOf('\n', cursor);
      lineEnd = lineEnd == -1 ? text.length : lineEnd;
      final String line = text.substring(lineStart, lineEnd);
      if (line.trim().isEmpty) {
        final String marker = ordered ? '1. ' : '\u2022 ';
        final String nextText = text.replaceRange(lineStart, lineEnd, marker);
        _editorController.value = TextEditingValue(
          text: nextText,
          selection: TextSelection.collapsed(
            offset: (lineStart + marker.length).clamp(0, nextText.length),
          ),
        );
        _lastEditorText = nextText;
      }
      return;
    }

    setState(() {
      _activeListMode = nextMode;
    });
    _transformSelectedLines((line, index) {
      final String indent = RegExp(r'^\s*').firstMatch(line)?.group(0) ?? '';
      String content = line.substring(indent.length);
      content = content.replaceFirst(RegExp(r'^(?:-|\*|\u2022)\s+'), '');
      content = content.replaceFirst(RegExp(r'^\d+\.\s+'), '');

      if (ordered) {
        return '$indent${index + 1}. $content';
      }
      return '${indent}\u2022 $content';
    });
  }

  void _insertImageTag(String url) {
    if (url.trim().isEmpty) return;
    _replaceSelectionText('<img src="${url.trim()}" alt="image" />');
  }

  void _insertLinkTag(String text, String url) {
    final String cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;
    final String label = text.trim().isEmpty ? cleanUrl : text.trim();
    _replaceSelectionText('<a href="$cleanUrl">$label</a>');
  }

  void _insertVideoTag() {
    _replaceSelectionText('<video controls src=""></video>');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: SizedBox(
          width: double.infinity,
          height: 360.88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signature Settings',
                            style: AppTheme.pageTitle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E2430),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Below signature will appear on all templates.',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12,
                              color: const Color(0xFF72809A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.close, size: 20, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F7FB),
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    _ToolbarDropdown(
                      label: _selectedTextStyle,
                      items: _textStyleItems,
                      onSelected: (value) {
                        setState(() {
                          _selectedTextStyle = value;
                        });
                        _applySelectionOrTyping(_applyTextStylePreset);
                      },
                    ),
                    const _ToolbarDivider(horizontal: 10),
                    _ToolbarText(
                      label: 'B',
                      bold: true,
                      active: _bold,
                      onTap: () {
                        setState(() {
                          _bold = !_bold;
                        });
                        _applySelectionOrTyping(
                          (current) => current.copyWith(
                            fontWeight: _bold
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 18),
                    _ToolbarText(
                      label: 'I',
                      italic: true,
                      active: _italic,
                      onTap: () {
                        setState(() {
                          _italic = !_italic;
                        });
                        _applySelectionOrTyping(
                          (current) => current.copyWith(
                            fontStyle: _italic
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 18),
                    _ToolbarText(
                      label: 'U',
                      underline: true,
                      active: _underline,
                      onTap: () {
                        setState(() {
                          _underline = !_underline;
                          if (_underline) _strike = false;
                        });
                        _applySelectionOrTyping(
                          (current) => current.copyWith(
                            decoration: _underline
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 18),
                    _ToolbarText(
                      label: 'S',
                      strike: true,
                      active: _strike,
                      onTap: () {
                        setState(() {
                          _strike = !_strike;
                          if (_strike) _underline = false;
                        });
                        _applySelectionOrTyping(
                          (current) => current.copyWith(
                            decoration: _strike
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        );
                      },
                    ),
                    const _ToolbarDivider(horizontal: 10),
                    _SignatureColorDropdown(
                      isHighlight: false,
                      color: _selectedTextColor,
                      isDialog: true,
                      onApply: (color) {
                        setState(() {
                          _selectedTextColor = color;
                        });
                        _applySelectionOrTyping(
                          (current) => current.copyWith(color: color),
                        );
                      },
                    ),
                    const SizedBox(width: 18),
                    _SignatureColorDropdown(
                      isHighlight: true,
                      color: _selectedHighlightColor == Colors.transparent
                          ? Colors.black
                          : _selectedHighlightColor,
                      isDialog: true,
                      onDoubleTap: () {
                        setState(() {
                          _selectedHighlightColor = Colors.transparent;
                        });
                        _applySelectionOrTyping(
                          (current) => current.copyWith(
                            backgroundColor: Colors.transparent,
                          ),
                        );
                      },
                      onApply: (color) {
                        setState(() {
                          _selectedHighlightColor = color;
                        });
                        _applySelectionOrTyping(
                          (current) => current.copyWith(backgroundColor: color),
                        );
                      },
                    ),
                    const _ToolbarDivider(horizontal: 10),
                    _SignatureFontSizeDropdown(
                      label: _selectedFontSize,
                      items: _signatureFontSizeItems,
                      onSelected: (value) {
                        setState(() {
                          _selectedFontSize = value;
                        });
                        _applySelectionOrTyping(
                          (current) =>
                              current.copyWith(fontSize: _resolvedFontSize()),
                        );
                      },
                    ),
                    const _ToolbarDivider(horizontal: 10),
                    _SignatureFontFamilyDropdown(
                      label: _selectedFontFamily,
                      items: _signatureFontFamilyItems,
                      textStyleBuilder: (fontFamily, baseStyle) =>
                          _fontFamilyStyleFor(fontFamily, baseStyle),
                      onSelected: (value) {
                        setState(() {
                          _selectedFontFamily = value;
                        });
                        _applySelectionOrTyping(
                          (current) =>
                              _fontFamilyStyleFor(_selectedFontFamily, current),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    _SignatureOverflowMenu(
                      onIndentChange: _applyIndentChange,
                      onAlignChange: _applyAlignment,
                      onListChange: _applyBulletedList,
                      onImageInsert: _insertImageTag,
                      onLinkInsert: _insertLinkTag,
                      onVideoInsert: _insertVideoTag,
                    ),
                    const Spacer(),
                    _PlaceholderToolbarDropdown(
                      value: _selectedPlaceholder,
                      items: _signaturePlaceholderItems,
                      onSelected: _insertPlaceholderItem,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.borderLight),
                        bottom: BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                    child: TextField(
                      controller: _editorController,
                      scrollController: _editorScrollController,
                      inputFormatters: [
                        _EditorListFormatter(
                          getMode: () => _activeListMode,
                          onModeChanged: (mode) => _activeListMode = mode,
                        ),
                      ],
                      maxLines: null,
                      expands: true,
                      textAlign: _editorTextAlign,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      style: _currentEditorTypingStyle(),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        contentPadding: EdgeInsets.fromLTRB(18, 14, 18, 14),
                        border: InputBorder.none,
                        hoverColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Row(
                  children: [
                    ZButton.primary(
                      label: 'Save',
                      onPressed: () => Navigator.of(context).pop(),
                      height: 35,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    const SizedBox(width: 8),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                      height: 35,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
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

class _ToolbarDropdown extends StatelessWidget {
  const _ToolbarDropdown({
    required this.label,
    required this.items,
    required this.onSelected,
  });

  final String label;
  final List<String> items;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final bool isTextStyleDropdown =
        items.isNotEmpty && items.first == 'Normal Text';

    return FormDropdown<String>(
      value: label,
      items: items,
      onChanged: (value) {
        if (value != null) {
          onSelected(value);
        }
      },
      displayStringForValue: (value) => value,
      showSearch: false,
      showSearchIcon: false,
      isInline: true,
      height: 28,
      menuWidth: isTextStyleDropdown ? 136 : 126,
      menuMaxHeight: isTextStyleDropdown ? 312 : 220,
      itemEstimatedHeight: 40,
      textStyle: AppTheme.bodyText.copyWith(
        fontSize: 13,
        color: const Color(0xFF1F2430),
      ),
      itemBuilder: (item, isSelected, isHovered) {
        final bool active = isSelected || isHovered;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Container(
            height: 32,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: active ? AppTheme.primaryBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: active ? Colors.white : const Color(0xFF5A6477),
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignatureFontSizeDropdown extends StatelessWidget {
  const _SignatureFontSizeDropdown({
    required this.label,
    required this.items,
    required this.onSelected,
  });

  final String label;
  final List<String> items;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return FormDropdown<String>(
      value: label,
      items: items,
      onChanged: (value) {
        if (value != null) {
          onSelected(value);
        }
      },
      displayStringForValue: (value) => value,
      showSearch: false,
      showSearchIcon: false,
      isInline: true,
      height: 28,
      menuWidth: 82,
      menuMaxHeight: 286,
      itemEstimatedHeight: 40,
      textStyle: AppTheme.bodyText.copyWith(
        fontSize: 13,
        color: const Color(0xFF1F2430),
      ),
      itemBuilder: (item, isSelected, isHovered) {
        final bool active = isHovered;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Container(
            height: 32,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.primaryBlue
                  : isSelected
                  ? const Color(0xFFF1F4FB)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: active ? Colors.white : const Color(0xFF5A6477),
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignatureColorDropdown extends StatefulWidget {
  const _SignatureColorDropdown({
    required this.color,
    required this.onApply,
    required this.isHighlight,
    this.onDoubleTap,
    this.isDialog = false,
  });

  final Color color;
  final ValueChanged<Color> onApply;
  final bool isHighlight;
  final VoidCallback? onDoubleTap;
  final bool isDialog;

  @override
  State<_SignatureColorDropdown> createState() =>
      _SignatureColorDropdownState();
}

class _SignatureColorDropdownState extends State<_SignatureColorDropdown> {
  late HSVColor _draftColor;
  late TextEditingController _hexController;
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _draftColor = HSVColor.fromColor(widget.color);
    _hexController = TextEditingController(text: _formatColorHex(widget.color));
  }

  @override
  void didUpdateWidget(covariant _SignatureColorDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _draftColor = HSVColor.fromColor(widget.color);
      _hexController.text = _formatColorHex(widget.color);
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _hexController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (!mounted || _overlayEntry != null) {
      return;
    }

    _draftColor = HSVColor.fromColor(widget.color);
    _hexController.text = _formatColorHex(widget.color);
    _overlayEntry = OverlayEntry(builder: (context) => _buildOverlay(context));
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _markOverlayNeedsBuild() {
    _overlayEntry?.markNeedsBuild();
  }

  Widget _buildOverlay(BuildContext context) {
    final RenderBox? buttonBox = this.context.findRenderObject() as RenderBox?;
    final Offset buttonOffset =
        buttonBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final Size buttonSize = buttonBox?.size ?? const Size(24, 25);
    final double left = (buttonOffset.dx + (buttonSize.width - 236) / 2).clamp(
      8.0,
      double.infinity,
    );
    final double top =
        buttonOffset.dy + buttonSize.height - (widget.isDialog ? 0 : 52);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeOverlay,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, setLocalState) {
                void localUpdate(Color color) {
                  setLocalState(() {
                    _draftColor = HSVColor.fromColor(color);
                    _hexController.text = _formatColorHex(color);
                  });
                  _markOverlayNeedsBuild();
                }

                final Color panelColor = _draftColor.toColor();

                return Container(
                  width: 236,
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE4E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A0F172A),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SignatureColorArea(
                        color: panelColor,
                        onChanged: localUpdate,
                      ),
                      const SizedBox(height: 10),
                      _SignatureGradientSlider(
                        value: _draftColor.hue / 360,
                        gradient: const [
                          Color(0xFFFF0000),
                          Color(0xFFFFFF00),
                          Color(0xFF00FF00),
                          Color(0xFF00FFFF),
                          Color(0xFF0000FF),
                          Color(0xFFFF00FF),
                          Color(0xFFFF0000),
                        ],
                        thumbColor: panelColor,
                        onChanged: (value) {
                          localUpdate(
                            _draftColor.withHue(value * 360).toColor(),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _SignatureGradientSlider(
                        value: _draftColor.alpha,
                        gradient: [
                          Colors.transparent,
                          panelColor.withAlpha(255),
                        ],
                        backgroundPattern: true,
                        thumbColor: Colors.black,
                        onChanged: (value) {
                          localUpdate(_draftColor.withAlpha(value).toColor());
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: TextField(
                                controller: _hexController,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFBFD0F8),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFBFD0F8),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF1F2430),
                                ),
                                onSubmitted: (value) {
                                  final Color? parsed = _parseColorHex(value);
                                  if (parsed != null) {
                                    localUpdate(parsed);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 52,
                            height: 30,
                            decoration: BoxDecoration(
                              color: panelColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () {},
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    Color(0xFFFF0000),
                                    Color(0xFFFFFF00),
                                    Color(0xFF00FF00),
                                    Color(0xFF00FFFF),
                                    Color(0xFF0000FF),
                                    Color(0xFFFF00FF),
                                    Color(0xFFFF0000),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Swatches',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: const Color(0xFF4B5565),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Color(0xFF4B5565),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: Color(0xFFE8ECF3)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ZButton.primary(
                            label: 'Apply',
                            onPressed: () {
                              widget.onApply(panelColor);
                              _removeOverlay();
                            },
                            height: 32,
                            fontSize: 14,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          const SizedBox(width: 10),
                          ZButton.secondary(
                            label: 'Cancel',
                            onPressed: _removeOverlay,
                            height: 32,
                            fontSize: 14,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleOverlay,
      onDoubleTap: widget.isHighlight ? widget.onDoubleTap : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _isOpen ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: _isOpen ? Border.all(color: const Color(0xFFD8DCE7)) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'A',
              style: AppTheme.bodyText.copyWith(
                fontSize: 15,
                height: 1.1,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 1),
            Container(
              width: widget.isHighlight ? 14 : 12,
              height: 3,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatColorHex(Color color) {
    final String rr = (color.r * 255.0)
        .round()
        .clamp(0, 255)
        .toRadixString(16)
        .padLeft(2, '0');
    final String gg = (color.g * 255.0)
        .round()
        .clamp(0, 255)
        .toRadixString(16)
        .padLeft(2, '0');
    final String bb = (color.b * 255.0)
        .round()
        .clamp(0, 255)
        .toRadixString(16)
        .padLeft(2, '0');
    final String aa = (color.a * 255.0)
        .round()
        .clamp(0, 255)
        .toRadixString(16)
        .padLeft(2, '0');
    final String rrggbbaa = '$rr$gg$bb$aa';
    return '#${rrggbbaa.toUpperCase()}';
  }

  Color? _parseColorHex(String value) {
    String normalized = value.trim().replaceAll('#', '');
    if (normalized.length == 6) {
      normalized = '${normalized}FF';
    }
    if (normalized.length != 8) {
      return null;
    }

    final String aarrggbb =
        '${normalized.substring(6, 8)}${normalized.substring(0, 6)}';
    final int? parsed = int.tryParse(aarrggbb, radix: 16);
    if (parsed == null) {
      return null;
    }
    return Color(parsed);
  }
}

class _SignatureColorArea extends StatelessWidget {
  const _SignatureColorArea({required this.color, required this.onChanged});

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    final HSVColor hsv = HSVColor.fromColor(color);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double height = 146;
        final double dx = hsv.saturation * width;
        final double dy = (1 - hsv.value) * height;

        void handleUpdate(Offset localPosition) {
          final double saturation = (localPosition.dx / width).clamp(0.0, 1.0);
          final double value = (1 - (localPosition.dy / height)).clamp(
            0.0,
            1.0,
          );
          onChanged(hsv.withSaturation(saturation).withValue(value).toColor());
        }

        return GestureDetector(
          onPanDown: (details) => handleUpdate(details.localPosition),
          onPanUpdate: (details) => handleUpdate(details.localPosition),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                    ),
                  ),
                ),
                Positioned(
                  left: dx - 6,
                  top: dy - 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x4D000000), blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ImageUploadDashedBorderPainter extends CustomPainter {
  const _ImageUploadDashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    final Paint paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Path source = Path()..addRRect(rrect);
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = (distance + 6).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SignatureGradientSlider extends StatelessWidget {
  const _SignatureGradientSlider({
    required this.value,
    required this.gradient,
    required this.thumbColor,
    required this.onChanged,
    this.backgroundPattern = false,
  });

  final double value;
  final List<Color> gradient;
  final Color thumbColor;
  final ValueChanged<double> onChanged;
  final bool backgroundPattern;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double x = value.clamp(0.0, 1.0) * width;

        void update(Offset localPosition) {
          onChanged((localPosition.dx / width).clamp(0.0, 1.0));
        }

        return GestureDetector(
          onPanDown: (details) => update(details.localPosition),
          onPanUpdate: (details) => update(details.localPosition),
          child: SizedBox(
            height: 14,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (backgroundPattern)
                  Container(
                    height: 8,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4D4D4), Color(0xFFFFFFFF)],
                      ),
                    ),
                  ),
                Container(
                  height: 8,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(colors: gradient),
                  ),
                ),
                Positioned(
                  left: x - 6,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: thumbColor,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x40000000), blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SignatureFontFamilyDropdown extends StatelessWidget {
  const _SignatureFontFamilyDropdown({
    required this.label,
    required this.items,
    required this.onSelected,
    required this.textStyleBuilder,
  });

  final String label;
  final List<String> items;
  final ValueChanged<String> onSelected;
  final TextStyle Function(String fontFamily, TextStyle baseStyle)
  textStyleBuilder;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseFieldStyle = AppTheme.bodyText.copyWith(
      fontSize: 13,
      color: const Color(0xFF1F2430),
    );

    return FormDropdown<String>(
      value: label,
      items: items,
      onChanged: (value) {
        if (value != null) {
          onSelected(value);
        }
      },
      displayStringForValue: (value) => value,
      showSearch: false,
      showSearchIcon: false,
      isInline: true,
      height: 28,
      menuWidth: 172,
      menuMaxHeight: 352,
      itemEstimatedHeight: 38,
      textStyle: textStyleBuilder(label, baseFieldStyle),
      itemBuilder: (item, isSelected, isHovered) {
        final bool active = isHovered;
        final Color backgroundColor = active
            ? AppTheme.primaryBlue
            : isSelected
            ? const Color(0xFFF1F4FB)
            : Colors.transparent;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Container(
            height: 32,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item,
              style: textStyleBuilder(
                item,
                AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: active ? Colors.white : const Color(0xFF1F2430),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlaceholderItem {
  const _PlaceholderItem(this.section, this.label, this.token);

  final String section;
  final String label;
  final String token;
}

class _HoverToolbarSurfaceButton extends StatefulWidget {
  const _HoverToolbarSurfaceButton({
    required this.child,
    required this.onTap,
    required this.borderRadius,
    required this.padding,
    this.active = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  final EdgeInsets padding;
  final bool active;

  @override
  State<_HoverToolbarSurfaceButton> createState() =>
      _HoverToolbarSurfaceButtonState();
}

class _HoverToolbarSurfaceButtonState
    extends State<_HoverToolbarSurfaceButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool activeOrHover = widget.active || _isHovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: activeOrHover ? Colors.white : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: activeOrHover
                ? const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _SignatureInlineToolbarTools extends StatefulWidget {
  const _SignatureInlineToolbarTools({
    required this.onIndentChange,
    required this.onAlignChange,
    required this.onListChange,
    required this.onImageInsert,
    required this.onLinkInsert,
    required this.onVideoInsert,
  });

  final ValueChanged<bool> onIndentChange;
  final ValueChanged<TextAlign> onAlignChange;
  final ValueChanged<bool> onListChange;
  final ValueChanged<String> onImageInsert;
  final void Function(String text, String url) onLinkInsert;
  final VoidCallback onVideoInsert;

  @override
  State<_SignatureInlineToolbarTools> createState() =>
      _SignatureInlineToolbarToolsState();
}

class _SignatureInlineToolbarToolsState
    extends State<_SignatureInlineToolbarTools> {
  String _selectedIndent = 'increase';
  String _selectedAlign = 'left';
  String _selectedList = 'bullet';
  String _selectedImageTab = 'upload';
  final MenuController _imageMenuController = MenuController();
  final MenuController _linkMenuController = MenuController();

  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _linkTextController = TextEditingController();
  final TextEditingController _linkUrlController = TextEditingController();

  @override
  void dispose() {
    _imageUrlController.dispose();
    _linkTextController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  Widget _buildActionButton({
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return _HoverToolbarSurfaceButton(
      onTap: onTap,
      borderRadius: 4,
      padding: const EdgeInsets.all(4),
      active: isActive,
      child: Icon(icon, size: 16, color: const Color(0xFF2B3342)),
    );
  }

  Widget _buildDropdownButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _HoverToolbarSurfaceButton(
      onTap: onTap,
      borderRadius: 6,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2B3342)),
          const SizedBox(width: 2),
          const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF5A6474)),
        ],
      ),
    );
  }

  Widget _buildDropdownMenuItem({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3B7CFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: isActive ? Colors.white : const Color(0xFF2B3342),
        ),
      ),
    );
  }

  Widget _buildImagePopoverContent(VoidCallback closeMenu) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedImageTab = 'upload'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedImageTab == 'upload'
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: _selectedImageTab == 'upload'
                            ? const [
                                BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.upload,
                            size: 14,
                            color: _selectedImageTab == 'upload'
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Upload From Desktop',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _selectedImageTab == 'upload'
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedImageTab = 'url'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedImageTab == 'url'
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: _selectedImageTab == 'url'
                            ? const [
                                BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.link,
                            size: 14,
                            color: _selectedImageTab == 'url'
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add Image URL',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _selectedImageTab == 'url'
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedImageTab == 'upload')
            CustomPaint(
              painter: const _ImageUploadDashedBorderPainter(),
              child: Container(
                width: double.infinity,
                height: 132,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.arrowUp,
                          size: 16,
                          color: Color(0xFF3B7CFF),
                        ),
                        const SizedBox(width: 6),
                        RichText(
                          text: TextSpan(
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF475569),
                            ),
                            children: [
                              const TextSpan(text: 'Drag and drop or '),
                              TextSpan(
                                text: 'Upload',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF3B7CFF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(text: ' image'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Maximum size: 1 MB',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image URL',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: TextField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(
                            hoverColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        final String url = _imageUrlController.text.trim();
                        if (url.isEmpty) return;
                        widget.onImageInsert(url);
                        _imageUrlController.clear();
                        closeMenu();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Fetch URL',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLinkPopoverContent(VoidCallback closeMenu) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Link Text',
            style: AppTheme.bodyText.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: TextField(
              controller: _linkTextController,
              decoration: InputDecoration(
                hoverColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF3B7CFF)),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Link URL',
            style: AppTheme.bodyText.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: TextField(
              controller: _linkUrlController,
              decoration: InputDecoration(
                hoverColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF3B7CFF)),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ZButton.primary(
                label: 'Add Link',
                onPressed: () {
                  widget.onLinkInsert(
                    _linkTextController.text,
                    _linkUrlController.text,
                  );
                  _linkTextController.clear();
                  _linkUrlController.clear();
                  closeMenu();
                },
                height: 30,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              const SizedBox(width: 8),
              ZButton.secondary(
                label: 'Cancel',
                onPressed: () {
                  _linkTextController.clear();
                  _linkUrlController.clear();
                  closeMenu();
                },
                height: 30,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MenuAnchor(
          controller: _imageMenuController,
          alignmentOffset: const Offset(0, 4),
          style: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
            padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.all(4)),
            elevation: WidgetStatePropertyAll<double>(6),
            side: WidgetStatePropertyAll<BorderSide>(
              BorderSide(color: AppTheme.borderLight),
            ),
          ),
          menuChildren: [
            _buildDropdownMenuItem(
              icon: LucideIcons.indent,
              isActive: _selectedIndent == 'increase',
              onTap: () {
                setState(() => _selectedIndent = 'increase');
                widget.onIndentChange(true);
              },
            ),
            const SizedBox(height: 4),
            _buildDropdownMenuItem(
              icon: LucideIcons.outdent,
              isActive: _selectedIndent == 'decrease',
              onTap: () {
                setState(() => _selectedIndent = 'decrease');
                widget.onIndentChange(false);
              },
            ),
          ],
          builder: (context, controller, child) {
            return _buildDropdownButton(
              icon: _selectedIndent == 'increase'
                  ? LucideIcons.indent
                  : LucideIcons.outdent,
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            );
          },
        ),
        const SizedBox(width: 8),
        MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          style: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
            padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.all(4)),
            elevation: WidgetStatePropertyAll<double>(6),
            side: WidgetStatePropertyAll<BorderSide>(
              BorderSide(color: AppTheme.borderLight),
            ),
          ),
          menuChildren: [
            _buildDropdownMenuItem(
              icon: LucideIcons.alignLeft,
              isActive: _selectedAlign == 'left',
              onTap: () {
                setState(() => _selectedAlign = 'left');
                widget.onAlignChange(TextAlign.left);
              },
            ),
            const SizedBox(height: 4),
            _buildDropdownMenuItem(
              icon: LucideIcons.alignCenter,
              isActive: _selectedAlign == 'center',
              onTap: () {
                setState(() => _selectedAlign = 'center');
                widget.onAlignChange(TextAlign.center);
              },
            ),
            const SizedBox(height: 4),
            _buildDropdownMenuItem(
              icon: LucideIcons.alignRight,
              isActive: _selectedAlign == 'right',
              onTap: () {
                setState(() => _selectedAlign = 'right');
                widget.onAlignChange(TextAlign.right);
              },
            ),
            const SizedBox(height: 4),
            _buildDropdownMenuItem(
              icon: LucideIcons.alignJustify,
              isActive: _selectedAlign == 'justify',
              onTap: () {
                setState(() => _selectedAlign = 'justify');
                widget.onAlignChange(TextAlign.justify);
              },
            ),
          ],
          builder: (context, controller, child) {
            final IconData alignIcon = _selectedAlign == 'center'
                ? LucideIcons.alignCenter
                : _selectedAlign == 'right'
                ? LucideIcons.alignRight
                : _selectedAlign == 'justify'
                ? LucideIcons.alignJustify
                : LucideIcons.alignLeft;
            return _buildDropdownButton(
              icon: alignIcon,
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            );
          },
        ),
        const SizedBox(width: 8),
        MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          style: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
            padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.all(4)),
            elevation: WidgetStatePropertyAll<double>(6),
            side: WidgetStatePropertyAll<BorderSide>(
              BorderSide(color: AppTheme.borderLight),
            ),
          ),
          menuChildren: [
            _buildDropdownMenuItem(
              icon: LucideIcons.list,
              isActive: _selectedList == 'bullet',
              onTap: () {
                setState(() => _selectedList = 'bullet');
                widget.onListChange(false);
              },
            ),
            const SizedBox(height: 4),
            _buildDropdownMenuItem(
              icon: LucideIcons.listOrdered,
              isActive: _selectedList == 'ordered',
              onTap: () {
                setState(() => _selectedList = 'ordered');
                widget.onListChange(true);
              },
            ),
          ],
          builder: (context, controller, child) {
            return _buildDropdownButton(
              icon: _selectedList == 'ordered'
                  ? LucideIcons.listOrdered
                  : LucideIcons.list,
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            );
          },
        ),
        const SizedBox(width: 6),
        Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
        const SizedBox(width: 6),
        MenuAnchor(
          controller: _imageMenuController,
          alignmentOffset: const Offset(0, 4),
          style: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
            padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
            elevation: WidgetStatePropertyAll<double>(6),
            side: WidgetStatePropertyAll<BorderSide>(
              BorderSide(color: AppTheme.borderLight),
            ),
          ),
          builder: (context, controller, child) {
            return _buildActionButton(
              icon: LucideIcons.image,
              isActive: controller.isOpen,
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            );
          },
          menuChildren: [_buildImagePopoverContent(_imageMenuController.close)],
        ),
        const SizedBox(width: 6),
        MenuAnchor(
          controller: _linkMenuController,
          alignmentOffset: const Offset(0, 4),
          style: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
            padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
            elevation: WidgetStatePropertyAll<double>(6),
            side: WidgetStatePropertyAll<BorderSide>(
              BorderSide(color: AppTheme.borderLight),
            ),
          ),
          builder: (context, controller, child) {
            return _buildActionButton(
              icon: LucideIcons.link,
              onTap: () {
                if (_linkMenuController.isOpen) {
                  _linkMenuController.close();
                } else {
                  _linkMenuController.open();
                }
              },
            );
          },
          menuChildren: [_buildLinkPopoverContent(_linkMenuController.close)],
        ),
      ],
    );
  }
}

class _SignatureOverflowMenu extends StatefulWidget {
  const _SignatureOverflowMenu({
    required this.onIndentChange,
    required this.onAlignChange,
    required this.onListChange,
    required this.onImageInsert,
    required this.onLinkInsert,
    required this.onVideoInsert,
  });

  final ValueChanged<bool> onIndentChange;
  final ValueChanged<TextAlign> onAlignChange;
  final ValueChanged<bool> onListChange;
  final ValueChanged<String> onImageInsert;
  final void Function(String text, String url) onLinkInsert;
  final VoidCallback onVideoInsert;

  @override
  State<_SignatureOverflowMenu> createState() => _SignatureOverflowMenuState();
}

class _SignatureOverflowMenuState extends State<_SignatureOverflowMenu> {
  final MenuController _menuController = MenuController();

  String _selectedIndent = 'increase';
  String _selectedAlign = 'left';
  String _selectedList = 'bullet';
  String _selectedImageTab = 'upload';

  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _linkTextController = TextEditingController();
  final TextEditingController _linkUrlController = TextEditingController();

  @override
  void dispose() {
    _imageUrlController.dispose();
    _linkTextController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  Widget _buildActionButton({
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return _HoverToolbarSurfaceButton(
      onTap: onTap,
      borderRadius: 4,
      padding: const EdgeInsets.all(4),
      active: isActive,
      child: Icon(icon, size: 16, color: const Color(0xFF2B3342)),
    );
  }

  Widget _buildDropdownButton({
    required IconData icon,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return _HoverToolbarSurfaceButton(
      onTap: onTap,
      borderRadius: 6,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2B3342)),
          const SizedBox(width: 2),
          const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF5A6474)),
        ],
      ),
    );
  }

  Widget _buildDropdownMenuItem({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        onTap();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3B7CFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: isActive ? Colors.white : const Color(0xFF2B3342),
        ),
      ),
    );
  }

  Widget _buildImagePopoverContent(VoidCallback closeMenu) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedImageTab = 'upload'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedImageTab == 'upload'
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: _selectedImageTab == 'upload'
                            ? const [
                                BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.upload,
                            size: 14,
                            color: _selectedImageTab == 'upload'
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Upload From Desktop',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _selectedImageTab == 'upload'
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedImageTab = 'url'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedImageTab == 'url'
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: _selectedImageTab == 'url'
                            ? const [
                                BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.link,
                            size: 14,
                            color: _selectedImageTab == 'url'
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add Image URL',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _selectedImageTab == 'url'
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedImageTab == 'upload')
            CustomPaint(
              painter: const _ImageUploadDashedBorderPainter(),
              child: Container(
                width: double.infinity,
                height: 132,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.arrowUp,
                          size: 16,
                          color: Color(0xFF3B7CFF),
                        ),
                        const SizedBox(width: 6),
                        RichText(
                          text: TextSpan(
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF475569),
                            ),
                            children: [
                              const TextSpan(text: 'Drag and drop or '),
                              TextSpan(
                                text: 'Upload',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF3B7CFF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(text: ' image'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Maximum size: 1 MB',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image URL',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: TextField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(
                            hoverColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        final String url = _imageUrlController.text.trim();
                        if (url.isEmpty) return;
                        widget.onImageInsert(url);
                        _imageUrlController.clear();
                        closeMenu();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Fetch URL',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLinkPopoverContent() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Link Text',
            style: AppTheme.bodyText.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: TextField(
              controller: _linkTextController,
              decoration: InputDecoration(
                hoverColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF3B7CFF)),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Link URL',
            style: AppTheme.bodyText.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: TextField(
              controller: _linkUrlController,
              decoration: InputDecoration(
                hoverColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF3B7CFF)),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ZButton.primary(
                label: 'Add Link',
                onPressed: () {
                  widget.onLinkInsert(
                    _linkTextController.text,
                    _linkUrlController.text,
                  );
                  _linkTextController.clear();
                  _linkUrlController.clear();
                  _menuController.close();
                },
                height: 30,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              const SizedBox(width: 8),
              ZButton.secondary(
                label: 'Cancel',
                onPressed: () {
                  _linkTextController.clear();
                  _linkUrlController.clear();
                  _menuController.close();
                },
                height: 30,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(-4, 8),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
        padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
        elevation: WidgetStatePropertyAll<double>(6),
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: AppTheme.borderLight),
        ),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MenuAnchor(
                  alignmentOffset: const Offset(0, 4),
                  style: const MenuStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(
                      Colors.white,
                    ),
                    padding: WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.all(4),
                    ),
                    elevation: WidgetStatePropertyAll<double>(6),
                    side: WidgetStatePropertyAll<BorderSide>(
                      BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  menuChildren: [
                    _buildDropdownMenuItem(
                      icon: LucideIcons.indent,
                      isActive: _selectedIndent == 'increase',
                      onTap: () {
                        setState(() => _selectedIndent = 'increase');
                        widget.onIndentChange(true);
                      },
                    ),
                    const SizedBox(height: 4),
                    _buildDropdownMenuItem(
                      icon: LucideIcons.outdent,
                      isActive: _selectedIndent == 'decrease',
                      onTap: () {
                        setState(() => _selectedIndent = 'decrease');
                        widget.onIndentChange(false);
                      },
                    ),
                  ],
                  builder: (context, controller, child) {
                    return _buildDropdownButton(
                      icon: _selectedIndent == 'increase'
                          ? LucideIcons.indent
                          : LucideIcons.outdent,
                      isActive:
                          controller.isOpen || _selectedIndent == 'increase',
                      onTap: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                    );
                  },
                ),
                const SizedBox(width: 8),
                MenuAnchor(
                  alignmentOffset: const Offset(0, 4),
                  style: const MenuStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(
                      Colors.white,
                    ),
                    padding: WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.all(4),
                    ),
                    elevation: WidgetStatePropertyAll<double>(6),
                    side: WidgetStatePropertyAll<BorderSide>(
                      BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  menuChildren: [
                    _buildDropdownMenuItem(
                      icon: LucideIcons.alignLeft,
                      isActive: _selectedAlign == 'left',
                      onTap: () {
                        setState(() => _selectedAlign = 'left');
                        widget.onAlignChange(TextAlign.left);
                      },
                    ),
                    const SizedBox(height: 4),
                    _buildDropdownMenuItem(
                      icon: LucideIcons.alignCenter,
                      isActive: _selectedAlign == 'center',
                      onTap: () {
                        setState(() => _selectedAlign = 'center');
                        widget.onAlignChange(TextAlign.center);
                      },
                    ),
                    const SizedBox(height: 4),
                    _buildDropdownMenuItem(
                      icon: LucideIcons.alignRight,
                      isActive: _selectedAlign == 'right',
                      onTap: () {
                        setState(() => _selectedAlign = 'right');
                        widget.onAlignChange(TextAlign.right);
                      },
                    ),
                    const SizedBox(height: 4),
                    _buildDropdownMenuItem(
                      icon: LucideIcons.alignJustify,
                      isActive: _selectedAlign == 'justify',
                      onTap: () {
                        setState(() => _selectedAlign = 'justify');
                        widget.onAlignChange(TextAlign.justify);
                      },
                    ),
                  ],
                  builder: (context, controller, child) {
                    final alignIcon = _selectedAlign == 'center'
                        ? LucideIcons.alignCenter
                        : _selectedAlign == 'right'
                        ? LucideIcons.alignRight
                        : _selectedAlign == 'justify'
                        ? LucideIcons.alignJustify
                        : LucideIcons.alignLeft;
                    return _buildDropdownButton(
                      icon: alignIcon,
                      isActive: controller.isOpen || _selectedAlign != 'left',
                      onTap: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                    );
                  },
                ),
                const SizedBox(width: 8),
                MenuAnchor(
                  alignmentOffset: const Offset(0, 4),
                  style: const MenuStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(
                      Colors.white,
                    ),
                    padding: WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.all(4),
                    ),
                    elevation: WidgetStatePropertyAll<double>(6),
                    side: WidgetStatePropertyAll<BorderSide>(
                      BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  menuChildren: [
                    _buildDropdownMenuItem(
                      icon: LucideIcons.list,
                      isActive: _selectedList == 'bullet',
                      onTap: () {
                        setState(() => _selectedList = 'bullet');
                        widget.onListChange(false);
                      },
                    ),
                    const SizedBox(height: 4),
                    _buildDropdownMenuItem(
                      icon: LucideIcons.listOrdered,
                      isActive: _selectedList == 'ordered',
                      onTap: () {
                        setState(() => _selectedList = 'ordered');
                        widget.onListChange(true);
                      },
                    ),
                  ],
                  builder: (context, controller, child) {
                    return _buildDropdownButton(
                      icon: _selectedList == 'ordered'
                          ? LucideIcons.listOrdered
                          : LucideIcons.list,
                      isActive: controller.isOpen || _selectedList != 'bullet',
                      onTap: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                    );
                  },
                ),
                const SizedBox(width: 6),
                Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
                const SizedBox(width: 6),
                MenuAnchor(
                  alignmentOffset: const Offset(0, 4),
                  style: const MenuStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(
                      Colors.white,
                    ),
                    padding: WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.zero,
                    ),
                    elevation: WidgetStatePropertyAll<double>(6),
                    side: WidgetStatePropertyAll<BorderSide>(
                      BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  menuChildren: [
                    _buildImagePopoverContent(_menuController.close),
                  ],
                  builder: (context, controller, child) {
                    return _buildActionButton(
                      icon: LucideIcons.image,
                      isActive: controller.isOpen,
                      onTap: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                    );
                  },
                ),
                const SizedBox(width: 6),
                MenuAnchor(
                  alignmentOffset: const Offset(0, 4),
                  style: const MenuStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(
                      Colors.white,
                    ),
                    padding: WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.zero,
                    ),
                    elevation: WidgetStatePropertyAll<double>(6),
                    side: WidgetStatePropertyAll<BorderSide>(
                      BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  menuChildren: [_buildLinkPopoverContent()],
                  builder: (context, controller, child) {
                    return _buildActionButton(
                      icon: LucideIcons.link,
                      isActive: controller.isOpen,
                      onTap: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: controller.isOpen ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: controller.isOpen
                  ? Border.all(color: AppTheme.borderLight)
                  : null,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.more_horiz,
              size: 20,
              color: Color(0xFF2B3342),
            ),
          ),
        );
      },
    );
  }
}

class _PlaceholderToolbarDropdown extends StatelessWidget {
  const _PlaceholderToolbarDropdown({
    required this.value,
    required this.items,
    required this.onSelected,
  });

  final _PlaceholderItem? value;
  final List<_PlaceholderItem> items;
  final ValueChanged<_PlaceholderItem> onSelected;

  @override
  Widget build(BuildContext context) {
    return FormDropdown<_PlaceholderItem>(
      value: value,
      items: items,
      onChanged: (item) {
        if (item != null) {
          onSelected(item);
        }
      },
      displayStringForValue: (_) => 'Insert Placeholder',
      searchStringForValue: (item) => '${item.section} ${item.label}',
      itemBuilder: (item, isSelected, isHovered) {
        final bool active = isSelected || isHovered;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Container(
            height: 40,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: active ? AppTheme.infoBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 15,
                color: active ? Colors.white : const Color(0xFF4D5565),
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        );
      },
      listBuilder: (filteredItems, itemBuilder) {
        final Map<String, List<_PlaceholderItem>> grouped =
            <String, List<_PlaceholderItem>>{};
        for (final item in filteredItems) {
          grouped
              .putIfAbsent(item.section, () => <_PlaceholderItem>[])
              .add(item);
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Text(
                      entry.key,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF7D8099),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Wrap(
                    children: entry.value.map((item) {
                      return SizedBox(width: 225, child: itemBuilder(item));
                    }).toList(),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
      hint: 'Insert Placeholder',
      placeholder: 'Search',
      showSearch: true,
      showSearchIcon: true,
      isInline: true,
      alignMenuRightToField: true,
      forceDownward: true,
      height: 28,
      menuWidth: 720,
      menuMaxHeight: 400,
      itemEstimatedHeight: 48,
      textStyle: AppTheme.bodyText.copyWith(
        fontSize: 14,
        color: const Color(0xFF1F2430),
      ),
    );
  }
}

class _ToolbarText extends StatelessWidget {
  const _ToolbarText({
    required this.label,
    this.active = false,
    this.onTap,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        color: active ? const Color(0xFFE7EFFD) : Colors.transparent,
        child: Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 16,
            color: Colors.black,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            decoration: underline
                ? TextDecoration.underline
                : strike
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider({this.horizontal = 14});

  final double horizontal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: EdgeInsets.symmetric(horizontal: horizontal),
      color: const Color(0xFFD8DCE7),
    );
  }
}

class _HoverMenuItem extends StatefulWidget {
  const _HoverMenuItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_HoverMenuItem> createState() => _HoverMenuItemState();
}

class _HoverMenuItemState extends State<_HoverMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 82,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: _isHovered ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverSuccessMenu extends StatelessWidget {
  const _HoverSuccessMenu({required this.onEdit, this.onClone, this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback? onClone;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-92, 8),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.all(6)),
        elevation: WidgetStatePropertyAll(10),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      menuChildren: [
        _HoverMenuItem(label: 'Edit', onTap: onEdit),
        if (onClone != null) ...[
          const SizedBox(height: 4),
          _HoverMenuItem(label: 'Clone', onTap: onClone!),
        ],
        if (onDelete != null) ...[
          const SizedBox(height: 4),
          _HoverMenuItem(label: 'Delete', onTap: onDelete!),
        ],
      ],
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF29B765),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _EmailNotificationsContent extends StatefulWidget {
  const _EmailNotificationsContent({
    required this.onNewSender,
    required this.onAuthenticateNow,
  });

  final VoidCallback onNewSender;
  final VoidCallback onAuthenticateNow;

  @override
  State<_EmailNotificationsContent> createState() =>
      _EmailNotificationsContentState();
}

class _EmailNotificationsContentState
    extends State<_EmailNotificationsContent> {
  late final TextEditingController _senderNameController;
  late final TextEditingController _senderEmailController;
  bool _isEditingSender = false;

  @override
  void initState() {
    super.initState();
    _senderNameController = TextEditingController();
    _senderEmailController = TextEditingController();
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              Text(
                'Sender Email Preferences',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: widget.onNewSender,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF21B66F),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+ New Sender',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Icon(
                    LucideIcons.lightbulb,
                    size: 15,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Page Tips',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: const Color(0xFFFFF5E8),
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Unauthenticated Domains',
                            style: AppTheme.pageTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const ZTooltip(
                            message:
                                "Domains that do not have DKIM records configured at the domain provider's website are Unauthenticated Domains.",
                            direction: ZTooltipDirection.top,
                            child: Icon(
                              LucideIcons.helpCircle,
                              size: 15,
                              color: Color(0xFF9099AB),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            height: 1.6,
                            color: const Color(0xFF5D6474),
                          ),
                          children: const [
                            TextSpan(
                              text:
                                  'If emails are sent with the following email addresses in the From field, emails will be sent from ',
                            ),
                            TextSpan(
                              text: 'message-service@sender.zoho-inventory.in',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(
                              text:
                                  ' to prevent them from landing in the Spam folder.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE6BF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.alertCircle,
                              size: 18,
                              color: Color(0xFFFFA500),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Authenticate this domain to send emails from your email address under this domain.',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: const Color(0xFF2D3444),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F1F2937),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                22,
                                28,
                                22,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.shield,
                                    size: 20,
                                    color: Color(0xFFEB2525),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Sender domain',
                                    style: AppTheme.pageTitle.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: widget.onAuthenticateNow,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Authenticate Now',
                                            style: AppTheme.bodyText.copyWith(
                                              fontSize: 13,
                                              color: AppTheme.primaryBlue,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            LucideIcons.arrowRight,
                                            size: 16,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: AppTheme.borderLight,
                            ),
                            if (_isEditingSender)
                              Container(
                                color: const Color(0xFFF7F9FE),
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  12,
                                  12,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: CustomTextField(
                                        controller: _senderNameController,
                                        height: 38,
                                        contentCase: ContentCase.none,
                                        forceUppercase: false,
                                        fillColor: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        textStyle: AppTheme.bodyText.copyWith(
                                          fontSize: 13,
                                          color: const Color(0xFF3C465A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 32),
                                    Expanded(
                                      flex: 4,
                                      child: CustomTextField(
                                        controller: _senderEmailController,
                                        height: 38,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        contentCase: ContentCase.none,
                                        forceUppercase: false,
                                        fillColor: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        textStyle: AppTheme.bodyText.copyWith(
                                          fontSize: 13,
                                          color: const Color(0xFF3C465A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    ZButton.primary(
                                      label: 'Save',
                                      onPressed: () {
                                        setState(() {
                                          _isEditingSender = false;
                                        });
                                      },
                                      height: 30,
                                      fontSize: 13,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ZButton.secondary(
                                      label: 'Cancel',
                                      onPressed: () {
                                        setState(() {
                                          _senderNameController.clear();
                                          _senderEmailController.clear();
                                          _isEditingSender = false;
                                        });
                                      },
                                      height: 30,
                                      fontSize: 13,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  15,
                                  24,
                                  15,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        _senderNameController.text,
                                        style: AppTheme.bodyText.copyWith(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        _senderEmailController.text,
                                        style: AppTheme.bodyText.copyWith(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            size: 18,
                                            color: Color(0xFFF5A300),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Unverified',
                                            style: AppTheme.bodyText.copyWith(
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '(Resend Email)',
                                            style: AppTheme.bodyText.copyWith(
                                              fontSize: 13,
                                              color: AppTheme.primaryBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isEditingSender = true;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          LucideIcons.pencil,
                                          size: 18,
                                          color: Color(0xFF9099AB),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      LucideIcons.trash2,
                                      size: 18,
                                      color: Color(0xFF9099AB),
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
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Public Domains',
                            style: AppTheme.pageTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const ZTooltip(
                            message:
                                'Public domains include free email service providers such as Gmail, Yahoo, Outlook, etc.',
                            direction: ZTooltipDirection.top,
                            child: Icon(
                              LucideIcons.helpCircle,
                              size: 15,
                              color: Color(0xFF9099AB),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1140),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 32,
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(
                                          30,
                                          44,
                                          20,
                                          44,
                                        ),
                                        color: Colors.white,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'EMAILS ARE SENT THROUGH',
                                              style: AppTheme.captionText
                                                  .copyWith(
                                                    fontSize: 12,
                                                    color: const Color(
                                                      0xFF78859B,
                                                    ),
                                                  ),
                                            ),
                                            const SizedBox(height: 28),
                                            Text(
                                              'Email address of Zoho Inventory',
                                              style: AppTheme.bodyText.copyWith(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '(message-service@sender.zoho-inventory.in)',
                                              style: AppTheme.bodyText.copyWith(
                                                fontSize: 13,
                                                color: const Color(0xFF7B88A0),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 68,
                                      child: Container(
                                        color: const Color(0xFFF2F7FF),
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          38,
                                          24,
                                          38,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(top: 2),
                                              child: Icon(
                                                Icons.info,
                                                size: 18,
                                                color: Color(0xFF2B86D9),
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  style: AppTheme.bodyText
                                                      .copyWith(
                                                        fontSize: 13,
                                                        height: 1.8,
                                                        color: const Color(
                                                          0xFF2D3444,
                                                        ),
                                                      ),
                                                  children: const [
                                                    TextSpan(
                                                      text:
                                                          'Emails sent from a public domain may be flagged as spam. If you use a public domain address, the email will be delivered via ',
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          'message-service@sender.zoho-inventory.in',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '. Emails sent through your configured Gmail or Microsoft account will first be sent through that account, and if sending fails, will automatically be resent via ',
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          'message-service@sender.zoho-inventory.in',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '. In all cases, the Reply-To address will be set to the from address.',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppTheme.borderLight,
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    14,
                                    24,
                                    14,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Text(
                                          'NAME',
                                          style: AppTheme.bodyText.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 7,
                                        child: Text(
                                          'EMAIL ADDRESS',
                                          style: AppTheme.bodyText.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 76),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppTheme.borderLight,
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Text(
                                    'No public domain senders configured',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
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
      ],
    );
  }
}

class _AddAdditionalContactDialog extends StatefulWidget {
  const _AddAdditionalContactDialog({required this.emailOptions});

  final List<String> emailOptions;

  @override
  State<_AddAdditionalContactDialog> createState() =>
      _AddAdditionalContactDialogState();
}

class _AddAdditionalContactDialogState
    extends State<_AddAdditionalContactDialog> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedEmail;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.only(top: 0),
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    Text(
                      'Add Additional Contact',
                      style: AppTheme.pageTitle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: Color(0xFFFF4D4F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.borderLight,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                child: Column(
                  children: [
                    _DialogFieldRow(
                      label: 'Name*',
                      child: CustomTextField(
                        controller: _nameController,
                        hintText: '',
                        height: 38,
                        forceUppercase: false,
                        contentCase: ContentCase.none,
                        fillColor: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DialogFieldRow(
                      label: 'Email*',
                      child: SizedBox(
                        height: 38,
                        child: FormDropdown<String>(
                          value: _selectedEmail,
                          items: widget.emailOptions,
                          hint: 'Select from organization users or type',
                          onChanged: (value) {
                            setState(() {
                              _selectedEmail = value;
                            });
                          },
                          allowCustomValue: true,
                          showSearch: true,
                          forceUppercase: false,
                          fillColor: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF7C8496),
                          ),
                          itemBuilder: (item, isSelected, isHovered) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: isHovered
                                    ? AppTheme.primaryBlue
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item,
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 13,
                                  color: isHovered
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.borderLight,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
                child: Row(
                  children: [
                    ZButton.primary(
                      label: 'Save',
                      onPressed: () => Navigator.of(context).pop(),
                      height: 38,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    const SizedBox(width: 8),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                      height: 38,
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

class _AuthenticateDomainDialog extends StatelessWidget {
  const _AuthenticateDomainDialog();

  static const String _hostName = '';
  static const String _value = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.only(top: 0),
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 790),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
                child: Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppTheme.pageTitle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        children: const [
                          TextSpan(text: 'Authenticate '),
                          TextSpan(
                            text: 'configured domain',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.borderLight,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
                child: Text(
                  'Add DKIM (Domain Keys Identified Mail) in the DNS settings of your domain provider to prevent your emails from landing in the Spam folder.',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    height: 1.55,
                    color: const Color(0xFF3F4757),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  color: const Color(0xFFF7F9FE),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 2, color: const Color(0xFF6A8FFF)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DKIM',
                              style: AppTheme.pageTitle.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3B3F4C),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Add the Host Name and the Value provided below in the DNS settings of your domain provider as a TXT record.',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                height: 1.6,
                                color: const Color(0xFF5B6274),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _AuthenticateInfoField(
                              label: 'HOST NAME',
                              value: _hostName,
                            ),
                            const SizedBox(height: 16),
                            _AuthenticateInfoField(
                              label: 'VALUE',
                              value: _value,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      height: 46,
                      color: const Color(0xFFF9B21B),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'After you\'ve added DKIM in the DNS settings of your domain provider, click Validate to authenticate the domain in Zoho Inventory.',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          height: 1.55,
                          color: const Color(0xFF5B6274),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Text(
                  'Note: It takes a while for DKIM to be available on the DNS server. If validation fails, please try again after some time.',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    height: 1.55,
                    color: const Color(0xFF7B83A2),
                  ),
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.borderLight,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
                child: Row(
                  children: [
                    ZButton.primary(
                      label: 'Validate',
                      onPressed: () => Navigator.of(context).pop(),
                      height: 36,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    const SizedBox(width: 8),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
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

class _AuthenticateInfoField extends StatelessWidget {
  const _AuthenticateInfoField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12,
            color: const Color(0xFF6B7590),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDBDEE8)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF41485A),
                    ),
                  ),
                ),
              ),
              Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F8F8),
                  border: Border(left: BorderSide(color: Color(0xFFDBDEE8))),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Copy',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF2F3542),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialogFieldRow extends StatelessWidget {
  const _DialogFieldRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: const Color(0xFFFF3B30),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _PublicDomainRow extends StatefulWidget {
  const _PublicDomainRow({required this.name, required this.email});

  final String name;
  final String email;

  @override
  State<_PublicDomainRow> createState() => _PublicDomainRowState();
}

class _PublicDomainRowState extends State<_PublicDomainRow> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _isEditing = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Container(
        color: const Color(0xFFF7F9FE),
        padding: const EdgeInsets.fromLTRB(24, 14, 14, 14),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: CustomTextField(
                controller: _nameController,
                height: 38,
                contentCase: ContentCase.none,
                forceUppercase: false,
                fillColor: Colors.white,
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF3C465A),
                ),
              ),
            ),
            const SizedBox(width: 34),
            Expanded(
              flex: 7,
              child: CustomTextField(
                controller: _emailController,
                height: 38,
                keyboardType: TextInputType.emailAddress,
                contentCase: ContentCase.none,
                forceUppercase: false,
                fillColor: Colors.white,
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF3C465A),
                ),
              ),
            ),
            const SizedBox(width: 24),
            ZButton.primary(
              label: 'Save',
              onPressed: () {
                setState(() {
                  _isEditing = false;
                });
              },
              height: 30,
              fontSize: 13,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            const SizedBox(width: 10),
            ZButton.secondary(
              label: 'Cancel',
              onPressed: () {
                setState(() {
                  _nameController.text = widget.name;
                  _emailController.text = widget.email;
                  _isEditing = false;
                });
              },
              height: 30,
              fontSize: 13,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ],
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        color: _isHovered ? const Color(0xFFF7F9FE) : Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _nameController.text,
                      style: AppTheme.bodyText.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 7,
              child: Text(
                _emailController.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyText.copyWith(fontSize: 13),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _isEditing = true;
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  LucideIcons.pencil,
                  size: 18,
                  color: Color(0xFF9099AB),
                ),
              ),
            ),
            const SizedBox(width: 26),
            const Icon(LucideIcons.trash2, size: 18, color: Color(0xFF9099AB)),
          ],
        ),
      ),
    );
  }
}
