part of '../sales_customer_create.dart';

extension _AddressSection on _SalesCustomerCreateScreenState {
  Widget _buildAddressSection() {
    final countriesAsync = ref.watch(countriesProvider(null));
    final billingStatesAsync = ref.watch(
      statesProvider(billingCountryId ?? ''),
    );
    final shippingStatesAsync = ref.watch(
      statesProvider(shippingCountryId ?? ''),
    );

    final countries = countriesAsync.value ?? [];
    final billingStates = billingStatesAsync.value ?? [];
    final shippingStates = shippingStatesAsync.value ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BILLING ADDRESS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlueDark,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
                _labeledInlineField(
                  'Attention',
                  CustomTextField(
                    height: _inputHeight,
                    controller: billingAttentionCtrl,
                    forceUppercase: false,
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'Country / Region',
                  FormDropdown<Map<String, String>>(
                    height: _inputHeight,
                    value:
                        countries
                            .firstWhere(
                              (c) => c['id'] == billingCountryId,
                              orElse: () => {},
                            )
                            .isEmpty
                        ? null
                        : countries.firstWhere(
                            (c) => c['id'] == billingCountryId,
                          ),
                    hint: 'Select',
                    items: countries,
                    displayStringForValue: (c) => c['name'] ?? '',
                    onChanged: (v) {
                      _state(() {
                        billingCountryId = v?['id'];
                        // Reset state when country changes
                        billingStateId = null;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'Street 1',
                  CustomTextField(
                    height: _inputHeight,
                    controller: billingStreetCtrl,
                    forceUppercase: false,
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'Street 2',
                  CustomTextField(
                    height: _inputHeight,
                    controller: billingStreet2Ctrl,
                    forceUppercase: false,
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'City',
                  CustomTextField(
                    height: _inputHeight,
                    controller: billingCityCtrl,
                    forceUppercase: false,
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'State',
                  FormDropdown<Map<String, String>>(
                    height: _inputHeight,
                    value:
                        billingStates
                            .firstWhere(
                              (s) => s['id'] == billingStateId,
                              orElse: () => {},
                            )
                            .isEmpty
                        ? null
                        : billingStates.firstWhere(
                            (s) => s['id'] == billingStateId,
                          ),
                    hint: 'Select or type to add',
                    items: billingStates,
                    displayStringForValue: (s) => s['name'] ?? '',
                    onChanged: (v) {
                      _state(() {
                        billingStateId = v?['id'];
                      });
                    },
                    allowCustomValue: true,
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'Zip Code',
                  CustomTextField(
                    height: _inputHeight,
                    controller: billingPinCtrl,
                    forceUppercase: false,
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'Phone',
                  _buildPhoneRow(
                    code: billingPhoneCode,
                    onCodeChanged: (v) => _state(() => billingPhoneCode = v),
                    controller: billingPhoneCtrl,
                    hintText: 'Phone',
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'Fax',
                  CustomTextField(
                    height: _inputHeight,
                    controller: billingFaxCtrl,
                    forceUppercase: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SHIPPING ADDRESS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlueDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _copyBillingToShipping,
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy billing address'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _labeledInlineField(
                  'Attention',
                  CustomTextField(
                    height: _inputHeight,
                    controller: shippingAttentionCtrl,
                    forceUppercase: false,
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'Country / Region',
                  FormDropdown<Map<String, String>>(
                    height: _inputHeight,
                    value:
                        countries
                            .firstWhere(
                              (c) => c['id'] == shippingCountryId,
                              orElse: () => {},
                            )
                            .isEmpty
                        ? null
                        : countries.firstWhere(
                            (c) => c['id'] == shippingCountryId,
                          ),
                    hint: 'Select',
                    items: countries,
                    displayStringForValue: (c) => c['name'] ?? '',
                    onChanged: (v) {
                      _state(() {
                        shippingCountryId = v?['id'];
                        // Reset state when country changes
                        shippingStateId = null;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'Street 1',
                  CustomTextField(
                    height: _inputHeight,
                    controller: shippingStreetCtrl,
                    forceUppercase: false,
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'Street 2',
                  CustomTextField(
                    height: _inputHeight,
                    controller: shippingStreet2Ctrl,
                    forceUppercase: false,
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'City',
                  CustomTextField(
                    height: _inputHeight,
                    controller: shippingCityCtrl,
                    forceUppercase: false,
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'State',
                  FormDropdown<Map<String, String>>(
                    height: _inputHeight,
                    value:
                        shippingStates
                            .firstWhere(
                              (s) => s['id'] == shippingStateId,
                              orElse: () => {},
                            )
                            .isEmpty
                        ? null
                        : shippingStates.firstWhere(
                            (s) => s['id'] == shippingStateId,
                          ),
                    hint: 'Select or type to add',
                    items: shippingStates,
                    displayStringForValue: (s) => s['name'] ?? '',
                    onChanged: (v) {
                      _state(() {
                        shippingStateId = v?['id'];
                      });
                    },
                    allowCustomValue: true,
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'Zip Code',
                  CustomTextField(
                    height: _inputHeight,
                    controller: shippingPinCtrl,
                    forceUppercase: false,
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'Phone',
                  _buildPhoneRow(
                    code: shippingPhoneCode,
                    onCodeChanged: (v) => _state(() => shippingPhoneCode = v),
                    controller: shippingPhoneCtrl,
                    hintText: 'Phone',
                  ),
                ),
                const SizedBox(height: 12),
                _labeledInlineField(
                  'Fax',
                  CustomTextField(
                    height: _inputHeight,
                    controller: shippingFaxCtrl,
                    forceUppercase: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
