import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/shared/models/account_node.dart';
import 'package:zerpai_erp/shared/theme/app_text_styles.dart';
import 'package:zerpai_erp/shared/widgets/inputs/account_tree_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/modules/settings/taxes/presentation/pages/settings_taxes_overview_page.dart';

class SettingsTaxesSectionRail extends StatelessWidget {
  const SettingsTaxesSectionRail({
    super.key,
    this.width = 300,
    this.selected = 'taxRates',
    this.onSelected,
    this.onGstinCreated,
    this.gstins = const [
      {
        'gstin': '32AACCZ4912F1ZL',
        'state': 'Kerala',
        'legalName': 'ZABNIX PRIVATE LIMITED',
      }
    ],
    this.selectedGstinIndex = 0,
    this.onGstinSelected,
  });

  final double width;
  final String selected;
  final ValueChanged<String>? onSelected;
  final ValueChanged<Map<String, dynamic>>? onGstinCreated;
  final List<Map<String, dynamic>> gstins;
  final int selectedGstinIndex;
  final ValueChanged<int>? onGstinSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: Color(0xFFE6E6E6))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 72,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE6E6E6)),
                ),
              ),
              child: const Text(
                'Taxes',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111111),
                ),
              ),
            ),
            _RailItem(
              label: 'Tax Rates',
              selected: selected == 'taxRates',
              onTap: () => onSelected?.call('taxRates'),
            ),
            _RailItem(
              label: 'Tax Exemptions',
              selected: selected == 'taxExemptions',
              onTap: () => onSelected?.call('taxExemptions'),
            ),
            _RailItem(
              label: 'GST TDS Settings',
              selected: selected == 'gstTds',
              onTap: () => onSelected?.call('gstTds'),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFE6E6E6)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 34, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GST SETTINGS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF888888),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gstins.length,
                    itemBuilder: (context, index) {
                      final item = gstins[index];
                      final isSelected =
                          selected == 'gstSettings' &&
                          selectedGstinIndex == index;
                      return InkWell(
                        onTap: () {
                          onGstinSelected?.call(index);
                          onSelected?.call('gstSettings');
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF7F8FA)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['gstin'] ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  ),
                                  if (item['isActive'] == false) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF64748B),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Text(
                                        'Inactive',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item['state'] ?? 'Kerala',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: Color(0xFF66708C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        barrierColor: Colors.black54,
                        builder: (context) => const _NewGstinDialog(),
                      );
                      if (result != null) {
                        onGstinCreated?.call(result);
                      }
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: Icon(
                              Icons.add,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'New GSTIN',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F6FEB),
                          ),
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
    );
  }
}

class _NewGstinDialog extends StatefulWidget {
  const _NewGstinDialog();

  @override
  State<_NewGstinDialog> createState() => _NewGstinDialogState();
}

class _NewGstinDialogState extends State<_NewGstinDialog> {
  static const List<_RegistrationTypeOption> _registrationTypes = [
    _RegistrationTypeOption(
      label: 'Registered Business - Regular',
      description: 'Business that is registered under GST.',
    ),
    _RegistrationTypeOption(
      label: 'Input Service Distributor (ISD)',
      description:
          'My business distributes input tax credit (ITC) on services to its locations.',
    ),
  ];

  final _gstinController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _tradeNameController = TextEditingController();
  final _registeredOnController = TextEditingController();
  final _registeredOnKey = GlobalKey();
  _RegistrationTypeOption? _registrationType;
  bool _reverseCharge = false;
  bool _importExport = false;
  bool _digitalServices = false;

  final List<AccountDropdownItem> _accountsList = [
    const AccountDropdownItem(name: 'Expense', isHeader: true),
    const AccountDropdownItem(name: 'Janitorial Expense'),
    const AccountDropdownItem(name: 'Interest and Late Fee'),
    const AccountDropdownItem(name: 'Travel Expense'),
    const AccountDropdownItem(name: 'Fuel/Mileage Expenses'),
    const AccountDropdownItem(name: 'Office Supplies'),
    const AccountDropdownItem(name: 'Depreciation Expense'),
    const AccountDropdownItem(name: 'Food Allowance'),
    const AccountDropdownItem(
      name: 'Directors Food Allowance',
      isSubItem: true,
    ),
    const AccountDropdownItem(name: 'Meeting Food Allowance', isSubItem: true),
    const AccountDropdownItem(name: 'Parking'),
    const AccountDropdownItem(name: 'Meals and Entertainment'),
    const AccountDropdownItem(name: 'Contract Assets'),
    const AccountDropdownItem(name: 'Credit Card Charges'),
    const AccountDropdownItem(name: 'Other Expenses'),
    const AccountDropdownItem(name: 'SALARY PAID'),
    const AccountDropdownItem(name: 'Depreciation And Amortisation'),
    const AccountDropdownItem(name: 'Freelancers-Wages'),
    const AccountDropdownItem(name: 'Room Rent Expense'),
    const AccountDropdownItem(name: 'Lodging'),
    const AccountDropdownItem(name: 'Automobile Expense'),
    const AccountDropdownItem(name: 'Bank Fees and Charges'),
    const AccountDropdownItem(name: 'Repairs and Maintenance'),
    const AccountDropdownItem(name: 'Printing and Stationery'),
    const AccountDropdownItem(name: 'Transportation Expense'),
    const AccountDropdownItem(name: 'IT and Internet Expenses'),
    const AccountDropdownItem(name: 'Zoho Book', isSubItem: true),
    const AccountDropdownItem(name: 'Telephone Expense'),
    const AccountDropdownItem(name: 'Purchase Discounts'),
    const AccountDropdownItem(name: 'Advertising And Marketing'),
    const AccountDropdownItem(name: 'Employees Welfare Activities'),
    const AccountDropdownItem(name: 'Consultant Expense'),
    const AccountDropdownItem(name: 'Bad Debt'),
    const AccountDropdownItem(name: 'Merchandise'),
    const AccountDropdownItem(name: 'Bank Chargers'),
    const AccountDropdownItem(
      name: 'Bank Charges Bandhan Bank',
      isSubItem: true,
    ),
    const AccountDropdownItem(name: 'MAB-C', isSubItem: true),
    const AccountDropdownItem(name: 'Bank Charges GST', isSubItem: true),
    const AccountDropdownItem(name: 'Postage'),
    const AccountDropdownItem(name: 'Raw Materials And Consumables'),
    const AccountDropdownItem(name: 'Other Expense', isHeader: true),
    const AccountDropdownItem(name: 'RCM (Rent 18% Tax)'),
    const AccountDropdownItem(name: 'CA & Legal'),
    const AccountDropdownItem(name: 'Utilities'),
    const AccountDropdownItem(name: 'Stay Allowance'),
    const AccountDropdownItem(name: 'Directors Stay Allowance', isSubItem: true),
    const AccountDropdownItem(name: 'Employee Stay Allowance', isSubItem: true),
    const AccountDropdownItem(name: 'Exchange Gain or Loss'),
    const AccountDropdownItem(name: 'Travel Allowance'),
    const AccountDropdownItem(name: 'Directors Travel Allowance', isSubItem: true),
    const AccountDropdownItem(name: 'Employee Travel Allowance', isSubItem: true),
    const AccountDropdownItem(name: 'Domain Charges'),
    const AccountDropdownItem(name: 'Administration'),
    const AccountDropdownItem(name: 'Municipality License Charges', isSubItem: true),
  ];
  AccountDropdownItem? _selectedAccount;

  List<AccountNode> get _accountTreeNodes {
    final groups = <_AccountTreeDraftGroup>[];
    _AccountTreeDraftGroup? currentGroup;
    _AccountTreeDraftNode? currentParent;

    for (final item in _accountsList) {
      if (item.isHeader) {
        currentGroup = _AccountTreeDraftGroup(name: item.name);
        groups.add(currentGroup);
        currentParent = null;
        continue;
      }

      currentGroup ??= _AccountTreeDraftGroup(name: 'Accounts');
      if (groups.isEmpty) {
        groups.add(currentGroup);
      }

      final draftNode = _AccountTreeDraftNode(name: item.name);
      if (item.isSubItem && currentParent != null) {
        currentParent.children.add(draftNode);
      } else {
        currentGroup.children.add(draftNode);
        if (!item.isSubItem) {
          currentParent = draftNode;
        }
      }
    }

    return groups
        .map(
          (group) => AccountNode(
            id: '__account_group__${group.name}',
            name: group.name,
            selectable: false,
            children: group.children.map((node) => node.toAccountNode()).toList(),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _gstinController.dispose();
    _legalNameController.dispose();
    _tradeNameController.dispose();
    _registeredOnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0, bottom: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'New GSTIN',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      color: Color(0xFFFF3333),
                      size: 20,
                    ),
                    splashRadius: 18,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                  child: Column(
                    children: [
                      _formRow(
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ZTooltip(
                              message:
                                  '15 digit number that you receive upon registering for GST',
                              maxWidth: 320,
                              child: Text(
                                'GSTIN*',
                                style: AppTextStyles.labelRequired.copyWith(
                                  fontWeight: FontWeight.normal,
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted,
                                ),
                              ),
                            ),
                            Text(
                              'Maximum 15 digits',
                              style: AppTextStyles.helper.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        field: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 40,
                              child: CustomTextField(
                                controller: _gstinController,
                                hintText: '',
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(15),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: () {
                                showDialog<void>(
                                  context: context,
                                  barrierColor: Colors.black54,
                                  builder: (context) => TaxpayerDetailsDialog(
                                    gstin: _gstinController.text.trim().isEmpty
                                        ? '32AACCZ4912F1ZL'
                                        : _gstinController.text.trim(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Get Taxpayer details',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF1F6FEB),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _formRow(
                        labelText: 'Registration Type',
                        field: SizedBox(
                          height: 42,
                          child: FormDropdown<_RegistrationTypeOption>(
                            value: _registrationType,
                            hint: 'Select a Registration Type',
                            items: _registrationTypes,
                            displayStringForValue: (value) => value.label,
                            searchStringForValue: (value) =>
                                '${value.label} ${value.description}',
                            menuMaxHeight: 240,
                            itemEstimatedHeight: 74,
                            boldSelected: false,
                            itemBuilderWithMenuHover: (
                              item,
                              isSelected,
                              isHovered,
                              isMenuHovered,
                            ) {
                              final isActive =
                                  isHovered || (isSelected && !isMenuHovered);
                              final backgroundColor = isActive
                                  ? const Color(0xFF4285F4)
                                  : isSelected
                                  ? const Color(0xFFE9EEF8)
                                  : Colors.white;
                              final titleColor = isActive
                                  ? Colors.white
                                  : const Color(0xFF2D3748);
                              final descriptionColor = isActive
                                  ? Colors.white
                                  : const Color(0xFF66708C);
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  10,
                                  16,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: titleColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        height: 1.25,
                                        color: descriptionColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onChanged: (value) {
                              setState(() => _registrationType = value);
                            },
                          ),
                        ),
                      ),
                      _formRow(
                        label: _requiredLabel('Business Legal Name*'),
                        field: SizedBox(
                          height: 40,
                          child: CustomTextField(
                            controller: _legalNameController,
                            hintText: '',
                          ),
                        ),
                      ),
                      _formRow(
                        labelText: 'Business Trade Name',
                        field: SizedBox(
                          height: 40,
                          child: CustomTextField(
                            controller: _tradeNameController,
                            hintText: '',
                          ),
                        ),
                      ),
                      _formRow(
                        labelText: 'GST Registered On',
                        field: _datePickerField(
                          controller: _registeredOnController,
                          targetKey: _registeredOnKey,
                        ),
                      ),
                      if (_registrationType?.label != 'Input Service Distributor (ISD)') ...[
                        _formRow(
                          labelText: 'Reverse Charge',
                          labelWidth: 280,
                          field: _checkboxLine(
                            value: _reverseCharge,
                            onChanged: (value) =>
                                setState(() => _reverseCharge = value),
                            text: 'Enable Reverse Charge in Sales transactions',
                          ),
                        ),
                        _formRow(
                          label: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: 1,
                            child: ZTooltip(
                              message:
                                  'Enabling this option would allow you to create Bill of entry for import and shipping bill for export.',
                              maxWidth: 320,
                              child: const Text(
                                'Import / Export',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: Color(0xFF2D3748),
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted,
                                ),
                              ),
                            ),
                          ),
                          labelWidth: 280,
                          field: _checkboxLine(
                            value: _importExport,
                            onChanged: (value) =>
                                setState(() => _importExport = value),
                            text:
                                'My business is involved in SEZ / Overseas Trading',
                          ),
                        ),
                        if (_importExport) ...[
                          _formRow(
                            label: const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Custom Duty Tracking Account*',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: Color(0xFFFF1F1F),
                                ),
                              ),
                            ),
                            field: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 38,
                                  child: AccountTreeDropdown(
                                    value: _selectedAccount?.name,
                                    nodes: _accountTreeNodes,
                                    hint: 'Select an account',
                                    height: 38,
                                    hierarchyBulletMinDepth: 2,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedAccount = value == null
                                            ? null
                                            : _accountsList.firstWhere(
                                                (item) =>
                                                    !item.isHeader &&
                                                    item.name == value,
                                                orElse: () =>
                                                    AccountDropdownItem(name: value),
                                              );
                                      });
                                    },
                                    /*
                                    itemBuilder: (item, isSelected, isHovered) {
                                      if (item.isHeader) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2D3748),
                                            ),
                                          ),
                                        );
                                      }
                                      final double paddingLeft =
                                          item.isSubItem ? 24.0 : 12.0;
                                      final isActive = isHovered;
                                      return Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.fromLTRB(
                                          paddingLeft,
                                          8,
                                          12,
                                          8,
                                        ),
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                          children: [
                                            if (item.isSubItem) ...[
                                              Text(
                                                '• ',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 13,
                                                  color: isActive
                                                      ? Colors.white
                                                      : const Color(0xFF66708C),
                                                ),
                                              ),
                                            ],
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 13,
                                                  color: isActive
                                                      ? Colors.white
                                                      : const Color(0xFF2D3748),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    */
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ],
                        _formRow(
                          labelText: 'Digital Services',
                          labelWidth: 280,
                          field: _checkboxLine(
                            value: _digitalServices,
                            onChanged: (value) =>
                                setState(() => _digitalServices = value),
                            text:
                                'Track sale of digital services to overseas customers',
                            helper: _digitalServices
                                ? 'If you disable this option, any digital service created by you will be considered as a service.'
                                : 'Enabling this option will let you record and track export of digital services to individuals.',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: 74,
              padding: const EdgeInsets.only(left: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  ZButton.primary(
                    onPressed: () {
                      final gstin = _gstinController.text.trim();
                      final legalName = _legalNameController.text.trim();
                      if (gstin.isEmpty || legalName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('GSTIN and Business Legal Name are mandatory.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop({
                        'gstin': gstin,
                        'registrationType': _registrationType,
                        'legalName': legalName,
                        'tradeName': _tradeNameController.text.trim(),
                        'registeredOn': _registeredOnController.text.trim(),
                        'reverseCharge': _reverseCharge,
                        'importExport': _importExport,
                        'selectedAccount': _selectedAccount,
                        'isActive': true,
                      });
                    },
                    label: 'Save',
                  ),
                  const SizedBox(width: 10),
                  ZButton.secondary(
                    onPressed: () => Navigator.of(context).pop(),
                    label: 'Cancel',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formRow({
    Widget? label,
    String? labelText,
    required Widget field,
    double labelWidth = 280,
    double fieldWidth = 248,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: label ??
                Text(
                  labelText ?? '',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF2D3748),
                  ),
                ),
          ),
          SizedBox(width: fieldWidth, child: field),
        ],
      ),
    );
  }

  Widget _requiredLabel(
    String text, {
    String? helper,
    bool hasUnderline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: AppTextStyles.labelRequired.copyWith(
            fontWeight: FontWeight.normal,
            decoration:
                hasUnderline ? TextDecoration.underline : TextDecoration.none,
            decorationStyle: hasUnderline ? TextDecorationStyle.dotted : null,
          ),
        ),
        if (helper != null)
          Text(
            helper,
            style: AppTextStyles.helper.copyWith(fontSize: 13),
          ),
      ],
    );
  }

  Widget _checkboxLine({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String text,
    String? helper,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Transform.scale(
              scale: 0.78,
              child: Checkbox(
                value: value,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: const Color(0xFF1F6FEB),
                side: const BorderSide(color: Color(0xFFC9CDD3)),
                onChanged: (next) => onChanged(next ?? false),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF2D3748),
                  ),
                ),
                if (helper != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    helper,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF66708C),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePickerField({
    required TextEditingController controller,
    required GlobalKey targetKey,
  }) {
    return GestureDetector(
      key: targetKey,
      onTap: () async {
        DateTime initial = DateTime.now();
        try {
          final parts = controller.text.split('-');
          if (parts.length == 3) {
            initial = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        } catch (_) {}

        final picked = await ZerpaiDatePicker.show(
          context,
          initialDate: initial,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          targetKey: targetKey,
        );
        if (picked != null) {
          final formatted =
              "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
          setState(() {
            controller.text = formatted;
          });
        }
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFF3B82F6),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  final text = value.text.isEmpty ? 'dd-MM-yyyy' : value.text;
                  final color = value.text.isEmpty
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF111827);
                  return Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: color,
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

class _RegistrationTypeOption {
  const _RegistrationTypeOption({
    required this.label,
    required this.description,
  });

  final String label;
  final String description;
}

class _AccountTreeDraftGroup {
  _AccountTreeDraftGroup({required this.name});

  final String name;
  final List<_AccountTreeDraftNode> children = [];
}

class _AccountTreeDraftNode {
  _AccountTreeDraftNode({required this.name});

  final String name;
  final List<_AccountTreeDraftNode> children = [];

  AccountNode toAccountNode() {
    return AccountNode(
      id: name,
      name: name,
      children: children.map((child) => child.toAccountNode()).toList(),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4F5F7) : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE6E6E6)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            color: selected ? const Color(0xFF111827) : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}
