part of '../purchases_vendors_vendor_create.dart';

extension _AddressSection on _PurchasesVendorsVendorCreateScreenState {
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
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_downward,
                size: 14,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 2),
              InkWell(
                onTap: () {
                  _state(() {
                    _shippingAttentionCtrl.text = _billingAttentionCtrl.text;
                    _shippingStreet1Ctrl.text = _billingStreet1Ctrl.text;
                    _shippingStreet2Ctrl.text = _billingStreet2Ctrl.text;
                    _shippingCityCtrl.text = _billingCityCtrl.text;
                    _shippingPinCtrl.text = _billingPinCtrl.text;
                    _shippingPhoneCtrl.text = _billingPhoneCtrl.text;
                    _shippingFaxCtrl.text = _billingFaxCtrl.text;
                    _shippingCountry = _billingCountry;
                    _shippingState = _billingState;
                  });
                },
                child: const Text(
                  'Copy billing address',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                ')',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _buildAddressField(
          'Attention',
          isShipping ? _shippingAttentionCtrl : _billingAttentionCtrl,
          isShipping: isShipping,
        ),
        _buildAddressField(
          'Country/Region',
          null,
          isShipping: isShipping,
          isDropdown: true,
          dropdownValue: isShipping ? _shippingCountry : _billingCountry,
          onDropdownChanged: (v) => _state(() {
            if (isShipping) {
              _shippingCountry = v;
              _shippingState = null;
            } else {
              _billingCountry = v;
              _billingState = null;
            }
          }),
        ),
        _buildAddressField(
          'Address',
          isShipping ? _shippingStreet1Ctrl : _billingStreet1Ctrl,
          isShipping: isShipping,
          hint: 'Street 1',
          maxLines: 1,
        ),
        _buildAddressField(
          '',
          isShipping ? _shippingStreet2Ctrl : _billingStreet2Ctrl,
          isShipping: isShipping,
          hint: 'Street 2',
          maxLines: 1,
        ),
        _buildAddressField(
          'City',
          isShipping ? _shippingCityCtrl : _billingCityCtrl,
          isShipping: isShipping,
        ),
        _buildAddressField(
          'State',
          null,
          isShipping: isShipping,
          isDropdown: true,
          dropdownValue: isShipping ? _shippingState : _billingState,
          onDropdownChanged: (v) async {
            if (v == null) return;
            final prevValue = isShipping ? _shippingState : _billingState;
            if (v == prevValue) return;

            final country = isShipping ? _shippingCountry : _billingCountry;
            final countries =
                ref.read(countriesProvider(null)).asData?.value ?? [];
            final countryShortCode =
                countries.firstWhere(
                  (c) => c['name'] == country,
                  orElse: () => {'shortCode': 'IN'},
                )['shortCode'] ??
                'IN';

            // Check if it's a custom value (not in current list)
            final states =
                ref.read(statesProvider(countryShortCode)).asData?.value ?? [];
            if (!states.any((s) => s['name'] == v)) {
              // Save new state to database
              await ref
                  .read(lookupServiceProvider)
                  .saveState(v, countryShortCode);
              // Invalidate states provider to refresh list
              ref.invalidate(statesProvider(countryShortCode));
            }

            _state(() {
              if (isShipping) {
                _shippingState = v;
              } else {
                _billingState = v;
              }
            });
          },
        ),
        _buildAddressField(
          'Pin Code',
          isShipping ? _shippingPinCtrl : _billingPinCtrl,
          isShipping: isShipping,
        ),
        _buildAddressField(
          'Phone',
          isShipping ? _shippingPhoneCtrl : _billingPhoneCtrl,
          isShipping: isShipping,
          isPhone: true,
        ),
        _buildAddressField(
          'Fax Number',
          isShipping ? _shippingFaxCtrl : _billingFaxCtrl,
          isShipping: isShipping,
        ),
      ],
    );
  }

  Widget _buildAddressField(
    String label,
    TextEditingController? ctrl, {
    required bool isShipping,
    bool isDropdown = false,
    bool isPhone = false,
    String? hint,
    int maxLines = 1,
    String? dropdownValue,
    ValueChanged<String?>? onDropdownChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _fieldWidth),
                child: isDropdown
                    ? Consumer(
                        builder: (context, ref, _) {
                          if (label == 'Country/Region') {
                            final countriesAsync = ref.watch(
                              countriesProvider(null),
                            );
                            return FormDropdown<String>(
                              height: _inputHeight,
                              value:
                                  (dropdownValue != null &&
                                      dropdownValue.isNotEmpty)
                                  ? dropdownValue
                                  : null,
                              hint: 'Select',
                              items: [
                                ...(countriesAsync.asData?.value.map(
                                      (e) => e['name'] as String,
                                    ) ??
                                    []),
                              ],
                              onChanged: onDropdownChanged!,
                            );
                          } else if (label == 'State') {
                            final country = isShipping
                                ? _shippingCountry
                                : _billingCountry;
                            final countries =
                                ref
                                    .read(countriesProvider(null))
                                    .asData
                                    ?.value ??
                                [];
                            final countryShortCode =
                                countries.firstWhere(
                                  (c) => c['name'] == country,
                                  orElse: () => {'shortCode': 'IN'},
                                )['shortCode'] ??
                                'IN';

                            final statesAsync = ref.watch(
                              statesProvider(countryShortCode),
                            );
                            return FormDropdown<String>(
                              height: _inputHeight,
                              isLoading: statesAsync.isLoading,
                              value:
                                  (dropdownValue != null &&
                                      dropdownValue.isNotEmpty)
                                  ? dropdownValue
                                  : null,
                              hint: 'Select or type to add',
                              allowCustomValue: true,
                              items: [
                                ...(statesAsync.asData?.value.map(
                                      (e) => e['name'] ?? '',
                                    ) ??
                                    []),
                              ],
                              onChanged: onDropdownChanged!,
                            );
                          }
                          return FormDropdown<String>(
                            height: _inputHeight,
                            value: null,
                            hint: 'Select',
                            items: const [],
                            onChanged: (_) {},
                          );
                        },
                      )
                    : (isPhone && label == 'Phone'
                          ? _buildPhoneRow(
                              code: isShipping
                                  ? _shippingPhoneCode
                                  : _billingPhoneCode,
                              onCodeChanged: (v) => _state(() {
                                if (isShipping) {
                                  _shippingPhoneCode = v;
                                } else {
                                  _billingPhoneCode = v;
                                }
                              }),
                              controller: ctrl!,
                              hintText: '',
                            )
                          : CustomTextField(
                              height: maxLines > 1 ? null : _inputHeight,
                              controller: ctrl!,
                              hintText: hint,
                              maxLines: maxLines,
                            )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
