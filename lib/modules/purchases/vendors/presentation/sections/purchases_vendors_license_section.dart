part of '../purchases_vendors_vendor_create.dart';

extension _LicenseSection on _PurchasesVendorsVendorCreateScreenState {
  Widget _buildLicenseSection() {
    const double inputWidth = 280.0;

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
                  activeColor: AppTheme.primaryBlueDark,
                  onChanged: (v) => _state(() => isDrugRegistered = v ?? false),
                ),
                const Text(
                  'This Vendor Is Registered Drug Licence',
                  style: TextStyle(fontSize: 13, color: AppTheme.textBody),
                ),
              ],
            ),
          ),
          if (isDrugRegistered) ...[
            SizedBox(height: _fieldSpacing),
            _buildFormRow(
              label: 'Drug Licence Type',
              isRequired: true,
              showInfo: true,
              tooltip: 'Select the type of drug licence held by this vendor.',
              child: SizedBox(
                width: inputWidth,
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
                isRequired: true,
                showInfo: true,
                tooltip:
                    'Enter the Drug License Number (Form 20) for retail sale of drugs.',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: inputWidth,
                      child: CustomTextField(
                        height: _inputHeight,
                        controller: drugLicense20Ctrl,
                        focusNode: drugLicense20Focus,
                        errorText: drugLicense20Error,
                        forceUppercase: true,
                        hintText: 'Enter the License Number',
                      ),
                    ),
                    const SizedBox(width: 12),
                    FileUploadButton(
                      files: drugLicense20Docs,
                      height: _inputHeight,
                      onFilesChanged: (updated) => _state(() => drugLicense20Docs = updated),
                    ),
                  ],
                ),
              ),
              SizedBox(height: _fieldSpacing),
              _buildFormRow(
                label: 'Drug License 21',
                isRequired: true,
                showInfo: true,
                tooltip:
                    'Enter the Drug License Number (Form 21) for retail sale of drugs.',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: inputWidth,
                      child: CustomTextField(
                        height: _inputHeight,
                        controller: drugLicense21Ctrl,
                        focusNode: drugLicense21Focus,
                        errorText: drugLicense21Error,
                        forceUppercase: true,
                        hintText: 'Enter the License Number',
                      ),
                    ),
                    const SizedBox(width: 12),
                    FileUploadButton(
                      files: drugLicense21Docs,
                      height: _inputHeight,
                      onFilesChanged: (updated) => _state(() => drugLicense21Docs = updated),
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
                isRequired: true,
                showInfo: true,
                tooltip:
                    'Enter the Drug License Number (Form 20B) for sale/distribution of drugs.',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: inputWidth,
                      child: CustomTextField(
                        height: _inputHeight,
                        controller: drugLicense20BCtrl,
                        focusNode: drugLicense20BFocus,
                        errorText: drugLicense20BError,
                        forceUppercase: true,
                        hintText: 'Enter the License Number',
                      ),
                    ),
                    const SizedBox(width: 12),
                    FileUploadButton(
                      files: drugLicense20BDocs,
                      height: _inputHeight,
                      onFilesChanged: (updated) => _state(() => drugLicense20BDocs = updated),
                    ),
                  ],
                ),
              ),
              SizedBox(height: _fieldSpacing),
              _buildFormRow(
                label: 'Drug License 21B',
                isRequired: true,
                showInfo: true,
                tooltip:
                    'Enter the Drug License Number (Form 21B) for sale/distribution of drugs.',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: inputWidth,
                      child: CustomTextField(
                        height: _inputHeight,
                        controller: drugLicense21BCtrl,
                        focusNode: drugLicense21BFocus,
                        errorText: drugLicense21BError,
                        forceUppercase: true,
                        hintText: 'Enter the License Number',
                      ),
                    ),
                    const SizedBox(width: 12),
                    FileUploadButton(
                      files: drugLicense21BDocs,
                      height: _inputHeight,
                      onFilesChanged: (updated) => _state(() => drugLicense21BDocs = updated),
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
                  activeColor: AppTheme.primaryBlueDark,
                  onChanged: (v) =>
                      _state(() => isFssaiRegistered = v ?? false),
                ),
                const Text(
                  'This Vendor Is Registered FSSAI License',
                  style: TextStyle(fontSize: 13, color: AppTheme.textBody),
                ),
              ],
            ),
          ),
          if (isFssaiRegistered) ...[
            SizedBox(height: _fieldSpacing),
            _buildFormRow(
              label: 'FSSAI Number',
              isRequired: true,
              showInfo: true,
              tooltip:
                  'Enter the 14-digit FSSAI (Food Safety and Standards Authority of India) license number.',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: inputWidth,
                    child: CustomTextField(
                      height: _inputHeight,
                      controller: fssaiCtrl,
                      focusNode: fssaiFocus,
                      errorText: fssaiError,
                      forceUppercase: true,
                      hintText: 'Enter the FSSAI Number',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FileUploadButton(
                    files: fssaiDocs,
                    height: _inputHeight,
                    onFilesChanged: (updated) => _state(() => fssaiDocs = updated),
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
                  value: _isMsmeRegistered,
                  activeColor: AppTheme.primaryBlueDark,
                  onChanged: (v) =>
                      _state(() => _isMsmeRegistered = v ?? false),
                ),
                const Text(
                  'This Vendor Is Registered MSME',
                  style: TextStyle(fontSize: 13, color: AppTheme.textBody),
                ),
              ],
            ),
          ),
          if (_isMsmeRegistered) ...[
            SizedBox(height: _fieldSpacing),
            _buildFormRow(
              label: 'MSME/Udyam Registration Type',
              isRequired: true,
              showInfo: true,
              tooltip: 'Select the type of MSME/Udyam registration.',
              child: SizedBox(
                width: inputWidth,
                child: FormDropdown<String>(
                  height: _inputHeight,
                  value: _msmeRegistrationType,
                  hint: 'Select the Registration Type',
                  items: const ['Micro', 'Small', 'Medium'],
                  onChanged: (v) => _state(() => _msmeRegistrationType = v),
                ),
              ),
            ),
            SizedBox(height: _fieldSpacing),
            _buildFormRow(
              label: 'MSME/Udyam Registration Number',
              isRequired: true,
              showInfo: true,
              tooltip:
                  'Enter the MSME/Udyam Registration Number issued by the Ministry of MSME.',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: inputWidth,
                    child: CustomTextField(
                      height: _inputHeight,
                      controller: _msmeRegistrationNumberCtrl,
                      focusNode: msmeFocus,
                      errorText: msmeError,
                      forceUppercase: true,
                      hintText: 'Enter the Registration Number',
                    ),
                  ),
                  const SizedBox(width: 12),
                  FileUploadButton(
                    files: msmeDocs,
                    height: _inputHeight,
                    onFilesChanged: (updated) => _state(() => msmeDocs = updated),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

}
