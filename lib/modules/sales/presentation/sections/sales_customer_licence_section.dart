part of '../sales_customer_create.dart';

extension _LicenceSection on _SalesCustomerCreateScreenState {
  Widget _buildLicenceSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drug License Section
          _buildFormRow(
            label: 'Drug Registered ?',
            child: Row(
              children: [
                Checkbox(
                  value: isDrugRegistered,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (v) => _state(() => isDrugRegistered = v ?? false),
                ),
                const Text(
                  'This Customer Is Registered Drug Licence',
                  style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                ),
              ],
            ),
          ),
          if (isDrugRegistered) ...[
            SizedBox(height: _fieldSpacing),
            _buildFormRow(
              label: 'Drug Licence Type',
              required: true,
              showInfo: true,
              tooltip: 'Select the type of drug licence held by this customer.',
              child: SizedBox(
                width: _fieldWidth,
                child: FormDropdown<String>(
                  height: _inputHeight,
                  value: drugLicenceType,
                  hint: 'Select licence type',
                  items: const ['Wholesale', 'Retail', 'Wholesale and Retail'],
                  onChanged: (v) => _state(() => drugLicenceType = v),
                ),
              ),
            ),
            SizedBox(height: _fieldSpacing),
            // Show Retail licenses (20, 21) for Retail or Combined
            if (drugLicenceType == 'Retail' ||
                drugLicenceType == 'Wholesale and Retail') ...[
              _buildFormRow(
                label: 'Drug License 20',
                required: true,
                showInfo: true,
                tooltip:
                    'Enter the Drug License Number (Form 20) for retail sale of drugs.',
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        height: _inputHeight,
                        controller: drugLicense20Ctrl,
                        forceUppercase: true,
                        hintText: 'Enter the License Number',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildUploadSection(
                      files: drugLicense20Docs,
                      onPick: () => _pickLicenseDocument('drugLicense20'),
                      onRemove: (file) =>
                          _removeLicenseDocument('drugLicense20', file),
                    ),
                  ],
                ),
              ),
              SizedBox(height: _fieldSpacing),
              _buildFormRow(
                label: 'Drug License 21',
                required: true,
                showInfo: true,
                tooltip:
                    'Enter the Drug License Number (Form 21) for retail sale of drugs.',
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        height: _inputHeight,
                        controller: drugLicense21Ctrl,
                        forceUppercase: true,
                        hintText: 'Enter the License Number',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildUploadSection(
                      files: drugLicense21Docs,
                      onPick: () => _pickLicenseDocument('drugLicense21'),
                      onRemove: (file) =>
                          _removeLicenseDocument('drugLicense21', file),
                    ),
                  ],
                ),
              ),
              SizedBox(height: _fieldSpacing),
            ],
            // Show Wholesale licenses (20B, 21B) for Wholesale or Combined
            if (drugLicenceType == 'Wholesale' ||
                drugLicenceType == 'Wholesale and Retail') ...[
              _buildFormRow(
                label: 'Drug License 20B',
                required: true,
                showInfo: true,
                tooltip:
                    'Enter the Drug License Number (Form 20B) for sale/distribution of drugs.',
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        height: _inputHeight,
                        controller: drugLicense20BCtrl,
                        forceUppercase: true,
                        hintText: 'Enter the License Number',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildUploadSection(
                      files: drugLicense20BDocs,
                      onPick: () => _pickLicenseDocument('drugLicense20B'),
                      onRemove: (file) =>
                          _removeLicenseDocument('drugLicense20B', file),
                    ),
                  ],
                ),
              ),
              SizedBox(height: _fieldSpacing),
              _buildFormRow(
                label: 'Drug License 21B',
                required: true,
                showInfo: true,
                tooltip:
                    'Enter the Drug License Number (Form 21B) for sale/distribution of drugs.',
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        height: _inputHeight,
                        controller: drugLicense21BCtrl,
                        forceUppercase: true,
                        hintText: 'Enter the License Number',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildUploadSection(
                      files: drugLicense21BDocs,
                      onPick: () => _pickLicenseDocument('drugLicense21B'),
                      onRemove: (file) =>
                          _removeLicenseDocument('drugLicense21B', file),
                    ),
                  ],
                ),
              ),
              SizedBox(height: _fieldSpacing),
            ],
          ],

          SizedBox(height: _fieldSpacing),

          // Food & Standards
          _buildFormRow(
            label: 'FSSAI License Registered ?',
            child: Row(
              children: [
                Checkbox(
                  value: isFssaiRegistered,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (v) =>
                      _state(() => isFssaiRegistered = v ?? false),
                ),
                const Text(
                  'This Customer Is Registered FSSAI License',
                  style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                ),
              ],
            ),
          ),
          if (isFssaiRegistered) ...[
            SizedBox(height: _fieldSpacing),
            _buildFormRow(
              label: 'FSSAI Number',
              required: true,
              showInfo: true,
              tooltip:
                  'Enter the 14-digit FSSAI (Food Safety and Standards Authority of India) license number.',
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      height: _inputHeight,
                      controller: fssaiCtrl,
                      forceUppercase: true,
                      hintText: 'Enter the FSSAI Number',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildUploadSection(
                    files: fssaiDocs,
                    onPick: () => _pickLicenseDocument('fssai'),
                    onRemove: (file) => _removeLicenseDocument('fssai', file),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: _fieldSpacing),

          // MSME Registration
          _buildFormRow(
            label: 'MSME Registered ?',
            child: Row(
              children: [
                Checkbox(
                  value: isMsmeRegistered,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (v) => _state(() => isMsmeRegistered = v ?? false),
                ),
                const Text(
                  'This Customer Is Registered MSME',
                  style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                ),
              ],
            ),
          ),
          if (isMsmeRegistered) ...[
            SizedBox(height: _fieldSpacing),
            _buildFormRow(
              label: 'MSME/Udyam Registration Type',
              required: true,
              showInfo: true,
              tooltip: 'Select the type of MSME/Udyam registration.',
              child: SizedBox(
                width: _fieldWidth,
                child: FormDropdown<String>(
                  height: _inputHeight,
                  value: msmeRegistrationType,
                  hint: 'Select the Registration Type',
                  items: const ['Micro', 'Small', 'Medium'],
                  onChanged: (v) => _state(() => msmeRegistrationType = v),
                ),
              ),
            ),
            SizedBox(height: _fieldSpacing),
            _buildFormRow(
              label: 'MSME/Udyam Registration Number',
              required: true,
              showInfo: true,
              tooltip:
                  'Enter the MSME/Udyam Registration Number issued by the Ministry of MSME.',
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      height: _inputHeight,
                      controller: msmeNumberCtrl,
                      forceUppercase: true,
                      hintText: 'Enter the Registration Number',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildUploadSection(
                    files: msmeDocs,
                    onPick: () => _pickLicenseDocument('msme'),
                    onRemove: (file) => _removeLicenseDocument('msme', file),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: _fieldSpacing),
        ],
      ),
    );
  }
}
