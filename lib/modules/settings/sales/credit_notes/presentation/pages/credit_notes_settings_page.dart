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
import 'package:zerpai_erp/modules/settings/shared/data/repositories/settings_preferences_repository.dart';

enum CreditNotesSettingsTab {
  preferences,
  approvals,
  fields,
  creditNoteCycle,
  validationRules,
  recordLocking,
  statuses,
  buttons,
  relatedLists,
}

class _QrCodeTypeItem {
  const _QrCodeTypeItem({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

const List<_QrCodeTypeItem> _qrCodeTypeItems = [
  _QrCodeTypeItem(
    id: 'UPI ID',
    title: 'UPI ID',
    description: 'Your UPI ID will be displayed as a QR code on invoices.',
  ),
  _QrCodeTypeItem(
    id: 'Invoice URL',
    title: 'Invoice URL',
    description:
        'When scanned, invoice URL will be displayed to the customer. Recommended if you provide online payment options.',
  ),
  _QrCodeTypeItem(
    id: 'Custom',
    title: 'Custom',
    description:
        'Adds a scannable QR code to the invoice; when scanned, it displays either a custom URL you configure or specific information you enter.',
  ),
  _QrCodeTypeItem(
    id: 'Bank Details',
    title: 'Bank Details',
    description:
        'Adds bank transfer details like Account Number and IFSC code as a scannable QR code.',
  ),
  _QrCodeTypeItem(
    id: 'PhonePe/UPI Number',
    title: 'PhonePe/UPI Number',
    description:
        'Display a scannable QR code linked to a mobile number for direct UPI payments.',
  ),
  _QrCodeTypeItem(
    id: 'Customer Portal URL',
    title: 'Customer Portal URL',
    description:
        'Scannable QR code pointing directly to the Customer Portal login page.',
  ),
];

class _CreditNoteStatusRecord {
  const _CreditNoteStatusRecord({
    required this.customStatusFor,
    required this.statusName,
    required this.description,
    required this.labelColor,
  });

  final String customStatusFor;
  final String statusName;
  final String description;
  final Color labelColor;

  _CreditNoteStatusRecord copyWith({
    String? customStatusFor,
    String? statusName,
    String? description,
    Color? labelColor,
  }) {
    return _CreditNoteStatusRecord(
      customStatusFor: customStatusFor ?? this.customStatusFor,
      statusName: statusName ?? this.statusName,
      description: description ?? this.description,
      labelColor: labelColor ?? this.labelColor,
    );
  }
}

class _StatusDialogResult {
  const _StatusDialogResult({this.record, this.deleted = false});

  final _CreditNoteStatusRecord? record;
  final bool deleted;
}

final ValueNotifier<List<_CreditNoteStatusRecord>> _creditNoteStatusesNotifier =
    ValueNotifier<List<_CreditNoteStatusRecord>>(
      const <_CreditNoteStatusRecord>[],
    );

class CreditNotesSettingsPage extends ConsumerStatefulWidget {
  const CreditNotesSettingsPage({
    super.key,
    this.initialTab = CreditNotesSettingsTab.preferences,
  });

  final CreditNotesSettingsTab initialTab;

  @override
  ConsumerState<CreditNotesSettingsPage> createState() =>
      _CreditNotesSettingsPageState();
}

class _CreditNotesSettingsPageState
    extends ConsumerState<CreditNotesSettingsPage> {
  final SettingsPreferencesRepository _preferencesRepository =
      SettingsPreferencesRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _termsController = TextEditingController();
  final TextEditingController _customerNotesController =
      TextEditingController();
  final TextEditingController _customQrCodeValueController =
      TextEditingController();
  final TextEditingController _qrCodeDescController = TextEditingController(
    text: 'Scan the QR code to view the configured information.',
  );
  final ScrollController _contentScrollController = ScrollController();

  bool _overrideCostPrices = true;
  bool _qrCodeEnabled = true;
  _QrCodeTypeItem _qrCodeType =
      _qrCodeTypeItems[2]; // Default to 'Custom' as in screenshot
  late CreditNotesSettingsTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final data = await _preferencesRepository.loadSection(
        'pdf_preferences',
        const ['documents', 'credit_notes'],
      );
      if (!mounted || data.isEmpty) return;
      setState(() {
        _overrideCostPrices =
            data['override_cost_prices'] as bool? ?? _overrideCostPrices;
        _qrCodeEnabled = data['qr_code_enabled'] as bool? ?? _qrCodeEnabled;
        _qrCodeType =
            _qrCodeTypeItems
                .where((v) => v.id == data['qr_code_type'])
                .firstOrNull ??
            _qrCodeType;
        _qrCodeDescController.text =
            data['qr_code_description']?.toString() ??
            _qrCodeDescController.text;
        _customQrCodeValueController.text =
            data['custom_qr_code_value']?.toString() ?? '';
        _termsController.text = data['terms']?.toString() ?? '';
        _customerNotesController.text =
            data['customer_notes']?.toString() ?? '';
      });
    } catch (_) {
      if (mounted)
        ZerpaiToast.error(context, 'Failed to load credit note preferences');
    }
  }

  Future<void> _savePreferences() async {
    try {
      await _preferencesRepository.saveSection(
        'pdf_preferences',
        {
          'override_cost_prices': _overrideCostPrices,
          'qr_code_enabled': _qrCodeEnabled,
          'qr_code_type': _qrCodeType.id,
          'qr_code_description': _qrCodeDescController.text,
          'custom_qr_code_value': _customQrCodeValueController.text,
          'terms': _termsController.text,
          'customer_notes': _customerNotesController.text,
        },
        const ['documents', 'credit_notes'],
      );
      if (mounted)
        ZerpaiToast.success(context, 'Credit Notes preferences saved');
    } catch (_) {
      if (mounted)
        ZerpaiToast.error(context, 'Failed to save credit note preferences');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _termsController.dispose();
    _customerNotesController.dispose();
    _customQrCodeValueController.dispose();
    _qrCodeDescController.dispose();
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
        group: 'Credit Notes',
        label: 'Preferences',
        subtitle: 'Credit Notes',
        keywords: const <String>['credit notes', 'preferences'],
        onSelected: () => _openTab(CreditNotesSettingsTab.preferences),
      ),
      SettingsSearchItem(
        group: 'Credit Notes',
        label: 'Credit Note Cycle',
        subtitle: 'Credit Notes',
        keywords: const <String>['cycle', 'rules', 'manual orders'],
        onSelected: () => _openTab(CreditNotesSettingsTab.creditNoteCycle),
      ),
      SettingsSearchItem(
        group: 'Credit Notes',
        label: 'Statuses',
        subtitle: 'Credit Notes',
        keywords: const <String>['status', 'custom status', 'label color'],
        onSelected: () => _openTab(CreditNotesSettingsTab.statuses),
      ),
      SettingsSearchItem(
        group: 'Credit Notes',
        label: 'Terms & Conditions',
        subtitle: 'Credit Notes',
        keywords: const <String>['terms', 'conditions'],
        onSelected: () => _openTab(CreditNotesSettingsTab.preferences),
      ),
    ];
  }

  void _openTab(CreditNotesSettingsTab tab) {
    final route = switch (tab) {
      CreditNotesSettingsTab.creditNoteCycle =>
        AppRoutes.settingsCreditNotesCycle,
      CreditNotesSettingsTab.statuses => AppRoutes.settingsCreditNotesStatuses,
      _ => AppRoutes.settingsCreditNotes,
    };
    if (_activeTab != tab) {
      setState(() => _activeTab = tab);
    }
    context.go(_withOrgPrefix(route));
  }

  Future<void> _openCustomQrCodeDialog() async {
    final result = await _showCustomQrCodeDialog(
      context,
      initialValue: _customQrCodeValueController.text,
    );
    if (!mounted || result == null) return;
    setState(() {
      _customQrCodeValueController.text = result;
    });
    ZerpaiToast.success(context, 'Custom QR code updated');
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
            _CreditNotesSettingsHeader(
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
                          _CreditNotesPageTitle(
                            trailing:
                                _activeTab == CreditNotesSettingsTab.statuses
                                ? const _StatusesHeaderButton()
                                : null,
                          ),
                          _CreditNotesTabsRow(
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
                                  _activeTab == CreditNotesSettingsTab.statuses
                                      ? 0
                                      : 22,
                                  _activeTab == CreditNotesSettingsTab.statuses
                                      ? 0
                                      : 18,
                                  _activeTab == CreditNotesSettingsTab.statuses
                                      ? 0
                                      : 22,
                                  34,
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child:
                                      _activeTab ==
                                          CreditNotesSettingsTab.statuses
                                      ? const _CreditNotesStatusesContent()
                                      : ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 820,
                                          ),
                                          child:
                                              _activeTab ==
                                                  CreditNotesSettingsTab
                                                      .creditNoteCycle
                                              ? const _CreditNotesCycleContent()
                                              : _CreditNotesPreferencesContent(
                                                  overrideCostPrices:
                                                      _overrideCostPrices,
                                                  qrCodeEnabled: _qrCodeEnabled,
                                                  qrCodeType: _qrCodeType,
                                                  qrCodeDescController:
                                                      _qrCodeDescController,
                                                  onConfigureQrCode:
                                                      _openCustomQrCodeDialog,
                                                  termsController:
                                                      _termsController,
                                                  customerNotesController:
                                                      _customerNotesController,
                                                  onSave: _savePreferences,
                                                  onOverrideCostPricesChanged:
                                                      (value) {
                                                        setState(
                                                          () =>
                                                              _overrideCostPrices =
                                                                  value,
                                                        );
                                                      },
                                                  onQrCodeEnabledChanged:
                                                      (value) {
                                                        setState(
                                                          () => _qrCodeEnabled =
                                                              value,
                                                        );
                                                      },
                                                  onQrCodeTypeChanged: (value) {
                                                    if (value != null) {
                                                      setState(
                                                        () =>
                                                            _qrCodeType = value,
                                                      );
                                                    }
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

class _CreditNotesPreferencesContent extends StatelessWidget {
  const _CreditNotesPreferencesContent({
    required this.overrideCostPrices,
    required this.qrCodeEnabled,
    required this.qrCodeType,
    required this.qrCodeDescController,
    required this.onConfigureQrCode,
    required this.termsController,
    required this.customerNotesController,
    required this.onOverrideCostPricesChanged,
    required this.onQrCodeEnabledChanged,
    required this.onQrCodeTypeChanged,
    required this.onSave,
  });

  final bool overrideCostPrices;
  final bool qrCodeEnabled;
  final _QrCodeTypeItem qrCodeType;
  final TextEditingController qrCodeDescController;
  final VoidCallback onConfigureQrCode;
  final TextEditingController termsController;
  final TextEditingController customerNotesController;

  final ValueChanged<bool> onOverrideCostPricesChanged;
  final ValueChanged<bool> onQrCodeEnabledChanged;
  final ValueChanged<_QrCodeTypeItem?> onQrCodeTypeChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cost Price Preference',
          style: AppTheme.pageTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _SettingsCheckboxRow(
          value: overrideCostPrices,
          label: 'Allow users to override cost prices in credit notes',
          onChanged: onOverrideCostPricesChanged,
        ),
        const SizedBox(height: 6),
        Text(
          'Mark this option to allow users to manually edit and update the cost price that is fetched from the recent transaction. Once you override the cost price, the latest cost price will not be updated based on the recent transaction.',
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Credit Note QR Code',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  qrCodeEnabled ? 'Enabled' : 'Disabled',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                _CustomMiniSwitch(
                  value: qrCodeEnabled,
                  onChanged: onQrCodeEnabledChanged,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Enable and configure the QR code you want to display on the PDF copy of an Credit Note. Your customers can scan the QR code using their device to access the URL or other information that you configure.',
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        if (qrCodeEnabled) ...[
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 160,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'QR Code Type',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 34,
                          width: 320,
                          child: FormDropdown<_QrCodeTypeItem>(
                            value: qrCodeType,
                            items: _qrCodeTypeItems,
                            onChanged: onQrCodeTypeChanged,
                            hint: 'Invoice URL',
                            showSearch: true,
                            showSearchIcon: true,
                            fillColor: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            displayStringForValue: (item) => item.title,
                            itemBuilder: (item, isSelected, isHovered) {
                              final backgroundColor = isHovered
                                  ? const Color(0xFF2196F3)
                                  : isSelected
                                  ? const Color(0xFFF0F4F9)
                                  : Colors.white;
                              final titleColor = isHovered
                                  ? Colors.white
                                  : AppTheme.textPrimary;
                              final descColor = isHovered
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : AppTheme.textSecondary;
                              final checkmarkColor = isHovered
                                  ? Colors.white
                                  : AppTheme.primaryBlue;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                color: backgroundColor,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item.title,
                                            style: AppTheme.bodyText.copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: titleColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.description,
                                            style: AppTheme.bodyText.copyWith(
                                              fontSize: 11,
                                              color: descColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.check,
                                        color: checkmarkColor,
                                        size: 16,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 34,
                          child: ElevatedButton(
                            onPressed: onConfigureQrCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Configure',
                              style: AppTheme.bodyText.copyWith(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      qrCodeType.description,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 160,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'QR Code Description',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  width: 480,
                  child: TextField(
                    controller: qrCodeDescController,
                    maxLines: 3,
                    style: AppTheme.bodyText.copyWith(fontSize: 14),
                    decoration: _textAreaDecoration(
                      'Scan the QR code to view the configured information.',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          RichText(
            text: TextSpan(
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
              children: [
                const TextSpan(
                  text: 'Note: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text:
                      'You can display this QR code in your credit note PDFs. To do this, edit the credit note template from ',
                ),
                TextSpan(
                  text: 'PDF Templates in Settings',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text:
                      ' and select the Show Credit Note QR Code checkbox in the Other Details section.',
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
        const SizedBox(height: 22),
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
        const SizedBox(height: 22),
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
            onPressed: onSave,
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

class _SettingsCheckboxRow extends StatelessWidget {
  const _SettingsCheckboxRow({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
          ],
        ),
      ),
    );
  }
}

class _CustomMiniSwitch extends StatelessWidget {
  const _CustomMiniSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34,
        height: 18,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: value ? const Color(0xFF2196F3) : const Color(0xFFD0D5DD),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreditNotesCycleContent extends StatelessWidget {
  const _CreditNotesCycleContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configure credit note cycle preference for manual credit notes',
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
                      'Create credit note cycle rules for marketplace orders',
                      style: AppTheme.pageTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF20263A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Create credit note cycle rules for different marketplaces to create transactions like invoices, packages, and shipments automatically after an order is received from a marketplace.',
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
                'You have to execute the credit note cycle from the credit note details page for orders that have been imported manually.',
                'The custom fields in transactions will be left empty, even if the custom fields are mandatory.',
                'If a credit note contains items with either serial number tracking or batch tracking, you cannot create packages or invoices while automating the credit note cycle.',
                'You have to disable any functions that might interfere with the credit note cycle. Contact support for more details.',
              ].map(_CycleNoteBullet.new),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreditNotesStatusesContent extends StatefulWidget {
  const _CreditNotesStatusesContent();

  @override
  State<_CreditNotesStatusesContent> createState() =>
      _CreditNotesStatusesContentState();
}

class _CreditNotesStatusesContentState
    extends State<_CreditNotesStatusesContent> {
  int? _hoveredRowIndex;
  final MenuController _rowMenuController = MenuController();
  bool _isRowMenuOpen = false;

  Future<void> _handleEditStatus(
    BuildContext context,
    int index,
    _CreditNoteStatusRecord record,
  ) async {
    final result = await _showEditStatusDialog(context, record);
    if (result == null) return;

    final next = List<_CreditNoteStatusRecord>.from(
      _creditNoteStatusesNotifier.value,
    );
    if (result.deleted) {
      next.removeAt(index);
      _creditNoteStatusesNotifier.value = next;
      if (context.mounted) {
        ZerpaiToast.success(context, 'Status deleted');
      }
      return;
    }

    if (result.record != null) {
      next[index] = result.record!;
      _creditNoteStatusesNotifier.value = next;
      if (context.mounted) {
        ZerpaiToast.success(context, 'Status updated');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<_CreditNoteStatusRecord>>(
      valueListenable: _creditNoteStatusesNotifier,
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
                                                    _CreditNoteStatusRecord
                                                  >.from(
                                                    _creditNoteStatusesNotifier
                                                        .value,
                                                  );
                                              next.removeAt(index);
                                              _creditNoteStatusesNotifier
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

Future<String?> _showCustomQrCodeDialog(
  BuildContext context, {
  required String initialValue,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Configure Custom QR Code',
    barrierColor: Colors.black.withValues(alpha: 0.58),
    pageBuilder: (_, __, ___) =>
        _CustomQrCodeDialog(initialValue: initialValue),
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
  _CreditNoteStatusRecord record,
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

class _CustomQrCodeDialog extends StatefulWidget {
  const _CustomQrCodeDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_CustomQrCodeDialog> createState() => _CustomQrCodeDialogState();
}

class _QrPlaceholderItem {
  const _QrPlaceholderItem({required this.label, required this.token});

  final String label;
  final String token;
}

class _QrPlaceholderSection {
  const _QrPlaceholderSection({required this.title, required this.items});

  final String title;
  final List<_QrPlaceholderItem> items;
}

const List<_QrPlaceholderSection>
_qrPlaceholderSections = <_QrPlaceholderSection>[
  _QrPlaceholderSection(
    title: 'ORGANIZATION',
    items: <_QrPlaceholderItem>[
      _QrPlaceholderItem(
        label: 'Organization Name',
        token: '{{organization_name}}',
      ),
      _QrPlaceholderItem(label: 'Logo', token: '{{organization_logo}}'),
      _QrPlaceholderItem(
        label: 'Street Address1',
        token: '{{organization_street_address1}}',
      ),
      _QrPlaceholderItem(
        label: 'Street Address2',
        token: '{{organization_street_address2}}',
      ),
      _QrPlaceholderItem(label: 'City', token: '{{organization_city}}'),
      _QrPlaceholderItem(
        label: 'ZIP/Postal Code',
        token: '{{organization_postal_code}}',
      ),
      _QrPlaceholderItem(
        label: 'State/Province',
        token: '{{organization_state}}',
      ),
      _QrPlaceholderItem(label: 'Country', token: '{{organization_country}}'),
      _QrPlaceholderItem(label: 'Phone#', token: '{{organization_phone}}'),
      _QrPlaceholderItem(label: 'Fax#', token: '{{organization_fax}}'),
      _QrPlaceholderItem(label: 'Website', token: '{{organization_website}}'),
      _QrPlaceholderItem(label: 'Label 1', token: '{{organization_label_1}}'),
      _QrPlaceholderItem(label: 'Label 2', token: '{{organization_label_2}}'),
      _QrPlaceholderItem(label: 'Label 3', token: '{{organization_label_3}}'),
      _QrPlaceholderItem(label: 'Label 4', token: '{{organization_label_4}}'),
      _QrPlaceholderItem(label: 'Label 5', token: '{{organization_label_5}}'),
      _QrPlaceholderItem(label: 'Value 1', token: '{{organization_value_1}}'),
      _QrPlaceholderItem(label: 'Value 2', token: '{{organization_value_2}}'),
      _QrPlaceholderItem(label: 'Value 3', token: '{{organization_value_3}}'),
      _QrPlaceholderItem(label: 'Value 4', token: '{{organization_value_4}}'),
      _QrPlaceholderItem(label: 'Value 5', token: '{{organization_value_5}}'),
      _QrPlaceholderItem(
        label: 'CompanyIDValue',
        token: '{{organization_company_id_value}}',
      ),
      _QrPlaceholderItem(
        label: 'CompanyIDLabel',
        token: '{{organization_company_id_label}}',
      ),
      _QrPlaceholderItem(
        label: 'TaxIDValue',
        token: '{{organization_tax_id_value}}',
      ),
      _QrPlaceholderItem(
        label: 'TaxIDLabel',
        token: '{{organization_tax_id_label}}',
      ),
    ],
  ),
  _QrPlaceholderSection(
    title: 'CUSTOMER',
    items: <_QrPlaceholderItem>[
      _QrPlaceholderItem(label: 'Salutation', token: '{{customer_salutation}}'),
      _QrPlaceholderItem(label: 'First Name', token: '{{customer_first_name}}'),
      _QrPlaceholderItem(label: 'Last Name', token: '{{customer_last_name}}'),
      _QrPlaceholderItem(label: 'Email', token: '{{customer_email}}'),
      _QrPlaceholderItem(label: 'Phone', token: '{{customer_phone}}'),
      _QrPlaceholderItem(label: 'Mobile', token: '{{customer_mobile}}'),
      _QrPlaceholderItem(label: 'Department', token: '{{customer_department}}'),
      _QrPlaceholderItem(
        label: 'Designation',
        token: '{{customer_designation}}',
      ),
      _QrPlaceholderItem(label: 'Skype', token: '{{customer_skype}}'),
      _QrPlaceholderItem(label: 'Name', token: '{{customer_name}}'),
      _QrPlaceholderItem(
        label: 'Company Name',
        token: '{{customer_company_name}}',
      ),
      _QrPlaceholderItem(
        label: 'Billing Attention',
        token: '{{customer_billing_attention}}',
      ),
      _QrPlaceholderItem(
        label: 'Billing Address',
        token: '{{customer_billing_address}}',
      ),
      _QrPlaceholderItem(
        label: 'Billing City',
        token: '{{customer_billing_city}}',
      ),
      _QrPlaceholderItem(
        label: 'Customer Number',
        token: '{{customer_number}}',
      ),
      _QrPlaceholderItem(
        label: 'Billing State',
        token: '{{customer_billing_state}}',
      ),
      _QrPlaceholderItem(
        label: 'Billing Code',
        token: '{{customer_billing_code}}',
      ),
      _QrPlaceholderItem(
        label: 'Billing Country',
        token: '{{customer_billing_country}}',
      ),
      _QrPlaceholderItem(
        label: 'Billing Phone',
        token: '{{customer_billing_phone}}',
      ),
      _QrPlaceholderItem(
        label: 'Billing Fax',
        token: '{{customer_billing_fax}}',
      ),
      _QrPlaceholderItem(
        label: 'Shipping Attention',
        token: '{{customer_shipping_attention}}',
      ),
      _QrPlaceholderItem(
        label: 'Shipping Address',
        token: '{{customer_shipping_address}}',
      ),
      _QrPlaceholderItem(
        label: 'Shipping City',
        token: '{{customer_shipping_city}}',
      ),
      _QrPlaceholderItem(
        label: 'Shipping State',
        token: '{{customer_shipping_state}}',
      ),
      _QrPlaceholderItem(
        label: 'Shipping Code',
        token: '{{customer_shipping_code}}',
      ),
      _QrPlaceholderItem(
        label: 'Shipping Country',
        token: '{{customer_shipping_country}}',
      ),
      _QrPlaceholderItem(
        label: 'Shipping Phone',
        token: '{{customer_shipping_phone}}',
      ),
      _QrPlaceholderItem(
        label: 'Shipping Fax',
        token: '{{customer_shipping_fax}}',
      ),
      _QrPlaceholderItem(
        label: 'Credit Limit',
        token: '{{customer_credit_limit}}',
      ),
      _QrPlaceholderItem(label: 'Twitter', token: '{{customer_twitter}}'),
      _QrPlaceholderItem(label: 'Facebook', token: '{{customer_facebook}}'),
      _QrPlaceholderItem(label: 'Website', token: '{{customer_website}}'),
    ],
  ),
  _QrPlaceholderSection(
    title: 'CREDIT NOTES',
    items: <_QrPlaceholderItem>[
      _QrPlaceholderItem(
        label: 'Credit Note Date',
        token: '{{credit_note_date}}',
      ),
      _QrPlaceholderItem(
        label: 'Credit Note Issue Date',
        token: '{{credit_note_issue_date}}',
      ),
      _QrPlaceholderItem(
        label: 'Credit Note#',
        token: '{{credit_note_number}}',
      ),
      _QrPlaceholderItem(label: 'Ref#', token: '{{credit_note_reference}}'),
      _QrPlaceholderItem(label: 'Total', token: '{{credit_note_total}}'),
      _QrPlaceholderItem(
        label: 'Total In Base Currency\nwithout currency code',
        token: '{{credit_note_total_in_base_currency}}',
      ),
      _QrPlaceholderItem(label: 'sinanzab', token: '{{credit_note_sinanzab}}'),
      _QrPlaceholderItem(label: 'erhj', token: '{{credit_note_erhj}}'),
      _QrPlaceholderItem(label: 'isjan', token: '{{credit_note_isjan}}'),
    ],
  ),
];

class _CustomQrCodeDialogState extends State<_CustomQrCodeDialog> {
  late final TextEditingController _controller;
  late final TextEditingController _searchController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _placeholderScrollController = ScrollController();
  bool _showPlaceholderDropdown = false;
  String? _selectedPlaceholderToken;
  String? _hoveredPlaceholderToken;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _editorFocusNode.dispose();
    _placeholderScrollController.dispose();
    super.dispose();
  }

  List<_QrPlaceholderSection> _filteredSections() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _qrPlaceholderSections;
    return _qrPlaceholderSections
        .map((section) {
          final items = section.items
              .where((item) => item.label.toLowerCase().contains(query))
              .toList();
          return _QrPlaceholderSection(title: section.title, items: items);
        })
        .where((section) => section.items.isNotEmpty)
        .toList();
  }

  void _insertPlaceholder(_QrPlaceholderItem item) {
    final value = _controller.text;
    final selection = _controller.selection;
    final replacement = item.token;
    if (!selection.isValid) {
      _controller.text = '$value$replacement';
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    } else {
      final newText = value.replaceRange(
        selection.start,
        selection.end,
        replacement,
      );
      final cursor = selection.start + replacement.length;
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor),
      );
    }
    setState(() {
      _selectedPlaceholderToken = item.token;
      _showPlaceholderDropdown = false;
    });
    _editorFocusNode.requestFocus();
  }

  List<Widget> _buildPlaceholderRows(List<_QrPlaceholderItem> items) {
    final rows = <Widget>[];
    for (var index = 0; index < items.length; index += 2) {
      final left = items[index];
      final _QrPlaceholderItem? right = index + 1 < items.length
          ? items[index + 1]
          : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPlaceholderTile(left)),
              const SizedBox(width: 14),
              Expanded(
                child: right != null
                    ? _buildPlaceholderTile(right)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  Widget _buildPlaceholderTile(_QrPlaceholderItem item) {
    final isSelected = _selectedPlaceholderToken == item.token;
    final isHovered = _hoveredPlaceholderToken == item.token;
    final backgroundColor = isHovered
        ? const Color(0xFF4285F4)
        : isSelected
        ? const Color(0xFFF0F4F9)
        : Colors.transparent;
    final textColor = isHovered ? Colors.white : const Color(0xFF40465E);
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredPlaceholderToken = item.token),
      onExit: (_) {
        if (_hoveredPlaceholderToken == item.token) {
          setState(() => _hoveredPlaceholderToken = null);
        }
      },
      child: InkWell(
        onTap: () => _insertPlaceholder(item),
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            item.label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSections = _filteredSections();
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 700,
          height: 434.53,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Configure Custom QR Code',
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDCE2EE)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 57,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE7EAF3),
                                    ),
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _showPlaceholderDropdown =
                                            !_showPlaceholderDropdown;
                                      });
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Insert Placeholders',
                                          style: AppTheme.bodyText.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 18,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _editorFocusNode,
                                  expands: true,
                                  maxLines: null,
                                  minLines: null,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 15,
                                    color: const Color(0xFF20263A),
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Enter a custom URL or the information you want to display when they scan the QR code',
                                    hintStyle: AppTheme.bodyText.copyWith(
                                      fontSize: 15,
                                      color: const Color(0xFF8E95B2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.fromLTRB(
                                      10,
                                      10,
                                      10,
                                      10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showPlaceholderDropdown)
                          Positioned(
                            left: 12,
                            top: 44,
                            right: 12,
                            bottom: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E7F2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0B1020,
                                    ).withValues(alpha: 0.18),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      12,
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (_) => setState(() {}),
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 14,
                                        color: const Color(0xFF4A5168),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Search',
                                        hintStyle: AppTheme.bodyText.copyWith(
                                          fontSize: 14,
                                          color: const Color(0xFF8B92AD),
                                        ),
                                        prefixIcon: const Icon(
                                          LucideIcons.search,
                                          size: 18,
                                          color: Color(0xFF8B92AD),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFD8DDF0),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFD8DDF0),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: ListView.builder(
                                            controller:
                                                _placeholderScrollController,
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                              bottom: 12,
                                            ),
                                            itemCount: filteredSections.length,
                                            itemBuilder: (context, sectionIndex) {
                                              final section =
                                                  filteredSections[sectionIndex];
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (sectionIndex > 0)
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom: 14,
                                                      ),
                                                      child: Divider(
                                                        height: 1,
                                                        thickness: 1,
                                                        color: Color(
                                                          0xFFE7EAF3,
                                                        ),
                                                      ),
                                                    ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 10,
                                                        ),
                                                    child: Text(
                                                      section.title,
                                                      style: AppTheme.bodyText
                                                          .copyWith(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: const Color(
                                                              0xFF858AA3,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                  ..._buildPlaceholderRows(
                                                    section.items,
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        const Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Icon(
                                            Icons.keyboard_arrow_up,
                                            size: 20,
                                            color: Color(0xFFB4B7C7),
                                          ),
                                        ),
                                        const Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 20,
                                            color: Color(0xFFB4B7C7),
                                          ),
                                        ),
                                        Positioned(
                                          top: 44,
                                          right: 8,
                                          bottom: 28,
                                          child: IgnorePointer(
                                            child: Container(
                                              width: 10,
                                              alignment: Alignment.topCenter,
                                              child: Container(
                                                width: 10,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFB7B5C4,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
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
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE7EAF3),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 37,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(_controller.text),
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
                            'Update',
                            style: AppTheme.bodyText.copyWith(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        height: 37,
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
                          'Select the transactions that has to be created after a credit note.',
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
  final _CreditNoteStatusRecord? initialRecord;
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
        record: _CreditNoteStatusRecord(
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

class _CreditNotesSettingsHeader extends StatelessWidget {
  const _CreditNotesSettingsHeader({
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

class _CreditNotesPageTitle extends StatelessWidget {
  const _CreditNotesPageTitle({this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Credit Notes',
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
    _creditNoteStatusesNotifier.value = <_CreditNoteStatusRecord>[
      ..._creditNoteStatusesNotifier.value,
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

class _CreditNotesTabsRow extends StatelessWidget {
  const _CreditNotesTabsRow({
    required this.activeTab,
    required this.onTabSelected,
  });

  final CreditNotesSettingsTab activeTab;
  final ValueChanged<CreditNotesSettingsTab> onTabSelected;

  static const List<(String, CreditNotesSettingsTab)> _tabs =
      <(String, CreditNotesSettingsTab)>[
        ('Preferences', CreditNotesSettingsTab.preferences),
        ('Fields', CreditNotesSettingsTab.fields),
        ('Credit Note Cycle', CreditNotesSettingsTab.creditNoteCycle),
        ('Validation Rules', CreditNotesSettingsTab.validationRules),
        ('Record Locking', CreditNotesSettingsTab.recordLocking),
        ('Statuses', CreditNotesSettingsTab.statuses),
        ('Buttons', CreditNotesSettingsTab.buttons),
        ('Related Lists', CreditNotesSettingsTab.relatedLists),
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
