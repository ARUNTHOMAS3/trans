import 'dart:js_interop';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:web/web.dart' as web;
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/font_family_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_page_header.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

const List<String> _reminderTimingOptions = <String>['before', 'after'];

Widget _buildReminderTimingDropdown({
  required String value,
  required ValueChanged<String> onChanged,
}) {
  return FormDropdown<String>(
    value: value,
    items: _reminderTimingOptions,
    hint: '',
    onChanged: (selectedValue) {
      if (selectedValue == null) {
        return;
      }
      onChanged(selectedValue);
    },
    height: 32,
    showSearch: true,
    showSearchIcon: true,
    menuMaxHeight: 126,
    maxVisibleItems: 2,
    itemHeight: 36,
    boldSelected: false,
    paintSelectionBackground: false,
    displayStringForValue: (item) => item,
    searchStringForValue: (item) => item,
    textStyle: AppTheme.bodyText.copyWith(
      fontSize: 14,
      color: const Color(0xFF374151),
    ),
    itemBuilder: (item, isSelected, isHovered) {
      final bool showBlueState = isHovered;
      final Color textColor = showBlueState
          ? Colors.white
          : (isSelected ? const Color(0xFF344054) : const Color(0xFF374151));

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: showBlueState ? const Color(0xFF4285F4) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check,
                  size: 16,
                  color: showBlueState ? Colors.white : const Color(0xFF667085),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class SetupConfigureReminderPage extends StatefulWidget {
  const SetupConfigureReminderPage({super.key});

  @override
  State<SetupConfigureReminderPage> createState() =>
      _SetupConfigureReminderPageState();
}

class _SetupConfigureReminderPageState
    extends State<SetupConfigureReminderPage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _paymentExpectedEnabled = false;
  bool _reminderOneEnabled = false;
  bool _reminderTwoEnabled = false;
  bool _reminderThreeEnabled = false;
  final Map<String, String> _ruleIds = {};

  @override
  void initState() {
    super.initState();
    _loadReminderRules();
  }

  Future<void> _loadReminderRules() async {
    try {
      final response = await _apiClient.get(
        'settings-customization/reminder-rules',
        queryParameters: const {'module': 'invoices'},
        useCache: false,
      );
      final rows = (response.data as List? ?? const []).whereType<Map>();
      final enabled = <String, bool>{};
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        final code = row['event_code']?.toString() ?? '';
        if (code.isEmpty) continue;
        enabled[code] = row['is_active'] == true;
        final id = row['id']?.toString();
        if (id != null && id.isNotEmpty) _ruleIds[code] = id;
      }
      if (!mounted) return;
      setState(() {
        _paymentExpectedEnabled = enabled['expected_payment_date'] ?? false;
        _reminderOneEnabled = enabled['reminder_1'] ?? false;
        _reminderTwoEnabled = enabled['reminder_2'] ?? false;
        _reminderThreeEnabled = enabled['reminder_3'] ?? false;
      });
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to load reminder rules');
    }
  }

  Future<void> _persistReminderRule(String eventCode, bool enabled) async {
    final payload = {
      'name': eventCode.replaceAll('_', ' '),
      'module': 'invoices',
      'event_code': eventCode,
      'channel': 'email',
      'offset_days': 0,
      'is_active': enabled,
    };
    final id = _ruleIds[eventCode];
    final response = id == null
        ? await _apiClient.post(
            'settings-customization/reminder-rules',
            data: payload,
          )
        : await _apiClient.patch(
            'settings-customization/reminder-rules/$id',
            data: payload,
          );
    final savedId = (response.data as Map?)?['id']?.toString();
    if (savedId != null && savedId.isNotEmpty) _ruleIds[eventCode] = savedId;
  }

  Future<void> _deleteReminderRule(String eventCode) async {
    final id = _ruleIds[eventCode];
    if (id == null) return;
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Reminder',
      message: 'This reminder will be deactivated.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (!confirmed || !mounted) return;
    try {
      await _apiClient.delete('settings-customization/reminder-rules/$id');
      await _loadReminderRules();
      if (mounted) ZerpaiToast.success(context, 'Reminder deleted');
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to delete reminder');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<SettingsSearchItem> _buildSearchItems(BuildContext context) {
    return kSettingsNavigationSections
        .expand(
          (section) => section.blocks.expand(
            (block) => block.items.map(
              (entry) => SettingsSearchItem(
                group: block.title,
                label: entry.label,
                subtitle: section.title,
                keywords: <String>[section.title, block.title, entry.label],
                onSelected: () => _handleEntryTap(context, entry),
              ),
            ),
          ),
        )
        .toList(growable: false);
  }

  void _handleEntryTap(BuildContext context, SettingsNavigationEntry entry) {
    if (entry.route == null) {
      ZerpaiToast.info(context, '${entry.label} is not available yet');
      return;
    }
    context.go(_orgScopedRoute(context, entry.route!));
  }

  String _orgScopedRoute(BuildContext context, String route) {
    final path = GoRouterState.of(context).uri.path;
    final match = RegExp(r'^/(\d{10,20})(?:/|$)').firstMatch(path);
    final orgSystemId = match?.group(1);
    if (orgSystemId == null || orgSystemId.isEmpty) {
      return route;
    }
    return '/$orgSystemId$route';
  }

  Future<void> _openReminderEditorDialog({
    required String title,
    required String subject,
    required String body,
    _AutomatedReminderDialogConfig? automatedConfig,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => _ReminderEditorDialog(
        title: title,
        subject: subject,
        body: body,
        automatedConfig: automatedConfig,
      ),
    );
  }

  String _buildAutomatedReminderBodyHtml() {
    return '''
<div>Dear %CustomerName%,</div>
<div><br></div>
<div>This is to remind you about the payment details for the below invoice.</div>
<div><br></div>
<div>--------------------------------------------------------------</div>
<div><br></div>
<div><b style="font-size:18px;">Invoice# : %InvoiceNumber%</b></div>
<div><br></div>
<div>Due Date : &nbsp; %DueDate%</div>
<div>--------------------------------------------------------------</div>
<div><b>Overdue By</b> &nbsp; : &nbsp; %OverdueDays%</div>
<div><b>Amount</b> &nbsp; &nbsp; &nbsp; : &nbsp; %Balance%</div>
<div>--------------------------------------------------------------</div>
<div><br></div>
<div>View your invoice and take the easy way out by making an <a href="#">online payment</a>.</div>
<div><br></div>
<div>If you have already paid, please accept our apologies and kindly ignore this payment reminder.</div>
''';
  }

  void _openOverdueManualReminderDialog() {
    _openReminderEditorDialog(
      title: 'Reminder For Overdue Invoices',
      subject: 'Payment of %Balance% is outstanding for %InvoiceNumber%',
      body: _buildAutomatedReminderBodyHtml(),
    );
  }

  void _openSentManualReminderDialog() {
    _openReminderEditorDialog(
      title: 'Reminder For Sent Invoices',
      subject: 'Payment of %Balance% is outstanding for %InvoiceNumber%',
      body: _buildAutomatedReminderBodyHtml(),
    );
  }

  Future<void> _handleReminderToggle({
    required bool nextValue,
    required bool currentValue,
    required ValueChanged<bool> applyValue,
    required String milestoneLabel,
    required String eventCode,
  }) async {
    final shouldEnable = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => _ReminderQuickConfigDialog(
        milestoneLabel: milestoneLabel,
        initialEnabled: nextValue,
      ),
    );

    if (shouldEnable != null) {
      try {
        await _persistReminderRule(eventCode, shouldEnable);
        applyValue(shouldEnable);
      } catch (_) {
        applyValue(currentValue);
        if (mounted) ZerpaiToast.error(context, 'Failed to save reminder rule');
      }
      return;
    }

    applyValue(currentValue);
  }

  Future<void> _openReminderQuickConfig({
    required bool currentValue,
    required ValueChanged<bool> applyValue,
    required String milestoneLabel,
    required String eventCode,
  }) {
    return _handleReminderToggle(
      nextValue: currentValue,
      currentValue: currentValue,
      applyValue: applyValue,
      milestoneLabel: milestoneLabel,
      eventCode: eventCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(
      context,
    ).uri.path.replaceFirst(RegExp(r'^/\d{10,20}'), '');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SettingsPageHeader(
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            searchItems: _buildSearchItems(context),
            showBackButton: true,
            onBack: () =>
                context.go(_orgScopedRoute(context, AppRoutes.settings)),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsNavigationSidebar(currentPath: currentPath),
                Expanded(
                  child: ColoredBox(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTitleBar(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSectionTitle('Manual Reminders'),
                                const SizedBox(height: 14),
                                _ReminderTableCard(
                                  headers: const [
                                    'NAME',
                                    'DESCRIPTION',
                                    'ACTIONS',
                                  ],
                                  columnWidths: const <int, TableColumnWidth>{
                                    0: FlexColumnWidth(1.4),
                                    1: FlexColumnWidth(4.8),
                                    2: FixedColumnWidth(118),
                                  },
                                  rows: [
                                    _ReminderRowData(
                                      firstCell: _buildLinkLabel(
                                        'Reminder For Overdue Invoices',
                                        onTap: _openOverdueManualReminderDialog,
                                      ),
                                      secondCell: _buildDescription(
                                        'You can send this reminder to your customers manually, from an overdue invoice\'s details page.',
                                      ),
                                      thirdCell: _buildActionButton(
                                        icon: LucideIcons.pencil,
                                        onTap: () => _openReminderEditorDialog(
                                          title:
                                              'Reminder For Overdue Invoices',
                                          subject:
                                              'Payment of %Balance% is outstanding for %InvoiceNumber%',
                                          body:
                                              'Dear %CustomerName%,\n\nYou might have missed the payment date and the invoice is now overdue by %OverdueDays% days.\n\n--------------------------------------------------------------\nInvoice# : %InvoiceNumber%\n\nDated : %InvoiceDate%\n--------------------------------------------------------------\nDue Date        :  %DueDate%\nAmount          :  %Balance%\n--------------------------------------------------------------\n\nNot to worry at all ! View your invoice and take the easy way out by making an online payment.\n\nIf you have already paid, please accept our apologies and kindly ignore this payment reminder.\n\nRegards,\n\n%UserName%\n%CompanyName%',
                                        ),
                                      ),
                                    ),
                                    _ReminderRowData(
                                      firstCell: _buildLinkLabel(
                                        'Reminder For Sent Invoices',
                                        onTap: _openSentManualReminderDialog,
                                      ),
                                      secondCell: _buildDescription(
                                        'You can send this reminder to your customers manually, from a sent (but not overdue) details page.',
                                      ),
                                      thirdCell: _buildActionButton(
                                        icon: LucideIcons.pencil,
                                        onTap: () => _openReminderEditorDialog(
                                          title: 'Reminder For Sent Invoices',
                                          subject:
                                              'Payment of %Balance% is outstanding for %InvoiceNumber%',
                                          body:
                                              'Dear %CustomerName%,\n\nThis is a friendly reminder that payment for invoice %InvoiceNumber% is still pending.\n\n--------------------------------------------------------------\nInvoice# : %InvoiceNumber%\n\nDated : %InvoiceDate%\n--------------------------------------------------------------\nDue Date        :  %DueDate%\nAmount          :  %Balance%\n--------------------------------------------------------------\n\nPlease make the payment at your earliest convenience.\n\nRegards,\n\n%UserName%\n%CompanyName%',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                _buildSectionTitle('Automated Reminders'),
                                const SizedBox(height: 14),
                                _buildAutomatedReminderCard(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Text(
        'Reminders',
        style: AppTheme.pageTitle.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.pageTitle.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111827),
      ),
    );
  }

  Widget _buildLinkLabel(String label, {VoidCallback? onTap}) {
    final child = Text(
      label,
      style: AppTheme.bodyText.copyWith(
        fontSize: 13,
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: child,
      ),
    );
  }

  Widget _buildDescription(String description) {
    return Text(
      description,
      style: AppTheme.bodyText.copyWith(
        fontSize: 13,
        color: const Color(0xFF111827),
        height: 1.2,
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, VoidCallback? onTap}) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 34,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFFC4CAD6)),
        ),
      ),
    );
  }

  Widget _buildReminderOverflowAction({
    required String eventCode,
    required String title,
    required String subject,
    required String body,
    required bool enabled,
    required String milestoneLabel,
  }) {
    return Center(
      child: _ReminderOverflowMenu(
        onEdit: () => _openReminderEditorDialog(
          title: 'Automated Reminders',
          subject: subject,
          body: body.isEmpty ? _buildAutomatedReminderBodyHtml() : body,
          automatedConfig: _AutomatedReminderDialogConfig(
            reminderName: title,
            enabled: enabled,
            dayCount: '0',
            timing: 'after',
            milestoneLabel: milestoneLabel,
            onDelete: () => _deleteReminderRule(eventCode),
          ),
        ),
        onDelete: () => _deleteReminderRule(eventCode),
      ),
    );
  }

  void _openAutomatedReminderEditor({
    required String eventCode,
    required String reminderName,
    required String subject,
    required String body,
    required bool enabled,
    required String milestoneLabel,
  }) {
    _openReminderEditorDialog(
      title: 'Automated Reminders',
      subject: subject,
      body: body.isEmpty ? _buildAutomatedReminderBodyHtml() : body,
      automatedConfig: _AutomatedReminderDialogConfig(
        reminderName: reminderName,
        enabled: enabled,
        dayCount: '0',
        timing: 'after',
        milestoneLabel: milestoneLabel,
        onDelete: () => _deleteReminderRule(eventCode),
      ),
    );
  }

  Widget _buildAutomatedReminderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Column(
        children: [
          _buildAutomatedHeader(),
          _buildGroupRow('Reminders Based on Expected Payment Date'),
          _buildAutomatedReminderRow(
            name: 'Payment Expected',
            info: true,
            infoTooltipMessage:
                "This reminder will be sent based on the expected payment date that you configure from an invoice's details page.",
            schedule: 'Remind me 0 day(s) After expected payment date',
            enabled: _paymentExpectedEnabled,
            onNameTap: () => _openReminderQuickConfig(
              currentValue: _paymentExpectedEnabled,
              applyValue: (next) =>
                  setState(() => _paymentExpectedEnabled = next),
              milestoneLabel: 'expected payment date',
              eventCode: 'expected_payment_date',
            ),
            onChanged: (value) => _handleReminderToggle(
              nextValue: value,
              currentValue: _paymentExpectedEnabled,
              applyValue: (next) =>
                  setState(() => _paymentExpectedEnabled = next),
              milestoneLabel: 'expected payment date',
              eventCode: 'expected_payment_date',
            ),
            action: _buildActionButton(
              icon: LucideIcons.pencil,
              onTap: () => _openReminderEditorDialog(
                title: 'Payment Expected',
                subject: 'Upcoming payment reminder for %InvoiceNumber%',
                body:
                    'Dear %CustomerName%,\n\nThis is a reminder that payment for invoice %InvoiceNumber% is expected soon.\n\n--------------------------------------------------------------\nInvoice# : %InvoiceNumber%\n\nExpected Payment Date : %ExpectedPaymentDate%\nAmount                : %Balance%\n--------------------------------------------------------------\n\nPlease ensure the payment is scheduled on time.\n\nRegards,\n\n%UserName%\n%CompanyName%',
              ),
            ),
          ),
          _buildGroupRow('Reminders Based on Due Date'),
          _buildAutomatedReminderRow(
            name: 'Reminder - 1',
            schedule: 'Remind me 0 day(s) After due date',
            enabled: _reminderOneEnabled,
            onNameTap: () => _openAutomatedReminderEditor(
              eventCode: 'reminder_1',
              reminderName: 'Reminder - 1',
              subject: 'Payment reminder for %InvoiceNumber%',
              body: '',
              enabled: _reminderOneEnabled,
              milestoneLabel: 'due date',
            ),
            onChanged: (value) => _handleReminderToggle(
              nextValue: value,
              currentValue: _reminderOneEnabled,
              applyValue: (next) => setState(() => _reminderOneEnabled = next),
              milestoneLabel: 'due date',
              eventCode: 'reminder_1',
            ),
            action: _buildReminderOverflowAction(
              eventCode: 'reminder_1',
              title: 'Reminder - 1',
              subject: 'Payment reminder for %InvoiceNumber%',
              body: '',
              enabled: _reminderOneEnabled,
              milestoneLabel: 'due date',
            ),
          ),
          _buildAutomatedReminderRow(
            name: 'Reminder - 2',
            schedule: 'Remind me 0 day(s) After due date',
            enabled: _reminderTwoEnabled,
            onNameTap: () => _openAutomatedReminderEditor(
              eventCode: 'reminder_2',
              reminderName: 'Reminder - 2',
              subject: 'Payment reminder for %InvoiceNumber%',
              body: '',
              enabled: _reminderTwoEnabled,
              milestoneLabel: 'due date',
            ),
            onChanged: (value) => _handleReminderToggle(
              nextValue: value,
              currentValue: _reminderTwoEnabled,
              applyValue: (next) => setState(() => _reminderTwoEnabled = next),
              milestoneLabel: 'due date',
              eventCode: 'reminder_2',
            ),
            action: _buildReminderOverflowAction(
              eventCode: 'reminder_2',
              title: 'Reminder - 2',
              subject: 'Payment reminder for %InvoiceNumber%',
              body: '',
              enabled: _reminderTwoEnabled,
              milestoneLabel: 'due date',
            ),
          ),
          _buildAutomatedReminderRow(
            name: 'Reminder - 3',
            schedule: 'Remind me 0 day(s) After due date',
            enabled: _reminderThreeEnabled,
            onNameTap: () => _openAutomatedReminderEditor(
              eventCode: 'reminder_3',
              reminderName: 'Reminder - 3',
              subject: 'Payment reminder for %InvoiceNumber%',
              body: '',
              enabled: _reminderThreeEnabled,
              milestoneLabel: 'due date',
            ),
            onChanged: (value) => _handleReminderToggle(
              nextValue: value,
              currentValue: _reminderThreeEnabled,
              applyValue: (next) =>
                  setState(() => _reminderThreeEnabled = next),
              milestoneLabel: 'due date',
              eventCode: 'reminder_3',
            ),
            action: _buildReminderOverflowAction(
              eventCode: 'reminder_3',
              title: 'Reminder - 3',
              subject: 'Payment reminder for %InvoiceNumber%',
              body: '',
              enabled: _reminderThreeEnabled,
              milestoneLabel: 'due date',
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: InkWell(
                onTap: () => _openReminderEditorDialog(
                  title: 'Automated Reminders',
                  subject:
                      'Payment of %Balance% is outstanding for %InvoiceNumber%',
                  body: _buildAutomatedReminderBodyHtml(),
                  automatedConfig: const _AutomatedReminderDialogConfig(
                    reminderName: '',
                    enabled: true,
                    dayCount: '0',
                    timing: 'after',
                    milestoneLabel: 'due date',
                  ),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.plus,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'New Reminder',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomatedHeader() {
    final headerStyle = AppTheme.captionText.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF7C88A0),
      letterSpacing: 0.5,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('NAME', style: headerStyle)),
          Expanded(flex: 3, child: Text('SCHEDULE', style: headerStyle)),
          SizedBox(
            width: 96,
            child: Center(child: Text('STATUS', style: headerStyle)),
          ),
          SizedBox(
            width: 92,
            child: Center(child: Text('ACTIONS', style: headerStyle)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupRow(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFD),
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Text(
        title,
        style: AppTheme.bodyText.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _buildAutomatedReminderRow({
    required String name,
    required String schedule,
    required bool enabled,
    required ValueChanged<bool> onChanged,
    required Widget action,
    VoidCallback? onNameTap,
    bool info = false,
    String? infoTooltipMessage,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 3, 14, 3),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: onNameTap,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          name,
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (info) ...[
                    const SizedBox(width: 6),
                    ZTooltip(
                      message: infoTooltipMessage ?? '',
                      direction: ZTooltipDirection.top,
                      child: const Icon(
                        LucideIcons.helpCircle,
                        size: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Text(
                schedule,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF111827),
                  height: 1.2,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 96,
            child: Center(
              child: _ReminderToggle(value: enabled, onChanged: onChanged),
            ),
          ),
          SizedBox(width: 92, child: action),
        ],
      ),
    );
  }
}

class _ReminderTableCard extends StatelessWidget {
  const _ReminderTableCard({
    required this.headers,
    required this.columnWidths,
    required this.rows,
  });

  final List<String> headers;
  final Map<int, TableColumnWidth> columnWidths;
  final List<_ReminderRowData> rows;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTheme.captionText.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF7C88A0),
      letterSpacing: 0.5,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Table(
        columnWidths: columnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            children: headers
                .map(
                  (header) => Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Text(header, style: headerStyle),
                  ),
                )
                .toList(growable: false),
          ),
          for (final row in rows)
            TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: row.firstCell,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: row.secondCell,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
                  child: row.thirdCell,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ReminderRowData {
  const _ReminderRowData({
    required this.firstCell,
    required this.secondCell,
    required this.thirdCell,
  });

  final Widget firstCell;
  final Widget secondCell;
  final Widget thirdCell;
}

class _AutomatedReminderDialogConfig {
  const _AutomatedReminderDialogConfig({
    required this.reminderName,
    required this.enabled,
    required this.dayCount,
    required this.timing,
    required this.milestoneLabel,
    this.onDelete,
  });

  final String reminderName;
  final bool enabled;
  final String dayCount;
  final String timing;
  final String milestoneLabel;
  final Future<void> Function()? onDelete;
}

class _ReminderToggle extends StatelessWidget {
  const _ReminderToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 34,
        height: 18,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF22C55E) : const Color(0xFFE1E5EA),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderQuickConfigDialog extends StatefulWidget {
  const _ReminderQuickConfigDialog({
    required this.milestoneLabel,
    required this.initialEnabled,
  });

  final String milestoneLabel;
  final bool initialEnabled;

  @override
  State<_ReminderQuickConfigDialog> createState() =>
      _ReminderQuickConfigDialogState();
}

class _ReminderQuickConfigDialogState
    extends State<_ReminderQuickConfigDialog> {
  final TextEditingController _dayCountController = TextEditingController(
    text: '0',
  );
  final TextEditingController _toController = TextEditingController();

  String _timing = 'after';
  List<String> _ccEmails = <String>[];
  List<String> _bccEmails = <String>[];
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
  }

  @override
  void dispose() {
    _dayCountController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 670),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE8EDF5))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Automated Reminders',
                      style: AppTheme.pageTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF22304A),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(false),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: Color(0xFFFF5B5B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRemindRow(),
                  const SizedBox(height: 14),
                  _buildReadonlyRow(label: 'To', controller: _toController),
                  const SizedBox(height: 12),
                  _buildEmailDropdownRow(
                    label: 'Cc',
                    values: _ccEmails,
                    onChanged: (values) => setState(() => _ccEmails = values),
                  ),
                  const SizedBox(height: 12),
                  _buildEmailDropdownRow(
                    label: 'Bcc',
                    values: _bccEmails,
                    onChanged: (values) => setState(() => _bccEmails = values),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              color: const Color(0xFFF7F8FA),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: InkWell(
                onTap: () => setState(() => _enabled = !_enabled),
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _enabled,
                        onChanged: (value) =>
                            setState(() => _enabled = value ?? false),
                        activeColor: AppTheme.primaryBlue,
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Enable this reminder',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF22304A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Row(
                children: [
                  ZButton.primary(
                    label: 'Save',
                    onPressed: () => Navigator.of(context).pop(_enabled),
                  ),
                  const SizedBox(width: 10),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Text(
              'Remind',
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 82,
                child: CustomTextField(
                  controller: _dayCountController,
                  height: 32,
                  keyboardType: TextInputType.number,
                  contentCase: ContentCase.none,
                  textStyle: AppTheme.bodyText.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'day(s)',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              SizedBox(
                width: 136,
                child: _buildReminderTimingDropdown(
                  value: _timing,
                  onChanged: (value) => setState(() => _timing = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.milestoneLabel,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadonlyRow({
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ),
        Expanded(
          child: CustomTextField(
            controller: controller,
            height: 32,
            enabled: false,
            contentCase: ContentCase.none,
            textStyle: AppTheme.bodyText.copyWith(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailDropdownRow({
    required String label,
    required List<String> values,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ),
        Expanded(
          child: FormDropdown<String>(
            value: null,
            items: const <String>[],
            hint: '',
            onChanged: (_) {},
            height: 32,
            showSearch: true,
            multiSelect: true,
            selectedValues: values,
            onSelectedValuesChanged: onChanged,
            hideSelectedItemsInMultiSelect: true,
            displayStringForValue: (item) => item,
            searchStringForValue: (item) => item,
            textStyle: AppTheme.bodyText.copyWith(
              fontSize: 14,
              color: const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReminderOverflowMenu extends StatelessWidget {
  const _ReminderOverflowMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ReminderOverflowAction>(
      tooltip: '',
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 8,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      offset: const Offset(-6, 6),
      constraints: const BoxConstraints(minWidth: 124),
      onSelected: (action) {
        switch (action) {
          case _ReminderOverflowAction.edit:
            onEdit();
            break;
          case _ReminderOverflowAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<_ReminderOverflowAction>>[
        PopupMenuItem<_ReminderOverflowAction>(
          value: _ReminderOverflowAction.edit,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          child: const _ReminderOverflowMenuItem(
            icon: LucideIcons.pencil,
            label: 'Edit',
          ),
        ),
        PopupMenuItem<_ReminderOverflowAction>(
          value: _ReminderOverflowAction.delete,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          child: const _ReminderOverflowMenuItem(
            icon: LucideIcons.trash2,
            label: 'Delete',
          ),
        ),
      ],
      child: Container(
        width: 34,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Icon(
          LucideIcons.moreVertical,
          size: 14,
          color: Color(0xFFC4CAD6),
        ),
      ),
    );
  }
}

class _ReminderOverflowMenuItem extends StatefulWidget {
  const _ReminderOverflowMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  State<_ReminderOverflowMenuItem> createState() =>
      _ReminderOverflowMenuItemState();
}

class _ReminderOverflowMenuItemState extends State<_ReminderOverflowMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final foreground = _isHovered ? Colors.white : const Color(0xFF4B5563);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(widget.icon, size: 14, color: foreground),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderEditorDialog extends StatefulWidget {
  const _ReminderEditorDialog({
    required this.title,
    required this.subject,
    required this.body,
    this.automatedConfig,
  });

  final String title;
  final String subject;
  final String body;
  final _AutomatedReminderDialogConfig? automatedConfig;

  @override
  State<_ReminderEditorDialog> createState() => _ReminderEditorDialogState();
}

class _ReminderEditorDialogState extends State<_ReminderEditorDialog> {
  final List<String> _emailOptions = const <String>[];
  final List<String> _headingOptions = const <String>[
    'Normal Text',
    'Heading 1',
    'Heading 2',
    'Heading 3',
    'Heading 4',
    'Heading 5',
    'Heading 6',
  ];
  final List<String> _fontSizeOptions = const <String>[
    '10px',
    '13px',
    '16px',
    '18px',
    '24px',
    '32px',
    '48px',
  ];
  final List<_PlaceholderOption> _placeholderOptions =
      const <_PlaceholderOption>[
        _PlaceholderOption(
          category: 'Invoice',
          label: 'Balance',
          token: '%Balance%',
        ),
        _PlaceholderOption(
          category: 'Invoice',
          label: 'DueDate',
          token: '%DueDate%',
        ),
        _PlaceholderOption(
          category: 'Invoice',
          label: 'InvoiceDate',
          token: '%InvoiceDate%',
        ),
        _PlaceholderOption(
          category: 'Invoice',
          label: 'Invoice Issue Date',
          token: '%InvoiceDate%',
        ),
        _PlaceholderOption(
          category: 'Invoice',
          label: 'InvoiceNumber',
          token: '%InvoiceNumber%',
        ),
        _PlaceholderOption(
          category: 'Invoice',
          label: 'Invoice URL',
          token: '%InvoiceURL%',
        ),
        _PlaceholderOption(
          category: 'Invoice',
          label: 'Subject',
          token: '%Subject%',
        ),
        _PlaceholderOption(
          category: 'Invoice',
          label: 'Total',
          token: '%Total%',
        ),
        _PlaceholderOption(
          category: 'Invoice',
          label: 'Profile Name',
          token: '%ProfileName%',
        ),
        _PlaceholderOption(
          category: 'Invoice',
          label: 'Project Name',
          token: '%ProjectName%',
        ),
        _PlaceholderOption(
          category: 'Invoice',
          label: 'Invoice Payment Link',
          token: '%InvoicePaymentLink%',
        ),
        _PlaceholderOption(
          category: 'Invoice',
          label: 'Created By',
          token: '%CreatedBy%',
        ),
        _PlaceholderOption(
          category: 'Invoice',
          label: 'OverdueDays',
          token: '%OverdueDays%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'Company Name',
          token: '%CompanyName%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'Salutation',
          token: '%Salutation%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'Customer Balance',
          token: '%CustomerBalance%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'Website',
          token: '%Website%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'Outstanding Balance',
          token: '%OutstandingBalance%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'Customer Name',
          token: '%CustomerName%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'FirstName',
          token: '%FirstName%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'LastName',
          token: '%LastName%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'Department',
          token: '%Department%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'Designation',
          token: '%Designation%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'Customer Email',
          token: '%CustomerEmail%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'Created By',
          token: '%CreatedBy%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'Credit Limit',
          token: '%CreditLimit%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'Customer Number',
          token: '%CustomerNumber%',
        ),
        _PlaceholderOption(
          category: 'Customer',
          label: 'Customer GSTIN',
          token: '%CustomerGSTIN%',
        ),
        _PlaceholderOption(
          category: 'Organization',
          label: 'Name',
          token: '%CompanyName%',
        ),
        _PlaceholderOption(
          category: 'Organization',
          label: 'User',
          token: '%UserName%',
        ),
        _PlaceholderOption(
          category: 'Organization',
          label: 'User Role',
          token: '%UserRole%',
        ),
        _PlaceholderOption(
          category: 'Organization',
          label: 'Email',
          token: '%CompanyEmail%',
        ),
        _PlaceholderOption(
          category: 'Organization',
          label: 'Phone#',
          token: '%CompanyPhone%',
        ),
        _PlaceholderOption(
          category: 'Organization',
          label: 'Fax#',
          token: '%CompanyFax%',
        ),
        _PlaceholderOption(
          category: 'Organization',
          label: 'Website',
          token: '%CompanyWebsite%',
        ),
        _PlaceholderOption(
          category: 'Organization',
          label: 'Label 1',
          token: '%Label1%',
        ),
        _PlaceholderOption(
          category: 'Organization',
          label: 'Value 1',
          token: '%Value1%',
        ),
        _PlaceholderOption(
          category: 'Organization',
          label: 'Company GSTIN',
          token: '%CompanyGSTIN%',
        ),
        _PlaceholderOption(
          category: 'Organization',
          label: 'Portal URL',
          token: '%PortalURL%',
        ),
      ];

  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;
  late final TextEditingController _nameController;
  late final TextEditingController _dayCountController;
  final ScrollController _dialogScrollController = ScrollController();
  final ScrollController _editorScrollController = ScrollController();
  final FocusNode _bodyFocusNode = FocusNode();

  String? _fromEmail;
  List<String> _ccEmails = <String>[];
  List<String> _bccEmails = <String>[];
  String? _remindEmail;
  String _selectedReminderTiming = 'after';
  bool _isReminderEnabled = false;
  String _selectedHeading = 'Heading 1';
  String _selectedFontSize = '16px';
  FontFamilyOption _selectedFontFamily = kDefaultFontFamilyOptions[1];
  _ParagraphAlignmentIconType _selectedParagraphToolIcon =
      _ParagraphAlignmentIconType.left;
  _TextAlignmentMenuType _selectedTextAlignmentTool =
      _TextAlignmentMenuType.left;
  _ListMenuType _selectedListTool = _ListMenuType.bullets;
  bool _isSourceView = false;
  String? _activeToolbarControlId;
  Color _selectedTextColor = const Color(0xFF1D1D1D);
  Color _selectedHighlightColor = const Color(0xFFFFFF00);
  web.HTMLDivElement? _webEditorElement;
  web.Range? _savedSelectionRange;
  late String _editorHtml;

  @override
  void initState() {
    super.initState();
    _fromEmail = _emailOptions.first;
    _remindEmail = _emailOptions.first;
    _subjectController = TextEditingController(text: widget.subject);
    _bodyController = TextEditingController(text: widget.body);
    _nameController = TextEditingController(
      text: widget.automatedConfig?.reminderName ?? widget.title,
    );
    _dayCountController = TextEditingController(
      text: widget.automatedConfig?.dayCount ?? '0',
    );
    _selectedReminderTiming = widget.automatedConfig?.timing ?? 'after';
    _isReminderEnabled = widget.automatedConfig?.enabled ?? false;
    _editorHtml = _normalizeEditorHtml(widget.body);
  }

  @override
  void dispose() {
    _dialogScrollController.dispose();
    _editorScrollController.dispose();
    _bodyFocusNode.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _nameController.dispose();
    _dayCountController.dispose();
    super.dispose();
  }

  String _normalizeEditorHtml(String value) {
    if (RegExp(r'<[a-z][\s\S]*>', caseSensitive: false).hasMatch(value)) {
      return value;
    }

    return _plainTextToHtml(value);
  }

  String _plainTextToHtml(String value) {
    final lines = value.split('\n');
    if (lines.isEmpty) {
      return '<div><br></div>';
    }

    return lines.map((line) {
      final escapedLine = line
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&#39;');
      return escapedLine.isEmpty
          ? '<div><br></div>'
          : '<div>$escapedLine</div>';
    }).join();
  }

  String _hexColor(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  void _initializeWebEditor(Object element) {
    if (!kIsWeb || element is! web.HTMLDivElement) {
      return;
    }

    _webEditorElement = element
      ..contentEditable = 'true'
      ..tabIndex = 0
      ..spellcheck = false
      ..innerHTML = _editorHtml.toJS;

    final style = element.style;
    style
      ..width = '100%'
      ..height = '100%'
      ..padding = '16px 20px'
      ..boxSizing = 'border-box'
      ..overflowY = 'auto'
      ..outline = 'none'
      ..border = 'none'
      ..backgroundColor = '#FFFFFF'
      ..color = '#202938'
      ..fontSize = '14px'
      ..lineHeight = '1.45'
      ..fontFamily = 'Inter, sans-serif'
      ..whiteSpace = 'pre-wrap';

    element.addEventListener(
      'input',
      ((web.Event _) {
        _syncWebEditorHtml();
        _cacheWebSelection();
      }).toJS,
    );
    element.addEventListener(
      'mouseup',
      ((web.Event _) {
        _cacheWebSelection();
      }).toJS,
    );
    element.addEventListener(
      'keyup',
      ((web.Event _) {
        _cacheWebSelection();
      }).toJS,
    );
    element.addEventListener(
      'focus',
      ((web.Event _) {
        _cacheWebSelection();
      }).toJS,
    );
    web.document.addEventListener(
      'selectionchange',
      ((web.Event _) {
        _cacheWebSelection();
      }).toJS,
    );
  }

  void _syncWebEditorHtml() {
    final currentHtml = _webEditorElement?.innerHTML.toString() ?? _editorHtml;
    _editorHtml = currentHtml;
    if (_bodyController.text != currentHtml) {
      _bodyController.text = currentHtml;
    }
  }

  void _cacheWebSelection() {
    if (!kIsWeb || _webEditorElement == null) {
      return;
    }

    final selection = web.window.getSelection();
    if (selection != null &&
        selection.rangeCount > 0 &&
        _selectionBelongsToEditor(selection)) {
      _savedSelectionRange = selection.getRangeAt(0).cloneRange();
    }
  }

  bool _selectionBelongsToEditor(web.Selection selection) {
    final editor = _webEditorElement;
    if (editor == null) {
      return false;
    }

    final anchorNode = selection.anchorNode;
    if (anchorNode == null) {
      return false;
    }

    return anchorNode == editor || editor.contains(anchorNode);
  }

  void _restoreWebSelection() {
    if (!kIsWeb || _webEditorElement == null) {
      return;
    }

    final selection = web.window.getSelection();
    if (selection == null) {
      return;
    }

    final range = _savedSelectionRange ?? _createRangeAtEditorEnd();
    if (range == null) {
      return;
    }

    selection.removeAllRanges();
    selection.addRange(range);
    _savedSelectionRange = range.cloneRange();
  }

  web.Range? _createRangeAtEditorEnd() {
    final editor = _webEditorElement;
    if (editor == null) {
      return null;
    }

    final range = web.document.createRange();
    range.selectNodeContents(editor);
    range.collapse(false);
    return range;
  }

  void _refocusEditorForTyping() {
    if (kIsWeb && _webEditorElement != null) {
      Future<void>.microtask(() {
        _webEditorElement!.focus();
        _restoreWebSelection();
      });
      return;
    }

    _bodyFocusNode.requestFocus();
  }

  void _runEditorCommand(String command, {String? value}) {
    if (!kIsWeb || _webEditorElement == null) {
      ZerpaiToast.info(context, 'Rich text formatting is available on web.');
      return;
    }

    _webEditorElement!.focus();
    _restoreWebSelection();
    web.document.execCommand(command, false, value ?? '');
    _cacheWebSelection();
    _syncWebEditorHtml();
    setState(() {});
    _refocusEditorForTyping();
  }

  void _toggleSourceView() {
    if (!_isSourceView) {
      _syncWebEditorHtml();
      _bodyController.text = _editorHtml;
      setState(() => _isSourceView = true);
      return;
    }

    _editorHtml = _bodyController.text;
    if (kIsWeb && _webEditorElement != null) {
      _webEditorElement!.innerHTML = _editorHtml.toJS;
    }
    setState(() => _isSourceView = false);
    _refocusEditorForTyping();
  }

  void _applyFontSize(String value) {
    setState(() => _selectedFontSize = value);
    const sizeMap = <String, String>{
      '10px': '1',
      '13px': '2',
      '16px': '3',
      '18px': '4',
      '24px': '5',
      '32px': '6',
      '48px': '7',
    };
    _runEditorCommand('fontSize', value: sizeMap[value] ?? '3');
  }

  void _applyFontFamily(FontFamilyOption value) {
    setState(() => _selectedFontFamily = value);
    _runEditorCommand('fontName', value: value.editorFontFamily);
  }

  void _insertPlaceholder(String value) {
    _runEditorCommand('insertText', value: value);
  }

  void _applyParagraphAlignment(_ParagraphAlignmentIconType value) {
    setState(() => _selectedParagraphToolIcon = value);
    final command = value == _ParagraphAlignmentIconType.left
        ? 'justifyLeft'
        : 'justifyRight';
    _runEditorCommand(command);
  }

  void _applyTextAlignment(_TextAlignmentMenuType value) {
    setState(() => _selectedTextAlignmentTool = value);
    final command = switch (value) {
      _TextAlignmentMenuType.left => 'justifyLeft',
      _TextAlignmentMenuType.center => 'justifyCenter',
      _TextAlignmentMenuType.justify => 'justifyFull',
      _TextAlignmentMenuType.right => 'justifyRight',
    };
    _runEditorCommand(command);
  }

  void _applyListStyle(_ListMenuType value) {
    setState(() => _selectedListTool = value);
    final command = switch (value) {
      _ListMenuType.bullets => 'insertUnorderedList',
      _ListMenuType.numbers => 'insertOrderedList',
    };
    _runEditorCommand(command);
  }

  String _getSelectedEditorText() {
    if (!kIsWeb || _webEditorElement == null) {
      return '';
    }

    final selection = web.window.getSelection();
    if (selection == null || !_selectionBelongsToEditor(selection)) {
      return '';
    }

    return selection.toString().trim();
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    if (trimmed.contains('://') ||
        trimmed.startsWith('mailto:') ||
        trimmed.startsWith('tel:')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  void _insertLink({required String linkText, required String linkUrl}) {
    final normalizedUrl = _normalizeUrl(linkUrl);
    final selectedText = _getSelectedEditorText();
    final effectiveText = linkText.trim().isEmpty
        ? selectedText
        : linkText.trim();

    if (normalizedUrl.isEmpty) {
      return;
    }

    if (selectedText.isNotEmpty &&
        (effectiveText.isEmpty || effectiveText == selectedText)) {
      _runEditorCommand('createLink', value: normalizedUrl);
      return;
    }

    final visibleText = effectiveText.isEmpty ? normalizedUrl : effectiveText;
    final html =
        '<a href="${_escapeHtml(normalizedUrl)}" target="_blank" rel="noopener noreferrer">${_escapeHtml(visibleText)}</a>';
    _runEditorCommand('insertHTML', value: html);
  }

  void _insertImageByUrl(String imageUrl) {
    final normalizedUrl = _normalizeUrl(imageUrl);
    if (normalizedUrl.isEmpty) {
      return;
    }
    _runEditorCommand('insertImage', value: normalizedUrl);
  }

  Future<void> _showImageDialog() async {
    final imageUrlController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        final screenSize = MediaQuery.sizeOf(dialogContext);
        final availableDialogWidth = screenSize.width - 56;
        final dialogWidth = availableDialogWidth < 1080
            ? availableDialogWidth
            : 1080.0;
        final dialogLeft = (screenSize.width - dialogWidth) / 2;
        final popupLeft = (dialogLeft + dialogWidth - 346).clamp(
          20.0,
          screenSize.width - 430,
        );

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned(
                left: popupLeft.toDouble(),
                top: 360,
                child: Container(
                  width: 382,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDDE3EE)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140F172A),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image URL',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: imageUrlController,
                              height: 32,
                              keyboardType: TextInputType.url,
                              contentCase: ContentCase.none,
                              fillColor: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              textStyle: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: const Color(0xFF1D1D1D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 32,
                            child: ZButton.primary(
                              label: 'Fetch URL',
                              onPressed: () {
                                final url = imageUrlController.text.trim();
                                if (url.isEmpty) {
                                  ZerpaiToast.info(
                                    context,
                                    'Enter an image URL',
                                  );
                                  return;
                                }
                                Navigator.of(dialogContext).pop();
                                _insertImageByUrl(url);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLinkDialog() async {
    final selectedText = _getSelectedEditorText();
    final linkTextController = TextEditingController(text: selectedText);
    final linkUrlController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        final screenSize = MediaQuery.sizeOf(dialogContext);
        final availableDialogWidth = screenSize.width - 56;
        final dialogWidth = availableDialogWidth < 1080
            ? availableDialogWidth
            : 1080.0;
        final dialogLeft = (screenSize.width - dialogWidth) / 2;
        final popupLeft = (dialogLeft + dialogWidth - 368).clamp(
          20.0,
          screenSize.width - 306,
        );

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned(
                left: popupLeft.toDouble(),
                top: 356,
                child: Container(
                  width: 286,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDDE3EE)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140F172A),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Link Text',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: linkTextController,
                        height: 32,
                        contentCase: ContentCase.none,
                        fillColor: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF1D1D1D),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Link URL',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: linkUrlController,
                        height: 32,
                        keyboardType: TextInputType.url,
                        contentCase: ContentCase.none,
                        fillColor: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF1D1D1D),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 32,
                            child: ZButton.primary(
                              label: 'Add Link',
                              onPressed: () {
                                final url = linkUrlController.text.trim();
                                if (url.isEmpty) {
                                  ZerpaiToast.info(context, 'Enter a link URL');
                                  return;
                                }
                                Navigator.of(dialogContext).pop();
                                _insertLink(
                                  linkText: linkTextController.text,
                                  linkUrl: url,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 32,
                            child: ZButton.secondary(
                              label: 'Cancel',
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleMoreAction(_MoreActionType value) {
    _setActiveToolbarControl('more');
    switch (value) {
      case _MoreActionType.image:
        _showImageDialog();
      case _MoreActionType.link:
        _showLinkDialog();
      case _MoreActionType.file:
        _toggleSourceView();
    }
  }

  void _applyHeadingFormat(String heading) {
    setState(() => _selectedHeading = heading);
    final block = switch (heading) {
      'Normal Text' => 'P',
      'Heading 1' => 'H1',
      'Heading 2' => 'H2',
      'Heading 3' => 'H3',
      'Heading 4' => 'H4',
      'Heading 5' => 'H5',
      'Heading 6' => 'H6',
      _ => 'P',
    };
    _runEditorCommand('formatBlock', value: block);
  }

  void _applyTextColor(Color color) {
    setState(() => _selectedTextColor = color);
    _runEditorCommand('foreColor', value: _hexColor(color));
  }

  void _applyHighlightColor(Color color) {
    setState(() => _selectedHighlightColor = color);
    _runEditorCommand('hiliteColor', value: _hexColor(color));
  }

  void _setActiveToolbarControl(String id) {
    if (_activeToolbarControlId == id) {
      return;
    }
    setState(() => _activeToolbarControlId = id);
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final dialogHeight = widget.automatedConfig != null
        ? (viewportHeight - 8).clamp(620.0, viewportHeight).toDouble()
        : viewportHeight;

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: SizedBox(
        height: dialogHeight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: Scrollbar(
                    controller: _dialogScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _dialogScrollController,
                      padding: EdgeInsets.fromLTRB(
                        0,
                        widget.automatedConfig != null ? 0 : 16,
                        0,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.automatedConfig?.onDelete != null) ...[
                            _buildAutomatedReminderSettingsSection(),
                            const SizedBox(height: 18),
                          ],
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildDropdownRow(
                                  label: widget.automatedConfig != null
                                      ? 'Remind'
                                      : 'From',
                                  value: widget.automatedConfig != null
                                      ? _remindEmail
                                      : _fromEmail,
                                  onChanged: (value) => setState(() {
                                    if (widget.automatedConfig != null) {
                                      _remindEmail = value;
                                    } else {
                                      _fromEmail = value;
                                    }
                                  }),
                                ),
                                const SizedBox(height: 10),
                                _buildDropdownRow(
                                  label: 'From',
                                  value: _fromEmail,
                                  onChanged: (value) =>
                                      setState(() => _fromEmail = value),
                                  helperText:
                                      'This email address will be used as the from address while sending . Other users can choose their email address if they wish to change it.',
                                ),
                                const SizedBox(height: 10),
                                _buildMultiDropdownRow(
                                  label: 'Cc',
                                  values: _ccEmails,
                                  onChanged: (values) =>
                                      setState(() => _ccEmails = values),
                                ),
                                const SizedBox(height: 10),
                                _buildMultiDropdownRow(
                                  label: 'Bcc',
                                  values: _bccEmails,
                                  onChanged: (values) =>
                                      setState(() => _bccEmails = values),
                                ),
                                const SizedBox(height: 10),
                                _buildSubjectRow(),
                                const SizedBox(height: 14),
                                _buildEditorShell(context),
                                Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    18,
                                    0,
                                    18,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      top: BorderSide(color: Color(0xFFE8EDF5)),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ZButton.primary(
                                        label: 'Save',
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                      const SizedBox(width: 10),
                                      ZButton.secondary(
                                        label: 'Cancel',
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                      if (widget.automatedConfig != null) ...[
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          height: 38,
                                          child: OutlinedButton.icon(
                                            onPressed: () async {
                                              await widget
                                                  .automatedConfig!
                                                  .onDelete!();
                                              if (context.mounted) {
                                                Navigator.of(context).pop();
                                              }
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFF111827,
                                              ),
                                              backgroundColor: Colors.white,
                                              side: const BorderSide(
                                                color: Color(0xFFD9E1EE),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                  ),
                                              minimumSize: const Size(0, 38),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            icon: const Icon(
                                              LucideIcons.trash2,
                                              size: 15,
                                            ),
                                            label: Text(
                                              'Delete this reminder',
                                              style: AppTheme.bodyText.copyWith(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        border: Border(bottom: BorderSide(color: Color(0xFFE8EDF5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: AppTheme.pageTitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF22304A),
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 18, color: Color(0xFFFF5B5B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomatedReminderSettingsSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        border: const Border(bottom: BorderSide(color: Color(0xFFE8EDF5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextFieldRow(label: 'Name', controller: _nameController),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 132,
                child: Padding(
                  padding: const EdgeInsets.only(top: 11),
                  child: Text(
                    'Remind',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 54,
                      child: CustomTextField(
                        controller: _dayCountController,
                        height: 32,
                        keyboardType: TextInputType.number,
                        contentCase: ContentCase.none,
                        textStyle: AppTheme.bodyText.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'day(s)',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 134,
                      child: _buildReminderTimingDropdown(
                        value: _selectedReminderTiming,
                        onChanged: (value) =>
                            setState(() => _selectedReminderTiming = value),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.automatedConfig!.milestoneLabel,
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              InkWell(
                onTap: () =>
                    setState(() => _isReminderEnabled = !_isReminderEnabled),
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _isReminderEnabled,
                        onChanged: (value) =>
                            setState(() => _isReminderEnabled = value ?? false),
                        activeColor: AppTheme.successGreen,
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Enable this reminder',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF22304A),
                      ),
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

  Widget _buildDropdownRow({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? helperText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormDropdown<String>(
                    value: value,
                    items: _emailOptions,
                    hint: '',
                    onChanged: onChanged,
                    height: 32,
                    menuWidth: constraints.maxWidth,
                    showSearch: true,
                    showSearchIcon: true,
                    searchStringForValue: (item) => item,
                    displayStringForValue: (item) => item,
                    menuMaxHeight: 176,
                    itemHeight: 38,
                    textStyle: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  if (helperText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      helperText,
                      style: AppTheme.captionText.copyWith(
                        fontSize: 11.5,
                        color: const Color(0xFF8B95A7),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMultiDropdownRow({
    required String label,
    required List<String> values,
    required ValueChanged<List<String>> onChanged,
    String? helperText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormDropdown<String>(
                    value: null,
                    items: _emailOptions,
                    hint: '',
                    onChanged: (_) {},
                    height: 32,
                    menuWidth: constraints.maxWidth,
                    showSearch: true,
                    showSearchIcon: true,
                    multiSelect: true,
                    selectedValues: values,
                    onSelectedValuesChanged: onChanged,
                    hideSelectedItemsInMultiSelect: true,
                    searchStringForValue: (item) => item,
                    displayStringForValue: (item) => item,
                    menuMaxHeight: 176,
                    itemHeight: 38,
                    textStyle: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  if (helperText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      helperText,
                      style: AppTheme.captionText.copyWith(
                        fontSize: 11.5,
                        color: const Color(0xFF8B95A7),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Text(
              'Subject',
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ),
        Expanded(
          child: CustomTextField(
            controller: _subjectController,
            height: 32,
            textStyle: AppTheme.bodyText.copyWith(
              fontSize: 14,
              color: const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldRow({
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ),
        Expanded(
          child: CustomTextField(
            controller: controller,
            height: 32,
            contentCase: ContentCase.none,
            textStyle: AppTheme.bodyText.copyWith(
              fontSize: 14,
              color: const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorShell(BuildContext context) {
    return SizedBox(
      height: 470,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD9E1EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildToolbar(),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: _isSourceView
                    ? TextField(
                        controller: _bodyController,
                        focusNode: _bodyFocusNode,
                        scrollController: _editorScrollController,
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        onChanged: (value) => _editorHtml = value,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.white,
                          hoverColor: Colors.white,
                          contentPadding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Color(0xFF202938),
                        ),
                      )
                    : kIsWeb
                    ? HtmlElementView.fromTagName(
                        tagName: 'div',
                        onElementCreated: _initializeWebEditor,
                      )
                    : TextField(
                        controller: _bodyController,
                        focusNode: _bodyFocusNode,
                        scrollController: _editorScrollController,
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.white,
                          hoverColor: Colors.white,
                          contentPadding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Color(0xFF202938),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F6FA),
        border: Border(bottom: BorderSide(color: Color(0xFFD9E1EE))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeadingToolbarDropdown(),
                _buildToolbarDivider(),
                _buildToolbarText(
                  'B',
                  controlId: 'bold',
                  boxed: true,
                  onTap: () {
                    _setActiveToolbarControl('bold');
                    _runEditorCommand('bold');
                  },
                ),
                _buildToolbarText(
                  'I',
                  controlId: 'italic',
                  italic: true,
                  onTap: () {
                    _setActiveToolbarControl('italic');
                    _runEditorCommand('italic');
                  },
                ),
                _buildToolbarText(
                  'U',
                  controlId: 'underline',
                  underline: true,
                  onTap: () {
                    _setActiveToolbarControl('underline');
                    _runEditorCommand('underline');
                  },
                ),
                _buildToolbarText(
                  'S',
                  controlId: 'strike',
                  strikeThrough: true,
                  onTap: () {
                    _setActiveToolbarControl('strike');
                    _runEditorCommand('strikeThrough');
                  },
                ),
                _buildToolbarDivider(),
                _buildTextColorDropdown(
                  controlId: 'text-color',
                  color: _selectedTextColor,
                ),
                _buildHighlightColorDropdown(
                  controlId: 'highlight-color',
                  fillColor: _selectedHighlightColor,
                ),
                _buildToolbarDivider(),
                _buildToolbarMenuDropdown(
                  label: _selectedFontSize,
                  controlId: 'font-size',
                  options: _fontSizeOptions,
                  onSelected: _applyFontSize,
                  fontWeight: FontWeight.w600,
                ),
                _buildToolbarDivider(),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: FontFamilyDropdown(
                    options: kDefaultFontFamilyOptions,
                    value: _selectedFontFamily,
                    isActive: _activeToolbarControlId == 'font-family',
                    width: 128,
                    menuWidth: 172,
                    onMenuStateChanged: (isOpen) {
                      if (isOpen) {
                        _setActiveToolbarControl('font-family');
                      }
                    },
                    onChanged: (value) {
                      _setActiveToolbarControl('font-family');
                      _applyFontFamily(value);
                    },
                  ),
                ),
                _buildToolbarDivider(),
                _buildToolbarIconMenuDropdown(
                  selectedIcon: _selectedParagraphToolIcon,
                  controlId: 'paragraph-tools',
                  options: const <_ParagraphAlignmentIconType>[
                    _ParagraphAlignmentIconType.left,
                    _ParagraphAlignmentIconType.right,
                  ],
                  onSelected: _applyParagraphAlignment,
                ),
                _buildTextAlignmentIconMenuDropdown(
                  selectedIcon: _selectedTextAlignmentTool,
                  controlId: 'align-tools',
                  options: const <_TextAlignmentMenuType>[
                    _TextAlignmentMenuType.left,
                    _TextAlignmentMenuType.center,
                    _TextAlignmentMenuType.justify,
                    _TextAlignmentMenuType.right,
                  ],
                  onSelected: _applyTextAlignment,
                ),
                _buildListIconMenuDropdown(
                  selectedIcon: _selectedListTool,
                  controlId: 'list-tools',
                  options: const <_ListMenuType>[
                    _ListMenuType.bullets,
                    _ListMenuType.numbers,
                  ],
                  onSelected: _applyListStyle,
                ),
                _buildMoreActionsDropdown(
                  controlId: 'more',
                  options: const <_MoreActionType>[
                    _MoreActionType.image,
                    _MoreActionType.link,
                    _MoreActionType.file,
                  ],
                  onSelected: _handleMoreAction,
                ),
                const SizedBox(width: 6),
                _buildPlaceholderDropdown(
                  label: 'Insert Placeholder',
                  controlId: 'insert-placeholder',
                  options: _placeholderOptions,
                  onSelected: (option) => _insertPlaceholder(option.token),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeadingToolbarDropdown() {
    final controller = MenuController();
    return MenuAnchor(
      controller: controller,
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.white),
        elevation: const WidgetStatePropertyAll<double>(6),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(vertical: 6),
        ),
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        side: const WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: Color(0xFFDDE3EE)),
        ),
      ),
      menuChildren: _headingOptions
          .map(
            (option) => SizedBox(
              width: 102,
              child: _ReminderToolbarMenuItem(
                label: option,
                onTap: () {
                  _applyHeadingFormat(option);
                  controller.close();
                },
              ),
            ),
          )
          .toList(growable: false),
      builder: (context, menuController, child) {
        return _ReminderToolbarHoverSurface(
          isActive:
              menuController.isOpen || _activeToolbarControlId == 'heading',
          onTap: () {
            _setActiveToolbarControl('heading');
            if (menuController.isOpen) {
              menuController.close();
            } else {
              menuController.open();
            }
          },
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedHeading,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D1D1D),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: Color(0xFF939393),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbarMenuDropdown({
    required String label,
    required String controlId,
    required List<String> options,
    required ValueChanged<String> onSelected,
    FontWeight? fontWeight,
  }) {
    final controller = MenuController();
    final menuItemWidth = controlId == 'insert-placeholder' ? 168.0 : 92.0;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: controlId == 'insert-placeholder' ? 12.5 : 13,
            fontWeight: fontWeight ?? FontWeight.w500,
            color: const Color(0xFF1D1D1D),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(LucideIcons.chevronDown, size: 14, color: Color(0xFF939393)),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(
        right: controlId == 'insert-placeholder' ? 0 : 12,
      ),
      child: MenuAnchor(
        controller: controller,
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.white),
          elevation: const WidgetStatePropertyAll<double>(6),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(vertical: 6),
          ),
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          side: const WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: Color(0xFFDDE3EE)),
          ),
        ),
        menuChildren: options
            .map(
              (option) => SizedBox(
                width: menuItemWidth,
                child: _ReminderToolbarMenuItem(
                  label: option,
                  onTap: () {
                    _setActiveToolbarControl(controlId);
                    onSelected(option);
                    controller.close();
                  },
                ),
              ),
            )
            .toList(growable: false),
        builder: (context, menuController, child) {
          return _ReminderToolbarHoverSurface(
            isActive:
                menuController.isOpen || _activeToolbarControlId == controlId,
            onTap: () {
              _setActiveToolbarControl(controlId);
              if (menuController.isOpen) {
                menuController.close();
              } else {
                menuController.open();
              }
            },
            padding: EdgeInsets.symmetric(
              horizontal: controlId == 'insert-placeholder' ? 8 : 12,
              vertical: 6,
            ),
            child: content,
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderDropdown({
    required String label,
    required String controlId,
    required List<_PlaceholderOption> options,
    required ValueChanged<_PlaceholderOption> onSelected,
  }) {
    final controller = MenuController();

    return MenuAnchor(
      controller: controller,
      alignmentOffset: const Offset(-468, 6),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.white),
        elevation: const WidgetStatePropertyAll<double>(6),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.zero,
        ),
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        side: const WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: Color(0xFFDDE3EE)),
        ),
      ),
      menuChildren: [
        SizedBox(
          width: 610,
          height: 340,
          child: _ReminderPlaceholderPanel(
            options: options,
            onSelected: (option) {
              _setActiveToolbarControl(controlId);
              onSelected(option);
              controller.close();
            },
          ),
        ),
      ],
      builder: (context, menuController, child) {
        return _ReminderToolbarHoverSurface(
          isActive:
              menuController.isOpen || _activeToolbarControlId == controlId,
          onTap: () {
            _setActiveToolbarControl(controlId);
            if (menuController.isOpen) {
              menuController.close();
            } else {
              controller.open();
            }
          },
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D1D1D),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: Color(0xFF939393),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbarDivider() {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFF939393),
    );
  }

  Widget _buildToolbarText(
    String label, {
    String? controlId,
    bool italic = false,
    bool boxed = false,
    bool underline = false,
    bool strikeThrough = false,
    Color color = const Color(0xFF1D1D1D),
    VoidCallback? onTap,
  }) {
    final text = Text(
      label,
      style: AppTheme.bodyText.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color,
        decoration: underline
            ? TextDecoration.underline
            : (strikeThrough
                  ? TextDecoration.lineThrough
                  : TextDecoration.none),
        decorationColor: color,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: _ReminderToolbarHoverSurface(
        isActive: controlId != null && _activeToolbarControlId == controlId,
        onTap: onTap,
        padding: boxed
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 5)
            : const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: text,
      ),
    );
  }

  Widget _buildToolbarIconMenuDropdown({
    required _ParagraphAlignmentIconType selectedIcon,
    required String controlId,
    required List<_ParagraphAlignmentIconType> options,
    required ValueChanged<_ParagraphAlignmentIconType> onSelected,
  }) {
    final controller = MenuController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: MenuAnchor(
        controller: controller,
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.white),
          elevation: const WidgetStatePropertyAll<double>(6),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(vertical: 6),
          ),
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          side: const WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: Color(0xFFDDE3EE)),
          ),
        ),
        menuChildren: options
            .map(
              (icon) => SizedBox(
                width: 44,
                height: 34,
                child: _ReminderToolbarIconMenuItem(
                  iconType: icon,
                  isSelected: selectedIcon == icon,
                  onTap: () {
                    _setActiveToolbarControl(controlId);
                    onSelected(icon);
                    controller.close();
                  },
                ),
              ),
            )
            .toList(growable: false),
        builder: (context, menuController, child) {
          return _ReminderToolbarHoverSurface(
            isActive:
                menuController.isOpen || _activeToolbarControlId == controlId,
            onTap: () {
              _setActiveToolbarControl(controlId);
              if (menuController.isOpen) {
                menuController.close();
              } else {
                menuController.open();
              }
            },
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ParagraphAlignmentGlyph(
                  type: selectedIcon,
                  color: const Color(0xFF1D1D1D),
                ),
                const SizedBox(width: 2),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 11,
                  color: Color(0xFF1D1D1D),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextAlignmentIconMenuDropdown({
    required _TextAlignmentMenuType selectedIcon,
    required String controlId,
    required List<_TextAlignmentMenuType> options,
    required ValueChanged<_TextAlignmentMenuType> onSelected,
  }) {
    final controller = MenuController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: MenuAnchor(
        controller: controller,
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.white),
          elevation: const WidgetStatePropertyAll<double>(6),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(vertical: 6),
          ),
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          side: const WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: Color(0xFFDDE3EE)),
          ),
        ),
        menuChildren: options
            .map(
              (icon) => SizedBox(
                width: 44,
                height: 34,
                child: _ReminderTextAlignmentIconMenuItem(
                  iconType: icon,
                  isSelected: selectedIcon == icon,
                  onTap: () {
                    _setActiveToolbarControl(controlId);
                    onSelected(icon);
                    controller.close();
                  },
                ),
              ),
            )
            .toList(growable: false),
        builder: (context, menuController, child) {
          return _ReminderToolbarHoverSurface(
            isActive:
                menuController.isOpen || _activeToolbarControlId == controlId,
            onTap: () {
              _setActiveToolbarControl(controlId);
              if (menuController.isOpen) {
                menuController.close();
              } else {
                menuController.open();
              }
            },
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TextAlignmentGlyph(
                  type: selectedIcon,
                  color: const Color(0xFF1D1D1D),
                ),
                const SizedBox(width: 2),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 11,
                  color: Color(0xFF1D1D1D),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListIconMenuDropdown({
    required _ListMenuType selectedIcon,
    required String controlId,
    required List<_ListMenuType> options,
    required ValueChanged<_ListMenuType> onSelected,
  }) {
    final controller = MenuController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: MenuAnchor(
        controller: controller,
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.white),
          elevation: const WidgetStatePropertyAll<double>(6),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(vertical: 6),
          ),
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          side: const WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: Color(0xFFDDE3EE)),
          ),
        ),
        menuChildren: options
            .map(
              (icon) => SizedBox(
                width: 44,
                height: 34,
                child: _ReminderListIconMenuItem(
                  iconType: icon,
                  onTap: () {
                    _setActiveToolbarControl(controlId);
                    onSelected(icon);
                    controller.close();
                  },
                ),
              ),
            )
            .toList(growable: false),
        builder: (context, menuController, child) {
          return _ReminderToolbarHoverSurface(
            isActive:
                menuController.isOpen || _activeToolbarControlId == controlId,
            onTap: () {
              _setActiveToolbarControl(controlId);
              if (menuController.isOpen) {
                menuController.close();
              } else {
                menuController.open();
              }
            },
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ListMenuGlyph(
                  type: selectedIcon,
                  color: const Color(0xFF1D1D1D),
                ),
                const SizedBox(width: 2),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 11,
                  color: Color(0xFF1D1D1D),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoreActionsDropdown({
    required String controlId,
    required List<_MoreActionType> options,
    required ValueChanged<_MoreActionType> onSelected,
  }) {
    final controller = MenuController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: MenuAnchor(
        controller: controller,
        alignmentOffset: const Offset(-46, 6),
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.white),
          elevation: const WidgetStatePropertyAll<double>(6),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          ),
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          side: const WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: Color(0xFFDDE3EE)),
          ),
        ),
        menuChildren: [
          SizedBox(
            width: 108,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: options
                  .map(
                    (option) => SizedBox(
                      width: 32,
                      height: 32,
                      child: _ReminderMoreActionMenuItem(
                        actionType: option,
                        onTap: () {
                          onSelected(option);
                        },
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
        builder: (context, menuController, child) {
          return _ReminderToolbarHoverSurface(
            isActive:
                menuController.isOpen || _activeToolbarControlId == controlId,
            onTap: () {
              _setActiveToolbarControl(controlId);
              if (menuController.isOpen) {
                menuController.close();
              } else {
                menuController.open();
              }
            },
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: const Icon(
              LucideIcons.moreHorizontal,
              size: 16,
              color: Color(0xFF1D1D1D),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolbarFilledGlyph(
    String label, {
    String? controlId,
    Color fillColor = const Color(0xFF4B5567),
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: _ReminderToolbarHoverSurface(
        isActive: controlId != null && _activeToolbarControlId == controlId,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextColorDropdown({
    required String controlId,
    required Color color,
  }) {
    final controller = MenuController();

    return MenuAnchor(
      controller: controller,
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.white),
        elevation: const WidgetStatePropertyAll<double>(8),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.zero,
        ),
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        side: const WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: Color(0xFFDDE3EE)),
        ),
      ),
      menuChildren: [
        SizedBox(
          width: 248,
          child: _ReminderInlineColorPickerPanel(
            initialColor: color,
            onApply: (selectedColor) {
              _setActiveToolbarControl(controlId);
              _applyTextColor(selectedColor);
              controller.close();
            },
            onCancel: controller.close,
          ),
        ),
      ],
      builder: (context, menuController, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: _ReminderToolbarHoverSurface(
            isActive:
                menuController.isOpen || _activeToolbarControlId == controlId,
            onTap: () {
              _setActiveToolbarControl(controlId);
              if (menuController.isOpen) {
                menuController.close();
              } else {
                menuController.open();
              }
            },
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: Text(
              'A',
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
                decoration: TextDecoration.underline,
                decorationColor: color,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHighlightColorDropdown({
    required String controlId,
    required Color fillColor,
  }) {
    final controller = MenuController();

    return MenuAnchor(
      controller: controller,
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.white),
        elevation: const WidgetStatePropertyAll<double>(8),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.zero,
        ),
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        side: const WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: Color(0xFFDDE3EE)),
        ),
      ),
      menuChildren: [
        SizedBox(
          width: 248,
          child: _ReminderInlineColorPickerPanel(
            initialColor: fillColor,
            onApply: (color) {
              _setActiveToolbarControl(controlId);
              _applyHighlightColor(color);
              controller.close();
            },
            onCancel: controller.close,
          ),
        ),
      ],
      builder: (context, menuController, child) {
        return _buildToolbarFilledGlyph(
          'A',
          controlId: controlId,
          fillColor: fillColor,
          onTap: () {
            _setActiveToolbarControl(controlId);
            if (menuController.isOpen) {
              menuController.close();
            } else {
              menuController.open();
            }
          },
        );
      },
    );
  }
}

class _ReminderToolbarMenuItem extends StatefulWidget {
  const _ReminderToolbarMenuItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_ReminderToolbarMenuItem> createState() =>
      _ReminderToolbarMenuItemState();
}

class _ReminderToolbarHoverSurface extends StatefulWidget {
  const _ReminderToolbarHoverSurface({
    required this.child,
    this.isActive = false,
    this.onTap,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final bool isActive;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  State<_ReminderToolbarHoverSurface> createState() =>
      _ReminderToolbarHoverSurfaceState();
}

class _ReminderToolbarHoverSurfaceState
    extends State<_ReminderToolbarHoverSurface> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: (_isHovered || widget.isActive)
                ? Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: (_isHovered || widget.isActive)
                  ? const Color(0xFFD4DCEB)
                  : Colors.transparent,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _ReminderInlineColorPickerPanel extends StatefulWidget {
  const _ReminderInlineColorPickerPanel({
    required this.initialColor,
    required this.onApply,
    required this.onCancel,
  });

  final Color initialColor;
  final ValueChanged<Color> onApply;
  final VoidCallback onCancel;

  @override
  State<_ReminderInlineColorPickerPanel> createState() =>
      _ReminderInlineColorPickerPanelState();
}

class _ReminderInlineColorPickerPanelState
    extends State<_ReminderInlineColorPickerPanel> {
  late Color _draftColor;

  @override
  void initState() {
    super.initState();
    _draftColor = widget.initialColor;
  }

  @override
  void didUpdateWidget(covariant _ReminderInlineColorPickerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor) {
      _draftColor = widget.initialColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: -6,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDDE3EE)),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColorPicker(
                  pickerColor: _draftColor,
                  onColorChanged: (color) =>
                      setState(() => _draftColor = color),
                  enableAlpha: true,
                  portraitOnly: true,
                  labelTypes: const <ColorLabelType>[],
                  pickerAreaHeightPercent: 0.72,
                  displayThumbColor: true,
                  hexInputBar: true,
                  pickerAreaBorderRadius: const BorderRadius.all(
                    Radius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ZButton.primary(
                      label: 'Apply',
                      onPressed: () => widget.onApply(_draftColor),
                    ),
                    const SizedBox(width: 10),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderToolbarIconMenuItem extends StatefulWidget {
  const _ReminderToolbarIconMenuItem({
    required this.iconType,
    required this.onTap,
    this.isSelected = false,
  });

  final _ParagraphAlignmentIconType iconType;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  State<_ReminderToolbarIconMenuItem> createState() =>
      _ReminderToolbarIconMenuItemState();
}

class _ReminderTextAlignmentIconMenuItem extends StatefulWidget {
  const _ReminderTextAlignmentIconMenuItem({
    required this.iconType,
    required this.onTap,
    this.isSelected = false,
  });

  final _TextAlignmentMenuType iconType;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  State<_ReminderTextAlignmentIconMenuItem> createState() =>
      _ReminderTextAlignmentIconMenuItemState();
}

class _ReminderListIconMenuItem extends StatefulWidget {
  const _ReminderListIconMenuItem({
    required this.iconType,
    required this.onTap,
  });

  final _ListMenuType iconType;
  final VoidCallback onTap;

  @override
  State<_ReminderListIconMenuItem> createState() =>
      _ReminderListIconMenuItemState();
}

class _ReminderMoreActionMenuItem extends StatefulWidget {
  const _ReminderMoreActionMenuItem({
    required this.actionType,
    required this.onTap,
  });

  final _MoreActionType actionType;
  final VoidCallback onTap;

  @override
  State<_ReminderMoreActionMenuItem> createState() =>
      _ReminderMoreActionMenuItemState();
}

class _ReminderPlaceholderPanel extends StatefulWidget {
  const _ReminderPlaceholderPanel({
    required this.options,
    required this.onSelected,
  });

  final List<_PlaceholderOption> options;
  final ValueChanged<_PlaceholderOption> onSelected;

  @override
  State<_ReminderPlaceholderPanel> createState() =>
      _ReminderPlaceholderPanelState();
}

class _ReminderToolbarMenuItemState extends State<_ReminderToolbarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _isHovered ? Colors.white : const Color(0xFF1D1D1D),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderToolbarIconMenuItemState
    extends State<_ReminderToolbarIconMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: _ParagraphAlignmentGlyph(
              type: widget.iconType,
              color: _isHovered ? Colors.white : const Color(0xFF1D1D1D),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderTextAlignmentIconMenuItemState
    extends State<_ReminderTextAlignmentIconMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: _TextAlignmentGlyph(
              type: widget.iconType,
              color: _isHovered ? Colors.white : const Color(0xFF1D1D1D),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderListIconMenuItemState extends State<_ReminderListIconMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: _ListMenuGlyph(
              type: widget.iconType,
              color: _isHovered ? Colors.white : const Color(0xFF1D1D1D),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderPlaceholderPanelState extends State<_ReminderPlaceholderPanel> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.options
        .where((option) {
          if (query.isEmpty) {
            return true;
          }
          return option.label.toLowerCase().contains(query) ||
              option.token.toLowerCase().contains(query) ||
              option.category.toLowerCase().contains(query);
        })
        .toList(growable: false);

    final grouped = <String, List<_PlaceholderOption>>{};
    for (final option in filtered) {
      grouped
          .putIfAbsent(option.category, () => <_PlaceholderOption>[])
          .add(option);
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFD9E1EE)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.search,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: grouped.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            'No placeholders found',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: grouped.entries
                              .map((entry) {
                                final options = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key.toUpperCase(),
                                        style: AppTheme.bodyText.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF8B95A7),
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: options
                                            .map(
                                              (option) => SizedBox(
                                                width: 182,
                                                child:
                                                    _ReminderPlaceholderOptionItem(
                                                      option: option,
                                                      onTap: () => widget
                                                          .onSelected(option),
                                                    ),
                                              ),
                                            )
                                            .toList(growable: false),
                                      ),
                                    ],
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderPlaceholderOptionItem extends StatefulWidget {
  const _ReminderPlaceholderOptionItem({
    required this.option,
    required this.onTap,
  });

  final _PlaceholderOption option;
  final VoidCallback onTap;

  @override
  State<_ReminderPlaceholderOptionItem> createState() =>
      _ReminderPlaceholderOptionItemState();
}

class _ReminderPlaceholderOptionItemState
    extends State<_ReminderPlaceholderOptionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _isHovered ? Colors.white : const Color(0xFF4B5563),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ParagraphAlignmentIconType { left, right }

enum _TextAlignmentMenuType { left, center, justify, right }

enum _ListMenuType { bullets, numbers }

enum _ReminderOverflowAction { edit, delete }

enum _MoreActionType { image, link, file }

class _PlaceholderOption {
  const _PlaceholderOption({
    required this.category,
    required this.label,
    required this.token,
  });

  final String category;
  final String label;
  final String token;
}

class _ParagraphAlignmentGlyph extends StatelessWidget {
  const _ParagraphAlignmentGlyph({required this.type, required this.color});

  final _ParagraphAlignmentIconType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final arrowIcon = type == _ParagraphAlignmentIconType.left
        ? LucideIcons.arrowLeft
        : LucideIcons.arrowRight;
    final isLeft = type == _ParagraphAlignmentIconType.left;

    return SizedBox(
      width: 18,
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 3.2,
            left: isLeft ? 7 : 1.5,
            right: isLeft ? 1.5 : 7,
            child: Container(
              height: 1.3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            top: 7.2,
            left: isLeft ? 6 : 3,
            right: isLeft ? 3 : 6,
            child: Container(
              height: 1.3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            top: 11.2,
            left: isLeft ? 7 : 1.5,
            right: isLeft ? 1.5 : 7,
            child: Container(
              height: 1.3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Align(
            alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: Icon(arrowIcon, size: 8.5, color: color),
          ),
        ],
      ),
    );
  }
}

class _TextAlignmentGlyph extends StatelessWidget {
  const _TextAlignmentGlyph({required this.type, required this.color});

  final _TextAlignmentMenuType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLine(12),
          const SizedBox(height: 2),
          _buildLine(
            switch (type) {
              _TextAlignmentMenuType.left => 8,
              _TextAlignmentMenuType.center => 8,
              _TextAlignmentMenuType.justify => 12,
              _TextAlignmentMenuType.right => 8,
            },
            align: switch (type) {
              _TextAlignmentMenuType.left => Alignment.centerLeft,
              _TextAlignmentMenuType.center => Alignment.center,
              _TextAlignmentMenuType.justify => Alignment.center,
              _TextAlignmentMenuType.right => Alignment.centerRight,
            },
          ),
          const SizedBox(height: 2),
          _buildLine(
            switch (type) {
              _TextAlignmentMenuType.left => 10,
              _TextAlignmentMenuType.center => 10,
              _TextAlignmentMenuType.justify => 12,
              _TextAlignmentMenuType.right => 10,
            },
            align: switch (type) {
              _TextAlignmentMenuType.left => Alignment.centerLeft,
              _TextAlignmentMenuType.center => Alignment.center,
              _TextAlignmentMenuType.justify => Alignment.center,
              _TextAlignmentMenuType.right => Alignment.centerRight,
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLine(double width, {Alignment align = Alignment.centerLeft}) {
    return Align(
      alignment: align,
      child: Container(
        width: width,
        height: 1.4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _ListMenuGlyph extends StatelessWidget {
  const _ListMenuGlyph({required this.type, required this.color});

  final _ListMenuType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      switch (type) {
        _ListMenuType.bullets => LucideIcons.list,
        _ListMenuType.numbers => LucideIcons.listOrdered,
      },
      size: 16,
      color: color,
    );
  }
}

class _ReminderMoreActionMenuItemState
    extends State<_ReminderMoreActionMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(
              switch (widget.actionType) {
                _MoreActionType.image => LucideIcons.image,
                _MoreActionType.link => LucideIcons.link,
                _MoreActionType.file => LucideIcons.fileText,
              },
              size: 16,
              color: _isHovered ? Colors.white : const Color(0xFF1D1D1D),
            ),
          ),
        ),
      ),
    );
  }
}
