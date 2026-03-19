part of '../purchases_vendors_vendor_create.dart';

extension _PrimaryInfoSection on _PurchasesVendorsVendorCreateScreenState {
  Widget _buildPrimaryInfo() {
    return Column(
      children: [
        _buildFormRow(
          label: 'Primary Contact',
          isRequired: true,
          showInfo: true,
          tooltip: 'Primary contact name for this vendor.',
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: FormDropdown<String>(
                  height: _inputHeight,
                  value: _salutation,
                  items: const ['Mr.', 'Mrs.', 'Ms.', 'Dr.'],
                  itemBuilder: (item, isSelected, isHovered) =>
                      _buildStandardLookupRow(item, isSelected, isHovered),
                  onChanged: (val) {
                    _state(() => _salutation = val!);
                    _refreshDisplayNameOptions();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomTextField(
                  height: _inputHeight,
                  controller: _firstNameCtrl,
                  hintText: 'First Name',
                  onChanged: (_) => _refreshDisplayNameOptions(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomTextField(
                  height: _inputHeight,
                  controller: _lastNameCtrl,
                  hintText: 'Last Name',
                  onChanged: (_) => _refreshDisplayNameOptions(),
                ),
              ),
            ],
          ),
        ),

        _buildFormRow(
          label: 'Company Name',
          showInfo: true,
          tooltip: 'Legal name of the business.',
          child: CustomTextField(
            height: _inputHeight,
            controller: _companyNameCtrl,
          ),
        ),

        _buildFormRow(
          label: 'Display Name*',
          isRequired: true,
          showInfo: true,
          tooltip: 'Name that will appear on purchase orders and bills.',
          child: FormDropdown<String>(
            height: _inputHeight,
            value: _displayNameCtrl.text,
            items: _displayNameOptions,
            allowClear: false,
            allowCustomValue: true,
            itemBuilder: (item, isSelected, isHovered) =>
                _buildStandardLookupRow(item, isSelected, isHovered),
            onChanged: (v) => _state(() => _displayNameCtrl.text = v ?? ''),
          ),
        ),

        _buildFormRow(
          label: 'Email Address',
          showInfo: true,
          tooltip: 'Contact email for this vendor.',
          child: CustomTextField(
            height: _inputHeight,
            controller: _emailCtrl,
            prefixIcon: LucideIcons.mail,
            prefixBox: true,
          ),
        ),

        _buildFormRow(
          label: 'Vendor Number',
          isRequired: true,
          showInfo: true,
          tooltip: 'Unique identifier for the vendor.',
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  height: _inputHeight,
                  controller: _vendorNumberCtrl,
                ),
              ),
              const SizedBox(width: 8),
              _buildSquareIconButton(
                Icons.settings,
                onPressed: _openVendorNumberPreferences,
                tooltip: 'Configure vendor number preferences',
              ),
            ],
          ),
        ),

        _buildFormRow(
          label: 'Phone',
          showInfo: true,
          tooltip: 'Primary contact numbers.',
          child: Row(
            children: [
              Expanded(
                child: _buildPhoneRow(
                  code: _workPhoneCode,
                  onCodeChanged: (val) => _state(() => _workPhoneCode = val),
                  controller: _workPhoneCtrl,
                  hintText: 'Work Phone',
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                child: _buildPhoneRow(
                  code: _mobilePhoneCode,
                  onCodeChanged: (val) => _state(() => _mobilePhoneCode = val),
                  controller: _mobilePhoneCtrl,
                  hintText: 'Mobile',
                ),
              ),
            ],
          ),
        ),

        _buildFormRow(
          label: 'Vendor Language',
          showInfo: true,
          tooltip: 'Preferred language for communication.',
          child: FormDropdown<String>(
            height: _inputHeight,
            value: _vendorLanguage,
            items: const ['English', 'Hindi', 'Spanish'],
            itemBuilder: (item, isSelected, isHovered) =>
                _buildStandardLookupRow(item, isSelected, isHovered),
            onChanged: (val) => _state(() => _vendorLanguage = val!),
          ),
        ),
      ],
    );
  }

  Widget _buildSquareIconButton(
    IconData icon, {
    VoidCallback? onPressed,
    String? tooltip,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          height: _inputHeight,
          width: _inputHeight,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryBlueDark),
        ),
      ),
    );

    if (tooltip == null || tooltip.isEmpty) {
      return button;
    }

    return Tooltip(message: tooltip, child: button);
  }
}
