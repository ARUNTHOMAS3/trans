part of '../sales_customer_create.dart';

extension _PrimaryInfoSection on _SalesCustomerCreateScreenState {
  Widget _buildPrimaryInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPrefillBanner(),
        const SizedBox(height: 32),

          // 1. Customer Type
          _buildFormRow(
            label: 'Customer Type',
            showInfo: true,
            tooltip:
                'The contacts which are associated to any Account in CRM is of type Business and the other contacts will be of type Individual.',
            child: ZerpaiRadioGroup<String>(
              options: const ['Business', 'Individual'],
              current: customerType,
              onChanged: (v) => _handleCustomerTypeChange(v),
            ),
          ),

          // 2. Primary Contact
          _buildFormRow(
            label: 'Primary Contact',
            required: true,
            showInfo: true,
            tooltip:
                'Select the salutation and enter the first and last name of the primary contact person.',
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: FormDropdown<String>(
                    height: _inputHeight,
                    value: salutation,
                    items: const ['Mr.', 'Mrs.', 'Ms.', 'Miss', 'Dr.'],
                    onChanged: _updateSalutation,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    height: _inputHeight,
                    controller: firstNameCtrl,
                    hintText: 'First Name',
                    onChanged: (_) => _refreshDisplayNameOptions(),
                    forceUppercase: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    height: _inputHeight,
                    controller: lastNameCtrl,
                    hintText: 'Last Name',
                    onChanged: (_) => _refreshDisplayNameOptions(),
                    forceUppercase: false,
                  ),
                ),
              ],
            ),
          ),

          // 3. Company Name
          _buildFormRow(
            label: 'Company Name',
            showInfo: true,
            tooltip: 'Enter the legal business name of the customer.',
            child: CustomTextField(
              height: _inputHeight,
              controller: companyNameCtrl,
              onChanged: (_) => _refreshDisplayNameOptions(),
              forceUppercase: false,
            ),
          ),

          // 4. Customer Display Name
          _buildFormRow(
            label: 'Display Name',
            required: true,
            showInfo: true,
            tooltip:
                'Name that will appear on invoices, transactions, and reports for this customer.',
            child: FormDropdown<String>(
              height: _inputHeight,
              value: displayNameCtrl.text,
              items: _displayNameOptions,
              allowClear: false,
              allowCustomValue: true,
              onChanged: (v) => _state(() => displayNameCtrl.text = v ?? ''),
            ),
          ),

          if (customerType == 'Individual') ...[
            // 4.1 Parent Dropdown
            _buildFormRow(
              label: 'Parent',
              showInfo: true,
              tooltip: 'Associate this contact with a parent customer/account.',
              child: Consumer(
                builder: (context, ref, child) {
                  final customersAsync = ref.watch(salesCustomersProvider);
                  final items =
                      customersAsync.value
                          ?.where(
                            (c) =>
                                c.customerType?.toLowerCase() == 'individual',
                          )
                          .map((c) => c.displayName)
                          .toList() ??
                      [];

                  return FormDropdown<String>(
                    height: _inputHeight,
                    value: parentCustomer,
                    hint: 'Select or type to add',
                    items: items,
                    onChanged: (v) => _state(() => parentCustomer = v),
                  );
                },
              ),
            ),
          ],

          // 4.5 Business Type
          if (customerType == 'Business') ...[
            _buildFormRow(
              label: 'Business Type',
              showInfo: true,
              tooltip:
                  'Select the operational model for this business entity (COCO, FOFO, or FICO).',
              child: FormDropdown<String>(
                height: _inputHeight,
                value: businessType,
                items: const ['COCO', 'FOFO', 'FICO', 'Others'],
                onChanged: (v) => _state(() => businessType = v ?? 'COCO'),
              ),
            ),
          ],

          // 5. Customer Email
          _buildFormRow(
            label: 'Email Address',
            required: enablePortal,
            showInfo: true,
            tooltip:
                'Contact email where all system-generated communications and invoices will be sent.',
            child: CustomTextField(
              height: _inputHeight,
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              forceUppercase: false,
              prefixIcon: LucideIcons.mail,
              prefixBox: true,
            ),
          ),

          // 6. Customer Number
          _buildFormRow(
            label: 'Customer Number',
            required: true,
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    height: _inputHeight,
                    controller: customerNumberCtrl,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp('-')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildSquareIconButton(
                  Icons.settings,
                  onPressed: _openCustomerNumberPreferences,
                  tooltip: 'Configure customer number preferences',
                ),
              ],
            ),
          ),

          // 7. Phone
          _buildFormRow(
            label: 'Phone',
            showInfo: true,
            tooltip:
                'Primary work and mobile contact numbers for the customer.',
            child: Row(
              children: [
                Expanded(
                  child: _buildPhoneRow(
                    code: phoneCode,
                    onCodeChanged: (v) => _state(() => phoneCode = v),
                    controller: workPhoneCtrl,
                    hintText: customerType == 'Individual'
                        ? 'WhatsApp Number'
                        : 'Work Phone',
                  ),
                ),
                const SizedBox(width: 48),
                Expanded(
                  child: _buildPhoneRow(
                    code: mobileCode,
                    onCodeChanged: (v) => _state(() => mobileCode = v),
                    controller: mobilePhoneCtrl,
                    hintText: 'Mobile',
                  ),
                ),
              ],
            ),
          ),

          if (customerType == 'Individual') ...[
            // 8. Date of Birth Dropdowns
            _buildFormRow(
              label: 'Date of Birth',
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FormDropdown<String>(
                      height: _inputHeight,
                      value: dobDay,
                      hint: 'Day',
                      items: List.generate(31, (i) => (i + 1).toString()),
                      onChanged: (v) {
                        _state(() => dobDay = v);
                        _updateAgeFromDropdowns();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: FormDropdown<String>(
                      height: _inputHeight,
                      value: dobMonth,
                      hint: 'Month',
                      items: const [
                        'January',
                        'February',
                        'March',
                        'April',
                        'May',
                        'June',
                        'July',
                        'August',
                        'September',
                        'October',
                        'November',
                        'December',
                      ],
                      onChanged: (v) {
                        _state(() => dobMonth = v);
                        _updateAgeFromDropdowns();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: FormDropdown<String>(
                      height: _inputHeight,
                      value: dobYear,
                      hint: 'Year',
                      items: List.generate(
                        100,
                        (i) => (DateTime.now().year - i).toString(),
                      ),
                      onChanged: (v) {
                        _state(() => dobYear = v);
                        _updateAgeFromDropdowns();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 9. Age (ReadOnly)
            _buildFormRow(
              label: 'Age',
              child: CustomTextField(
                height: _inputHeight,
                controller: TextEditingController(
                  text: dob == null ? '' : _calculateAge(dob!).toString(),
                ),
                readOnly: true,
                forceUppercase: false,
              ),
            ),

            // 10. Gender (Radio)
            _buildFormRow(
              label: 'Gender',
              child: ZerpaiRadioGroup<String>(
                options: const ['Male', 'Female', 'Other'],
                current: gender,
                onChanged: (v) => _state(() => gender = v),
              ),
            ),

            // 11. Place of customer
            _buildFormRow(
              label: 'Place of customer',
              child: CustomTextField(
                height: _inputHeight,
                controller: placeOfCustomerCtrl,
                forceUppercase: false,
              ),
            ),

            // 12. Privilege Card Number
            _buildFormRow(
              label: 'Privilege Card Number',
              child: CustomTextField(
                height: _inputHeight,
                controller: privilegeCardNumberCtrl,
                forceUppercase: false,
              ),
            ),
          ],

          // 13. Customer Language
          _buildFormRow(
            label: 'Customer Language',
            showInfo: true,
            tooltip: 'Preferred language for all communications and documents.',
            child: FormDropdown<String>(
              height: _inputHeight,
              value: customerLanguage,
              items: const [
                'English',
                'Tamil',
                'Hindi',
                'Telugu',
                'Marathi',
                'Gujarati',
                'Kannada',
                'Arabic (Egyptian)',
                'Arabic',
                'Bulgarian',
                'German',
                'Spanish',
                'French',
                'French (Canada)',
                'Croatian',
                'Indonesian',
                'Italian',
                'Japanese',
                'Dutch',
                'Portuguese',
                'Swedish',
                'Thai',
                'Vietnamese',
                'Chinese (Simplified)',
                'Filipino',
                'Malay',
                'Chinese (Traditional)',
              ],
              onChanged: (v) =>
                  _state(() => customerLanguage = v ?? customerLanguage),
            ),
          ),
      ],
    );
  }
}
