import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/customers/providers/customers_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/shared/constants/gst_constants.dart';
import 'package:zerpai_erp/shared/constants/phone_prefixes.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/phone_input_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/dialogs/number_preferences_dialog.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/models/recurring_expense_lookup_models.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/recurring_expense_form_metrics.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/recurring_expense_gst_option_row.dart';
import 'package:zerpai_erp/shared/widgets/inputs/resizable_box.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';

const double _customerDialogWidth = 780.0;
const double _customerDialogFieldMaxWidth = kRecurringExpenseDialogFieldWidth;
const double _customerDialogCompositeFieldWidth =
    kRecurringExpenseDialogCompositeFieldWidth;
const double _customerDialogFieldHeight = kRecurringExpenseCompactFieldHeight;
const double _customerOpeningBalanceLocationWidth =
    kRecurringExpenseOpeningBalanceLocationWidth;
const double _customerGstMenuMaxHeight = 300.0;
const double _customerGstOptionHeight = kRecurringExpenseGstOptionHeight;
const double _customerGstOptionContentHeight =
    kRecurringExpenseGstOptionContentHeight;
const List<String> _customerDialogCurrencyCodes = ['INR', 'USD', 'EUR', 'GBP'];

String _customerCurrencyLabel(String code) {
  final option = defaultCurrencyOptions.firstWhere((item) => item.code == code);
  return option.label.replaceFirst(' - ', '- ');
}

/// Dialog for creating a new Customer from within the Recurring Expenses form.
/// Mirrors the Customer creation popup design from the design spec.
///
/// Returns the created [RecurringExpenseCustomerOption] if saved.
class AddCustomerDialog extends ConsumerStatefulWidget {
  const AddCustomerDialog({super.key});

  static Future<RecurringExpenseCustomerOption?> show(BuildContext context) {
    return showGeneralDialog<RecurringExpenseCustomerOption>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: AppTheme.textPrimary.withValues(alpha: 0.1),
      pageBuilder: (context, anim1, anim2) {
        return const Align(
          alignment: Alignment.topCenter,
          child: AddCustomerDialog(),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.1),
              end: Offset.zero,
            ).animate(anim1),
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _CustomerReportingTagFieldConfig {
  const _CustomerReportingTagFieldConfig({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // ── Primary Contact ──────────────────────────────────────────────────────
  String _customerType = 'Business';
  String? _salutation;
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();

  // ── Display Name ─────────────────────────────────────────────────────────
  String? _selectedDisplayName;

  // ── Contact Details ───────────────────────────────────────────────────────
  final _emailCtrl = TextEditingController();
  final _customerNumberCtrl = TextEditingController();

  // ── Phone ─────────────────────────────────────────────────────────────────
  String _workPhoneCode = phonePrefixOptions.first;
  final _workPhoneCtrl = TextEditingController();
  String _mobileCode = phonePrefixOptions.first;
  final _mobileCtrl = TextEditingController();

  // ── Tab ───────────────────────────────────────────────────────────────────
  String _selectedTab = 'Other Details';
  static const List<String> _tabs = [
    'Other Details',
    'Address',
    'Custom Fields',
    'Reporting Tags',
    'Remarks',
  ];

  // ── Other Details ─────────────────────────────────────────────────────────
  String? _selectedGstTreatment;
  final _gstinUinCtrl = TextEditingController();
  final _businessLegalNameCtrl = TextEditingController();
  final _businessTradeNameCtrl = TextEditingController();
  String? _selectedSourceOfSupply;
  final _panCtrl = TextEditingController();
  String _taxPreference = 'Taxable';
  String? _selectedCurrency = _customerCurrencyLabel('INR');
  String? _openingBalanceLocation = 'ZABNIX PRIVA...';
  final _openingBalanceCtrl = TextEditingController();
  final _creditLimitCtrl = TextEditingController();
  String? _paymentTerms = 'Net 360';
  String? _selectedPriceList;
  bool _enablePortal = false;
  List<PlatformFile> _uploadedFiles = [];
  bool _showMoreDetails = false;
  final _websiteUrlCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _xCtrl = TextEditingController();
  final _skypeCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();

  // ── Address Tab — Billing ─────────────────────────────────────────────────
  final _billingAttentionCtrl = TextEditingController();
  String? _billingCountry;
  final _billingStreet1Ctrl = TextEditingController();
  final _billingStreet2Ctrl = TextEditingController();
  final _billingCityCtrl = TextEditingController();
  String? _billingState;
  final _billingPinCtrl = TextEditingController();
  String _billingPhoneCode = phonePrefixOptions.first;
  final _billingPhoneCtrl = TextEditingController();
  final _billingFaxCtrl = TextEditingController();

  // ── Address Tab — Shipping ────────────────────────────────────────────────
  final _shippingAttentionCtrl = TextEditingController();
  String? _shippingCountry;
  final _shippingStreet1Ctrl = TextEditingController();
  final _shippingStreet2Ctrl = TextEditingController();
  final _shippingCityCtrl = TextEditingController();
  String? _shippingState;
  final _shippingPinCtrl = TextEditingController();
  String _shippingPhoneCode = phonePrefixOptions.first;
  final _shippingPhoneCtrl = TextEditingController();
  final _shippingFaxCtrl = TextEditingController();

  // ── Custom Fields Tab ─────────────────────────────────────────────────────
  final _customField1Ctrl = TextEditingController();

  // ── Reporting Tags Tab ────────────────────────────────────────────────────
  final Map<String, String?> _selectedReportingTagValues = {};
  final List<_CustomerReportingTagFieldConfig> _reportingTagFields = const [
    _CustomerReportingTagFieldConfig(id: 'adgf', label: 'ADGF'),
    _CustomerReportingTagFieldConfig(id: 'shedule', label: 'shedule'),
    _CustomerReportingTagFieldConfig(
      id: 'demo_reporting_tag',
      label: 'demo adavced reporting tag',
    ),
  ];

  // ── Remarks Tab ───────────────────────────────────────────────────────────
  final _remarksCtrl = TextEditingController();
  double _remarksHeight = 88;

  // ── Static Options ────────────────────────────────────────────────────────
  static const List<String> _paymentTermsOptions = [
    'Due on Receipt',
    'Net 15',
    'Net 30',
    'Net 45',
    'Net 60',
    'Net 90',
    'Net 360',
  ];
  static const List<String> _priceLists = [
    'Standard Price List',
    'Wholesale Price List',
    'Retail Price List',
  ];
  late final List<String> _currencyOptions = _customerDialogCurrencyCodes
      .map(_customerCurrencyLabel)
      .toList(growable: false);
  static const List<String> _locationOptions = [
    'ZABNIX PRIVA...',
    'Head Office',
    'Warehouse A',
  ];
  static const List<String> _countryOptions = [
    'India',
    'United States',
    'United Kingdom',
    'Germany',
    'Australia',
  ];
  static const List<String> _stateOptions = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];
  static const List<String> _stateSources = [
    '[AN] - Andaman and Nicobar Islands',
    '[AP] - Andhra Pradesh',
    '[AR] - Arunachal Pradesh',
    '[AS] - Assam',
    '[BR] - Bihar',
    '[CH] - Chandigarh',
    '[CG] - Chhattisgarh',
    '[DL] - Delhi',
    '[GA] - Goa',
    '[GJ] - Gujarat',
    '[HR] - Haryana',
    '[HP] - Himachal Pradesh',
    '[JK] - Jammu and Kashmir',
    '[JH] - Jharkhand',
    '[KA] - Karnataka',
    '[KL] - Kerala',
    '[LA] - Ladakh',
    '[MP] - Madhya Pradesh',
    '[MH] - Maharashtra',
    '[MN] - Manipur',
    '[ML] - Meghalaya',
    '[MZ] - Mizoram',
    '[NL] - Nagaland',
    '[OD] - Odisha',
    '[PY] - Puducherry',
    '[PB] - Punjab',
    '[RJ] - Rajasthan',
    '[SK] - Sikkim',
    '[TN] - Tamil Nadu',
    '[TG] - Telangana',
    '[TR] - Tripura',
    '[UP] - Uttar Pradesh',
    '[UK] - Uttarakhand',
    '[WB] - West Bengal',
  ];
  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _companyNameCtrl.dispose();
    _emailCtrl.dispose();
    _customerNumberCtrl.dispose();
    _workPhoneCtrl.dispose();
    _mobileCtrl.dispose();
    _gstinUinCtrl.dispose();
    _businessLegalNameCtrl.dispose();
    _businessTradeNameCtrl.dispose();
    _panCtrl.dispose();
    _openingBalanceCtrl.dispose();
    _creditLimitCtrl.dispose();
    _websiteUrlCtrl.dispose();
    _departmentCtrl.dispose();
    _designationCtrl.dispose();
    _xCtrl.dispose();
    _skypeCtrl.dispose();
    _facebookCtrl.dispose();
    _billingAttentionCtrl.dispose();
    _billingStreet1Ctrl.dispose();
    _billingStreet2Ctrl.dispose();
    _billingCityCtrl.dispose();
    _billingPinCtrl.dispose();
    _billingPhoneCtrl.dispose();
    _billingFaxCtrl.dispose();
    _shippingAttentionCtrl.dispose();
    _shippingStreet1Ctrl.dispose();
    _shippingStreet2Ctrl.dispose();
    _shippingCityCtrl.dispose();
    _shippingPinCtrl.dispose();
    _shippingPhoneCtrl.dispose();
    _shippingFaxCtrl.dispose();
    _customField1Ctrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  // ── Display name auto-fill ────────────────────────────────────────────────
  List<String> get _displayNameOptions {
    final f = _firstNameCtrl.text.trim();
    final l = _lastNameCtrl.text.trim();
    final c = _companyNameCtrl.text.trim();
    final opts = <String>{};
    if (f.isNotEmpty || l.isNotEmpty) opts.add('$f $l'.trim());
    if (c.isNotEmpty) opts.add(c);
    if (f.isNotEmpty && l.isNotEmpty) opts.add('$l, $f');
    return opts.toList();
  }

  void _autoFillDisplayName() {
    final opts = _displayNameOptions;
    if (opts.isNotEmpty &&
        (_selectedDisplayName == null ||
            !opts.contains(_selectedDisplayName))) {
      setState(() => _selectedDisplayName = opts.first);
    } else {
      setState(() {});
    }
  }

  void _copyBillingToShipping() {
    setState(() {
      _shippingAttentionCtrl.text = _billingAttentionCtrl.text;
      _shippingCountry = _billingCountry;
      _shippingStreet1Ctrl.text = _billingStreet1Ctrl.text;
      _shippingStreet2Ctrl.text = _billingStreet2Ctrl.text;
      _shippingCityCtrl.text = _billingCityCtrl.text;
      _shippingState = _billingState;
      _shippingPinCtrl.text = _billingPinCtrl.text;
      _shippingPhoneCode = _billingPhoneCode;
      _shippingPhoneCtrl.text = _billingPhoneCtrl.text;
      _shippingFaxCtrl.text = _billingFaxCtrl.text;
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get _showCustomerGstinUin {
    return switch (_selectedGstTreatment) {
      'Registered Business - Regular' ||
      'Registered Business - Composition' ||
      'Special Economic Zone' ||
      'Deemed Export' ||
      'Tax Deductor' ||
      'SEZ Developer' ||
      'Input Service Distributor' => true,
      _ => false,
    };
  }

  bool get _showCustomerBusinessNames => _showCustomerGstinUin;

  bool get _showCustomerPlaceOfSupply {
    return _selectedGstTreatment != 'Overseas';
  }

  bool get _showCustomerTaxPreference {
    return _selectedGstTreatment != 'Overseas';
  }

  Widget _fieldBox(Widget child) {
    return _fieldBoxWithWidth(_customerDialogFieldMaxWidth, child);
  }

  Widget _fieldBoxWithWidth(double width, Widget child) {
    final compactChild = _usesCompactFieldHeight(child)
        ? SizedBox(height: _customerDialogFieldHeight, child: child)
        : child;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: compactChild,
      ),
    );
  }

  bool _usesCompactFieldHeight(Widget child) {
    if (child is CustomTextField) {
      return child.maxLines == null || child.maxLines == 1;
    }
    return child is FormDropdown<String> || child is PhoneInputField;
  }

  Widget _customerGstTreatmentRow(
    String item,
    bool isSelected,
    bool isHovered,
  ) {
    return buildRecurringExpenseGstOptionRow(
      item: item,
      isSelected: isSelected,
      isHovered: isHovered,
      height: _customerGstOptionContentHeight,
    );
  }

  /// Standard label-left / field-right row used in the primary contact section.
  Widget _fieldRow({
    required String label,
    required Widget child,
    bool required = false,
    String? tooltipMsg,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          SizedBox(
            width: 168,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        text: label,
                        style: TextStyle(
                          fontSize: 13,
                          color: required
                              ? AppTheme.errorRed
                              : AppTheme.textSecondary,
                        ),
                        children: required
                            ? const [
                                TextSpan(
                                  text: '*',
                                  style: TextStyle(color: AppTheme.errorRed),
                                ),
                              ]
                            : [],
                      ),
                    ),
                  ),
                  if (tooltipMsg != null) ...[
                    const SizedBox(width: 4),
                    ZTooltip(message: tooltipMsg),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: _tabs.map((tab) {
          final bool isActive = _selectedTab == tab;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tab,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isActive
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 68,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.infoBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Tab: Other Details ────────────────────────────────────────────────────
  Widget _buildCustomerOwnerInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: 'Customer Owner: ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text:
                  'Assign a user as the customer owner to provide access only to the data of this customer. ',
            ),
            TextSpan(
              text: 'Learn More',
              style: TextStyle(color: AppTheme.primaryBlueDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialPrefix(Widget child) {
    return SizedBox(width: 34, child: Center(child: child));
  }

  Widget _buildMoreDetails() {
    if (!_showMoreDetails) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        _fieldRow(
          label: 'Website URL',
          child: CustomTextField(
            controller: _websiteUrlCtrl,
            hintText: 'ex: www.zylker.com',
            keyboardType: TextInputType.url,
            prefixIcon: LucideIcons.globe,
          ),
        ),
        _fieldRow(
          label: 'Department',
          child: CustomTextField(controller: _departmentCtrl, hintText: ''),
        ),
        _fieldRow(
          label: 'Designation',
          child: CustomTextField(controller: _designationCtrl, hintText: ''),
        ),
        _fieldRow(
          label: 'X',
          crossAxisAlignment: CrossAxisAlignment.start,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _xCtrl,
                hintText: '',
                prefixBox: true,
                prefixWidget: _socialPrefix(
                  const Text(
                    'X',
                    style: TextStyle(fontSize: 16, color: AppTheme.textBody),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'https://x.com/',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        _fieldRow(
          label: 'Skype Name/Number',
          child: CustomTextField(
            controller: _skypeCtrl,
            hintText: '',
            prefixBox: true,
            prefixWidget: _socialPrefix(
              const Text(
                'S',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.infoBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        _fieldRow(
          label: 'Facebook',
          crossAxisAlignment: CrossAxisAlignment.start,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _facebookCtrl,
                hintText: '',
                prefixBox: true,
                prefixWidget: _socialPrefix(
                  const Text(
                    'f',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppTheme.infoBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'http://www.facebook.com/',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtherDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldRow(
          label: 'GST Treatment',
          required: true,
          child: _fieldBox(
            FormDropdown<String>(
              height: _customerDialogFieldHeight,
              value: _selectedGstTreatment,
              items: kRecurringExpenseBaseGstTreatmentOptions,
              hint: 'Select a GST treatment',
              menuWidth: _customerDialogFieldMaxWidth,
              menuMaxHeight: _customerGstMenuMaxHeight,
              itemHeight: _customerGstOptionHeight,
              itemBuilder: _customerGstTreatmentRow,
              onChanged: (v) {
                setState(() {
                  _selectedGstTreatment = v;
                  if (v == 'Unregistered Business' || v == 'Consumer') {
                    _selectedSourceOfSupply = '[KL] - Kerala';
                  } else if (v == 'Overseas') {
                    _selectedSourceOfSupply = null;
                  }
                });
              },
            ),
          ),
        ),
        if (_showCustomerGstinUin)
          _fieldRow(
            label: 'GSTIN / UIN',
            required: true,
            tooltipMsg: 'Customer GSTIN or UIN used for tax validation.',
            crossAxisAlignment: CrossAxisAlignment.start,
            child: _fieldBox(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _gstinUinCtrl,
                    hintText: '',
                    forceUppercase: true,
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Validate',
                      style: TextStyle(
                        color: AppTheme.infoBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_showCustomerBusinessNames) ...[
          _fieldRow(
            label: 'Business Legal Name',
            child: _fieldBox(
              CustomTextField(controller: _businessLegalNameCtrl, hintText: ''),
            ),
          ),
          _fieldRow(
            label: 'Business Trade Name',
            child: _fieldBox(
              CustomTextField(controller: _businessTradeNameCtrl, hintText: ''),
            ),
          ),
        ],
        if (_showCustomerPlaceOfSupply)
          _fieldRow(
            label: 'Place of Supply',
            required: true,
            child: _fieldBox(
              FormDropdown<String>(
                height: _customerDialogFieldHeight,
                value: _selectedSourceOfSupply,
                items: _stateSources,
                hint: '',
                onChanged: (v) => setState(() => _selectedSourceOfSupply = v),
              ),
            ),
          ),
        _fieldRow(
          label: 'PAN',
          tooltipMsg: 'Permanent Account Number of the customer.',
          child: _fieldBox(CustomTextField(controller: _panCtrl, hintText: '')),
        ),
        if (_showCustomerTaxPreference)
          _fieldRow(
            label: 'Tax Preference',
            required: true,
            child: ZerpaiRadioGroup<String>(
              options: const ['Taxable', 'Tax Exempt'],
              current: _taxPreference,
              onChanged: (val) {
                setState(() => _taxPreference = val);
              },
            ),
          ),
        _fieldRow(
          label: 'Currency',
          child: _fieldBox(
            FormDropdown<String>(
              height: _customerDialogFieldHeight,
              value: _selectedCurrency,
              items: _currencyOptions,
              hint: 'Currency',
              onChanged: (v) => setState(() => _selectedCurrency = v),
            ),
          ),
        ),
        _fieldRow(
          label: 'Opening Balance',
          child: _fieldBox(
            Row(
              children: [
                SizedBox(
                  width: _customerOpeningBalanceLocationWidth,
                  child: SizedBox(
                    height: _customerDialogFieldHeight,
                    child: FormDropdown<String>(
                      height: _customerDialogFieldHeight,
                      value: _openingBalanceLocation,
                      items: _locationOptions,
                      hint: 'Location',
                      onChanged: (v) =>
                          setState(() => _openingBalanceLocation = v),
                    ),
                  ),
                ),
                const SizedBox(width: 36),
                Expanded(
                  child: CustomTextField(
                    controller: _openingBalanceCtrl,
                    height: _customerDialogFieldHeight,
                    hintText: '',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixBox: true,
                    prefixWidget: Text(
                      _selectedCurrency?.split('-').first.trim() ?? 'INR',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _fieldRow(
          label: 'Credit Limit',
          tooltipMsg: 'Maximum credit amount permitted for this customer.',
          child: _fieldBox(
            CustomTextField(
              controller: _creditLimitCtrl,
              height: _customerDialogFieldHeight,
              hintText: '',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixBox: true,
              prefixWidget: Text(
                _selectedCurrency?.split('-').first.trim() ?? 'INR',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
        _fieldRow(
          label: 'Payment Terms',
          child: _fieldBox(
            FormDropdown<String>(
              height: _customerDialogFieldHeight,
              value: _paymentTerms,
              items: _paymentTermsOptions,
              hint: 'Select Payment Terms',
              onChanged: (v) => setState(() => _paymentTerms = v),
            ),
          ),
        ),
        _fieldRow(
          label: 'Price List',
          required: true,
          child: _fieldBox(
            FormDropdown<String>(
              height: _customerDialogFieldHeight,
              value: _selectedPriceList,
              items: _priceLists,
              hint: '',
              onChanged: (v) => setState(() => _selectedPriceList = v),
            ),
          ),
        ),
        _fieldRow(
          label: 'Enable Portal?',
          tooltipMsg: 'Enable customer portal access.',
          child: Row(
            children: [
              Checkbox(
                value: _enablePortal,
                onChanged: (v) => setState(() => _enablePortal = v ?? false),
                activeColor: AppTheme.primaryBlueDark,
              ),
              const SizedBox(width: 8),
              const Text(
                'Allow portal access for this customer',
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        _fieldRow(
          label: 'Documents',
          crossAxisAlignment: CrossAxisAlignment.start,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FileUploadButton(
                files: _uploadedFiles,
                onFilesChanged: (updated) =>
                    setState(() => _uploadedFiles = updated),
                maxFiles: 10,
                allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
              ),
            ],
          ),
        ),
        if (!_showMoreDetails) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ZerpaiLinkText(
              text: 'Add more details',
              onTap: () {
                setState(() => _showMoreDetails = true);
              },
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
        _buildMoreDetails(),
        _buildCustomerOwnerInfo(),
      ],
    );
  }

  // ── Tab: Address ──────────────────────────────────────────────────────────
  Widget _addressField({
    required String label,
    required Widget child,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildAddressTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Billing Address column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Billing Address',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _addressField(
                    label: 'Attention',
                    child: CustomTextField(
                      controller: _billingAttentionCtrl,
                      hintText: '',
                    ),
                  ),
                  _addressField(
                    label: 'Country/Region',
                    child: FormDropdown<String>(
                      height: _customerDialogFieldHeight,
                      value: _billingCountry,
                      items: _countryOptions,
                      hint: 'Select',
                      onChanged: (v) => setState(() => _billingCountry = v),
                    ),
                  ),
                  _addressField(
                    label: 'Address',
                    crossAxisAlignment: CrossAxisAlignment.start,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _billingStreet1Ctrl,
                          hintText: 'Street 1',
                        ),
                        const SizedBox(height: 6),
                        CustomTextField(
                          controller: _billingStreet2Ctrl,
                          hintText: 'Street 2',
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  _addressField(
                    label: 'City',
                    child: CustomTextField(
                      controller: _billingCityCtrl,
                      hintText: '',
                    ),
                  ),
                  _addressField(
                    label: 'State',
                    child: FormDropdown<String>(
                      height: _customerDialogFieldHeight,
                      value: _billingState,
                      items: _stateOptions,
                      hint: 'Select or type to add',
                      allowCustomValue: true,
                      onChanged: (v) => setState(() => _billingState = v),
                    ),
                  ),
                  _addressField(
                    label: 'Pin Code',
                    child: CustomTextField(
                      controller: _billingPinCtrl,
                      hintText: '',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  _addressField(
                    label: 'Phone',
                    child: PhoneInputField(
                      selectedPrefix: _billingPhoneCode,
                      controller: _billingPhoneCtrl,
                      hintText: '',
                      onPrefixChanged: (v) =>
                          setState(() => _billingPhoneCode = v ?? '+91'),
                    ),
                  ),
                  _addressField(
                    label: 'Fax Number',
                    child: CustomTextField(
                      controller: _billingFaxCtrl,
                      hintText: '',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Shipping Address column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Shipping Address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _copyBillingToShipping,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              '( ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Icon(
                              LucideIcons.arrowDown,
                              size: 12,
                              color: AppTheme.infoBlue,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Copy billing address',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.infoBlue,
                              ),
                            ),
                            SizedBox(width: 2),
                            Text(
                              ')',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _addressField(
                    label: 'Attention',
                    child: CustomTextField(
                      controller: _shippingAttentionCtrl,
                      hintText: '',
                    ),
                  ),
                  _addressField(
                    label: 'Country/Region',
                    child: FormDropdown<String>(
                      height: _customerDialogFieldHeight,
                      value: _shippingCountry,
                      items: _countryOptions,
                      hint: 'Select',
                      onChanged: (v) => setState(() => _shippingCountry = v),
                    ),
                  ),
                  _addressField(
                    label: 'Address',
                    crossAxisAlignment: CrossAxisAlignment.start,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _shippingStreet1Ctrl,
                          hintText: 'Street 1',
                        ),
                        const SizedBox(height: 6),
                        CustomTextField(
                          controller: _shippingStreet2Ctrl,
                          hintText: 'Street 2',
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  _addressField(
                    label: 'City',
                    child: CustomTextField(
                      controller: _shippingCityCtrl,
                      hintText: '',
                    ),
                  ),
                  _addressField(
                    label: 'State',
                    child: FormDropdown<String>(
                      height: _customerDialogFieldHeight,
                      value: _shippingState,
                      items: _stateOptions,
                      hint: 'Select or type to add',
                      allowCustomValue: true,
                      onChanged: (v) => setState(() => _shippingState = v),
                    ),
                  ),
                  _addressField(
                    label: 'Pin Code',
                    child: CustomTextField(
                      controller: _shippingPinCtrl,
                      hintText: '',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  _addressField(
                    label: 'Phone',
                    child: PhoneInputField(
                      selectedPrefix: _shippingPhoneCode,
                      controller: _shippingPhoneCtrl,
                      hintText: '',
                      onPrefixChanged: (v) =>
                          setState(() => _shippingPhoneCode = v ?? '+91'),
                    ),
                  ),
                  _addressField(
                    label: 'Fax Number',
                    child: CustomTextField(
                      controller: _shippingFaxCtrl,
                      hintText: '',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppTheme.warningOrange, // Yellow left accent line
                width: 3,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Note:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Add and manage additional addresses from this Customers and Vendors details section.\n'
                '• You can customise how customers\' addresses are displayed in transaction PDFs. To do this, go to Settings >',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab: Custom Fields ────────────────────────────────────────────────────
  Widget _buildCustomFieldsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldRow(
          label: 'demo feild',
          tooltipMsg: 'This is a custom field configured in settings.',
          child: CustomTextField(controller: _customField1Ctrl, hintText: ''),
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 12),
            children: [
              TextSpan(
                text: 'Note: ',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text:
                    'You can add additional fields for your Customers and Vendors and have these show up on your PDF by going to ',
                style: TextStyle(color: AppTheme.errorRed),
              ),
              TextSpan(
                text: 'Settings',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: ' ➔ ',
                style: TextStyle(color: AppTheme.errorRed),
              ),
              TextSpan(
                text: 'Preferences',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: ' ➔ ',
                style: TextStyle(color: AppTheme.errorRed),
              ),
              TextSpan(
                text: 'Customers and Vendors',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text:
                    '. You can also refine the address format of your Customers and Vendors from there.',
                style: TextStyle(color: AppTheme.errorRed),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab: Reporting Tags ───────────────────────────────────────────────────
  Widget _buildReportingTagsTab() {
    return Column(
      children: [
        for (final field in _reportingTagFields)
          _fieldRow(
            label: field.label.contains('reporting tag')
                ? 'demo adavced\nreporting tag'
                : field.label,
            crossAxisAlignment: field.label.contains('reporting tag')
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            child: field.label.contains('reporting tag')
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _fieldBox(
                      FormDropdown<String>(
                        height: _customerDialogFieldHeight,
                        value: _selectedReportingTagValues[field.id],
                        items: const [],
                        hint: 'None',
                        onChanged: (value) => setState(
                          () => _selectedReportingTagValues[field.id] = value,
                        ),
                      ),
                    ),
                  )
                : _fieldBox(
                    FormDropdown<String>(
                      height: _customerDialogFieldHeight,
                      value: _selectedReportingTagValues[field.id],
                      items: const [],
                      hint: 'None',
                      onChanged: (value) => setState(
                        () => _selectedReportingTagValues[field.id] = value,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }

  // ── Tab: Remarks ──────────────────────────────────────────────────────────
  Widget _buildRemarksTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Remarks (For Internal Use)',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        ResizableBox(
          initialHeight: _remarksHeight,
          minHeight: 88,
          maxHeight: 220,
          onResize: (height) {
            setState(() => _remarksHeight = height);
          },
          child: CustomTextField(
            controller: _remarksCtrl,
            hintText: '',
            maxLines: null,
            height: _remarksHeight,
            minHeight: 88,
            padding: const EdgeInsets.only(
              left: 10,
              top: 10,
              right: 24,
              bottom: 24,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    Widget tabContent;
    switch (_selectedTab) {
      case 'Address':
        tabContent = _buildAddressTab();
        break;
      case 'Custom Fields':
        tabContent = _buildCustomFieldsTab();
        break;
      case 'Reporting Tags':
        tabContent = _buildReportingTagsTab();
        break;
      case 'Remarks':
        tabContent = _buildRemarksTab();
        break;
      case 'Other Details':
      default:
        tabContent = _buildOtherDetails();
        break;
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: _customerDialogWidth,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: screenH - 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'New Customer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderColor),

                // ── Scrollable body ─────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Customer Type
                        _fieldRow(
                          label: 'Customer Type',
                          tooltipMsg:
                              'Select whether the customer is a business or an individual.',
                          child: ZerpaiRadioGroup<String>(
                            options: const ['Business', 'Individual'],
                            current: _customerType,
                            onChanged: (val) {
                              setState(() => _customerType = val);
                            },
                          ),
                        ),

                        // Primary Contact
                        _fieldRow(
                          label: 'Primary Contact',
                          tooltipMsg:
                              'Salutation, First Name, and Last Name of the customer contact.',
                          child: _fieldBoxWithWidth(
                            _customerDialogCompositeFieldWidth,
                            Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: FormDropdown<String>(
                                    height: _customerDialogFieldHeight,
                                    value: _salutation,
                                    items: kSalutationOptions,
                                    hint: 'Salutation',
                                    onChanged: (v) =>
                                        setState(() => _salutation = v),
                                    showSearch: false,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CustomTextField(
                                    controller: _firstNameCtrl,
                                    hintText: 'First Name',
                                    onChanged: (_) => _autoFillDisplayName(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CustomTextField(
                                    controller: _lastNameCtrl,
                                    hintText: 'Last Name',
                                    onChanged: (_) => _autoFillDisplayName(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Company Name
                        _fieldRow(
                          label: 'Company Name',
                          child: _fieldBox(
                            CustomTextField(
                              controller: _companyNameCtrl,
                              hintText: 'Company Name',
                              onChanged: (_) => _autoFillDisplayName(),
                            ),
                          ),
                        ),

                        // Display Name*
                        _fieldRow(
                          label: 'Display Name',
                          required: true,
                          tooltipMsg:
                              'Select a generated name or type a custom one.',
                          child: _fieldBox(
                            FormDropdown<String>(
                              height: _customerDialogFieldHeight,
                              value: _selectedDisplayName,
                              items: _displayNameOptions,
                              hint: 'Select or type to add',
                              allowCustomValue: true,
                              onChanged: (v) =>
                                  setState(() => _selectedDisplayName = v),
                            ),
                          ),
                        ),

                        // Email Address
                        _fieldRow(
                          label: 'Email Address',
                          tooltipMsg:
                              'Primary email for invoices and notifications.',
                          child: _fieldBox(
                            CustomTextField(
                              controller: _emailCtrl,
                              hintText: 'Email Address',
                              prefixIcon: LucideIcons.mail,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ),

                        // Customer Number*
                        _fieldRow(
                          label: 'Customer Number',
                          required: true,
                          child: _fieldBox(
                            CustomTextField(
                              controller: _customerNumberCtrl,
                              hintText: 'e.g. CUST-00001',
                              suffixWidget: GestureDetector(
                                onTap: () async {
                                  final current = _customerNumberCtrl.text
                                      .trim();
                                  String initPrefix = 'CUST-';
                                  String initNext = '02';
                                  if (current.isNotEmpty) {
                                    final match = RegExp(
                                      r'^([A-Za-z\-]+)(\d+)$',
                                    ).firstMatch(current);
                                    if (match != null) {
                                      initPrefix = match.group(1) ?? 'CUST-';
                                      initNext = match.group(2) ?? '02';
                                    }
                                  }
                                  final result =
                                      await NumberPreferencesDialog.show(
                                        context,
                                        entityName: 'Customer',
                                        initialPrefix: initPrefix,
                                        initialNextNumber: initNext,
                                      );
                                  if (result != null && mounted) {
                                    final padded = result.nextNumber.padLeft(
                                      2,
                                      '0',
                                    );
                                    _customerNumberCtrl.text =
                                        '${result.prefix}$padded';
                                  }
                                },
                                child: const Icon(
                                  LucideIcons.settings,
                                  size: 16,
                                  color: AppTheme.primaryBlueDark,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Customer Number is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),

                        // Phone — using reusable PhoneInputField (x2)
                        _fieldRow(
                          label: 'Phone',
                          tooltipMsg: 'Work phone and mobile numbers.',
                          child: _fieldBoxWithWidth(
                            _customerDialogCompositeFieldWidth,
                            Row(
                              children: [
                                Expanded(
                                  child: PhoneInputField(
                                    selectedPrefix: _workPhoneCode,
                                    controller: _workPhoneCtrl,
                                    hintText: 'Work Phone',
                                    onPrefixChanged: (v) => setState(
                                      () => _workPhoneCode = v ?? '+91',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PhoneInputField(
                                    selectedPrefix: _mobileCode,
                                    controller: _mobileCtrl,
                                    hintText: 'Mobile',
                                    onPrefixChanged: (v) => setState(
                                      () => _mobileCode = v ?? '+91',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Tab Bar ────────────────────────────────────────
                        _buildTabBar(),

                        const SizedBox(height: 16),

                        // ── Tab Content ────────────────────────────────────
                        tabContent,
                      ],
                    ),
                  ),
                ),

                // ── Footer ─────────────────────────────────────────────────
                const Divider(height: 1, color: AppTheme.borderColor),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Theme(
                        data: AppTheme.themedWith(AppTheme.successDark),
                        child: ZButton.primary(
                          label: 'Save',
                          loading: _isSaving,
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  if (!(_formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  if (_selectedDisplayName == null ||
                                      _selectedDisplayName!.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter a Display Name',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _isSaving = true;
                                  });

                                  try {
                                    final customerData = SalesCustomer(
                                      id: '',
                                      customerNumber:
                                          _customerNumberCtrl.text
                                              .trim()
                                              .isNotEmpty
                                          ? _customerNumberCtrl.text.trim()
                                          : null,
                                      displayName: _selectedDisplayName!.trim(),
                                      customerType: _customerType,
                                      salutation: _salutation,
                                      firstName: _firstNameCtrl.text.trim(),
                                      lastName: _lastNameCtrl.text.trim(),
                                      companyName: _companyNameCtrl.text.trim(),
                                      email: _emailCtrl.text.trim(),
                                      phone: _workPhoneCtrl.text.trim(),
                                      mobilePhone: _mobileCtrl.text.trim(),
                                      designation: _designationCtrl.text.trim(),
                                      department: _departmentCtrl.text.trim(),
                                      website: _websiteUrlCtrl.text.trim(),
                                      gstTreatment: _selectedGstTreatment,
                                      gstin: _gstinUinCtrl.text.trim(),
                                      placeOfSupply: _selectedSourceOfSupply,
                                      pan: _panCtrl.text.trim(),
                                      taxPreference: _taxPreference,
                                      paymentTerms: _paymentTerms,
                                      priceList: _selectedPriceList,
                                      openingBalance: double.tryParse(
                                        _openingBalanceCtrl.text.trim(),
                                      ),
                                      creditLimit: double.tryParse(
                                        _creditLimitCtrl.text.trim(),
                                      ),
                                      enablePortal: _enablePortal,
                                      facebookHandle: _facebookCtrl.text.trim(),
                                      whatsappNumber: _mobileCtrl.text.trim(),
                                      billingAddressStreet1: _billingStreet1Ctrl
                                          .text
                                          .trim(),
                                      billingAddressStreet2: _billingStreet2Ctrl
                                          .text
                                          .trim(),
                                      billingAddressCity: _billingCityCtrl.text
                                          .trim(),
                                      billingAddressStateId: _billingState,
                                      billingAddressZip: _billingPinCtrl.text
                                          .trim(),
                                      billingAddressCountryId: _billingCountry,
                                      billingAddressPhone: _billingPhoneCtrl
                                          .text
                                          .trim(),
                                      shippingAddressStreet1:
                                          _shippingStreet1Ctrl.text.trim(),
                                      shippingAddressStreet2:
                                          _shippingStreet2Ctrl.text.trim(),
                                      shippingAddressCity: _shippingCityCtrl
                                          .text
                                          .trim(),
                                      shippingAddressStateId: _shippingState,
                                      shippingAddressZip: _shippingPinCtrl.text
                                          .trim(),
                                      shippingAddressCountryId:
                                          _shippingCountry,
                                      shippingAddressPhone: _shippingPhoneCtrl
                                          .text
                                          .trim(),
                                      isActive: true,
                                    );

                                    final createdCustomer = await ref
                                        .read(customersRepositoryProvider)
                                        .createCustomer(customerData);

                                    if (!mounted) return;

                                    final newCustomerOption =
                                        RecurringExpenseCustomerOption(
                                          id: createdCustomer.id,
                                          displayName:
                                              createdCustomer.displayName,
                                          customerNumber:
                                              createdCustomer.customerNumber,
                                          gstTreatment:
                                              createdCustomer.gstTreatment,
                                          placeOfSupply:
                                              createdCustomer.placeOfSupply,
                                        );

                                    Navigator.pop(context, newCustomerOption);
                                  } catch (error) {
                                    if (!mounted) return;
                                    ErrorHandler.showErrorSnackBar(
                                      context,
                                      ErrorHandler.getFriendlyMessage(error),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isSaving = false;
                                      });
                                    }
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ZButton.secondary(
                        label: 'Cancel',
                        onPressed: () => Navigator.pop(context),
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
