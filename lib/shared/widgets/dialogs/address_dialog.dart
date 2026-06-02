import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';

const _kBlue = Color(0xFF2563EB);
const _kBodyText = Color(0xFF1F2937);
const _kBorder = Color(0xFFE5E7EB);
const _kLabelGrey = Color(0xFF4B5563);
const _kGreen = Color(0xFF10B981);

class AddressDialog extends ConsumerStatefulWidget {
  final String title;
  final Map<String, dynamic> initialAddress;
  final ValueChanged<Map<String, dynamic>> onSave;

  const AddressDialog({
    super.key,
    required this.title,
    required this.initialAddress,
    required this.onSave,
  });

  @override
  ConsumerState<AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends ConsumerState<AddressDialog> {
  final _companyNameCtrl = TextEditingController();
  final _attentionCtrl = TextEditingController();
  final _street1Ctrl = TextEditingController();
  final _street2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _faxCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  Map<String, String>? _selectedCountry;
  Map<String, String>? _selectedState;
  String _phoneCode = '+91';

  static const _phoneCodes = [
    '+91',
    '+1',
    '+44',
    '+971',
    '+61',
    '+1-CA',
    '+65',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialAddress;
    _companyNameCtrl.text = (init['companyName'] ?? init['company_name'] ?? '').toString();
    _attentionCtrl.text = (init['attention'] ?? init['billingAttention'] ?? init['shippingAttention'] ?? '').toString();
    _street1Ctrl.text = (init['street1'] ?? init['billingAddressStreet'] ?? init['shippingAddressStreet'] ?? '').toString();
    _street2Ctrl.text = (init['street2'] ?? init['billingAddressPlace'] ?? init['shippingAddressPlace'] ?? '').toString();
    _cityCtrl.text = (init['city'] ?? init['billingAddressCity'] ?? init['shippingAddressCity'] ?? init['billingCity'] ?? init['shippingCity'] ?? '').toString();
    _pinCtrl.text = (init['zip'] ?? init['pincode'] ?? init['billingAddressZip'] ?? init['shippingAddressZip'] ?? init['billingPincode'] ?? init['shippingPincode'] ?? '').toString();
    _faxCtrl.text = (init['fax'] ?? init['billingFax'] ?? init['shippingFax'] ?? '').toString();

    // Parse phone and phoneCode
    final rawPhone = (init['phone'] ?? init['billingAddressPhone'] ?? init['shippingAddressPhone'] ?? init['billingPhone'] ?? init['shippingPhone'] ?? '').toString().trim();
    String parsedPhone = rawPhone;
    for (final code in _phoneCodes) {
      if (rawPhone.startsWith(code)) {
        _phoneCode = code;
        parsedPhone = rawPhone.substring(code.length).trim();
        break;
      }
    }
    _phoneCtrl.text = parsedPhone;
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _attentionCtrl.dispose();
    _street1Ctrl.dispose();
    _street2Ctrl.dispose();
    _cityCtrl.dispose();
    _pinCtrl.dispose();
    _faxCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDec({String? hint, bool multiline = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), fontFamily: 'Inter'),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: multiline ? 10 : 9,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: _kBlue),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _kBodyText,
        fontFamily: 'Inter',
      ),
    ),
  );

  Widget _dropdownItemBuilder(
    String label,
    bool isSelected,
    bool isHovered,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHovered
            ? const Color(0xFF3B82F6)
            : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'Inter',
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          color: isHovered ? Colors.white : const Color(0xFF1F2937),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialogTitle = widget.title.contains('BILLING')
        ? 'Billing Address'
        : widget.title.contains('SHIPPING')
        ? 'Shipping Address'
        : widget.title;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 680),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                  child: Row(
                    children: [
                      Text(
                        dialogTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _kBodyText,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _kBorder),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dialogTitle == 'Drop Shipping Address') ...[
                          _label('Company Name'),
                          TextField(
                            controller: _companyNameCtrl,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _kBodyText,
                              fontFamily: 'Inter',
                            ),
                            decoration: _inputDec(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _label('Attention'),
                        TextField(
                          controller: _attentionCtrl,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kBodyText,
                            fontFamily: 'Inter',
                          ),
                          decoration: _inputDec(),
                        ),
                        const SizedBox(height: 16),
                        _label('Country/Region'),
                        Builder(
                          builder: (context) {
                            final countriesAsync = ref.watch(
                              countriesProvider(null),
                            );
                            final countries = countriesAsync.value ?? [];
                            if (_selectedCountry == null && countries.isNotEmpty) {
                              final initialCountryId = widget.initialAddress['country'] ?? widget.initialAddress['country_id'] ?? widget.initialAddress['billingAddressCountry'] ?? widget.initialAddress['shippingAddressCountry'] ?? widget.initialAddress['billingCountryRegion'] ?? widget.initialAddress['shippingCountryRegion'];
                              if (initialCountryId != null && initialCountryId.toString().isNotEmpty) {
                                final initialStr = initialCountryId.toString().toLowerCase();
                                final found = countries.firstWhere(
                                  (c) => c['id'] == initialCountryId ||
                                      c['shortCode'] == initialCountryId ||
                                      c['name']?.toString().toLowerCase() == initialStr ||
                                      c['shortCode']?.toString().toLowerCase() == initialStr,
                                  orElse: () => <String, String>{},
                                );
                                if (found.isNotEmpty) {
                                  _selectedCountry = found;
                                }
                              }
                            }
                            return FormDropdown<Map<String, String>>(
                              height: 32,
                              value: _selectedCountry,
                              hint: 'Select',
                              isLoading: countriesAsync.isLoading,
                              items: countries,
                              displayStringForValue: (c) => c['name'] ?? '',
                              itemBuilder: (c, isSelected, isHovered) =>
                                  _dropdownItemBuilder(
                                    c['name'] ?? '',
                                    isSelected,
                                    isHovered,
                                  ),
                              onChanged: (v) {
                                setState(() {
                                  _selectedCountry = v;
                                  _selectedState = null;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _label('Address'),
                        TextField(
                          controller: _street1Ctrl,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kBodyText,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 2,
                          minLines: 2,
                          decoration: _inputDec(
                            hint: 'Street 1',
                            multiline: true,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _street2Ctrl,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kBodyText,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 2,
                          minLines: 2,
                          decoration: _inputDec(
                            hint: 'Street 2',
                            multiline: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label('City'),
                        TextField(
                          controller: _cityCtrl,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kBodyText,
                            fontFamily: 'Inter',
                          ),
                          decoration: _inputDec(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('State'),
                                  Builder(
                                    builder: (context) {
                                      final countryId =
                                          _selectedCountry?['id'] ?? '';
                                      final statesAsync = ref.watch(
                                        statesProvider(countryId),
                                      );
                                      final states = statesAsync.value ?? [];
                                      if (_selectedState == null && states.isNotEmpty) {
                                        final initialStateId = widget.initialAddress['state'] ?? widget.initialAddress['state_id'] ?? widget.initialAddress['billingAddressState'] ?? widget.initialAddress['shippingAddressState'] ?? widget.initialAddress['billingState'] ?? widget.initialAddress['shippingState'];
                                        if (initialStateId != null && initialStateId.toString().isNotEmpty) {
                                          final initialStr = initialStateId.toString().toLowerCase();
                                          final found = states.firstWhere(
                                            (s) => s['id'] == initialStateId ||
                                                s['code'] == initialStateId ||
                                                s['name']?.toString().toLowerCase() == initialStr ||
                                                s['code']?.toString().toLowerCase() == initialStr,
                                            orElse: () => <String, String>{},
                                          );
                                          if (found.isNotEmpty) {
                                            _selectedState = found;
                                          }
                                        }
                                      }
                                      return FormDropdown<Map<String, String>>(
                                        height: 32,
                                        value: _selectedState,
                                        hint: 'Select or type to add',
                                        isLoading: statesAsync.isLoading,
                                        items: states,
                                        displayStringForValue: (s) =>
                                            s['name'] ?? '',
                                        itemBuilder:
                                            (s, isSelected, isHovered) =>
                                                _dropdownItemBuilder(
                                                  s['name'] ?? '',
                                                  isSelected,
                                                  isHovered,
                                                ),
                                        onChanged: (v) =>
                                            setState(() => _selectedState = v),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Pin Code'),
                                  TextField(
                                    controller: _pinCtrl,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _kBodyText,
                                      fontFamily: 'Inter',
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                    decoration: _inputDec(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Phone'),
                                  Row(
                                    children: [
                                      Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFFD1D5DB),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _phoneCode,
                                            isDense: true,
                                            alignment: Alignment.center,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Inter',
                                              color: _kBodyText,
                                            ),
                                            items: _phoneCodes
                                                .map(
                                                  (c) => DropdownMenuItem(
                                                    value: c,
                                                    alignment: Alignment.center,
                                                    child: Text(c),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (v) =>
                                                setState(() => _phoneCode = v!),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextField(
                                          controller: _phoneCtrl,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: _kBodyText,
                                            fontFamily: 'Inter',
                                          ),
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(10),
                                          ],
                                          decoration: _inputDec(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Fax Number'),
                                  TextField(
                                    controller: _faxCtrl,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _kBodyText,
                                      fontFamily: 'Inter',
                                    ),
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDec(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 12, fontFamily: 'Inter'),
                            children: [
                              const TextSpan(
                                text: 'Note: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _kBodyText,
                                ),
                              ),
                              TextSpan(
                                text:
                                    'Changes made here will be updated for this ${widget.title.toLowerCase().contains('warehouse') ? 'warehouse' : 'entity'}.',
                                style: const TextStyle(color: _kLabelGrey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: _kBorder),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () {
                          widget.onSave({
                            'companyName': _companyNameCtrl.text.trim(),
                            'attention': _attentionCtrl.text.trim(),
                            'street1': _street1Ctrl.text.trim(),
                            'street2': _street2Ctrl.text.trim(),
                            'city': _cityCtrl.text.trim(),
                            'zip': _pinCtrl.text.trim(),
                            'phone': '$_phoneCode ${_phoneCtrl.text.trim()}'.trim(),
                            'phoneCode': _phoneCode,
                            'fax': _faxCtrl.text.trim(),
                            'country': _selectedCountry?['id'],
                            'countryName': _selectedCountry?['name'],
                            'state': _selectedState?['id'],
                            'stateName': _selectedState?['name'],
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kBodyText,
                          side: const BorderSide(color: _kBorder),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 13, fontFamily: 'Inter'),
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
