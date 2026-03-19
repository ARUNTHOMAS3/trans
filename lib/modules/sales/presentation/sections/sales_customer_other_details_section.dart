part of '../sales_customer_create.dart';

extension _OtherDetailsSection on _SalesCustomerCreateScreenState {
  Widget _buildOtherDetails() {
    final hideGstRegistrationFields = _shouldHideGstRegistrationFields();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          // --- SECTION 1: TAXING DETAILS ---
          _buildFormRow(
            label: 'GST Treatment',
            required: true,
            showInfo: true,
            tooltip:
                'Select the GST classification based on the customer\'s registration status.',
            child: SizedBox(
              width: _fieldWidth,
              child: FormDropdown<_GstTreatmentOption>(
                height: _inputHeight,
                value: gstTreatment,
                items: _gstTreatmentOptions,
                hint: 'Select a GST treatment',
                displayStringForValue: (v) => v.label,
                searchStringForValue: (v) => '${v.label} ${v.description}',
                itemBuilder: (item, isSelected, isHovered) =>
                    _buildGstTreatmentRow(item, isSelected, isHovered),
                onChanged: (v) =>
                    _state(() => gstTreatment = v ?? gstTreatment),
              ),
            ),
          ),
          SizedBox(height: _fieldSpacing),
          if (!hideGstRegistrationFields) ...[
            _buildFormRow(
              label: 'GSTIN / UIN',
              required: gstTreatment.label.contains('Registered'),
              showInfo: true,
              tooltip:
                  'Enter the 15-digit Goods and Services Tax Identification Number.',
              trailing: InkWell(
                onTap: _openGstinPrefillDialog,
                child: const Text(
                  'Get Taxpayer details',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlueDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              child: CustomTextField(
                height: _inputHeight,
                controller: gstinPrefillCtrl,
                forceUppercase: true,
                onChanged: (v) => _state(() {}),
              ),
            ),
            SizedBox(height: _fieldSpacing),
            _buildFormRow(
              label: 'Business Legal Name',
              showInfo: true,
              tooltip:
                  'Legal and trade names as registered with the GST department.',
              child: SizedBox(
                width: _fieldWidth,
                child: CustomTextField(
                  height: _inputHeight,
                  controller: businessLegalNameCtrl,
                  forceUppercase: false,
                ),
              ),
            ),
            SizedBox(height: _fieldSpacing),
            _buildFormRow(
              label: 'Business Trade Name',
              showInfo: true,
              tooltip:
                  'Legal and trade names as registered with the GST department.',
              child: SizedBox(
                width: _fieldWidth,
                child: CustomTextField(
                  height: _inputHeight,
                  controller: businessTradeNameCtrl,
                  forceUppercase: false,
                ),
              ),
            ),
            SizedBox(height: _fieldSpacing),
          ],
          if (!_shouldHidePlaceOfSupply()) ...[
            _buildFormRow(
              label: 'Place of Supply',
              required: true,
              showInfo: true,
              tooltip:
                  'State where the supply of goods or services is intended to take place for GST purposes.',
              child: SizedBox(
                width: _fieldWidth,
                child: FormDropdown<String>(
                  height: _inputHeight,
                  value: placeOfSupply,
                  items: [
                    'Select',
                    ..._indiaStates.map((s) => '[${s['code']}] - ${s['name']}'),
                  ],
                  onChanged: (v) =>
                      _state(() => placeOfSupply = v ?? placeOfSupply),
                ),
              ),
            ),
            SizedBox(height: _fieldSpacing),
          ],
          _buildFormRow(
            label: 'PAN',
            showInfo: true,
            tooltip:
                '10-digit Permanent Account Number for tax identification in India.',
            child: SizedBox(
              width: _fieldWidth,
              child: CustomTextField(
                height: _inputHeight,
                controller: panCtrl,
                forceUppercase: true,
              ),
            ),
          ),
          SizedBox(height: _fieldSpacing),

          // --- SECTION 2: TAX PREFERENCE ---
          _buildFormRow(
            label: 'Tax Preference',
            required: true,
            showInfo: true,
            tooltip:
                'Choose whether the customer is subject to tax or exempt from tax.',
            child: ZerpaiRadioGroup<String>(
              options: const ['Taxable', 'Tax Exempt'],
              current: taxPreference,
              onChanged: (v) => _state(() {
                taxPreference = v;
                if (v == 'Taxable') exemptionReason = null;
              }),
            ),
          ),
          if (taxPreference == 'Tax Exempt') ...[
            SizedBox(height: _fieldSpacing),
            _buildFormRow(
              label: 'Exemption Reason',
              required: true,
              tooltip: 'Reason for marking this customer as tax exempt.',
              child: SizedBox(
                width: _fieldWidth,
                child: FormDropdown<String>(
                  height: _inputHeight,
                  value: exemptionReason,
                  items: const [
                    'Charitable Organization',
                    'Export Customer',
                    'Government Entity',
                    'Nil Rated',
                    'Non-GST Supply',
                    'SEZ Supply',
                  ],
                  hint: 'Select or type to add',
                  onChanged: (v) => _state(() => exemptionReason = v),
                  allowClear: true,
                  allowCustomValue: true,
                ),
              ),
            ),
          ],
          SizedBox(height: _fieldSpacing),

          // --- SECTION 3: FINANCIAL DETAILS ---
          _buildFormRow(
            label: 'Currency',
            showInfo: true,
            tooltip:
                'Default currency for all transactions with this customer.',
            child: SizedBox(
              width: _fieldWidth,
              child: FormDropdown<CurrencyOption>(
                height: _inputHeight,
                value: currency,
                items: _localCurrencyOptions,
                onSearch: (q) async {
                  return await ref.read(currenciesProvider(q).future);
                },
                displayStringForValue: (v) => v.label,
                searchStringForValue: (v) => '${v.code} ${v.name}',
                itemBuilder: (item, isSelected, isHovered) =>
                    _buildCurrencyRow(item, isSelected, isHovered),
                onChanged: (v) => _state(() => currency = v ?? currency),
              ),
            ),
          ),
          SizedBox(height: _fieldSpacing),
          _buildFormRow(
            label: 'Opening Balance',
            showInfo: true,
            tooltip:
                'Outstanding balance amount carried forward for this customer.',
            trailing: InkWell(
            onTap: () => context.go(AppRoutes.accountantOpeningBalances),
              child: const Text(
                'Configure in Accountant',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryBlueDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            child: SizedBox(
              width: _fieldWidth,
              child: _buildAmountRow(openingBalanceCtrl, currency.code),
            ),
          ),
          SizedBox(height: _fieldSpacing),
          _buildFormRow(
            label: 'Credit Limit',
            showInfo: true,
            tooltip:
                'Maximum credit amount allowed before system alerts or blocks.',
            child: SizedBox(
              width: _fieldWidth,
              child: _buildAmountRow(creditLimitCtrl, currency.code),
            ),
          ),
          SizedBox(height: _fieldSpacing),
          _buildFormRow(
            label: 'Payment Terms',
            showInfo: true,
            tooltip: 'Standard time frame within which payments are expected.',
            child: SizedBox(
              width: _fieldWidth,
              child: FormDropdown<String>(
                height: _inputHeight,
                value: paymentTerms,
                items: const ['Net 360', 'Net 30', 'Net 45', 'Due on Receipt'],
                onChanged: (v) =>
                    _state(() => paymentTerms = v ?? paymentTerms),
              ),
            ),
          ),
          SizedBox(height: _fieldSpacing),
          _buildFormRow(
            label: 'Price List',
            showInfo: true,
            tooltip:
                'Specific price list to automatically apply pre-defined rates.',
            child: SizedBox(
              width: _fieldWidth,
              child: FormDropdown<PriceList>(
                height: _inputHeight,
                value: selectedPriceList,
                items: ref.watch(activePriceListsProvider),
                hint: 'Select',
                displayStringForValue: (v) => v.name,
                searchStringForValue: (v) => v.name,
                onChanged: (v) => _state(() => selectedPriceList = v),
                allowClear: true,
              ),
            ),
          ),
          SizedBox(height: _fieldSpacing),

          // --- SECTION 4: PORTAL & DOCUMENTS ---
          _buildFormRow(
            label: 'Enable Portal?',
            showInfo: true,
            tooltip:
                'Grant access to the customer portal for viewing invoices and making payments.',
            child: Row(
              children: [
                Checkbox(
                  value: enablePortal,
                  onChanged: (v) => _state(() => enablePortal = v ?? false),
                  activeColor: AppTheme.primaryBlueDark,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Allow portal access for this customer',
                      children: [
                        if (enablePortal)
                          const TextSpan(
                            text: ' ( Email address is mandatory )',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: _fieldSpacing),
          _buildFormRow(
            label: 'Documents',
            child: SizedBox(
              width: _fieldWidth,
              child: _buildUploadSection(
                files: documents,
                onPick: _pickDocuments,
                onRemove: _removeDocument,
                hintText: 'You can upload a maximum of 5 files, 10MB each',
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _state(() => showMoreDetails = !showMoreDetails),
              child: Text(
                showMoreDetails ? 'Hide more details' : 'Add more details',
              ),
            ),
          ),
          if (showMoreDetails) ...[
            const SizedBox(height: 16),
            _buildAdditionalDetails(),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalDetails() {
    return Column(
      children: [
        _buildFormRow(
          label: 'Department',
          child: SizedBox(
            width: _fieldWidth,
            child: CustomTextField(
              height: _inputHeight,
              controller: departmentCtrl,
              forceUppercase: false,
            ),
          ),
        ),
        SizedBox(height: _fieldSpacing),
        _buildFormRow(
          label: 'Designation',
          child: SizedBox(
            width: _fieldWidth,
            child: CustomTextField(
              height: _inputHeight,
              controller: designationCtrl,
              forceUppercase: false,
            ),
          ),
        ),
        SizedBox(height: _fieldSpacing),
        _buildFormRow(
          label: 'X (formerly Twitter)',
          child: SizedBox(
            width: _fieldWidth,
            child: CustomTextField(
              height: _inputHeight,
              controller: xHandleCtrl,
              prefixBox: true,
              prefixWidget: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><path fill="#010409" d="M357.2 48L427.8 48 273.6 224.2 455 464 313 464 201.7 318.6 74.5 464 3.8 464 168.7 275.5-5.2 48 140.4 48 240.9 180.9 357.2 48zM332.4 421.8l39.1 0-252.4-333.8-42 0 255.3 333.8z"/></svg>''',
                width: 20,
                height: 20,
              ),
              forceUppercase: false,
            ),
          ),
        ),
        SizedBox(height: _fieldSpacing),
        _buildFormRow(
          label: 'WhatsApp',
          child: SizedBox(
            width: _fieldWidth,
            child: CustomTextField(
              height: _inputHeight,
              controller: whatsappCtrl,
              prefixBox: true,
              prefixWidget: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><path fill="#1af43e" d="M380.9 97.1c-41.9-42-97.7-65.1-157-65.1-122.4 0-222 99.6-222 222 0 39.1 10.2 77.3 29.6 111L0 480 117.7 449.1c32.4 17.7 68.9 27 106.1 27l.1 0c122.3 0 224.1-99.6 224.1-222 0-59.3-25.2-115-67.1-157zm-157 341.6c-33.2 0-65.7-8.9-94-25.7l-6.7-4-69.8 18.3 18.6-68.1-4.4-7c-18.5-29.4-28.2-63.3-28.2-98.2 0-101.7 82.8-184.5 184.6-184.5 49.3 0 95.6 19.2 130.4 54.1s56.2 81.2 56.1 130.5c0 101.8-84.9 184.6-186.6 184.6zM325.1 300.5c-5.5-2.8-32.8-16.2-37.9-18-5.1-1.9-8.8-2.8-12.5 2.8s-14.3 18-17.6 21.8c-3.2 3.7-6.5 4.2-12 1.4-32.6-16.3-54-29.1-75.5-66-5.7-9.8 5.7-9.1 16.3-30.3 1.8-3.7 .9-6.9-.5-9.7s-12.5-30.1-17.1-41.2c-4.5-10.8-9.1-9.3-12.5-9.5-3.2-.2-6.9-.2-10.6-.2s-9.7 1.4-14.8 6.9c-5.1 5.6-19.4 19-19.4 46.3s19.9 53.7 22.6 57.4c2.8 3.7 39.1 59.7 94.8 83.8 35.2 15.2 49 16.5 66.6 13.9 10.7-1.6 32.8-13.4 37.4-26.4s4.6-24.1 3.2-26.4c-1.3-2.5-5-3.9-10.5-6.6z"/></svg>''',
                width: 24,
                height: 24,
              ),
              forceUppercase: false,
            ),
          ),
        ),
        SizedBox(height: _fieldSpacing),
        _buildFormRow(
          label: 'Facebook',
          child: SizedBox(
            width: _fieldWidth,
            child: CustomTextField(
              height: _inputHeight,
              controller: facebookCtrl,
              prefixBox: true,
              prefixWidget: SvgPicture.string(
                '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><path fill="#2a70ea" d="M512 256C512 114.6 397.4 0 256 0S0 114.6 0 256C0 376 82.7 476.8 194.2 504.5l0-170.3-52.8 0 0-78.2 52.8 0 0-33.7c0-87.1 39.4-127.5 125-127.5 16.2 0 44.2 3.2 55.7 6.4l0 70.8c-6-.6-16.5-1-29.6-1-42 0-58.2 15.9-58.2 57.2l0 27.8 83.6 0-14.4 78.2-69.3 0 0 175.9C413.8 494.8 512 386.9 512 256z"/></svg>''',
                width: 22,
                height: 22,
              ),
              forceUppercase: false,
            ),
          ),
        ),
      ],
    );
  }
}
