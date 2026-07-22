import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';

enum SalesOrdersSettingsTab {
  preferences,
  approvals,
  fields,
  salesOrderCycle,
  validationRules,
  recordLocking,
  statuses,
  buttons,
  relatedLists,
}

class _SalesOrderStatusRecord {
  const _SalesOrderStatusRecord({
    required this.customStatusFor,
    required this.statusName,
    required this.description,
    required this.labelColor,
  });

  final String customStatusFor;
  final String statusName;
  final String description;
  final Color labelColor;

  _SalesOrderStatusRecord copyWith({
    String? customStatusFor,
    String? statusName,
    String? description,
    Color? labelColor,
  }) {
    return _SalesOrderStatusRecord(
      customStatusFor: customStatusFor ?? this.customStatusFor,
      statusName: statusName ?? this.statusName,
      description: description ?? this.description,
      labelColor: labelColor ?? this.labelColor,
    );
  }
}

class _StatusDialogResult {
  const _StatusDialogResult({this.record, this.deleted = false});

  final _SalesOrderStatusRecord? record;
  final bool deleted;
}

final ValueNotifier<List<_SalesOrderStatusRecord>> _salesOrderStatusesNotifier =
    ValueNotifier<List<_SalesOrderStatusRecord>>(
      const <_SalesOrderStatusRecord>[
        _SalesOrderStatusRecord(
          customStatusFor: 'Confirmed',
          statusName: 'ef',
          description: 'wfwef',
          labelColor: Color(0xFFFF2B6D),
        ),
      ],
    );

class SalesOrdersSettingsPage extends ConsumerStatefulWidget {
  const SalesOrdersSettingsPage({
    super.key,
    this.initialTab = SalesOrdersSettingsTab.preferences,
  });

  final SalesOrdersSettingsTab initialTab;

  @override
  ConsumerState<SalesOrdersSettingsPage> createState() =>
      _SalesOrdersSettingsPageState();
}

class _SalesOrdersSettingsPageState
    extends ConsumerState<SalesOrdersSettingsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _termsController = TextEditingController();
  final TextEditingController _customerNotesController =
      TextEditingController();
  final ScrollController _contentScrollController = ScrollController();

  bool _updateAddress = true;
  bool _updateCustomerNotes = true;
  bool _updateTerms = true;
  _SalesOrderCloseOption _closeOption = _SalesOrderCloseOption.invoiceCreated;
  bool _restrictClosedEdits = true;
  bool _restrictFulfillmentUntilPayment = false;
  late SalesOrdersSettingsTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _termsController.dispose();
    _customerNotesController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  String _withOrgPrefix(String route) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    return '/$orgSystemId$route';
  }

  void _focusSearch() {
    if (!_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
    }
  }

  List<SettingsSearchItem> _buildSearchItems() {
    return <SettingsSearchItem>[
      SettingsSearchItem(
        group: 'Sales Orders',
        label: 'Preferences',
        subtitle: 'Sales Orders',
        keywords: const <String>['sales orders', 'preferences'],
        onSelected: () => _openTab(SalesOrdersSettingsTab.preferences),
      ),
      SettingsSearchItem(
        group: 'Sales Orders',
        label: 'Sales Order Cycle',
        subtitle: 'Sales Orders',
        keywords: const <String>['cycle', 'rules', 'manual orders'],
        onSelected: () => _openTab(SalesOrdersSettingsTab.salesOrderCycle),
      ),
      SettingsSearchItem(
        group: 'Sales Orders',
        label: 'Statuses',
        subtitle: 'Sales Orders',
        keywords: const <String>['status', 'custom status', 'label color'],
        onSelected: () => _openTab(SalesOrdersSettingsTab.statuses),
      ),
      SettingsSearchItem(
        group: 'Sales Orders',
        label: 'Terms & Conditions',
        subtitle: 'Sales Orders',
        keywords: const <String>['terms', 'conditions'],
        onSelected: () => _openTab(SalesOrdersSettingsTab.preferences),
      ),
    ];
  }

  void _openTab(SalesOrdersSettingsTab tab) {
    final route = switch (tab) {
      SalesOrdersSettingsTab.salesOrderCycle =>
        AppRoutes.settingsSalesOrdersCycle,
      SalesOrdersSettingsTab.statuses => AppRoutes.settingsSalesOrdersStatuses,
      _ => AppRoutes.settingsSalesOrders,
    };
    if (_activeTab != tab) {
      setState(() => _activeTab = tab);
    }
    context.go(_withOrgPrefix(route));
  }

  @override
  Widget build(BuildContext context) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final orgName = orgSettings?.name.trim().isNotEmpty == true
        ? orgSettings!.name.trim()
        : 'ZERPAI ERP';

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.slash): _focusSearch,
      },
      child: ColoredBox(
        color: const Color(0xFFF7F8FC),
        child: Column(
          children: [
            _SalesOrdersSettingsHeader(
              orgName: orgName,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              searchItems: _buildSearchItems(),
              onBack: () => context.go(_withOrgPrefix(AppRoutes.settings)),
              onClose: () => context.go(_withOrgPrefix(AppRoutes.home)),
            ),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsNavigationSidebar(
                    currentPath: GoRouterState.of(context).uri.path,
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SalesOrdersPageTitle(
                            trailing:
                                _activeTab == SalesOrdersSettingsTab.statuses
                                ? const _StatusesHeaderButton()
                                : null,
                          ),
                          _SalesOrdersTabsRow(
                            activeTab: _activeTab,
                            onTabSelected: _openTab,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppTheme.borderLight,
                          ),
                          Expanded(
                            child: Scrollbar(
                              controller: _contentScrollController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _contentScrollController,
                                padding: EdgeInsets.fromLTRB(
                                  _activeTab == SalesOrdersSettingsTab.statuses
                                      ? 0
                                      : 22,
                                  _activeTab == SalesOrdersSettingsTab.statuses
                                      ? 0
                                      : 18,
                                  _activeTab == SalesOrdersSettingsTab.statuses
                                      ? 0
                                      : 22,
                                  34,
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child:
                                      _activeTab ==
                                          SalesOrdersSettingsTab.statuses
                                      ? const _SalesOrdersStatusesContent()
                                      : ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 1120,
                                          ),
                                          child:
                                              _activeTab ==
                                                  SalesOrdersSettingsTab
                                                      .salesOrderCycle
                                              ? const _SalesOrdersCycleContent()
                                              : _SalesOrdersPreferencesContent(
                                                  updateAddress: _updateAddress,
                                                  updateCustomerNotes:
                                                      _updateCustomerNotes,
                                                  updateTerms: _updateTerms,
                                                  closeOption: _closeOption,
                                                  restrictClosedEdits:
                                                      _restrictClosedEdits,
                                                  restrictFulfillmentUntilPayment:
                                                      _restrictFulfillmentUntilPayment,
                                                  termsController:
                                                      _termsController,
                                                  customerNotesController:
                                                      _customerNotesController,
                                                  onUpdateAddressChanged:
                                                      (value) {
                                                        setState(
                                                          () => _updateAddress =
                                                              value,
                                                        );
                                                      },
                                                  onUpdateCustomerNotesChanged:
                                                      (value) {
                                                        setState(
                                                          () =>
                                                              _updateCustomerNotes =
                                                                  value,
                                                        );
                                                      },
                                                  onUpdateTermsChanged:
                                                      (value) {
                                                        setState(
                                                          () => _updateTerms =
                                                              value,
                                                        );
                                                      },
                                                  onCloseOptionChanged:
                                                      (value) {
                                                        if (value != null) {
                                                          setState(
                                                            () => _closeOption =
                                                                value,
                                                          );
                                                        }
                                                      },
                                                  onRestrictClosedEditsChanged:
                                                      (value) {
                                                        setState(
                                                          () =>
                                                              _restrictClosedEdits =
                                                                  value,
                                                        );
                                                      },
                                                  onRestrictFulfillmentChanged:
                                                      (value) {
                                                        setState(
                                                          () =>
                                                              _restrictFulfillmentUntilPayment =
                                                                  value,
                                                        );
                                                      },
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
    );
  }
}

enum _SalesOrderCloseOption {
  invoiceCreated,
  shipmentFulfilled,
  shipmentFulfilledAndInvoiceCreated,
}

class _SalesOrdersPreferencesContent extends StatelessWidget {
  const _SalesOrdersPreferencesContent({
    required this.updateAddress,
    required this.updateCustomerNotes,
    required this.updateTerms,
    required this.closeOption,
    required this.restrictClosedEdits,
    required this.restrictFulfillmentUntilPayment,
    required this.termsController,
    required this.customerNotesController,
    required this.onUpdateAddressChanged,
    required this.onUpdateCustomerNotesChanged,
    required this.onUpdateTermsChanged,
    required this.onCloseOptionChanged,
    required this.onRestrictClosedEditsChanged,
    required this.onRestrictFulfillmentChanged,
  });

  final bool updateAddress;
  final bool updateCustomerNotes;
  final bool updateTerms;
  final _SalesOrderCloseOption closeOption;
  final bool restrictClosedEdits;
  final bool restrictFulfillmentUntilPayment;
  final TextEditingController termsController;
  final TextEditingController customerNotesController;
  final ValueChanged<bool> onUpdateAddressChanged;
  final ValueChanged<bool> onUpdateCustomerNotesChanged;
  final ValueChanged<bool> onUpdateTermsChanged;
  final ValueChanged<_SalesOrderCloseOption?> onCloseOptionChanged;
  final ValueChanged<bool> onRestrictClosedEditsChanged;
  final ValueChanged<bool> onRestrictFulfillmentChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which of the following fields of Sales Orders do you want to update in the respective Invoices?',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        _SettingsCheckboxRow(
          value: updateAddress,
          label: 'Address',
          onChanged: onUpdateAddressChanged,
        ),
        _SettingsCheckboxRow(
          value: updateCustomerNotes,
          label: 'Customer Notes',
          onChanged: onUpdateCustomerNotesChanged,
        ),
        _SettingsCheckboxRow(
          value: updateTerms,
          label: 'Terms & Conditions',
          onChanged: onUpdateTermsChanged,
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
        const SizedBox(height: 22),
        Text(
          'When do you want your Sales Orders to be closed?',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _SettingsRadioRow(
          value: _SalesOrderCloseOption.invoiceCreated,
          groupValue: closeOption,
          label: 'When invoice is created',
          onChanged: onCloseOptionChanged,
        ),
        _SettingsRadioRow(
          value: _SalesOrderCloseOption.shipmentFulfilled,
          groupValue: closeOption,
          label: 'When shipment is fulfilled',
          onChanged: onCloseOptionChanged,
        ),
        _SettingsRadioRow(
          value: _SalesOrderCloseOption.shipmentFulfilledAndInvoiceCreated,
          groupValue: closeOption,
          label: 'When shipment is fulfilled and invoice is created',
          onChanged: onCloseOptionChanged,
        ),
        const SizedBox(height: 14),
        _SettingsCheckboxRow(
          value: restrictClosedEdits,
          label: 'Restrict closed sales orders from being edited',
          onChanged: onRestrictClosedEditsChanged,
        ),
        _SettingsCheckboxRow(
          value: restrictFulfillmentUntilPayment,
          label: 'Restrict sales order fulfilment until payment is received',
          trailing: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: ZTooltip(
              message: 'Block fulfilment until payment is marked received.',
            ),
          ),
          onChanged: onRestrictFulfillmentChanged,
        ),
        const SizedBox(height: 22),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
        const SizedBox(height: 24),
        Text(
          'Terms & Conditions',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 820,
          child: TextField(
            controller: termsController,
            maxLines: 7,
            style: AppTheme.bodyText.copyWith(fontSize: 14),
            decoration: _textAreaDecoration(
              'Enter the terms and conditions of your business to be displayed in your transaction',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Customer Notes',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 820,
          child: TextField(
            controller: customerNotesController,
            maxLines: 7,
            style: AppTheme.bodyText.copyWith(fontSize: 14),
            decoration: _textAreaDecoration(
              'Enter any notes to be displayed in your transaction',
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
        const SizedBox(height: 28),
        SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: () {
              ZerpaiToast.success(context, 'Sales Orders preferences saved');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Save',
              style: AppTheme.bodyText.copyWith(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _textAreaDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTheme.bodyText.copyWith(
      color: const Color(0xFF8E95B2),
      fontSize: 14,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD8DDF0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.primaryBlue),
    ),
  );
}

class _SalesOrdersCycleContent extends StatelessWidget {
  const _SalesOrdersCycleContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configure sales order cycle preference for manual sales orders',
          style: AppTheme.bodyText.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF20263A),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7EAF3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FD),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 26,
                      child: Text('ACTIONS', style: _cycleHeaderStyle()),
                    ),
                    Expanded(
                      flex: 26,
                      child: Text('APPLIES TO', style: _cycleHeaderStyle()),
                    ),
                    Expanded(
                      flex: 26,
                      child: Text(
                        'PAYMENT PREFERENCE',
                        style: _cycleHeaderStyle(),
                      ),
                    ),
                    Expanded(
                      flex: 26,
                      child: Text(
                        'SHIPMENT PREFERENCE',
                        style: _cycleHeaderStyle(),
                      ),
                    ),
                    const SizedBox(width: 60),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 26,
                      child: Text(
                        'Create  Package',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 15,
                          color: const Color(0xFF20263A),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 26,
                      child: Text(
                        'Manual Orders',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 15,
                          color: const Color(0xFF20263A),
                        ),
                      ),
                    ),
                    const Expanded(flex: 26, child: SizedBox()),
                    const Expanded(flex: 26, child: SizedBox()),
                    SizedBox(
                      width: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => _showRulePreferencesDialog(context),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(
                                LucideIcons.pencil,
                                size: 17,
                                color: Color(0xFF4A556F),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            LucideIcons.trash2,
                            size: 17,
                            color: Color(0xFF4A556F),
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
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7EAF3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create sales order cycle rules for marketplace orders',
                      style: AppTheme.pageTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF20263A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Create sales order cycle rules for different marketplaces to create transactions like invoices, packages, and shipments automatically after an order is received from a marketplace.',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        height: 1.5,
                        color: const Color(0xFF5B667F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: () => _showCreateRuleDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '+ New Rule',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info, size: 16, color: Color(0xFFFF8A1E)),
                  const SizedBox(width: 6),
                  Text(
                    'NOTE',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF8A1E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...const [
                'You have to execute the sales order cycle from the sales order details page for orders that have been imported manually.',
                'The custom fields in transactions will be left empty, even if the custom fields are mandatory.',
                'If a sales order contains items with either serial number tracking or batch tracking, you cannot create packages or invoices while automating the sales order cycle.',
                'You have to disable any functions that might interfere with the sales order cycle. Contact support for more details.',
              ].map(_CycleNoteBullet.new),
            ],
          ),
        ),
      ],
    );
  }
}

class _SalesOrdersStatusesContent extends StatefulWidget {
  const _SalesOrdersStatusesContent();

  @override
  State<_SalesOrdersStatusesContent> createState() =>
      _SalesOrdersStatusesContentState();
}

class _SalesOrdersStatusesContentState
    extends State<_SalesOrdersStatusesContent> {
  int? _hoveredRowIndex;
  final MenuController _rowMenuController = MenuController();
  bool _isRowMenuOpen = false;

  Future<void> _handleEditStatus(
    BuildContext context,
    int index,
    _SalesOrderStatusRecord record,
  ) async {
    final result = await _showEditStatusDialog(context, record);
    if (result == null) return;

    final next = List<_SalesOrderStatusRecord>.from(
      _salesOrderStatusesNotifier.value,
    );
    if (result.deleted) {
      next.removeAt(index);
      _salesOrderStatusesNotifier.value = next;
      if (context.mounted) {
        ZerpaiToast.success(context, 'Status deleted');
      }
      return;
    }

    if (result.record != null) {
      next[index] = result.record!;
      _salesOrderStatusesNotifier.value = next;
      if (context.mounted) {
        ZerpaiToast.success(context, 'Status updated');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<_SalesOrderStatusRecord>>(
      valueListenable: _salesOrderStatusesNotifier,
      builder: (context, statuses, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE3E8F3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F8FC),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE3E8F3)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 23,
                          child: Text(
                            'CUSTOM STATUS FOR',
                            style: _statusTableHeaderStyle(),
                          ),
                        ),
                        Expanded(
                          flex: 23,
                          child: Text(
                            'STATUS NAME',
                            style: _statusTableHeaderStyle(),
                          ),
                        ),
                        Expanded(
                          flex: 31,
                          child: Text(
                            'DESCRIPTION',
                            style: _statusTableHeaderStyle(),
                          ),
                        ),
                        Expanded(
                          flex: 23,
                          child: Text(
                            'LABEL COLOR',
                            style: _statusTableHeaderStyle(),
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                  for (var index = 0; index < statuses.length; index++)
                    MouseRegion(
                      onEnter: (_) => setState(() => _hoveredRowIndex = index),
                      onExit: (_) => setState(() => _hoveredRowIndex = null),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
                        decoration: BoxDecoration(
                          color: _hoveredRowIndex == index
                              ? const Color(0xFFF8FBFF)
                              : Colors.white,
                          border: const Border(
                            bottom: BorderSide(color: Color(0xFFE9EDF6)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 23,
                              child: Text(
                                statuses[index].customStatusFor,
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  color: const Color(0xFF20263A),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 23,
                              child: Text(
                                statuses[index].statusName,
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  color: const Color(0xFF20263A),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 31,
                              child: Text(
                                statuses[index].description,
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  color: const Color(0xFF20263A),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 23,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 19,
                                  height: 19,
                                  decoration: BoxDecoration(
                                    color: statuses[index].labelColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 44,
                              child: Align(
                                alignment: const Alignment(-0.2, 0),
                                child:
                                    (_hoveredRowIndex == index ||
                                        _isRowMenuOpen)
                                    ? MenuAnchor(
                                        controller: _rowMenuController,
                                        alignmentOffset: const Offset(-10, 8),
                                        style: MenuStyle(
                                          backgroundColor:
                                              WidgetStateProperty.all(
                                                Colors.white,
                                              ),
                                          surfaceTintColor:
                                              WidgetStateProperty.all(
                                                Colors.white,
                                              ),
                                          elevation: WidgetStateProperty.all(0),
                                          padding: WidgetStateProperty.all(
                                            EdgeInsets.zero,
                                          ),
                                          side: WidgetStateProperty.all(
                                            const BorderSide(
                                              color: Colors.transparent,
                                            ),
                                          ),
                                          shape: WidgetStateProperty.all(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        menuChildren: [
                                          _StatusRowActionMenu(
                                            onEdit: () {
                                              _rowMenuController.close();
                                              if (mounted) {
                                                setState(
                                                  () => _isRowMenuOpen = false,
                                                );
                                              }
                                              _handleEditStatus(
                                                context,
                                                index,
                                                statuses[index],
                                              );
                                            },
                                            onDelete: () {
                                              _rowMenuController.close();
                                              if (mounted) {
                                                setState(
                                                  () => _isRowMenuOpen = false,
                                                );
                                              }
                                              final next =
                                                  List<
                                                    _SalesOrderStatusRecord
                                                  >.from(
                                                    _salesOrderStatusesNotifier
                                                        .value,
                                                  );
                                              next.removeAt(index);
                                              _salesOrderStatusesNotifier
                                                      .value =
                                                  next;
                                              ZerpaiToast.success(
                                                context,
                                                'Status deleted',
                                              );
                                            },
                                          ),
                                        ],
                                        builder: (context, controller, child) {
                                          return InkWell(
                                            onTap: () {
                                              if (controller.isOpen) {
                                                controller.close();
                                                setState(
                                                  () => _isRowMenuOpen = false,
                                                );
                                              } else {
                                                setState(
                                                  () => _isRowMenuOpen = true,
                                                );
                                                controller.open();
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                            child: Container(
                                              width: 22,
                                              height: 22,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF2DBE72),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color(0x22000000),
                                                    blurRadius: 6,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                LucideIcons.chevronDown,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : const SizedBox(width: 22, height: 22),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    height: statuses.isEmpty
                        ? 606
                        : (606 - ((statuses.length - 1) * 40))
                              .clamp(0, 606)
                              .toDouble(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

TextStyle _statusTableHeaderStyle() {
  return AppTheme.bodyText.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF667493),
  );
}

TextStyle _cycleHeaderStyle() {
  return AppTheme.bodyText.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF7A8091),
  );
}

Future<void> _showRulePreferencesDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Configure Rule Preferences',
    barrierColor: Colors.black.withValues(alpha: 0.58),
    pageBuilder: (_, __, ___) => const _RulePreferencesDialog(),
    transitionDuration: const Duration(milliseconds: 120),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

Future<void> _showCreateRuleDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Create Rule',
    barrierColor: Colors.black.withValues(alpha: 0.58),
    pageBuilder: (_, __, ___) => const _CreateRuleDialog(),
    transitionDuration: const Duration(milliseconds: 120),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

Future<_StatusDialogResult?> _showNewStatusDialog(BuildContext context) {
  return showGeneralDialog<_StatusDialogResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'New Status',
    barrierColor: Colors.black.withValues(alpha: 0.58),
    pageBuilder: (_, __, ___) => const _NewStatusDialog(),
    transitionDuration: const Duration(milliseconds: 120),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

Future<_StatusDialogResult?> _showEditStatusDialog(
  BuildContext context,
  _SalesOrderStatusRecord record,
) {
  return showGeneralDialog<_StatusDialogResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Edit Status',
    barrierColor: Colors.black.withValues(alpha: 0.58),
    pageBuilder: (_, __, ___) => _NewStatusDialog(
      title: 'Edit Status',
      initialRecord: record,
      showDeleteAction: true,
    ),
    transitionDuration: const Duration(milliseconds: 120),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

class _RulePreferencesDialog extends StatefulWidget {
  const _RulePreferencesDialog();

  @override
  State<_RulePreferencesDialog> createState() => _RulePreferencesDialogState();
}

class _RulePreferencesDialogState extends State<_RulePreferencesDialog> {
  bool _createInvoice = true;
  bool _markAsSent = true;
  bool _recordPayment = true;
  bool _createPackage = true;
  bool _createShipment = true;
  String? _paymentMode = 'Bank Transfer';
  String? _depositTo = 'Bandhan Bank';
  String? _carrier = 'SPEED AND SAFE';
  String? _shipmentStatus = 'Shipped';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 687.58),
          child: Container(
            width: 500,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Configure Rule Preferences',
                          style: AppTheme.pageTitle.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFFFF4C4C),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE7EAF3),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                    child: _RuleTransactionConfigurator(
                      createInvoice: _createInvoice,
                      markAsSent: _markAsSent,
                      recordPayment: _recordPayment,
                      createPackage: _createPackage,
                      createShipment: _createShipment,
                      paymentMode: _paymentMode,
                      depositTo: _depositTo,
                      carrier: _carrier,
                      shipmentStatus: _shipmentStatus,
                      onCreateInvoiceChanged: (value) {
                        setState(() => _createInvoice = value);
                      },
                      onMarkAsSentChanged: (value) {
                        setState(() {
                          _markAsSent = value;
                          if (!value) _recordPayment = false;
                        });
                      },
                      onRecordPaymentChanged: (value) {
                        setState(() => _recordPayment = value);
                      },
                      onCreatePackageChanged: (value) {
                        setState(() {
                          _createPackage = value;
                          if (!value) _createShipment = false;
                        });
                      },
                      onCreateShipmentChanged: (value) {
                        setState(() => _createShipment = value);
                      },
                      onPaymentModeChanged: (value) {
                        setState(() => _paymentMode = value);
                      },
                      onDepositToChanged: (value) {
                        setState(() => _depositTo = value);
                      },
                      onCarrierChanged: (value) {
                        setState(() => _carrier = value);
                      },
                      onShipmentStatusChanged: (value) {
                        setState(() => _shipmentStatus = value);
                      },
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE7EAF3),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Save',
                            style: AppTheme.bodyText.copyWith(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFD5DAE6)),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTheme.bodyText.copyWith(
                              color: Colors.black,
                              fontSize: 13,
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
      ),
    );
  }
}

class _CreateRuleDialog extends StatefulWidget {
  const _CreateRuleDialog();

  @override
  State<_CreateRuleDialog> createState() => _CreateRuleDialogState();
}

class _CreateRuleDialogState extends State<_CreateRuleDialog> {
  String? _appliesTo = 'Select or type to add';
  bool _createInvoice = false;
  bool _markAsSent = false;
  bool _recordPayment = false;
  bool _createPackage = false;
  bool _createShipment = false;
  String? _paymentMode = 'Bank Transfer';
  String? _depositTo = 'Bandhan Bank';
  String? _carrier = 'SPEED AND SAFE';
  String? _shipmentStatus = 'Shipped';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 687.58),
          child: Container(
            width: 500,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Create Rule',
                          style: AppTheme.pageTitle.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFFFF4C4C),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE7EAF3),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select the transactions that has to be created after a sales order.',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 12.5,
                            color: const Color(0xFF363F55),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Applies To*',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13.5,
                            color: const Color(0xFFFF3B30),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 38,
                          child: FormDropdown<String>(
                            value: _appliesTo,
                            items: const <String>[
                              'Select or type to add',
                              'Amazon',
                              'Flipkart',
                              'Manual Orders',
                            ],
                            onChanged: (value) {
                              setState(() => _appliesTo = value);
                            },
                            hint: 'Select or type to add',
                            showSearch: false,
                            showSearchIcon: false,
                            fillColor: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            textStyle: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF7D849A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE7EAF3),
                        ),
                        const SizedBox(height: 14),
                        _RuleTransactionConfigurator(
                          createInvoice: _createInvoice,
                          markAsSent: _markAsSent,
                          recordPayment: _recordPayment,
                          createPackage: _createPackage,
                          createShipment: _createShipment,
                          paymentMode: _paymentMode,
                          depositTo: _depositTo,
                          carrier: _carrier,
                          shipmentStatus: _shipmentStatus,
                          onCreateInvoiceChanged: (value) {
                            setState(() => _createInvoice = value);
                          },
                          onMarkAsSentChanged: (value) {
                            setState(() {
                              _markAsSent = value;
                              if (!value) _recordPayment = false;
                            });
                          },
                          onRecordPaymentChanged: (value) {
                            setState(() => _recordPayment = value);
                          },
                          onCreatePackageChanged: (value) {
                            setState(() {
                              _createPackage = value;
                              if (!value) _createShipment = false;
                            });
                          },
                          onCreateShipmentChanged: (value) {
                            setState(() => _createShipment = value);
                          },
                          onPaymentModeChanged: (value) {
                            setState(() => _paymentMode = value);
                          },
                          onDepositToChanged: (value) {
                            setState(() => _depositTo = value);
                          },
                          onCarrierChanged: (value) {
                            setState(() => _carrier = value);
                          },
                          onShipmentStatusChanged: (value) {
                            setState(() => _shipmentStatus = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE7EAF3),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Create Rule',
                            style: AppTheme.bodyText.copyWith(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFD5DAE6)),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTheme.bodyText.copyWith(
                              color: Colors.black,
                              fontSize: 13,
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
      ),
    );
  }
}

class _NewStatusDialog extends StatefulWidget {
  const _NewStatusDialog({
    this.title = 'New Status',
    this.initialRecord,
    this.showDeleteAction = false,
  });

  final String title;
  final _SalesOrderStatusRecord? initialRecord;
  final bool showDeleteAction;

  @override
  State<_NewStatusDialog> createState() => _NewStatusDialogState();
}

class _NewStatusDialogState extends State<_NewStatusDialog> {
  String? _statusName;
  final TextEditingController _applyToStatusController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Color? _selectedLabelColor;
  final LayerLink _labelColorLayerLink = LayerLink();
  OverlayEntry? _labelColorOverlayEntry;

  static const List<Color> _labelColorOptions = <Color>[
    Color(0xFFFF3B3B),
    Color(0xFF3F73E9),
    Color(0xFFFF6B00),
    Color(0xFF16A34A),
    Color(0xFF8B46E7),
    Color(0xFF5D4B68),
    Color(0xFFFF2B6A),
    Color(0xFF4CCAE8),
    Color(0xFF1E88F0),
    Color(0xFF52B70A),
    Color(0xFFFF5A2F),
    Color(0xFFFFB648),
    Color(0xFF7B58D6),
    Color(0xFF8793B9),
    Color(0xFFFFA300),
    Color(0xFF4D63B6),
    Color(0xFFB05AEF),
    Color(0xFF5B7BD8),
    Color(0xFFA33FD2),
    Color(0xFF12BFA5),
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRecord;
    if (initial != null) {
      _statusName = initial.customStatusFor;
      _applyToStatusController.text = initial.statusName;
      _descriptionController.text = initial.description;
      _selectedLabelColor = initial.labelColor;
    }
  }

  bool get _showsLabelColorRow => _statusName != null;

  bool get _showVoidWarning => _statusName == 'Void';

  bool get _showColorSwatch =>
      (_statusName == 'Confirmed' && _selectedLabelColor != null) ||
      _statusName == 'Draft' ||
      _statusName == 'Void' ||
      _statusName == 'On Hold';

  String get _labelColorActionText =>
      _statusName == 'Confirmed' && _selectedLabelColor == null
      ? 'Choose Label Color'
      : 'Change Color';

  Color get _labelColorSwatch {
    if (_selectedLabelColor != null) {
      return _selectedLabelColor!;
    }
    switch (_statusName) {
      case 'Void':
        return const Color(0xFF5F6668);
      case 'Draft':
        return const Color(0xFF98A1BC);
      case 'On Hold':
        return const Color(0xFF5A84EA);
      default:
        return const Color(0xFF98A1BC);
    }
  }

  void _saveStatus() {
    final statusName = _statusName?.trim();
    final applyToStatus = _applyToStatusController.text.trim();
    final description = _descriptionController.text.trim();
    if (statusName == null || statusName.isEmpty || applyToStatus.isEmpty) {
      ZerpaiToast.error(context, 'Fill required fields before saving');
      return;
    }

    Navigator.of(context).pop(
      _StatusDialogResult(
        record: _SalesOrderStatusRecord(
          customStatusFor: statusName,
          statusName: applyToStatus,
          description: description,
          labelColor: _labelColorSwatch,
        ),
      ),
    );
  }

  void _deleteStatus() {
    Navigator.of(context).pop(const _StatusDialogResult(deleted: true));
  }

  @override
  void dispose() {
    _removeLabelColorPalette(updateState: false);
    _applyToStatusController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleLabelColorPalette() {
    if (_statusName == null) return;
    if (_labelColorOverlayEntry != null) {
      _removeLabelColorPalette();
      return;
    }

    final overlay = Overlay.of(context);
    _labelColorOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _removeLabelColorPalette(),
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _labelColorLayerLink,
            showWhenUnlinked: false,
            offset: const Offset(4, 28),
            child: _AdvancedLabelColorPalette(
              colors: _labelColorOptions,
              initialColor: _labelColorSwatch,
              onClose: _removeLabelColorPalette,
              onColorTap: (color) {
                setState(() => _selectedLabelColor = color);
                _removeLabelColorPalette();
              },
            ),
          ),
        ],
      ),
    );
    overlay.insert(_labelColorOverlayEntry!);
    setState(() {});
  }

  void _removeLabelColorPalette({bool updateState = true}) {
    _labelColorOverlayEntry?.remove();
    _labelColorOverlayEntry = null;
    if (updateState && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 790,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTheme.pageTitle.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFFFF4C4C),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE7EAF3)),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                child: Column(
                  children: [
                    _NewStatusFormRow(
                      label: const _FormRedLabel(text: 'Status Name*'),
                      child: SizedBox(
                        width: 290,
                        height: 38,
                        child: FormDropdown<String>(
                          value: _statusName,
                          items: const <String>[
                            'Draft',
                            'Confirmed',
                            'Void',
                            'On Hold',
                          ],
                          onChanged: (value) {
                            setState(() {
                              _statusName = value;
                              _removeLabelColorPalette(updateState: false);
                              if (value == null) {
                                _selectedLabelColor = null;
                              }
                            });
                          },
                          itemEstimatedHeight: 40,
                          hint: '',
                          placeholder: 'Search',
                          allowClear: true,
                          showSearch: true,
                          showSearchIcon: true,
                          fillColor: Colors.white,
                          menuWidth: 290,
                          menuMaxHeight: 186,
                          maxVisibleItems: 4,
                          activeBorderColor: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(8),
                          itemBuilder: (item, isSelected, isHovered) {
                            final backgroundColor = isHovered
                                ? const Color(0xFF3B82F6)
                                : isSelected
                                ? const Color(0xFFF1F4FA)
                                : Colors.white;
                            final textColor = isHovered
                                ? Colors.white
                                : const Color(0xFF56617D);
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(color: backgroundColor),
                              child: Text(
                                item,
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  color: textColor,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            );
                          },
                          textStyle: AppTheme.bodyText.copyWith(
                            fontSize: 14,
                            color: const Color(0xFF20263A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _NewStatusFormRow(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Apply to Status',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 14,
                              color: const Color(0xFFFF3B30),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const ZTooltip(
                            message:
                                'When a record is in this default status, a Mark as [Status Name] button will appear on the record'
                                's list page and you can click it to apply this custom status to that record.',
                          ),
                          Text(
                            ' *',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 14,
                              color: const Color(0xFFFF3B30),
                            ),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 290,
                        height: 38,
                        child: TextField(
                          controller: _applyToStatusController,
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 14,
                            color: const Color(0xFF20263A),
                          ),
                          decoration: _newStatusInputDecoration(''),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_showsLabelColorRow) ...[
                      _NewStatusFormRow(
                        label: const _FormRedLabel(text: 'Label Color*'),
                        child: SizedBox(
                          width: 290,
                          height: 38,
                          child: CompositedTransformTarget(
                            link: _labelColorLayerLink,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: _statusName != null
                                    ? _toggleLabelColorPalette
                                    : null,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_showColorSwatch) ...[
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: _labelColorSwatch,
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                    ],
                                    Text(
                                      _labelColorActionText,
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 14,
                                        color: const Color(0xFF2E79FF),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_showVoidWarning) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(
                                  LucideIcons.alertTriangle,
                                  size: 20,
                                  color: Color(0xFFFF9B3D),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Consider selecting a lighter accent color to '
                                  'improve the readability of low-contrast text.',
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 14,
                                    height: 1.35,
                                    color: const Color(0xFF404652),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                    ],
                    _NewStatusFormRow(
                      label: Text(
                        'Description',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF20263A),
                        ),
                      ),
                      child: SizedBox(
                        width: 290,
                        child: TextField(
                          controller: _descriptionController,
                          maxLines: 2,
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 14,
                            color: const Color(0xFF20263A),
                          ),
                          decoration: _newStatusInputDecoration(
                            'Max. 250 characters',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE7EAF3)),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
                child: Row(
                  children: [
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: _saveStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: AppTheme.bodyText.copyWith(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD5DAE6)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTheme.bodyText.copyWith(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (widget.showDeleteAction) ...[
                      const SizedBox(width: 18),
                      InkWell(
                        onTap: _deleteStatus,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.trash2,
                              size: 16,
                              color: Color(0xFF245EF0),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Delete',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 14,
                                color: const Color(0xFF245EF0),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

InputDecoration _newStatusInputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTheme.bodyText.copyWith(
      fontSize: 14,
      color: const Color(0xFF8A91A8),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD7DCEF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD7DCEF)),
    ),
  );
}

class _NewStatusFormRow extends StatelessWidget {
  const _NewStatusFormRow({required this.label, required this.child});

  final Widget label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 170,
          child: Padding(padding: const EdgeInsets.only(top: 10), child: label),
        ),
        child,
      ],
    );
  }
}

class _AdvancedLabelColorPalette extends StatefulWidget {
  const _AdvancedLabelColorPalette({
    required this.colors,
    required this.initialColor,
    required this.onClose,
    required this.onColorTap,
  });

  final List<Color> colors;
  final Color initialColor;
  final VoidCallback onClose;
  final ValueChanged<Color> onColorTap;

  @override
  State<_AdvancedLabelColorPalette> createState() =>
      _AdvancedLabelColorPaletteState();
}

class _AdvancedLabelColorPaletteState
    extends State<_AdvancedLabelColorPalette> {
  late final TextEditingController _hexController;
  late HSVColor _currentHsv;
  bool _showCustomColorDropdown = false;
  bool _showExpandedPicker = false;

  @override
  void initState() {
    super.initState();
    _currentHsv = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(
      text: _colorToHex(widget.initialColor),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color _parsedHexColor() {
    final raw = _hexController.text.trim().replaceAll('#', '');
    if (raw.length != 6) return _currentHsv.toColor();
    final value = int.tryParse('FF$raw', radix: 16);
    if (value == null) return _currentHsv.toColor();
    return Color(value);
  }

  String _colorToHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  void _syncHexFromCurrentColor() {
    final nextValue = _colorToHex(_currentHsv.toColor());
    if (_hexController.text.toLowerCase() == nextValue.toLowerCase()) return;
    _hexController.value = TextEditingValue(
      text: nextValue,
      selection: TextSelection.collapsed(offset: nextValue.length),
    );
  }

  void _setColor(Color color) {
    setState(() {
      _currentHsv = HSVColor.fromColor(color).withAlpha(1);
      _syncHexFromCurrentColor();
    });
  }

  void _setHue(double hue) {
    setState(() {
      _currentHsv = _currentHsv.withHue(hue.clamp(0, 360).toDouble());
      _syncHexFromCurrentColor();
    });
  }

  void _setSaturationValue(double saturation, double value) {
    setState(() {
      _currentHsv = _currentHsv
          .withSaturation(saturation.clamp(0, 1).toDouble())
          .withValue(value.clamp(0, 1).toDouble());
      _syncHexFromCurrentColor();
    });
  }

  void _handleHexChanged(String value) {
    final raw = value.trim().replaceAll('#', '');
    if (raw.length != 6) return;
    final parsed = int.tryParse('FF$raw', radix: 16);
    if (parsed == null) return;
    setState(() {
      _currentHsv = HSVColor.fromColor(Color(parsed)).withAlpha(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 340,
        height: 560,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -6,
                    left: 48,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFDADFEA)),
                          left: BorderSide(color: Color(0xFFDADFEA)),
                        ),
                      ),
                      transform: Matrix4.rotationZ(-0.785398),
                    ),
                  ),
                  Container(
                    width: 198,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDADFEA)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: InkWell(
                            onTap: widget.onClose,
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 11,
                          runSpacing: 16,
                          children: widget.colors
                              .map(
                                (color) => InkWell(
                                  onTap: () {
                                    _setColor(color);
                                    widget.onColorTap(color);
                                  },
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showCustomColorDropdown =
                                  !_showCustomColorDropdown;
                              if (!_showCustomColorDropdown) {
                                _showExpandedPicker = false;
                              }
                            });
                          },
                          child: Text(
                            'Choose Custom Color >',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13.5,
                              color: const Color(0xFF245EF0),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_showCustomColorDropdown)
              Positioned(
                left: 6,
                top: 180,
                child: _CustomColorEntryDropdown(
                  controller: _hexController,
                  previewColor: _currentHsv.toColor(),
                  onChanged: _handleHexChanged,
                  onArrowTap: () {
                    setState(() {
                      _showExpandedPicker = !_showExpandedPicker;
                    });
                  },
                  onOk: () => widget.onColorTap(_parsedHexColor()),
                  onCancel: () {
                    setState(() {
                      _showCustomColorDropdown = false;
                      _showExpandedPicker = false;
                    });
                  },
                ),
              ),
            if (_showCustomColorDropdown && _showExpandedPicker)
              Positioned(
                left: 66,
                top: 228,
                child: _ExpandedCustomColorPicker(
                  controller: _hexController,
                  previewColor: _currentHsv.toColor(),
                  hsvColor: _currentHsv,
                  onHexChanged: _handleHexChanged,
                  onHueChanged: _setHue,
                  onSaturationValueChanged: _setSaturationValue,
                  onApply: () => widget.onColorTap(_currentHsv.toColor()),
                  onCancel: () {
                    setState(() {
                      _showExpandedPicker = false;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomColorEntryDropdown extends StatelessWidget {
  const _CustomColorEntryDropdown({
    required this.controller,
    required this.previewColor,
    required this.onChanged,
    required this.onArrowTap,
    required this.onOk,
    required this.onCancel,
  });

  final TextEditingController controller;
  final Color previewColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onArrowTap;
  final VoidCallback onOk;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -5,
            left: 108,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFDADFEA)),
                  left: BorderSide(color: Color(0xFFDADFEA)),
                ),
              ),
              transform: Matrix4.rotationZ(-0.785398),
            ),
          ),
          Container(
            width: 180,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDADFEA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFD7DCEF)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          onChanged: onChanged,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                          ),
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF56617D),
                          ),
                        ),
                      ),
                      Container(width: 28, color: previewColor),
                      InkWell(
                        onTap: onArrowTap,
                        child: Container(
                          width: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Color(0xFFD7DCEF)),
                            ),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 14,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: onOk,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          'OK',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 12.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 28,
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4B5563),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD5DAE6)),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 12.5,
                            color: const Color(0xFF4B5563),
                          ),
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
    );
  }
}

class _ExpandedCustomColorPicker extends StatelessWidget {
  const _ExpandedCustomColorPicker({
    required this.controller,
    required this.previewColor,
    required this.hsvColor,
    required this.onHexChanged,
    required this.onHueChanged,
    required this.onSaturationValueChanged,
    required this.onApply,
    required this.onCancel,
  });

  final TextEditingController controller;
  final Color previewColor;
  final HSVColor hsvColor;
  final ValueChanged<String> onHexChanged;
  final ValueChanged<double> onHueChanged;
  final void Function(double saturation, double value) onSaturationValueChanged;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  void _handleSquareInteraction(Offset localPosition, Size size) {
    final saturation = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - (localPosition.dy / size.height)).clamp(0.0, 1.0);
    onSaturationValueChanged(saturation, value);
  }

  void _handleHueInteraction(Offset localPosition, Size size) {
    final hue = ((localPosition.dx / size.width).clamp(0.0, 1.0)) * 360;
    onHueChanged(hue);
  }

  @override
  Widget build(BuildContext context) {
    final hueOnlyColor = HSVColor.fromAHSV(1, hsvColor.hue, 1, 1).toColor();
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -6,
            left: 100,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFDADFEA)),
                  left: BorderSide(color: Color(0xFFDADFEA)),
                ),
              ),
              transform: Matrix4.rotationZ(-0.785398),
            ),
          ),
          Container(
            width: 254,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDADFEA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    const squareHeight = 148.0;
                    const squareWidth = 234.0;
                    final markerLeft = (hsvColor.saturation * squareWidth)
                        .clamp(0.0, squareWidth)
                        .toDouble();
                    final markerTop = ((1 - hsvColor.value) * squareHeight)
                        .clamp(0.0, squareHeight)
                        .toDouble();
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (details) => _handleSquareInteraction(
                        details.localPosition,
                        const Size(squareWidth, squareHeight),
                      ),
                      onPanUpdate: (details) => _handleSquareInteraction(
                        details.localPosition,
                        const Size(squareWidth, squareHeight),
                      ),
                      onTapDown: (details) => _handleSquareInteraction(
                        details.localPosition,
                        const Size(squareWidth, squareHeight),
                      ),
                      child: SizedBox(
                        width: squareWidth,
                        height: squareHeight,
                        child: Stack(
                          children: [
                            Container(
                              width: squareWidth,
                              height: squareHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: hueOnlyColor,
                              ),
                            ),
                            Container(
                              width: squareWidth,
                              height: squareHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: <Color>[
                                    Colors.white,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: squareWidth,
                              height: squareHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Colors.transparent,
                                    Colors.black,
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: markerLeft - 7,
                              top: markerTop - 7,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.24,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = constraints.maxWidth;
                    final markerLeft = ((hsvColor.hue / 360) * barWidth)
                        .clamp(0.0, barWidth)
                        .toDouble();
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (details) => _handleHueInteraction(
                        details.localPosition,
                        Size(barWidth, 8),
                      ),
                      onPanUpdate: (details) => _handleHueInteraction(
                        details.localPosition,
                        Size(barWidth, 8),
                      ),
                      onTapDown: (details) => _handleHueInteraction(
                        details.localPosition,
                        Size(barWidth, 8),
                      ),
                      child: SizedBox(
                        height: 14,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: 3,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: <Color>[
                                      Colors.red,
                                      Colors.yellow,
                                      Colors.green,
                                      Colors.cyan,
                                      Colors.blue,
                                      Color(0xFFFF00FF),
                                      Colors.red,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: markerLeft - 7,
                              top: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: HSVColor.fromAHSV(
                                    1,
                                    hsvColor.hue,
                                    1,
                                    1,
                                  ).toColor(),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF6FA1FF)),
                        ),
                        child: TextField(
                          controller: controller,
                          onChanged: onHexChanged,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF56617D),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 58,
                      height: 34,
                      decoration: BoxDecoration(
                        color: previewColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE7EAF3)),
                      bottom: BorderSide(color: Color(0xFFE7EAF3)),
                    ),
                  ),
                  child: Text(
                    'Swatches >',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13.5,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: onApply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Apply',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 34,
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4B5563),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD5DAE6)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13.5,
                            color: const Color(0xFF4B5563),
                          ),
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
    );
  }
}

class _FormRedLabel extends StatelessWidget {
  const _FormRedLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.bodyText.copyWith(
        fontSize: 14,
        color: const Color(0xFFFF3B30),
      ),
    );
  }
}

class _StatusRowActionMenu extends StatefulWidget {
  const _StatusRowActionMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_StatusRowActionMenu> createState() => _StatusRowActionMenuState();
}

class _StatusRowActionMenuState extends State<_StatusRowActionMenu> {
  String? _hovered;
  String? _pressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3E8F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusRowActionItem(
            label: 'Edit',
            isHovered: _hovered == 'edit',
            isPressed: _pressed == 'edit',
            onHoverChanged: (value) {
              setState(() => _hovered = value ? 'edit' : null);
            },
            onTapDown: () {
              setState(() => _pressed = 'edit');
            },
            onTapUp: () {
              setState(() => _pressed = null);
            },
            onTap: widget.onEdit,
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE9EDF6)),
          _StatusRowActionItem(
            label: 'Delete',
            isHovered: _hovered == 'delete',
            isPressed: _pressed == 'delete',
            onHoverChanged: (value) {
              setState(() => _hovered = value ? 'delete' : null);
            },
            onTapDown: () {
              setState(() => _pressed = 'delete');
            },
            onTapUp: () {
              setState(() => _pressed = null);
            },
            onTap: widget.onDelete,
          ),
        ],
      ),
    );
  }
}

class _StatusRowActionItem extends StatelessWidget {
  const _StatusRowActionItem({
    required this.label,
    required this.isHovered,
    required this.isPressed,
    required this.onHoverChanged,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTap,
  });

  final String label;
  final bool isHovered;
  final bool isPressed;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isHovered
        ? const Color(0xFF3B82F6)
        : isPressed
        ? const Color(0xFFF1F3F7)
        : Colors.white;
    final textColor = isHovered ? Colors.white : const Color(0xFF586480);

    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) => onTapUp(),
        onTapCancel: onTapUp,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: backgroundColor,
          child: Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 14,
              color: textColor,
              fontWeight: isHovered ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleTransactionConfigurator extends StatelessWidget {
  const _RuleTransactionConfigurator({
    required this.createInvoice,
    required this.markAsSent,
    required this.recordPayment,
    required this.createPackage,
    required this.createShipment,
    required this.paymentMode,
    required this.depositTo,
    required this.carrier,
    required this.shipmentStatus,
    required this.onCreateInvoiceChanged,
    required this.onMarkAsSentChanged,
    required this.onRecordPaymentChanged,
    required this.onCreatePackageChanged,
    required this.onCreateShipmentChanged,
    required this.onPaymentModeChanged,
    required this.onDepositToChanged,
    required this.onCarrierChanged,
    required this.onShipmentStatusChanged,
  });

  final bool createInvoice;
  final bool markAsSent;
  final bool recordPayment;
  final bool createPackage;
  final bool createShipment;
  final String? paymentMode;
  final String? depositTo;
  final String? carrier;
  final String? shipmentStatus;
  final ValueChanged<bool> onCreateInvoiceChanged;
  final ValueChanged<bool> onMarkAsSentChanged;
  final ValueChanged<bool> onRecordPaymentChanged;
  final ValueChanged<bool> onCreatePackageChanged;
  final ValueChanged<bool> onCreateShipmentChanged;
  final ValueChanged<String?> onPaymentModeChanged;
  final ValueChanged<String?> onDepositToChanged;
  final ValueChanged<String?> onCarrierChanged;
  final ValueChanged<String?> onShipmentStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RuleCheckboxRow(
          value: createInvoice,
          label: 'Create an invoice',
          onChanged: onCreateInvoiceChanged,
        ),
        if (createInvoice)
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 1, bottom: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 1, color: const Color(0xFFE6ECFA)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _RuleCheckboxRow(
                        value: markAsSent,
                        label: 'Mark it as sent',
                        onChanged: onMarkAsSentChanged,
                      ),
                      if (markAsSent)
                        _RuleCheckboxRow(
                          value: recordPayment,
                          label: 'Record a payment',
                          onChanged: onRecordPaymentChanged,
                        ),
                      if (markAsSent && recordPayment)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 6, bottom: 6),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _PaymentPreferenceRow(
                                label: 'Payment Mode*',
                                value: paymentMode,
                                items: const <String>[
                                  'Bank Transfer',
                                  'Cash',
                                  'UPI',
                                ],
                                onChanged: onPaymentModeChanged,
                              ),
                              const SizedBox(height: 12),
                              _PaymentPreferenceRow(
                                label: 'Deposit To*',
                                value: depositTo,
                                items: const <String>[
                                  'Bandhan Bank',
                                  'Cash',
                                  'Bank Account',
                                  'Undeposited Funds',
                                ],
                                onChanged: onDepositToChanged,
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
        _RuleCheckboxRow(
          value: createPackage,
          label: 'Create a package',
          onChanged: onCreatePackageChanged,
        ),
        if (createPackage)
          _RuleCheckboxRow(
            value: createShipment,
            label: 'Create a shipment',
            onChanged: onCreateShipmentChanged,
          ),
        if (createPackage && createShipment)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8, bottom: 10),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHIPMENT PREFERENCE',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFF20263A),
                  ),
                ),
                const SizedBox(height: 14),
                _PaymentPreferenceRow(
                  label: 'Carrier*',
                  value: carrier,
                  items: const <String>[
                    'SPEED AND SAFE',
                    'Delhivery',
                    'Blue Dart',
                  ],
                  onChanged: onCarrierChanged,
                ),
                const SizedBox(height: 12),
                _NeutralPreferenceRow(
                  label: 'Status',
                  value: shipmentStatus,
                  items: const <String>['Shipped', 'Packed', 'Delivered'],
                  onChanged: onShipmentStatusChanged,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RuleCheckboxRow extends StatelessWidget {
  const _RuleCheckboxRow({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
                activeColor: const Color(0xFF4E8DF5),
                checkColor: Colors.white,
                side: const BorderSide(color: Color(0xFFB9C3D7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13.5,
                color: const Color(0xFF30384D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentPreferenceRow extends StatelessWidget {
  const _PaymentPreferenceRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 118,
          child: Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13.5,
              color: const Color(0xFFFF3B30),
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 34,
            child: FormDropdown<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              hint: items.first,
              showSearch: false,
              showSearchIcon: false,
              fillColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              textStyle: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: const Color(0xFF7D849A),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NeutralPreferenceRow extends StatelessWidget {
  const _NeutralPreferenceRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 118,
          child: Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13.5,
              color: const Color(0xFF20263A),
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 34,
            child: FormDropdown<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              hint: items.first,
              showSearch: false,
              showSearchIcon: false,
              fillColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              textStyle: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: const Color(0xFF20263A),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CycleNoteBullet extends StatelessWidget {
  const _CycleNoteBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF20263A),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                height: 1.5,
                color: const Color(0xFF20263A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesOrdersSettingsHeader extends StatelessWidget {
  const _SalesOrdersSettingsHeader({
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
      height: 72,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book_outlined,
              color: Color(0xFFFF5D5D),
              size: 24,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            color: AppTheme.borderLight,
          ),
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD8DDF0)),
              ),
              child: const Icon(
                LucideIcons.chevronLeft,
                size: 18,
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
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                orgName,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 320,
            child: SettingsSearchField(
              controller: searchController,
              focusNode: searchFocusNode,
              items: searchItems,
            ),
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.close, size: 14, color: Color(0xFFFF5C73)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesOrdersPageTitle extends StatelessWidget {
  const _SalesOrdersPageTitle({this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Sales Orders',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _StatusesHeaderButton extends StatelessWidget {
  const _StatusesHeaderButton();

  Future<void> _handleNewStatus(BuildContext context) async {
    final result = await _showNewStatusDialog(context);
    if (result == null || result.record == null) return;
    _salesOrderStatusesNotifier.value = <_SalesOrderStatusRecord>[
      ..._salesOrderStatusesNotifier.value,
      result.record!,
    ];
    if (context.mounted) {
      ZerpaiToast.success(context, 'Status saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: () => _handleNewStatus(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          '+ New Status',
          style: AppTheme.bodyText.copyWith(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SalesOrdersTabsRow extends StatelessWidget {
  const _SalesOrdersTabsRow({
    required this.activeTab,
    required this.onTabSelected,
  });

  final SalesOrdersSettingsTab activeTab;
  final ValueChanged<SalesOrdersSettingsTab> onTabSelected;

  static const List<(String, SalesOrdersSettingsTab)> _tabs =
      <(String, SalesOrdersSettingsTab)>[
        ('Preferences', SalesOrdersSettingsTab.preferences),
        ('Fields', SalesOrdersSettingsTab.fields),
        ('Sales Order Cycle', SalesOrdersSettingsTab.salesOrderCycle),
        ('Validation Rules', SalesOrdersSettingsTab.validationRules),
        ('Record Locking', SalesOrdersSettingsTab.recordLocking),
        ('Statuses', SalesOrdersSettingsTab.statuses),
        ('Buttons', SalesOrdersSettingsTab.buttons),
        ('Related Lists', SalesOrdersSettingsTab.relatedLists),
      ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final (label, tab) = _tabs[index];
          final isActive = tab == activeTab;
          return InkWell(
            onTap: () => onTabSelected(tab),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: isActive
                      ? const Border(
                          bottom: BorderSide(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                        )
                      : null,
                ),
                child: Text(
                  label,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: isActive
                        ? AppTheme.textPrimary
                        : const Color(0xFF56617D),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsCheckboxRow extends StatelessWidget {
  const _SettingsCheckboxRow({
    required this.value,
    required this.label,
    required this.onChanged,
    this.trailing,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Checkbox(
                value: value,
                activeColor: AppTheme.primaryBlue,
                side: const BorderSide(color: Color(0xFFC3C9DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (checked) => onChanged(checked ?? false),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _SettingsRadioRow extends StatelessWidget {
  const _SettingsRadioRow({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
  });

  final _SalesOrderCloseOption value;
  final _SalesOrderCloseOption groupValue;
  final String label;
  final ValueChanged<_SalesOrderCloseOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Radio<_SalesOrderCloseOption>(
                value: value,
                groupValue: groupValue,
                activeColor: AppTheme.primaryBlue,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
