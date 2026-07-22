import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
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

const double _vendorDialogWidth = 780.0;
const double _vendorDialogFieldMaxWidth = kRecurringExpenseDialogFieldWidth;
const double _vendorDialogCompositeFieldWidth =
    kRecurringExpenseDialogCompositeFieldWidth;
const double _vendorDialogFieldHeight = kRecurringExpenseCompactFieldHeight;
const double _vendorOpeningBalanceLocationWidth =
    kRecurringExpenseOpeningBalanceLocationWidth;
const double _vendorGstMenuWidth = kRecurringExpenseGstMenuWidth;
const double _vendorGstMenuMaxHeight = kRecurringExpenseGstMenuMaxHeight;
const double _vendorGstOptionHeight = kRecurringExpenseGstOptionHeight;
const double _vendorGstOptionContentHeight =
    kRecurringExpenseGstOptionContentHeight;
const double _vendorBankFieldWidth = 390.0;
const double _vendorBankInfoCardWidth = 444.0;
const List<String> _vendorDialogCurrencyCodes = ['INR', 'USD', 'EUR', 'GBP'];

String _vendorCurrencyLabel(String code) {
  final option = defaultCurrencyOptions.firstWhere((item) => item.code == code);
  return option.label.replaceFirst(' - ', '- ');
}

/// Dialog for creating a new Vendor from within the Recurring Expenses form.
/// Mirrors the Vendor creation popup design from the design spec.
///
/// Returns the created [RecurringExpenseVendorOption] if saved.
class AddVendorDialog extends ConsumerStatefulWidget {
  const AddVendorDialog({super.key});

  static Future<RecurringExpenseVendorOption?> show(BuildContext context) {
    return showGeneralDialog<RecurringExpenseVendorOption>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: AppTheme.textPrimary.withValues(alpha: 0.1),
      pageBuilder: (context, anim1, anim2) {
        return const Align(
          alignment: Alignment.topCenter,
          child: AddVendorDialog(),
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
  ConsumerState<AddVendorDialog> createState() => _AddVendorDialogState();
}

class _VendorBankFormData {
  _VendorBankFormData();

  final accountHolderCtrl = TextEditingController();
  final bankNameCtrl = TextEditingController();
  final accountNumberCtrl = TextEditingController();
  final reEnterAccountNumberCtrl = TextEditingController();
  final ifscCtrl = TextEditingController();
  bool showAccountNumber = false;
  bool showReEnterAccountNumber = false;

  void dispose() {
    accountHolderCtrl.dispose();
    bankNameCtrl.dispose();
    accountNumberCtrl.dispose();
    reEnterAccountNumberCtrl.dispose();
    ifscCtrl.dispose();
  }
}

class _AddVendorDialogState extends ConsumerState<AddVendorDialog> {
  final _formKey = GlobalKey<FormState>();

  // ── Primary Contact ──────────────────────────────────────────────────────
  String? _salutation;
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();

  // ── Display Name ─────────────────────────────────────────────────────────
  String? _selectedDisplayName;

  // ── Contact Details ───────────────────────────────────────────────────────
  final _emailCtrl = TextEditingController();
  final _vendorNumberCtrl = TextEditingController();

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
    'Bank Details',
    'Custom Fields',
    'Reporting Tags',
    'Remarks',
  ];

  // ── Other Details ─────────────────────────────────────────────────────────
  String? _selectedGstTreatment;
  final _gstinUinCtrl = TextEditingController();
  String? _selectedSourceOfSupply;
  final _panCtrl = TextEditingController();
  bool _isMsmeRegistered = false;
  String? _selectedMsmeRegistrationType;
  final _msmeRegistrationNumberCtrl = TextEditingController();
  String? _selectedCurrency = _vendorCurrencyLabel('INR');
  String? _openingBalanceLocation;
  final _openingBalanceCtrl = TextEditingController();
  String? _paymentTerms;
  String? _selectedTds;
  String? _selectedPriceList;
  List<PlatformFile> _uploadedFiles = [];
  bool _showMoreDetails = false;
  final _websiteUrlCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _xProfileCtrl = TextEditingController();
  final _skypeCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  bool _submitted = false;
  bool _isSaving = false;

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

  // ── Bank Details Tab ──────────────────────────────────────────────────────
  bool _showBankForm = false;
  bool _showBankInfoBanner = true;
  final List<_VendorBankFormData> _bankForms = [_VendorBankFormData()];

  // ── Custom Fields Tab ─────────────────────────────────────────────────────
  final _customField1Ctrl = TextEditingController();

  // ── Reporting Tags Tab ────────────────────────────────────────────────────
  String? _reportingTag1;
  String? _reportingTag2;
  String? _reportingTag3;

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
  static const List<String> _tdsOptions = [
    'TDS @ 1%',
    'TDS @ 2%',
    'TDS @ 5%',
    'TDS @ 10%',
  ];
  static const List<String> _priceLists = [
    'Standard Price List',
    'Wholesale Price List',
    'Retail Price List',
  ];
  late final List<String> _currencyOptions = _vendorDialogCurrencyCodes
      .map(_vendorCurrencyLabel)
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
    _vendorNumberCtrl.dispose();
    _workPhoneCtrl.dispose();
    _mobileCtrl.dispose();
    _gstinUinCtrl.dispose();
    _panCtrl.dispose();
    _msmeRegistrationNumberCtrl.dispose();
    _openingBalanceCtrl.dispose();
    _websiteUrlCtrl.dispose();
    _departmentCtrl.dispose();
    _designationCtrl.dispose();
    _xProfileCtrl.dispose();
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
    for (final bank in _bankForms) {
      bank.dispose();
    }
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

  bool get _showVendorGstinUin {
    return switch (_selectedGstTreatment) {
      'Registered Business - Regular' ||
      'Registered Business - Composition' ||
      'Special Economic Zone' ||
      'Deemed Export' ||
      'Tax Deductor' ||
      'SEZ Developer' ||
      'Input Service Distributor' ||
      'Overseas' => true,
      _ => false,
    };
  }

  bool get _gstinUinRequired =>
      _showVendorGstinUin && _selectedGstTreatment != 'Overseas';

  bool get _showVendorSourceOfSupply {
    return switch (_selectedGstTreatment) {
      'Overseas' || 'Out Of Scope' => false,
      _ => true,
    };
  }

  String? get _gstTreatmentError {
    if (!_submitted || _selectedGstTreatment != null) return null;
    return 'Please choose proper GST Treatment.';
  }

  String? get _gstinUinError {
    if (!_submitted || !_gstinUinRequired || _gstinUinCtrl.text.isNotEmpty) {
      return null;
    }
    return 'Please enter GSTIN / UIN.';
  }

  String? get _msmeTypeError {
    if (!_submitted ||
        !_isMsmeRegistered ||
        _selectedMsmeRegistrationType != null) {
      return null;
    }
    return 'Select the MSME/Udyam Registration Type';
  }

  String? get _msmeNumberError {
    if (!_submitted ||
        !_isMsmeRegistered ||
        _msmeRegistrationNumberCtrl.text.trim().isNotEmpty) {
      return null;
    }
    return 'Enter the MSME/Udyam Registration Number';
  }

  Widget _fieldBox(Widget child) {
    return _fieldBoxWithWidth(_vendorDialogFieldMaxWidth, child);
  }

  Widget _fieldBoxWithWidth(double width, Widget child) {
    final compactChild = _usesCompactFieldHeight(child)
        ? SizedBox(height: _vendorDialogFieldHeight, child: child)
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

  Widget _bankFieldBox(Widget child) {
    return _fieldBoxWithWidth(_vendorBankFieldWidth, child);
  }

  Widget _errorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.warning, size: 14, color: AppTheme.errorRed),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vendorGstTreatmentRow(String item, bool isSelected, bool isHovered) {
    return buildRecurringExpenseGstOptionRow(
      item: item,
      isSelected: isSelected,
      isHovered: isHovered,
      height: _vendorGstOptionContentHeight,
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
          _fieldBox(child),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  /// Matches screenshot: plain gray inactive text, dark bold active text,
  /// blue 2px bottom border on active tab only.
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
  Widget _buildOtherDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldRow(
          label: 'GST Treatment',
          required: true,
          child: _fieldBox(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormDropdown<String>(
                  height: _vendorDialogFieldHeight,
                  value: _selectedGstTreatment,
                  items: kRecurringExpenseExtendedGstTreatmentOptions,
                  hint: 'Select a GST treatment',
                  errorText: _gstTreatmentError,
                  menuWidth: _vendorGstMenuWidth,
                  menuMaxHeight: _vendorGstMenuMaxHeight,
                  itemHeight: _vendorGstOptionHeight,
                  itemBuilder: _vendorGstTreatmentRow,
                  onChanged: (v) {
                    setState(() {
                      _selectedGstTreatment = v;
                      if (v == 'Unregistered Business') {
                        _selectedSourceOfSupply = '[KL] - Kerala';
                      } else if (v == 'Overseas' || v == 'Out Of Scope') {
                        _selectedSourceOfSupply = null;
                      }
                    });
                  },
                ),
                if (_gstTreatmentError != null) _errorText(_gstTreatmentError!),
              ],
            ),
          ),
        ),
        if (_showVendorGstinUin)
          _fieldRow(
            label: 'GSTIN / UIN',
            required: _gstinUinRequired,
            tooltipMsg: 'Vendor GSTIN or UIN used for tax validation.',
            crossAxisAlignment: CrossAxisAlignment.start,
            child: _fieldBox(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _gstinUinCtrl,
                    errorText: _gstinUinError,
                    forceUppercase: true,
                    onChanged: (_) => setState(() {}),
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
                  if (_gstinUinError != null) _errorText(_gstinUinError!),
                ],
              ),
            ),
          ),
        if (_showVendorSourceOfSupply)
          _fieldRow(
            label: 'Source of Supply',
            required: true,
            child: _fieldBox(
              FormDropdown<String>(
                height: _vendorDialogFieldHeight,
                value: _selectedSourceOfSupply,
                items: _stateSources,
                hint: 'Select a state',
                onChanged: (v) => setState(() => _selectedSourceOfSupply = v),
              ),
            ),
          ),
        _fieldRow(
          label: 'PAN',
          tooltipMsg: 'Permanent Account Number of the vendor.',
          child: _fieldBox(CustomTextField(controller: _panCtrl, hintText: '')),
        ),
        _fieldRow(
          label: 'MSME Registered?',
          tooltipMsg: 'Check if this vendor is MSME registered.',
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _isMsmeRegistered,
                  onChanged: (v) {
                    setState(() {
                      _isMsmeRegistered = v ?? false;
                      if (!_isMsmeRegistered) {
                        _selectedMsmeRegistrationType = null;
                        _msmeRegistrationNumberCtrl.clear();
                      }
                    });
                  },
                  activeColor: AppTheme.primaryBlueDark,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'This vendor is MSME registered',
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        if (_isMsmeRegistered) ...[
          _fieldRow(
            label: 'MSME/Udyam\nRegistration Type',
            required: true,
            crossAxisAlignment: CrossAxisAlignment.start,
            child: _fieldBox(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormDropdown<String>(
                    height: _vendorDialogFieldHeight,
                    value: _selectedMsmeRegistrationType,
                    items: const ['Micro', 'Small', 'Medium'],
                    hint: 'Select the Registration Type',
                    errorText: _msmeTypeError,
                    menuWidth: _vendorDialogFieldMaxWidth,
                    onChanged: (v) =>
                        setState(() => _selectedMsmeRegistrationType = v),
                  ),
                  if (_msmeTypeError != null) _errorText(_msmeTypeError!),
                ],
              ),
            ),
          ),
          _fieldRow(
            label: 'MSME/Udyam\nRegistration Number',
            required: true,
            tooltipMsg: 'MSME/Udyam registration number of the vendor.',
            crossAxisAlignment: CrossAxisAlignment.start,
            child: _fieldBox(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _msmeRegistrationNumberCtrl,
                    hintText: 'Enter the Registration Number',
                    errorText: _msmeNumberError,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_msmeNumberError != null) _errorText(_msmeNumberError!),
                ],
              ),
            ),
          ),
        ],
        _fieldRow(
          label: 'Currency',
          child: _fieldBox(
            FormDropdown<String>(
              height: _vendorDialogFieldHeight,
              value: _selectedCurrency,
              items: _currencyOptions,
              hint: 'Select currency',
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
                  width: _vendorOpeningBalanceLocationWidth,
                  child: SizedBox(
                    height: _vendorDialogFieldHeight,
                    child: FormDropdown<String>(
                      height: _vendorDialogFieldHeight,
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
                    height: _vendorDialogFieldHeight,
                    hintText: '',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixWidget: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
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
              ],
            ),
          ),
        ),
        _fieldRow(
          label: 'Payment Terms',
          child: _fieldBox(
            FormDropdown<String>(
              height: _vendorDialogFieldHeight,
              value: _paymentTerms,
              items: _paymentTermsOptions,
              hint: 'Select payment terms',
              onChanged: (v) => setState(() => _paymentTerms = v),
            ),
          ),
        ),
        _fieldRow(
          label: 'TDS',
          child: _fieldBox(
            FormDropdown<String>(
              height: _vendorDialogFieldHeight,
              value: _selectedTds,
              items: _tdsOptions,
              hint: 'Select a Tax',
              onChanged: (v) => setState(() => _selectedTds = v),
            ),
          ),
        ),
        _fieldRow(
          label: 'Price List',
          required: true,
          child: _fieldBox(
            FormDropdown<String>(
              height: _vendorDialogFieldHeight,
              value: _selectedPriceList,
              items: _priceLists,
              hint: 'Select a Price List',
              onChanged: (v) => setState(() => _selectedPriceList = v),
            ),
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
                allowedExtensions: const [
                  'pdf',
                  'jpg',
                  'jpeg',
                  'png',
                  'doc',
                  'docx',
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'You can upload a maximum of 10 files, 10MB each',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        if (_showMoreDetails) ...[
          _fieldRow(
            label: 'Website URL',
            child: _fieldBox(
              CustomTextField(
                controller: _websiteUrlCtrl,
                hintText: 'ex: www.zylker.com',
                prefixIcon: Icons.language,
                prefixBox: true,
              ),
            ),
          ),
          _fieldRow(
            label: 'Department',
            child: _fieldBox(CustomTextField(controller: _departmentCtrl)),
          ),
          _fieldRow(
            label: 'Designation',
            child: _fieldBox(CustomTextField(controller: _designationCtrl)),
          ),
          _fieldRow(
            label: 'X',
            crossAxisAlignment: CrossAxisAlignment.start,
            child: _fieldBox(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _xProfileCtrl,
                    prefixBox: true,
                    prefixWidget: const Text(
                      'X',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'https://x.com/',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
          _fieldRow(
            label: 'Skype Name/Number',
            child: _fieldBox(
              CustomTextField(
                controller: _skypeCtrl,
                prefixBox: true,
                prefixWidget: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppTheme.infoBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'S',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.backgroundColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _fieldRow(
            label: 'Facebook',
            crossAxisAlignment: CrossAxisAlignment.start,
            child: _fieldBox(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _facebookCtrl,
                    prefixBox: true,
                    prefixWidget: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppTheme.infoBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'f',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.backgroundColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'http://www.facebook.com/',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 184),
            child: GestureDetector(
              onTap: () => setState(() => _showMoreDetails = true),
              child: const Text(
                'Add more details',
                style: TextStyle(
                  color: AppTheme.infoBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Tab: Address ──────────────────────────────────────────────────────────
  /// Two-column layout: Billing (left) + Shipping (right), matching screenshot.
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
                      height: _vendorDialogFieldHeight,
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
                      height: _vendorDialogFieldHeight,
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
                      height: _vendorDialogFieldHeight,
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
                      height: _vendorDialogFieldHeight,
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Note:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '• Add and manage additional addresses from this Customers and Vendors details section.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              SizedBox(height: 2),
              Text(
                "• You can customise how customers' addresses are displayed in transaction PDFs. To do this, go to Settings > Preferences > Customers and Vendors, and navigate to the Address Format sections.",
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Compact label+field row used inside the Address two-column layout.
  Widget _addressField({
    required String label,
    required Widget child,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          SizedBox(
            width: 108,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  // ── Tab: Bank Details ─────────────────────────────────────────────────────
  /// Shows empty state with "+ Add Bank Account" link.
  /// On click, reveals the bank form fields matching the design screenshot.
  Widget _buildBankDetailsTab() {
    if (!_showBankForm) {
      return SizedBox(
        height: 160,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Add your vendor's bank details and make payments.",
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _showBankForm = true),
              child: const Text(
                '+ Add Bank Account',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.infoBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < _bankForms.length; index++) ...[
          _buildBankSection(index, _bankForms[index]),
          if (index == 0 && _showBankInfoBanner) ...[
            const SizedBox(height: 6),
            _buildBankInfoCard(),
          ],
          if (index < _bankForms.length - 1) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppTheme.borderLight),
            const SizedBox(height: 20),
          ],
        ],
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppTheme.borderLight),
        const SizedBox(height: 16),
        if (_bankForms.length < 9)
          GestureDetector(
            onTap: () {
              setState(() {
                _bankForms.add(_VendorBankFormData());
              });
            },
            child: const Text(
              '+ Add New Bank',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.infoBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBankSection(int index, _VendorBankFormData bank) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'BANK ${index + 1}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            if (index > 0)
              GestureDetector(
                onTap: () {
                  setState(() {
                    final removedBank = _bankForms.removeAt(index);
                    removedBank.dispose();
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      LucideIcons.trash2,
                      size: 14,
                      color: AppTheme.textHint,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Delete',
                      style: TextStyle(fontSize: 12, color: AppTheme.textHint),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _bankFormRow(
          label: 'Account Holder Name',
          child: CustomTextField(
            controller: bank.accountHolderCtrl,
            hintText: '',
          ),
        ),
        _bankFormRow(
          label: 'Bank Name',
          child: CustomTextField(controller: bank.bankNameCtrl, hintText: ''),
        ),
        _bankFormRow(
          label: 'Account Number',
          required: true,
          child: CustomTextField(
            controller: bank.accountNumberCtrl,
            hintText: '',
            obscureText: !bank.showAccountNumber,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              return null;
            },
            suffixWidget: GestureDetector(
              onTap: () {
                setState(() {
                  bank.showAccountNumber = !bank.showAccountNumber;
                });
              },
              child: Icon(
                bank.showAccountNumber ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
        _bankFormRow(
          label: 'Re-enter Account\nNumber',
          required: true,
          crossAxisAlignment: CrossAxisAlignment.start,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: CustomTextField(
              controller: bank.reEnterAccountNumberCtrl,
              hintText: '',
              obscureText: !bank.showReEnterAccountNumber,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim() != bank.accountNumberCtrl.text.trim()) {
                  return 'Account numbers do not match';
                }
                return null;
              },
            ),
          ),
        ),
        _bankFormRow(
          label: 'IFSC',
          required: true,
          child: CustomTextField(
            controller: bank.ifscCtrl,
            hintText: '',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBankInfoCard() {
    return _fieldBoxWithWidth(
      _vendorBankInfoCardWidth,
      Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text('\u{1F4A1}', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    height: 1.6,
                  ),
                  children: [
                    TextSpan(
                      text:
                          'Initiate payments for your purchases directly\n'
                          'from Zoho Books by integrating with one of\n'
                          'our partner banks. ',
                    ),
                    TextSpan(
                      text: 'Set Up Now',
                      style: TextStyle(
                        color: AppTheme.infoBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() => _showBankInfoBanner = false),
              child: const Icon(
                Icons.close,
                size: 18,
                color: AppTheme.errorRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact label+field row for the Bank Details form.
  /// Labels are left-aligned in a fixed 160 px column, optional red asterisk.
  Widget _bankFormRow({
    required String label,
    required Widget child,
    bool required = false,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          SizedBox(
            width: 168,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
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
          ),
          const SizedBox(width: 16),
          _bankFieldBox(child),
        ],
      ),
    );
  }

  // ── Tab: Custom Fields ────────────────────────────────────────────────────
  Widget _buildCustomFieldsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldRow(
          label: 'demo field',
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
        _fieldRow(
          label: 'ADGF',
          child: FormDropdown<String>(
            height: _vendorDialogFieldHeight,
            value: _reportingTag1,
            items: const [],
            hint: 'None',
            onChanged: (v) => setState(() => _reportingTag1 = v),
          ),
        ),
        _fieldRow(
          label: 'shedule',
          child: FormDropdown<String>(
            height: _vendorDialogFieldHeight,
            value: _reportingTag2,
            items: const [],
            hint: 'None',
            onChanged: (v) => setState(() => _reportingTag2 = v),
          ),
        ),
        _fieldRow(
          label: 'demo adavced\nreporting tag',
          crossAxisAlignment: CrossAxisAlignment.start,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: FormDropdown<String>(
              height: _vendorDialogFieldHeight,
              value: _reportingTag3,
              items: const [],
              hint: 'None',
              onChanged: (v) => setState(() => _reportingTag3 = v),
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
            maxLines: 6,
            height: _remarksHeight,
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
      case 'Bank Details':
        tabContent = _buildBankDetailsTab();
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
        width: _vendorDialogWidth,
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
                          'New Vendor',
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
                        // Primary Contact
                        _fieldRow(
                          label: 'Primary Contact',
                          tooltipMsg:
                              'Salutation, First Name, and Last Name of the vendor contact.',
                          child: _fieldBoxWithWidth(
                            _vendorDialogCompositeFieldWidth,
                            Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: FormDropdown<String>(
                                    height: _vendorDialogFieldHeight,
                                    value: _salutation,
                                    // kSalutationOptions from gst_constants - Reusables Rule
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
                              height: _vendorDialogFieldHeight,
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

                        // Vendor Number*
                        _fieldRow(
                          label: 'Vendor Number',
                          required: true,
                          child: _fieldBox(
                            CustomTextField(
                              controller: _vendorNumberCtrl,
                              hintText: 'e.g. VEN-00001',
                              suffixWidget: GestureDetector(
                                onTap: () async {
                                  // Parse current vendor number into prefix + next
                                  final current = _vendorNumberCtrl.text.trim();
                                  String initPrefix = 'VEN-';
                                  String initNext = '02';
                                  if (current.isNotEmpty) {
                                    final match = RegExp(
                                      r'^([A-Za-z\-]+)(\d+)$',
                                    ).firstMatch(current);
                                    if (match != null) {
                                      initPrefix = match.group(1) ?? 'VEN-';
                                      initNext = match.group(2) ?? '02';
                                    }
                                  }
                                  final result =
                                      await NumberPreferencesDialog.show(
                                        context,
                                        entityName: 'Vendor',
                                        initialPrefix: initPrefix,
                                        initialNextNumber: initNext,
                                      );
                                  if (result != null && mounted) {
                                    final padded = result.nextNumber.padLeft(
                                      2,
                                      '0',
                                    );
                                    _vendorNumberCtrl.text =
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
                                  return 'Vendor Number is required';
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
                            _vendorDialogCompositeFieldWidth,
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
                                  setState(() => _submitted = true);
                                  if (!(_formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  if (_gstTreatmentError != null ||
                                      _gstinUinError != null ||
                                      _msmeTypeError != null ||
                                      _msmeNumberError != null) {
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
                                    final billingAddress =
                                        _billingStreet1Ctrl.text
                                                .trim()
                                                .isNotEmpty ||
                                            _billingStreet2Ctrl.text
                                                .trim()
                                                .isNotEmpty ||
                                            _billingCityCtrl.text
                                                .trim()
                                                .isNotEmpty ||
                                            _billingState != null ||
                                            _billingPinCtrl.text
                                                .trim()
                                                .isNotEmpty ||
                                            _billingCountry != null
                                        ? {
                                            'attention': _billingAttentionCtrl
                                                .text
                                                .trim(),
                                            'street1': _billingStreet1Ctrl.text
                                                .trim(),
                                            'street2': _billingStreet2Ctrl.text
                                                .trim(),
                                            'city': _billingCityCtrl.text
                                                .trim(),
                                            'state': _billingState,
                                            'zip': _billingPinCtrl.text.trim(),
                                            'country': _billingCountry,
                                            'phone': _billingPhoneCtrl.text
                                                .trim(),
                                            'fax': _billingFaxCtrl.text.trim(),
                                          }
                                        : null;

                                    final shippingAddress =
                                        _shippingStreet1Ctrl.text
                                                .trim()
                                                .isNotEmpty ||
                                            _shippingStreet2Ctrl.text
                                                .trim()
                                                .isNotEmpty ||
                                            _shippingCityCtrl.text
                                                .trim()
                                                .isNotEmpty ||
                                            _shippingState != null ||
                                            _shippingPinCtrl.text
                                                .trim()
                                                .isNotEmpty ||
                                            _shippingCountry != null
                                        ? {
                                            'attention': _shippingAttentionCtrl
                                                .text
                                                .trim(),
                                            'street1': _shippingStreet1Ctrl.text
                                                .trim(),
                                            'street2': _shippingStreet2Ctrl.text
                                                .trim(),
                                            'city': _shippingCityCtrl.text
                                                .trim(),
                                            'state': _shippingState,
                                            'zip': _shippingPinCtrl.text.trim(),
                                            'country': _shippingCountry,
                                            'phone': _shippingPhoneCtrl.text
                                                .trim(),
                                            'fax': _shippingFaxCtrl.text.trim(),
                                          }
                                        : null;

                                    final bankDetails = _bankForms
                                        .where((bank) {
                                          return bank.accountNumberCtrl.text
                                                  .trim()
                                                  .isNotEmpty ||
                                              bank.bankNameCtrl.text
                                                  .trim()
                                                  .isNotEmpty ||
                                              bank.accountHolderCtrl.text
                                                  .trim()
                                                  .isNotEmpty ||
                                              bank.ifscCtrl.text
                                                  .trim()
                                                  .isNotEmpty;
                                        })
                                        .map((bank) {
                                          return {
                                            'holderName': bank
                                                .accountHolderCtrl
                                                .text
                                                .trim(),
                                            'bankName': bank.bankNameCtrl.text
                                                .trim(),
                                            'accountNumber': bank
                                                .accountNumberCtrl
                                                .text
                                                .trim(),
                                            'ifsc': bank.ifscCtrl.text.trim(),
                                          };
                                        })
                                        .toList();

                                    final vendorData = Vendor(
                                      id: '',
                                      vendorNumber:
                                          _vendorNumberCtrl.text
                                              .trim()
                                              .isNotEmpty
                                          ? _vendorNumberCtrl.text.trim()
                                          : null,
                                      displayName: _selectedDisplayName!.trim(),
                                      salutation: _salutation,
                                      firstName: _firstNameCtrl.text.trim(),
                                      lastName: _lastNameCtrl.text.trim(),
                                      companyName: _companyNameCtrl.text.trim(),
                                      email: _emailCtrl.text.trim(),
                                      phone: _workPhoneCtrl.text.trim(),
                                      mobilePhone: _mobileCtrl.text.trim(),
                                      gstTreatment: _selectedGstTreatment,
                                      gstin: _gstinUinCtrl.text.trim(),
                                      sourceOfSupply: _selectedSourceOfSupply,
                                      pan: _panCtrl.text.trim(),
                                      isMsmeRegistered: _isMsmeRegistered,
                                      msmeRegistrationType:
                                          _selectedMsmeRegistrationType,
                                      msmeRegistrationNumber:
                                          _msmeRegistrationNumberCtrl.text
                                              .trim(),
                                      currency: _selectedCurrency,
                                      paymentTerms: _paymentTerms,
                                      remarks: _remarksCtrl.text.trim(),
                                      billingAddress: billingAddress,
                                      shippingAddress: shippingAddress,
                                      bankDetails: bankDetails,
                                    );

                                    final createdVendor = await ref
                                        .read(vendorProvider.notifier)
                                        .createVendor(vendorData);

                                    if (!mounted) return;

                                    final newVendorOption =
                                        RecurringExpenseVendorOption(
                                          id: createdVendor.id,
                                          displayName:
                                              createdVendor.displayName,
                                          vendorNumber:
                                              createdVendor.vendorNumber,
                                          gstTreatment:
                                              createdVendor.gstTreatment,
                                          sourceOfSupply:
                                              createdVendor.sourceOfSupply,
                                        );

                                    Navigator.pop(context, newVendorOption);
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
