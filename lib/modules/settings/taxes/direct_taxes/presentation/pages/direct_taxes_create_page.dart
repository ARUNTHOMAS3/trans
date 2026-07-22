import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_page_header.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';

class DirectTaxesCreatePage extends StatefulWidget {
  const DirectTaxesCreatePage({super.key});

  @override
  State<DirectTaxesCreatePage> createState() => _DirectTaxesCreatePageState();
}

enum _DirectTaxMenuItem { tdsIncomeSettings, tdsIncomeRates, tcsIncomeRates }

enum _TdsApplyMode { transaction, lineItem }

class _TdsRateRow {
  const _TdsRateRow({
    required this.taxName,
    required this.rate,
    required this.taxType,
    required this.status,
    this.isGroup = false,
  });

  final String taxName;
  final String rate;
  final String taxType;
  final String status;
  final bool isGroup;
}

class _SectionOption {
  const _SectionOption({
    required this.title,
    required this.description,
    required this.earlier,
  });

  final String title;
  final String description;
  final String earlier;
}

class _HigherTdsReasonOption {
  const _HigherTdsReasonOption({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

const List<String> _directTaxAccountOptions = <String>[
  'Other Current Liability',
  '[ Payroll-004 ] Deductions Payable',
  'Director salary payables',
  '• Dr.Irfan-Salary',
  '• Mr.Favas-Salary',
  '• Mr.Sameer-Salary',
  '• Mr.Shabin-Salary',
  'GST PAYABLE',
  '[ Payroll-006 ] Hold Salary Payable',
  '[ Payroll-005 ] Net Salary Payable',
  '[ Payroll-002 ] Payroll Tax Payable',
  'RCM Output CGST 9%',
  'RCM Output SGST 9%',
  '[ Payroll-001 ] Reimbursements Payable',
  'Rent Payable A/C',
  'Staff Salary Payable',
  '• Althaf -Salary',
  '• Bijisha -Salary',
  '• Deepthi -Salary',
  '• Fathima -Salary',
  '• Nandana -Salary',
  '• RAHUL MURALEEDARAN - SALARY',
  '• Reshama -Salary',
  '[ Payroll-003 ] Statutory Deductions Payable',
  'TCS Payable',
];

const String _directTaxAccountHeading = 'Other Current Liability';

const List<String> _directTaxReceivableAccountOptions = <String>[
  'Other Current Asset',
  'Advance Tax',
  'Goods In Transit',
  'Prepaid Expenses',
  'RCM Input CGST 9%',
  'RCM Input SGST 9%',
  'TCS Receivable',
  'TDS Receivable',
  'Zoho Payroll - Loan Account',
];

const String _directTaxReceivableAccountHeading = 'Other Current Asset';

class _GroupTaxSelectableRate {
  const _GroupTaxSelectableRate({
    required this.name,
    required this.rate,
    this.sectionLabel,
  });

  final String name;
  final String rate;
  final String? sectionLabel;
}

class _DirectTaxesCreatePageState extends State<DirectTaxesCreatePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  _DirectTaxMenuItem _selectedMenuItem = _DirectTaxMenuItem.tdsIncomeSettings;
  _TdsApplyMode _selectedApplyMode = _TdsApplyMode.transaction;
  bool _enableTdsLiabilitiesReport = false;
  String? _selectedStartPeriod;
  String? _selectedPenaltyAccount = 'Other Expenses';
  String? _selectedInterestAccount = 'Other Expenses';
  String _selectedTdsRatesFilter = 'All';

  static const List<_TdsRateRow> _tdsRateRows = <_TdsRateRow>[
    _TdsRateRow(
      taxName: 'althaf 2 demo',
      rate: '12',
      taxType: 'Section 195',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'althaf demo',
      rate: '12',
      taxType: 'Section 195',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'Commission or Brokerage',
      rate: '2',
      taxType: 'Section 194 H',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'Commission or Brokerage (Reduced)',
      rate: '3.75',
      taxType: 'Section 194 H',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'd (TDS Tax Group)',
      rate: '24',
      taxType: '',
      status: 'Expired',
      isGroup: true,
    ),
    _TdsRateRow(
      taxName: 'Dividend',
      rate: '10',
      taxType: 'Section 194',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'Dividend (Reduced)',
      rate: '7.5',
      taxType: 'Section 194',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'Other Interest than securities',
      rate: '10',
      taxType: 'Section 194 A',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'Other Interest than securities (Reduced)',
      rate: '7.5',
      taxType: 'Section 194 A',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'Payment of contractors for Others',
      rate: '2',
      taxType: 'Section 194 C',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'Payment of contractors for Others (Reduced)',
      rate: '1.5',
      taxType: 'Section 194 C',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'Payment of contractors HUF/Indiv',
      rate: '1',
      taxType: 'Section 194 C',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'Payment of contractors HUF/Indiv (Reduced)',
      rate: '0.75',
      taxType: 'Section 194 C',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'Professional Fees',
      rate: '10',
      taxType: 'Section 194 J',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'Professional Fees (Reduced)',
      rate: '7.5',
      taxType: 'Section 194 J',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'Rent on land or furniture etc',
      rate: '10',
      taxType: 'Section 194 I',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'Rent on land or furniture etc (Reduced)',
      rate: '7.5',
      taxType: 'Section 194 I',
      status: 'Expired',
    ),
    _TdsRateRow(
      taxName: 'Technical Fees (2%)',
      rate: '2',
      taxType: 'Section 194 J',
      status: 'Expired',
    ),
  ];

  static const List<_TdsRateRow> _tcsRateRows = <_TdsRateRow>[
    _TdsRateRow(
      taxName: 'gb',
      rate: '23',
      taxType: 'Section 394(1) SI2',
      status: 'Active',
    ),
  ];

  static const List<String> _tdsRatesFilters = <String>[
    'All',
    'Active',
    'Inactive',
    'Expired',
    'TDS',
    'TDS Group',
  ];
  static const List<String> _newTdsTaxActions = <String>[
    'New TDS Surcharge',
    'New TDS Cess',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _showNewTdsDialog({String title = 'New TDS'}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      useSafeArea: false,
      builder: (BuildContext context) => _NewTdsDialog(title: title),
    );
  }

  Future<void> _showNewTdsGroupTaxDialog() {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      useSafeArea: false,
      builder: (BuildContext context) => const _NewTdsGroupTaxDialog(),
    );
  }

  List<SettingsSearchItem> _buildSearchItems() {
    return <SettingsSearchItem>[
      SettingsSearchItem(
        group: 'Taxes & Compliance',
        label: 'Direct Taxes',
        subtitle: 'Income TDS Settings',
        keywords: const <String>[
          'direct taxes',
          'tds',
          'tcs',
          'income tds settings',
        ],
        onSelected: () => setState(
          () => _selectedMenuItem = _DirectTaxMenuItem.tdsIncomeSettings,
        ),
      ),
      SettingsSearchItem(
        group: 'Taxes & Compliance',
        label: 'Income TDS Rates',
        subtitle: 'Direct Taxes',
        keywords: const <String>['tds', 'rates'],
        onSelected: () => setState(
          () => _selectedMenuItem = _DirectTaxMenuItem.tdsIncomeRates,
        ),
      ),
      SettingsSearchItem(
        group: 'Taxes & Compliance',
        label: 'Income TCS Rates',
        subtitle: 'Direct Taxes',
        keywords: const <String>['tcs', 'rates'],
        onSelected: () => setState(
          () => _selectedMenuItem = _DirectTaxMenuItem.tcsIncomeRates,
        ),
      ),
    ];
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
            searchItems: _buildSearchItems(),
            showBackButton: true,
            onBack: () =>
                context.go(_orgScopedRoute(context, AppRoutes.settings)),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsNavigationSidebar(currentPath: currentPath),
                  _buildSectionRail(),
                  Expanded(child: _buildContentPane()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionRail() {
    return Container(
      width: 228,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 50,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Text(
              'Direct Taxes',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          _buildSectionLabel('TDS'),
          _buildRailItem(
            label: 'Income TDS Settings',
            item: _DirectTaxMenuItem.tdsIncomeSettings,
            showBottomBorder: false,
          ),
          _buildRailItem(
            label: 'Income TDS Rates',
            item: _DirectTaxMenuItem.tdsIncomeRates,
            showBottomBorder: false,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
          _buildSectionLabel('TCS'),
          _buildRailItem(
            label: 'Income TCS Rates',
            item: _DirectTaxMenuItem.tcsIncomeRates,
            showBottomBorder: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Text(
        label,
        style: AppTheme.bodyText.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildRailItem({
    required String label,
    required _DirectTaxMenuItem item,
    bool showBottomBorder = true,
  }) {
    final bool isActive = _selectedMenuItem == item;
    return InkWell(
      onTap: () => setState(() => _selectedMenuItem = item),
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF7F8FB) : Colors.white,
          border: Border(
            bottom: showBottomBorder
                ? const BorderSide(color: AppTheme.borderLight)
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildContentPane() {
    switch (_selectedMenuItem) {
      case _DirectTaxMenuItem.tdsIncomeSettings:
        return _buildTdsSettingsPane();
      case _DirectTaxMenuItem.tdsIncomeRates:
        return _buildTdsRatesPane();
      case _DirectTaxMenuItem.tcsIncomeRates:
        return _buildTcsRatesPane();
    }
  }

  Widget _buildTdsSettingsPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 52,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Text(
            'Income TDS Settings',
            style: AppTheme.pageTitle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TDS',
                              style: AppTheme.pageTitle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'TDS or Tax Deducted at Source, can be associated at either the transaction level or at the line item level.',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF98A2B3),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Apply TDS:',
                              style: AppTheme.bodyText.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildRadioOption(
                              title: 'At Transaction Level',
                              subtitle:
                                  'TDS will be applied to the transaction\'s total.',
                              value: _TdsApplyMode.transaction,
                            ),
                            const SizedBox(height: 12),
                            _buildRadioOption(
                              title: 'At Line Item Level',
                              subtitle:
                                  'TDS will be applied to the line items for which you associate TDS.',
                              value: _TdsApplyMode.lineItem,
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
                        padding: const EdgeInsets.fromLTRB(18, 18, 20, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Transform.translate(
                                  offset: const Offset(-2, 0),
                                  child: Checkbox(
                                    value: _enableTdsLiabilitiesReport,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _enableTdsLiabilitiesReport =
                                            value ?? false;
                                      });
                                    },
                                    activeColor: AppTheme.primaryBlue,
                                    checkColor: Colors.white,
                                    side: const BorderSide(
                                      color: AppTheme.borderColorDark,
                                    ),
                                    visualDensity: const VisualDensity(
                                      horizontal: -4,
                                      vertical: -4,
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Enable TDS Liabilities Report',
                                  style: AppTheme.bodyText.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: const Color(0xFF1F2937),
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ),
                            if (_enableTdsLiabilitiesReport) ...[
                              const SizedBox(height: 10),
                              _buildLiabilitiesFields(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: AppTheme.buttonText.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String subtitle,
    required _TdsApplyMode value,
  }) {
    return RadioListTile<_TdsApplyMode>(
      value: value,
      groupValue: _selectedApplyMode,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedApplyMode = value);
      },
      activeColor: AppTheme.primaryBlue,
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -3),
      title: Text(
        title,
        style: AppTheme.bodyText.copyWith(
          fontSize: 12.9,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF374151),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          subtitle,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12.4,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF98A2B3),
          ),
        ),
      ),
    );
  }

  Widget _buildLiabilitiesFields() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 646),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Start Period',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12.6,
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w400,
                ),
                children: <InlineSpan>[
                  TextSpan(
                    text: '*',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 12.6,
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(width: 191, child: _buildMonthYearField()),
            const SizedBox(height: 10),
            SizedBox(
              width: 448,
              child: Text(
                'Note: The TDS liability details will be generated starting from the selected month, and you can record challans accordingly.',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12.4,
                  color: const Color(0xFF8A94B2),
                  fontWeight: FontWeight.w400,
                  height: 1.38,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Select Account To Track Penalties and Interest',
              style: AppTheme.bodyText.copyWith(
                fontSize: 12.95,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildAccountField(
                    label: 'Penalty Account',
                    value: _selectedPenaltyAccount,
                    onChanged: (String? value) {
                      setState(() => _selectedPenaltyAccount = value);
                    },
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: _buildAccountField(
                    label: 'Interest Account',
                    value: _selectedInterestAccount,
                    onChanged: (String? value) {
                      setState(() => _selectedInterestAccount = value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountField({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12.75,
            color: const Color(0xFF2E3646),
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        _buildStyledPatternDropdown(
          value: value,
          items: _directTaxAccountOptions,
          hint: 'Other Expenses',
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildStyledPatternDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return FormDropdown<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      height: 33,
      showSearch: true,
      hint: hint,
      boldSelected: false,
      itemHeight: 36,
      itemEstimatedHeight: 36,
      menuMaxHeight: 260,
      maxVisibleItems: 7,
      allowClear: false,
      showCustomValueAction: false,
      paintSelectionBackground: false,
      textStyle: AppTheme.bodyText.copyWith(
        fontSize: 12.9,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF4B5563),
      ),
      itemBuilder: (String item, bool isSelected, bool isHovered) {
        final Color rowColor = isHovered
            ? const Color(0xFF4A86E8)
            : isSelected
            ? const Color(0xFFF1F4FA)
            : Colors.white;
        final Color textColor = isHovered
            ? Colors.white
            : const Color(0xFF374151);
        final Color tickColor = isHovered ? Colors.white : AppTheme.primaryBlue;

        return Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: rowColor,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check, size: 16, color: tickColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthYearField() {
    return _MonthYearPickerField(
      value: _selectedStartPeriod,
      onChanged: (String? value) {
        setState(() => _selectedStartPeriod = value);
      },
    );
  }

  Widget _buildTdsRatesPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 50,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(18, 0, 8, 0),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              _buildTdsRatesFilterDropdown(),
              const Spacer(),
              _buildNewTdsTaxDropdownButton(),
              const SizedBox(width: 8),
              _buildHeaderActionButton(
                label: 'TDS Group Tax',
                showAddIcon: true,
                onPressed: _showNewTdsGroupTaxDialog,
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
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: const Row(
                    children: [
                      _RateHeaderCell(label: 'TAX NAME', width: 298),
                      _RateHeaderCell(label: 'RATE (%)', width: 82),
                      _RateHeaderCell(label: 'TAX TYPE', width: 154),
                      _RateHeaderCell(label: 'STATUS', width: 96),
                      Expanded(child: SizedBox()),
                    ],
                  ),
                ),
                for (final row in _tdsRateRows)
                  _buildTdsRateRow(row, showMarkAsInactive: false),
                _buildRatesTableFooter(totalCount: _tdsRateRows.length),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTcsRatesPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 52,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              Text(
                'Income TCS Rates',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              _buildHeaderActionButton(
                label: 'New TCS Tax',
                showAddIcon: true,
                onPressed: () => _showNewTdsDialog(title: 'New TCS'),
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
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: const Row(
                    children: [
                      _RateHeaderCell(label: 'TAX NAME', width: 298),
                      _RateHeaderCell(label: 'RATE (%)', width: 82),
                      _RateHeaderCell(label: 'TAX TYPE', width: 154),
                      _RateHeaderCell(label: 'STATUS', width: 96),
                      Expanded(child: SizedBox()),
                    ],
                  ),
                ),
                for (final row in _tcsRateRows)
                  _buildTdsRateRow(row, showMarkAsInactive: true),
                _buildRatesTableFooter(totalCount: _tcsRateRows.length),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatesTableFooter({required int totalCount}) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Text(
            'Total Count: $totalCount',
            style: AppTheme.bodyText.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
          const Spacer(),
          Container(
            height: 32,
            width: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD9E2F2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.chevronLeft,
                  size: 15,
                  color: Color(0xFFB7C3D7),
                ),
                const SizedBox(width: 8),
                Text(
                  '1 - $totalCount',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 15,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required String label,
    bool showAddIcon = false,
    bool showCaret = false,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: onPressed ?? () {},
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAddIcon) ...[
              const Icon(Icons.add, size: 14),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: AppTheme.buttonText.copyWith(
                fontSize: 11.8,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showCaret) ...[
              const SizedBox(width: 3),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewTdsTaxDropdownButton() {
    final MenuController controller = MenuController();

    return MenuAnchor(
      controller: controller,
      crossAxisUnconstrained: false,
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        surfaceTintColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(8),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      menuChildren: <Widget>[
        Container(
          width: 194,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _newTdsTaxActions.map((String option) {
              return InkWell(
                onTap: () {
                  controller.close();
                  _showNewTdsDialog(title: option);
                },
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: _HeaderActionDropdownItem(label: option),
              );
            }).toList(),
          ),
        ),
      ],
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
            final bool isOpen = controller.isOpen;

            return Container(
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF22B378),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _showNewTdsDialog(),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 14, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            'New TDS Tax',
                            style: AppTheme.buttonText.copyWith(
                              fontSize: 11.8,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                  InkWell(
                    onTap: () {
                      if (isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                    child: SizedBox(
                      width: 26,
                      height: 28,
                      child: Icon(
                        isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  Widget _buildTdsRatesFilterDropdown() {
    final MenuController controller = MenuController();

    return MenuAnchor(
      controller: controller,
      crossAxisUnconstrained: false,
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        surfaceTintColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(8),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      menuChildren: <Widget>[
        Container(
          width: 240,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _tdsRatesFilters.map((String option) {
              return InkWell(
                onTap: () {
                  setState(() => _selectedTdsRatesFilter = option);
                  controller.close();
                },
                hoverColor: const Color(0xFF4A86E8),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: _TdsRatesFilterMenuItem(
                  label: option,
                  isSelected: _selectedTdsRatesFilter == option,
                ),
              );
            }).toList(),
          ),
        ),
      ],
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
            final bool isOpen = controller.isOpen;
            return InkWell(
              onTap: () {
                if (isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              borderRadius: BorderRadius.circular(4),
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'All TDS Rates',
                    style: AppTheme.pageTitle.copyWith(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.expand_more,
                    size: 17,
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),
            );
          },
    );
  }

  Widget _buildTdsRateRow(_TdsRateRow row, {required bool showMarkAsInactive}) {
    return _HoverableTdsRateTableRow(
      row: row,
      showMarkAsInactive: showMarkAsInactive,
    );
  }
}

class _HoverableTdsRateTableRow extends StatefulWidget {
  const _HoverableTdsRateTableRow({
    required this.row,
    required this.showMarkAsInactive,
  });

  final _TdsRateRow row;
  final bool showMarkAsInactive;

  @override
  State<_HoverableTdsRateTableRow> createState() =>
      _HoverableTdsRateTableRowState();
}

class _HoverableTdsRateTableRowState extends State<_HoverableTdsRateTableRow> {
  bool _hovered = false;
  bool _menuOpen = false;

  void _setRowActionMenuOpen(bool isOpen) {
    if (!mounted || _menuOpen == isOpen) {
      return;
    }

    setState(() => _menuOpen = isOpen);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF22B378);
      case 'inactive':
        return const Color(0xFF98A2B3);
      default:
        return const Color(0xFFFF6B6B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _TdsRateRow row = widget.row;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF3F4F6) : Colors.white,
          border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 298,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18, right: 14),
                    child: Text(
                      row.taxName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13.4,
                        fontWeight: FontWeight.w600,
                        color: row.isGroup
                            ? AppTheme.accentGreen
                            : AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 82,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Text(
                        row.rate,
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13.1,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF344054),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 154,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 14),
                    child: Text(
                      row.taxType,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13.1,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF344054),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Text(
                      row.status,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13.1,
                        fontWeight: FontWeight.w500,
                        color: _statusColor(row.status),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 42),
              ],
            ),
            Positioned(
              right: 62,
              top: 10,
              child: MenuAnchor(
                onOpen: () => _setRowActionMenuOpen(true),
                onClose: () => _setRowActionMenuOpen(false),
                crossAxisUnconstrained: false,
                alignmentOffset: const Offset(-172, 6),
                style: MenuStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                  surfaceTintColor: WidgetStateProperty.all(Colors.white),
                  elevation: WidgetStateProperty.all(10),
                  padding: WidgetStateProperty.all(EdgeInsets.zero),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                menuChildren: [
                  Container(
                    width: 228,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _TdsRateRowActionMenuItem(
                          icon: LucideIcons.refreshCcw,
                          label: 'View Associated Records',
                        ),
                        const _TdsRateRowActionMenuItem(
                          icon: LucideIcons.edit3,
                          label: 'Edit',
                        ),
                        const _TdsRateRowActionMenuItem(
                          icon: LucideIcons.trash2,
                          label: 'Delete',
                        ),
                        if (widget.showMarkAsInactive)
                          const _TdsRateRowActionMenuItem(
                            icon: LucideIcons.ban,
                            label: 'Mark as Inactive',
                          ),
                      ],
                    ),
                  ),
                ],
                builder:
                    (
                      BuildContext context,
                      MenuController controller,
                      Widget? child,
                    ) {
                      final bool showAction = _hovered || _menuOpen;

                      return IgnorePointer(
                        ignoring: !showAction,
                        child: InkWell(
                          onTap: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 120),
                            opacity: showAction ? 1 : 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22B378),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                LucideIcons.chevronDown,
                                size: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TdsRateRowActionMenuItem extends StatefulWidget {
  const _TdsRateRowActionMenuItem({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  State<_TdsRateRowActionMenuItem> createState() =>
      _TdsRateRowActionMenuItemState();
}

class _TdsRateRowActionMenuItemState extends State<_TdsRateRowActionMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = widget.highlighted || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFF4A86E8) : Colors.white,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 17,
              color: isHighlighted ? Colors.white : const Color(0xFF4A86E8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13.2,
                  fontWeight: FontWeight.w400,
                  color: isHighlighted ? Colors.white : const Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateHeaderCell extends StatelessWidget {
  const _RateHeaderCell({required this.label, required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    final TextAlign textAlign = label == 'RATE (%)'
        ? TextAlign.right
        : TextAlign.left;
    final EdgeInsets padding = EdgeInsets.only(
      left: label == 'TAX NAME'
          ? 18
          : label == 'RATE (%)'
          ? 12
          : 8,
      right: 14,
    );

    return SizedBox(
      width: width,
      child: Padding(
        padding: padding,
        child: Text(
          label,
          textAlign: textAlign,
          style: AppTheme.bodyText.copyWith(
            fontSize: 11.4,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF7B869C),
            letterSpacing: 0.18,
          ),
        ),
      ),
    );
  }
}

class _TdsRatesFilterMenuItem extends StatefulWidget {
  const _TdsRatesFilterMenuItem({
    required this.label,
    required this.isSelected,
  });

  final String label;
  final bool isSelected;

  @override
  State<_TdsRatesFilterMenuItem> createState() =>
      _TdsRatesFilterMenuItemState();
}

class _TdsRatesFilterMenuItemState extends State<_TdsRatesFilterMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isHovered = _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isHovered ? const Color(0xFF4A86E8) : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: isHovered ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderActionDropdownItem extends StatefulWidget {
  const _HeaderActionDropdownItem({required this.label});

  final String label;

  @override
  State<_HeaderActionDropdownItem> createState() =>
      _HeaderActionDropdownItemState();
}

class _HeaderActionDropdownItemState extends State<_HeaderActionDropdownItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isHovered = _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isHovered ? const Color(0xFF4A86E8) : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add,
              size: 15,
              color: isHovered ? Colors.white : AppTheme.primaryBlue,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13.2,
                  fontWeight: FontWeight.w400,
                  color: isHovered ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthYearPickerField extends StatefulWidget {
  const _MonthYearPickerField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  State<_MonthYearPickerField> createState() => _MonthYearPickerFieldState();
}

class _MonthYearPickerFieldState extends State<_MonthYearPickerField> {
  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const Map<String, String> _monthAliases = <String, String>{
    'January': 'Jan',
    'February': 'Feb',
    'March': 'Mar',
    'April': 'Apr',
    'May': 'May',
    'June': 'Jun',
    'July': 'Jul',
    'August': 'Aug',
    'September': 'Sep',
    'October': 'Oct',
    'November': 'Nov',
    'December': 'Dec',
  };

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  int _displayYear = 2026;

  @override
  void initState() {
    super.initState();
    _displayYear = _parseYear(widget.value) ?? 2026;
  }

  @override
  void didUpdateWidget(covariant _MonthYearPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isOpen) {
      _displayYear = _parseYear(widget.value) ?? _displayYear;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  int? _parseYear(String? value) {
    if (value == null || value == 'Month Year') {
      return null;
    }
    final List<String> parts = value.split(' ');
    if (parts.length < 2) {
      return null;
    }
    return int.tryParse(parts.last);
  }

  String? _selectedMonthAbbrev() {
    final String? value = widget.value;
    if (value == null || value == 'Month Year') {
      return null;
    }
    final List<String> parts = value.split(' ');
    if (parts.isEmpty) {
      return null;
    }
    return _monthAliases[parts.first] ?? parts.first;
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final OverlayState? overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Positioned.fill(
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, -238),
                child: _buildOverlayCard(),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted && _isOpen) {
      setState(() => _isOpen = false);
    }
  }

  void _changeYear(int delta) {
    setState(() => _displayYear += delta);
    _overlayEntry?.markNeedsBuild();
  }

  void _selectMonth(String month) {
    widget.onChanged('$month $_displayYear');
    _removeOverlay();
  }

  Widget _buildOverlayCard() {
    final String? selectedMonth = _selectedMonthAbbrev();
    final int? selectedYear = _parseYear(widget.value);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 248,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _changeYear(-1),
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Center(
                              child: Text(
                                '«',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF667085),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$_displayYear',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13.8,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _changeYear(1),
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Center(
                              child: Text(
                                '»',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF667085),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _months.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1.12,
                          ),
                      itemBuilder: (BuildContext context, int index) {
                        final String month = _months[index];
                        final bool isSelected =
                            selectedMonth == month &&
                            selectedYear == _displayYear;

                        return InkWell(
                          onTap: () => _selectMonth(month),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE5E7EB)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              month,
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 12.8,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 14,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 18,
                    child: Center(
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 158,
                    child: Center(
                      child: Container(
                        width: 7,
                        height: 158,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8B8C7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                    child: Center(
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: AppTheme.textMuted,
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

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleOverlay,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 33,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isOpen ? AppTheme.primaryBlue : AppTheme.borderColor,
              width: _isOpen
                  ? AppTheme.inputActiveBorderWidth
                  : AppTheme.inputBorderWidth,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.value ?? 'Month Year',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12.9,
                    fontWeight: FontWeight.w400,
                    color: widget.value == null
                        ? AppTheme.textMuted
                        : const Color(0xFF4B5563),
                  ),
                ),
              ),
              Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewTdsGroupTaxDialog extends StatefulWidget {
  const _NewTdsGroupTaxDialog();

  @override
  State<_NewTdsGroupTaxDialog> createState() => _NewTdsGroupTaxDialogState();
}

class _NewTdsGroupTaxDialogState extends State<_NewTdsGroupTaxDialog> {
  final TextEditingController _groupTaxNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final GlobalKey _startDateKey = GlobalKey();
  final GlobalKey _endDateKey = GlobalKey();
  final Set<String> _selectedRateNames = <String>{};

  DateTime? _startDateValue;
  DateTime? _endDateValue;
  late final List<_GroupTaxSelectableRate> _rateItems;

  static const List<_GroupTaxSelectableRate> _rates = <_GroupTaxSelectableRate>[
    _GroupTaxSelectableRate(
      name: 'althaf 2 demo',
      sectionLabel: 'Section 195',
      rate: '12 %',
    ),
    _GroupTaxSelectableRate(
      name: 'althaf demo',
      sectionLabel: 'Section 195',
      rate: '12 %',
    ),
    _GroupTaxSelectableRate(name: 'Commission or Brokerage', rate: '2 %'),
    _GroupTaxSelectableRate(
      name: 'Commission or Brokerage (Reduced)',
      rate: '3.75 %',
    ),
    _GroupTaxSelectableRate(name: 'Dividend', rate: '10 %'),
    _GroupTaxSelectableRate(name: 'Dividend (Reduced)', rate: '7.5 %'),
    _GroupTaxSelectableRate(
      name: 'Other Interest than securities',
      rate: '10 %',
    ),
    _GroupTaxSelectableRate(
      name: 'Other Interest than securities (Reduced)',
      rate: '7.5 %',
    ),
    _GroupTaxSelectableRate(
      name: 'Payment of contractors for Others',
      rate: '2 %',
    ),
    _GroupTaxSelectableRate(
      name: 'Payment of contractors for Others (Reduced)',
      rate: '1.5 %',
    ),
    _GroupTaxSelectableRate(
      name: 'Payment of contractors HUF/Indiv',
      rate: '1 %',
    ),
    _GroupTaxSelectableRate(
      name: 'Payment of contractors HUF/Indiv (Reduced)',
      rate: '0.75 %',
    ),
    _GroupTaxSelectableRate(name: 'Professional Fees', rate: '10 %'),
    _GroupTaxSelectableRate(name: 'Professional Fees (Reduced)', rate: '7.5 %'),
    _GroupTaxSelectableRate(
      name: 'Rent on land or furniture etc',
      rate: '10 %',
    ),
    _GroupTaxSelectableRate(
      name: 'Rent on land or furniture etc (Reduced)',
      rate: '7.5 %',
    ),
    _GroupTaxSelectableRate(name: 'Technical Fees (2%)', rate: '2 %'),
  ];

  @override
  void initState() {
    super.initState();
    _rateItems = List<_GroupTaxSelectableRate>.from(_rates);
  }

  @override
  void dispose() {
    _groupTaxNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day-$month-$year';
  }

  Future<void> _pickStartDate() async {
    final DateTime initialDate =
        _startDateValue ?? DateTime(DateTime.now().year, 4, 1);
    final DateTime? picked = await ZerpaiDatePicker.show(
      context,
      initialDate: initialDate,
      targetKey: _startDateKey,
      openAbove: true,
    );
    if (picked == null) return;

    setState(() {
      _startDateValue = picked;
      _startDateController.text = _formatDate(picked);
      if (_endDateValue != null && _endDateValue!.isBefore(picked)) {
        _endDateValue = null;
        _endDateController.clear();
      }
    });
  }

  Future<void> _pickEndDate() async {
    final DateTime initialDate =
        _endDateValue ?? _startDateValue ?? DateTime.now();
    final DateTime? picked = await ZerpaiDatePicker.show(
      context,
      initialDate: initialDate,
      firstDate: _startDateValue,
      targetKey: _endDateKey,
      openAbove: true,
    );
    if (picked == null) return;

    setState(() {
      _endDateValue = picked;
      _endDateController.text = _formatDate(picked);
    });
  }

  void _reorderRates(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final _GroupTaxSelectableRate item = _rateItems.removeAt(oldIndex);
      _rateItems.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.of(context).size.height - 28;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 660, maxHeight: maxHeight),
          child: Material(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 24,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildHeader(context),
                const Divider(height: 1, color: AppTheme.borderLight),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabeledField(
                            label: 'TDS Group Tax Name*',
                            child: SizedBox(
                              width: 270,
                              child: CustomTextField(
                                controller: _groupTaxNameController,
                                height: 34,
                                autoFocus: true,
                                forceUppercase: false,
                                contentCase: ContentCase.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Applicable Period',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const ZTooltip(
                                message:
                                    'If this TDS rate is applicable only for a certain period, select the date range during which, users can use this rate in transactions.',
                                direction: ZTooltipDirection.top,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildNeutralLabeledField(
                                  label: 'Start Date',
                                  child: Container(
                                    key: _startDateKey,
                                    child: CustomTextField(
                                      controller: _startDateController,
                                      height: 34,
                                      hintText: 'dd-MM-yyyy',
                                      readOnly: true,
                                      onTap: _pickStartDate,
                                      forceUppercase: false,
                                      contentCase: ContentCase.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 28),
                              Expanded(
                                child: _buildNeutralLabeledField(
                                  label: 'End Date',
                                  child: Container(
                                    key: _endDateKey,
                                    child: CustomTextField(
                                      controller: _endDateController,
                                      height: 34,
                                      hintText: 'dd-MM-yyyy',
                                      readOnly: true,
                                      onTap: _pickEndDate,
                                      forceUppercase: false,
                                      contentCase: ContentCase.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4D8DFF),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'i',
                                    style: AppTheme.bodyText.copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You can create a TDS group tax only using TDSs that fall under section 195.',
                                    style: AppTheme.bodyText.copyWith(
                                      fontSize: 12.8,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text(
                                'Associate TDS Rates*',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 12.8,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.errorRed,
                                ),
                              ),
                              const Spacer(),
                              _buildDragGrip(),
                              const SizedBox(width: 5),
                              Text(
                                'Drag TDS rates to reorder',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 12.3,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF98A2B3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildRatesTable(),
                          const SizedBox(height: 16),
                          Text(
                            'TDS Surcharge*',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.errorRed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No TDS Surcharge Available.',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TDS Cess*',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.errorRed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No TDS Cess Available.',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 36, 18, 18),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: AppTheme.borderLight),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 31,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: Text(
                                      'Save',
                                      style: AppTheme.buttonText.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 31,
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF4B5563),
                                      side: const BorderSide(
                                        color: AppTheme.borderLight,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: AppTheme.buttonText.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF4B5563),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'New TDS Group Tax',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 18, color: Color(0xFFFF5A5A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatesTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        primary: false,
        buildDefaultDragHandles: false,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        onReorder: _reorderRates,
        itemCount: _rateItems.length,
        itemBuilder: (BuildContext context, int index) {
          final _GroupTaxSelectableRate rate = _rateItems[index];
          return _buildRateTableRow(
            rate,
            index,
            index == _rateItems.length - 1,
            key: ValueKey<String>(rate.name),
          );
        },
      ),
    );
  }

  Widget _buildRateTableRow(
    _GroupTaxSelectableRate rate,
    int index,
    bool isLast, {
    required Key key,
  }) {
    return Container(
      key: key,
      height: 34,
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Checkbox(
              value: _selectedRateNames.contains(rate.name),
              onChanged: (bool? value) {
                setState(() {
                  if (value ?? false) {
                    _selectedRateNames.add(rate.name);
                  } else {
                    _selectedRateNames.remove(rate.name);
                  }
                });
              },
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              activeColor: AppTheme.primaryBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppTheme.borderLight)),
              ),
              child: rate.sectionLabel == null
                  ? Text(
                      rate.name,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 12.7,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF4B5563),
                      ),
                    )
                  : RichText(
                      text: TextSpan(
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 12.7,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF4B5563),
                        ),
                        children: [
                          TextSpan(text: rate.name),
                          TextSpan(
                            text: '  (${rate.sectionLabel!})',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12.7,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFFFF6A3D),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          SizedBox(
            width: 96,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  rate.rate,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12.7,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: SizedBox(
                width: 24,
                child: Center(child: _buildDragGrip()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12.8,
            fontWeight: FontWeight.w400,
            color: AppTheme.errorRed,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _buildNeutralLabeledField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12.8,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _buildDragGrip() {
    return SizedBox(
      width: 10,
      height: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(4, (_) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(2, (_) {
                return Container(
                  width: 2,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD1D5DB),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _NewTdsDialog extends StatefulWidget {
  const _NewTdsDialog({required this.title});

  final String title;

  @override
  State<_NewTdsDialog> createState() => _NewTdsDialogState();
}

class _NewTdsDialogState extends State<_NewTdsDialog> {
  final TextEditingController _taxNameController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController(
    text: '01-04-2026',
  );
  final TextEditingController _endDateController = TextEditingController();
  final GlobalKey _startDateKey = GlobalKey();
  final GlobalKey _endDateKey = GlobalKey();

  String? _selectedIncomeTaxAct = 'New Income Tax Act 2025';
  _SectionOption? _selectedSection;
  _HigherTdsReasonOption? _selectedHigherTdsReason;
  String? _selectedTdsPayableAccount;
  String? _selectedTdsReceivableAccount;
  bool _showAccountDropdowns = false;
  bool _isHigherTdsRate = false;
  DateTime _startDateValue = DateTime(2026, 4, 1);
  DateTime? _endDateValue;

  static const List<String> _incomeTaxActOptions = <String>[
    'New Income Tax Act 2025',
    'Income Tax Act 1961',
  ];

  static const List<_HigherTdsReasonOption>
  _higherTdsReasonOptions = <_HigherTdsReasonOption>[
    _HigherTdsReasonOption(
      title: 'Non-furnishing of PAN',
      description:
          'Deduction is on higher rate under section 206AA/397(2)(b)(i) on account of non-furnishing of PAN',
    ),
    _HigherTdsReasonOption(
      title: 'Non-filing of return of income',
      description:
          'Deduction is on higher rate in view of section 206AB for non-filing of return of income',
    ),
    _HigherTdsReasonOption(
      title: 'Invalid PAN details',
      description:
          'Deduction is on higher rate because the PAN details available are invalid or mismatched',
    ),
  ];

  static const List<_SectionOption> _sectionOptions = <_SectionOption>[
    _SectionOption(
      title: 'Section 392 – Indian Government Employees',
      description: 'Payment to Indian Government employees',
      earlier: 'Earlier: 192',
    ),
    _SectionOption(
      title: 'Section 392 – Other Government Employees',
      description: 'Payment to employees other than Government employees',
      earlier: 'Earlier: 192',
    ),
    _SectionOption(
      title: 'Section 392 – Non Union Employees',
      description:
          'Payment to Government employees other than Union Government employees',
      earlier: 'Earlier: 192',
    ),
    _SectionOption(
      title: 'Section 392(7)',
      description: 'Specified salary and payroll-related payments',
      earlier: 'Earlier: 192',
    ),
    _SectionOption(
      title: 'Section 393(1) – Contract Payments – Individual/HUF',
      description: 'Payment to contractors who are Individuals or HUF',
      earlier: 'Earlier: 194C',
    ),
    _SectionOption(
      title: 'Section 393(1) – Contract Payments – Others',
      description: 'Payment to contractors other than Individuals or HUF',
      earlier: 'Earlier: 194C',
    ),
    _SectionOption(
      title: 'Section 393(1) – Professional Fees',
      description: 'Payment of professional fees',
      earlier: 'Earlier: 194J',
    ),
    _SectionOption(
      title: 'Section 393(1) – Technical Fees',
      description: 'Payment of technical fees',
      earlier: 'Earlier: 194J',
    ),
    _SectionOption(
      title: 'Section 393(1) – Director Fees/Commission',
      description: 'Payment of director fees or commission',
      earlier: 'Earlier: 194J',
    ),
    _SectionOption(
      title: 'Section 393(1) – Commission/Brokerage',
      description: 'Payment of commission or brokerage',
      earlier: 'Earlier: 194H',
    ),
    _SectionOption(
      title: 'Section 393(1) – Rent Payments',
      description: 'Payment of rent',
      earlier: 'Earlier: 194I',
    ),
    _SectionOption(
      title: 'Section 393(1) Sl2(i)',
      description: 'Any rent – Individual/HUF',
      earlier: 'Earlier: 194IB',
    ),
    _SectionOption(
      title: 'Section 393(1) Sl2(ii)D(a)',
      description: 'Rent on plant and machinery',
      earlier: 'Earlier: 194I(a)',
    ),
    _SectionOption(
      title: 'Section 393(1) Sl2(ii)D(b)',
      description: 'Rent on land or furniture etc',
      earlier: 'Earlier: 194I(b)',
    ),
    _SectionOption(
      title: 'Section 393(1) – Interest Other Than Securities',
      description: 'Payment of interest other than securities',
      earlier: 'Earlier: 194A',
    ),
    _SectionOption(
      title: 'Section 393(1) – Royalty',
      description: 'Payment of royalty',
      earlier: 'Earlier: 194J',
    ),
    _SectionOption(
      title: 'Section 393(1) – Call Centre Payments',
      description: 'Payment made to call centres',
      earlier: 'Earlier: 194J',
    ),
    _SectionOption(
      title: 'Section 393(2) – Non Resident Interest',
      description: 'Payment of interest to non-residents',
      earlier: 'Earlier: 195',
    ),
    _SectionOption(
      title: 'Section 393(2) – Foreign Company Payments',
      description: 'Payments made to foreign companies',
      earlier: 'Earlier: 195',
    ),
    _SectionOption(
      title: 'Section 393(2) – Long Term Capital Gains',
      description: 'Long term capital gains payments',
      earlier: 'Earlier: 195',
    ),
    _SectionOption(
      title: 'Section 393(2) – Dividend / Bond Income',
      description: 'Dividend or bond income payments',
      earlier: 'Earlier: 195',
    ),
  ];

  bool get _isChargeDialog =>
      widget.title == 'New TDS Surcharge' || widget.title == 'New TDS Cess';

  String get _chargeLabel =>
      widget.title == 'New TDS Cess' ? 'TDS Cess' : 'TDS Surcharge';

  String get _dialogTitle => _isChargeDialog ? 'New TDS' : widget.title;

  Widget _buildAccountDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
    required List<String> items,
    required String heading,
  }) {
    return FormDropdown<String>(
      value: value,
      items: items,
      onChanged: (String? nextValue) {
        if (nextValue == heading) return;
        onChanged(nextValue);
      },
      hint: 'Select an account',
      height: 34,
      showSearch: true,
      showSearchIcon: true,
      allowClear: true,
      clearTooltipMessage: 'Clear the selected option',
      clearTooltipDirection: ZTooltipDirection.top,
      showClearDivider: true,
      showCustomValueAction: false,
      boldSelected: false,
      paintSelectionBackground: false,
      itemBuilder: (String item, bool isSelected, bool isHovered) {
        final bool isHeading = item == heading;

        if (isHeading) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              item,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4B5563),
              ),
            ),
          );
        }

        final Color backgroundColor = isHovered
            ? const Color(0xFF4A86E8)
            : (isSelected ? const Color(0xFFE9EDF5) : Colors.white);
        final Color textColor = isHovered
            ? Colors.white
            : const Color(0xFF4B5563);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    size: 16,
                    color: isHovered ? Colors.white : const Color(0xFF4A86E8),
                  ),
              ],
            ),
          ),
        );
      },
      textStyle: AppTheme.bodyText.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF4B5563),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (_isChargeDialog) {
      _startDateController.clear();
    }
  }

  @override
  void dispose() {
    _taxNameController.dispose();
    _rateController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day-$month-$year';
  }

  Future<void> _pickStartDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: _startDateValue,
      targetKey: _startDateKey,
      openAbove: true,
    );
    if (picked == null) return;

    setState(() {
      _startDateValue = picked;
      _startDateController.text = _formatDate(picked);
      if (_endDateValue != null && _endDateValue!.isBefore(picked)) {
        _endDateValue = null;
        _endDateController.clear();
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: _endDateValue ?? _startDateValue,
      firstDate: _startDateValue,
      targetKey: _endDateKey,
      openAbove: true,
    );
    if (picked == null) return;

    setState(() {
      _endDateValue = picked;
      _endDateController.text = _formatDate(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 670),
          child: Material(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 24,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                const Divider(height: 1, color: AppTheme.borderLight),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildLabeledField(
                                  label: 'Tax Name*',
                                  child: CustomTextField(
                                    controller: _taxNameController,
                                    height: 34,
                                    autoFocus: true,
                                    forceUppercase: false,
                                    contentCase: ContentCase.none,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 26),
                              Expanded(
                                child: _buildLabeledField(
                                  label: 'Rate (%)*',
                                  child: CustomTextField(
                                    controller: _rateController,
                                    height: 34,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    forceUppercase: false,
                                    contentCase: ContentCase.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!_isChargeDialog) ...[
                            const SizedBox(height: 14),
                            _buildLabeledField(
                              label: 'Applicable Income Tax Act',
                              child: SizedBox(
                                width: 302,
                                child: FormDropdown<String>(
                                  value: _selectedIncomeTaxAct,
                                  items: _incomeTaxActOptions,
                                  onChanged: (String? value) {
                                    setState(
                                      () => _selectedIncomeTaxAct = value,
                                    );
                                  },
                                  hint: 'Select Income Tax Act',
                                  height: 34,
                                  showSearch: false,
                                  boldSelected: false,
                                  allowClear: false,
                                  showCustomValueAction: false,
                                  paintSelectionBackground: false,
                                  textStyle: AppTheme.bodyText.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF4B5563),
                                  ),
                                  itemBuilder:
                                      (
                                        String item,
                                        bool isSelected,
                                        bool isHovered,
                                      ) {
                                        return Container(
                                          height: 36,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isHovered
                                                ? const Color(0xFF4A86E8)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            item,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTheme.bodyText.copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: isHovered
                                                  ? Colors.white
                                                  : const Color(0xFF374151),
                                            ),
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildLabeledField(
                              label: 'Section*',
                              child: SizedBox(
                                width: 302,
                                child: FormDropdown<_SectionOption>(
                                  value: _selectedSection,
                                  items: _sectionOptions,
                                  onChanged: (_SectionOption? value) {
                                    setState(() => _selectedSection = value);
                                  },
                                  hint: 'Select a Tax Type.',
                                  height: 34,
                                  showSearch: true,
                                  showSearchIcon: true,
                                  allowClear: false,
                                  showCustomValueAction: false,
                                  menuWidth: 398,
                                  menuMaxHeight: 260,
                                  itemHeight: 74,
                                  itemEstimatedHeight: 74,
                                  displayStringForValue:
                                      (_SectionOption value) => value.title,
                                  searchStringForValue: (_SectionOption value) =>
                                      '${value.title} ${value.description} ${value.earlier}',
                                  textStyle: AppTheme.bodyText.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF4B5563),
                                  ),
                                  itemBuilder:
                                      (
                                        _SectionOption item,
                                        bool isSelected,
                                        bool isHovered,
                                      ) {
                                        final Color textColor = isHovered
                                            ? Colors.white
                                            : const Color(0xFF1F2937);
                                        final Color subTextColor = isHovered
                                            ? Colors.white
                                            : const Color(0xFF667085);

                                        return Container(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            10,
                                            12,
                                            10,
                                          ),
                                          color: Colors.transparent,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.bodyText
                                                    .copyWith(
                                                      fontSize: 12.9,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: textColor,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.bodyText
                                                    .copyWith(
                                                      fontSize: 12.1,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: subTextColor,
                                                      height: 1.25,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.earlier,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.bodyText
                                                    .copyWith(
                                                      fontSize: 11.8,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: subTextColor,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ] else
                            const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.info,
                                    size: 14,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 12.7,
                                        height: 1.5,
                                        color: const Color(0xFF4B5563),
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              'By default, ${_isChargeDialog ? _chargeLabel : 'TDS'} will be tracked under ',
                                        ),
                                        TextSpan(
                                          text: 'TDS Payable',
                                          style: AppTheme.bodyText.copyWith(
                                            fontSize: 12.7,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF374151),
                                          ),
                                        ),
                                        const TextSpan(text: ' and '),
                                        TextSpan(
                                          text: 'TDS Receivable',
                                          style: AppTheme.bodyText.copyWith(
                                            fontSize: 12.7,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF374151),
                                          ),
                                        ),
                                        const TextSpan(
                                          text:
                                              ' accounts. Click Edit to choose an account of your choice. ',
                                        ),
                                        TextSpan(
                                          text: 'Edit',
                                          style: AppTheme.bodyText.copyWith(
                                            fontSize: 12.7,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.primaryBlue,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              setState(() {
                                                _showAccountDropdowns =
                                                    !_showAccountDropdowns;
                                              });
                                            },
                                        ),
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 3,
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _showAccountDropdowns =
                                                      !_showAccountDropdowns;
                                                });
                                              },
                                              child: Icon(
                                                LucideIcons.edit3,
                                                size: 12,
                                                color: AppTheme.primaryBlue,
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
                          if (_showAccountDropdowns) ...[
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildNeutralLabeledField(
                                    label: 'TDS Payable Account',
                                    child: _buildAccountDropdown(
                                      value: _selectedTdsPayableAccount,
                                      items: _directTaxAccountOptions,
                                      heading: _directTaxAccountHeading,
                                      onChanged: (String? value) {
                                        setState(
                                          () => _selectedTdsPayableAccount =
                                              value,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 26),
                                Expanded(
                                  child: _buildNeutralLabeledField(
                                    label: 'TDS Receivable Account',
                                    child: _buildAccountDropdown(
                                      value: _selectedTdsReceivableAccount,
                                      items: _directTaxReceivableAccountOptions,
                                      heading:
                                          _directTaxReceivableAccountHeading,
                                      onChanged: (String? value) {
                                        setState(
                                          () => _selectedTdsReceivableAccount =
                                              value,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (!_isChargeDialog) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Checkbox(
                                    value: _isHigherTdsRate,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _isHigherTdsRate = value ?? false;
                                        if (!_isHigherTdsRate) {
                                          _selectedHigherTdsReason = null;
                                        }
                                      });
                                    },
                                    side: const BorderSide(
                                      color: AppTheme.borderColorDark,
                                    ),
                                    activeColor: AppTheme.primaryBlue,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'This is a Higher TDS Rate',
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const ZTooltip(
                                  message:
                                      "Mark this option if the TDS you're adding is a Higher TDS Rate as mentioned under section 206AB of the Income Tax Act, 1961 effective from 1 July 2021. You'll have to deduct higher TDS rate if you're creating the transaction for a non-filer of Income Tax returns.",
                                  direction: ZTooltipDirection.top,
                                ),
                              ],
                            ),
                            if (_isHigherTdsRate) ...[
                              const SizedBox(height: 16),
                              _buildLabeledField(
                                label: 'Reason for Higher TDS Rate*',
                                child: SizedBox(
                                  width: 302,
                                  child: FormDropdown<_HigherTdsReasonOption>(
                                    value: _selectedHigherTdsReason,
                                    items: _higherTdsReasonOptions,
                                    onChanged: (_HigherTdsReasonOption? value) {
                                      setState(
                                        () => _selectedHigherTdsReason = value,
                                      );
                                    },
                                    hint: '',
                                    height: 34,
                                    showSearch: true,
                                    showSearchIcon: true,
                                    allowClear: false,
                                    showCustomValueAction: false,
                                    boldSelected: false,
                                    menuWidth: 430,
                                    menuMaxHeight: 220,
                                    itemHeight: 74,
                                    itemEstimatedHeight: 74,
                                    displayStringForValue:
                                        (_HigherTdsReasonOption value) =>
                                            value.title,
                                    searchStringForValue:
                                        (_HigherTdsReasonOption value) =>
                                            '${value.title} ${value.description}',
                                    paintSelectionBackground: false,
                                    textStyle: AppTheme.bodyText.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF4B5563),
                                    ),
                                    itemBuilder:
                                        (
                                          _HigherTdsReasonOption item,
                                          bool isSelected,
                                          bool isHovered,
                                        ) {
                                          final Color bgColor = isHovered
                                              ? const Color(0xFF4A86E8)
                                              : Colors.white;
                                          final Color titleColor = isHovered
                                              ? Colors.white
                                              : const Color(0xFF1F2937);
                                          final Color descColor = isHovered
                                              ? Colors.white
                                              : const Color(0xFF667085);

                                          return Container(
                                            padding: const EdgeInsets.fromLTRB(
                                              12,
                                              10,
                                              12,
                                              10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: bgColor,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  item.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTheme.bodyText
                                                      .copyWith(
                                                        fontSize: 12.9,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: titleColor,
                                                      ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  item.description,
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTheme.bodyText
                                                      .copyWith(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: descColor,
                                                        height: 1.25,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                  ),
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Text(
                                'Applicable Period',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const ZTooltip(
                                message:
                                    'If this TDS rate is applicable only for a certain period, select the date range during which, users can use this rate in transactions.',
                                direction: ZTooltipDirection.top,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child:
                                    (_isChargeDialog
                                    ? _buildNeutralLabeledField
                                    : _buildLabeledField)(
                                      label: 'Start Date',
                                      child: Container(
                                        key: _startDateKey,
                                        child: CustomTextField(
                                          controller: _startDateController,
                                          height: 34,
                                          readOnly: true,
                                          onTap: _pickStartDate,
                                          forceUppercase: false,
                                          contentCase: ContentCase.none,
                                          hintText: 'dd-MM-yyyy',
                                          suffixWidget: _isChargeDialog
                                              ? null
                                              : const Icon(
                                                  Icons.calendar_month_outlined,
                                                  size: 16,
                                                  color: AppTheme.textSecondary,
                                                ),
                                        ),
                                      ),
                                    ),
                              ),
                              const SizedBox(width: 26),
                              Expanded(
                                child:
                                    (_isChargeDialog
                                    ? _buildNeutralLabeledField
                                    : _buildLabeledField)(
                                      label: 'End Date',
                                      child: Container(
                                        key: _endDateKey,
                                        child: CustomTextField(
                                          controller: _endDateController,
                                          height: 34,
                                          readOnly: true,
                                          onTap: _pickEndDate,
                                          forceUppercase: false,
                                          contentCase: ContentCase.none,
                                          hintText: 'dd-MM-yyyy',
                                          suffixWidget: _isChargeDialog
                                              ? null
                                              : const Icon(
                                                  Icons.calendar_month_outlined,
                                                  size: 16,
                                                  color: AppTheme.textSecondary,
                                                ),
                                        ),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            'Save',
                            style: AppTheme.buttonText.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 28,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4B5563),
                            side: const BorderSide(color: AppTheme.borderLight),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTheme.buttonText.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4B5563),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _dialogTitle,
              style: AppTheme.pageTitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 18, color: Color(0xFFFF5A5A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12.8,
            fontWeight: FontWeight.w400,
            color: AppTheme.errorRed,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _buildNeutralLabeledField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12.8,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}
