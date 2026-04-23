part of '../sales_customer_create.dart';

extension _AddressSection on _SalesCustomerCreateScreenState {
  Widget _buildAddressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildAddressForm('Billing Address')),
          const SizedBox(width: 48),
          Expanded(
            child: _buildAddressForm('Shipping Address', isShipping: true),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressForm(String title, {bool isShipping = false}) {
    final countriesAsync = ref.watch(countriesProvider(null));
    final countries = countriesAsync.value ?? [];

    final countryId = isShipping ? shippingCountryId : billingCountryId;
    final statesAsync = ref.watch(statesProvider(countryId ?? ''));
    final states = statesAsync.value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            if (isShipping) ...[
              const SizedBox(width: 8),
              const Text(
                '(',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_downward,
                size: 14,
                color: AppTheme.primaryBlueDark,
              ),
              const SizedBox(width: 2),
              InkWell(
                onTap: _copyBillingToShipping,
                child: const Text(
                  'Copy billing address',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlueDark,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                ')',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _labeledInlineField(
          'Attention',
          CustomTextField(
            height: _inputHeight,
            controller: isShipping
                ? shippingAttentionCtrl
                : billingAttentionCtrl,
            forceUppercase: false,
          ),
        ),
        _labeledInlineField(
          'Country/Region',
          FormDropdown<Map<String, String>>(
            height: _inputHeight,
            value:
                countries
                    .firstWhere(
                      (c) =>
                          c['id'] ==
                          (isShipping ? shippingCountryId : billingCountryId),
                      orElse: () => {},
                    )
                    .isEmpty
                ? null
                : countries.firstWhere(
                    (c) =>
                        c['id'] ==
                        (isShipping ? shippingCountryId : billingCountryId),
                  ),
            hint: 'Select',
            items: countries,
            displayStringForValue: (c) => c['name'] ?? '',
            onChanged: (v) {
              _state(() {
                if (isShipping) {
                  shippingCountryId = v?['id'];
                  shippingStateId = null;
                } else {
                  billingCountryId = v?['id'];
                  billingStateId = null;
                }
              });
            },
          ),
        ),
        _labeledInlineField(
          'Address',
          CustomTextField(
            height: _inputHeight,
            controller: isShipping ? shippingStreetCtrl : billingStreetCtrl,
            hintText: 'Street 1',
            forceUppercase: false,
          ),
        ),
        _labeledInlineField(
          '',
          CustomTextField(
            height: _inputHeight,
            controller: isShipping ? shippingStreet2Ctrl : billingStreet2Ctrl,
            hintText: 'Street 2',
            forceUppercase: false,
          ),
        ),
        _labeledInlineField(
          'City',
          CustomTextField(
            height: _inputHeight,
            controller: isShipping ? shippingCityCtrl : billingCityCtrl,
            forceUppercase: false,
          ),
        ),
        _labeledInlineField(
          'State',
          FormDropdown<Map<String, String>>(
            height: _inputHeight,
            value:
                states
                    .firstWhere(
                      (s) =>
                          s['id'] ==
                          (isShipping ? shippingStateId : billingStateId),
                      orElse: () => {},
                    )
                    .isEmpty
                ? null
                : states.firstWhere(
                    (s) =>
                        s['id'] ==
                        (isShipping ? shippingStateId : billingStateId),
                  ),
            hint: 'Select or type to add',
            items: states,
            displayStringForValue: (s) => s['name'] ?? '',
            onChanged: (v) {
              _state(() {
                if (isShipping) {
                  shippingStateId = v?['id'];
                } else {
                  billingStateId = v?['id'];
                }
              });
            },
            allowCustomValue: true,
          ),
        ),
        _labeledInlineField(
          'Pin Code',
          CustomTextField(
            height: _inputHeight,
            controller: isShipping ? shippingPinCtrl : billingPinCtrl,
            forceUppercase: false,
          ),
        ),
        _labeledInlineField(
          'Phone',
          PhoneInputField(
            controller: isShipping ? shippingPhoneCtrl : billingPhoneCtrl,
            selectedPrefix: isShipping ? shippingPhoneCode : billingPhoneCode,
            onPrefixChanged: (v) => _state(() {
              if (isShipping) {
                shippingPhoneCode = v ?? '+91';
              } else {
                billingPhoneCode = v ?? '+91';
              }
            }),
            hintText: 'Phone',
          ),
        ),
        _labeledInlineField(
          'Fax Number',
          CustomTextField(
            height: _inputHeight,
            controller: isShipping ? shippingFaxCtrl : billingFaxCtrl,
            forceUppercase: false,
          ),
        ),
      ],
    );
  }

  void _copyBillingToShipping() {
    _state(() {
      shippingAttentionCtrl.text = billingAttentionCtrl.text;
      shippingCountryId = billingCountryId;
      shippingStreetCtrl.text = billingStreetCtrl.text;
      shippingStreet2Ctrl.text = billingStreet2Ctrl.text;
      shippingCityCtrl.text = billingCityCtrl.text;
      shippingStateId = billingStateId;
      shippingPinCtrl.text = billingPinCtrl.text;
      shippingPhoneCode = billingPhoneCode;
      shippingPhoneCtrl.text = billingPhoneCtrl.text;
      shippingFaxCtrl.text = billingFaxCtrl.text;
    });
  }
}
