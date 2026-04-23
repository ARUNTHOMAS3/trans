// FILE: lib/shared/widgets/sections/license_registration_section.dart
//
// Reusable license/registration section widget that consolidates the
// Drug Licence, FSSAI, and MSME registration patterns previously duplicated
// in:
//   lib/modules/sales/presentation/sections/sales_customer_licence_section.dart
//   lib/modules/purchases/vendors/presentation/sections/purchases_vendors_license_section.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/form_row.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';

// ─── Enum ─────────────────────────────────────────────────────────────────────

/// Which type of licence/registration block this widget renders.
enum LicenseType { drug, fssai, msme }

// ─── Widget ───────────────────────────────────────────────────────────────────

/// A self-contained, reusable licence/registration block.
///
/// Renders a toggle row followed (when enabled) by the relevant fields:
/// - [LicenseType.drug]  — licence-type FormDropdown + per-form-number
///                         CustomTextField + FileUploadButton pairs.
/// - [LicenseType.fssai] — single registration-number field + FileUploadButton.
/// - [LicenseType.msme]  — registration-type dropdown + registration-number
///                         field + FileUploadButton.
///
/// All layout uses [ZerpaiFormRow] / [ZerpaiFormCard] with [AppTheme] tokens.
///
/// ### Drug key map
/// | Key   | Shown when drug-licence type includes… |
/// |-------|---------------------------------------|
/// | `'20'`  | Retail or Wholesale and Retail        |
/// | `'21'`  | Retail or Wholesale and Retail        |
/// | `'20B'` | Wholesale or Wholesale and Retail     |
/// | `'21B'` | Wholesale or Wholesale and Retail     |
///
/// ### FSSAI key
/// | Key      | Field                     |
/// |----------|---------------------------|
/// | `'fssai'` | FSSAI registration number |
///
/// ### MSME keys
/// | Key           | Field                          |
/// |---------------|-------------------------------|
/// | `'msmeType'`  | Registration type (not shown as text field — managed via [drugLicenceType] slot for MSME type) |
/// | `'msme'`      | MSME/Udyam registration number |
class LicenseRegistrationSection extends StatelessWidget {
  // ── Toggle ──────────────────────────────────────────────────────────────────

  /// Whether this registration type is currently enabled.
  final bool isRegistered;

  /// Called when the user toggles the registration checkbox.
  final void Function(bool) onRegisteredChanged;

  // ── Drug-only ────────────────────────────────────────────────────────────────

  /// Currently selected drug-licence type string.
  /// One of: `'Wholesale'`, `'Retail'`, `'Wholesale and Retail'`.
  /// `null` for [LicenseType.fssai] and [LicenseType.msme].
  final String? drugLicenceType;

  /// Called when the drug-licence type dropdown changes.
  /// Ignored for non-drug licence types.
  final void Function(String?)? onDrugLicenceTypeChanged;

  // ── MSME-only ────────────────────────────────────────────────────────────────

  /// Currently selected MSME registration type.
  /// One of: `'Micro'`, `'Small'`, `'Medium'`.
  /// `null` for non-MSME licence types.
  final String? msmeRegistrationType;

  /// Called when the MSME registration-type dropdown changes.
  final void Function(String?)? onMsmeRegistrationTypeChanged;

  // ── Number controllers ───────────────────────────────────────────────────────

  /// Controllers keyed by field identifier:
  /// - Drug: `'20'`, `'21'`, `'20B'`, `'21B'`
  /// - FSSAI: `'fssai'`
  /// - MSME: `'msme'`
  final Map<String, TextEditingController> numberControllers;

  // ── Files ────────────────────────────────────────────────────────────────────

  /// Currently attached files per field key (same keys as [numberControllers]).
  final Map<String, List<PlatformFile>> selectedFiles;

  /// Called when files are added or removed for a given field [key].
  final void Function(String key, List<PlatformFile> files) onFilesChanged;

  // ── Errors ───────────────────────────────────────────────────────────────────

  /// Validation error texts per field key. Shown below the relevant field in
  /// [AppTheme.errorRed].
  final Map<String, String?> errorTexts;

  // ── Identity ─────────────────────────────────────────────────────────────────

  /// Which type of registration block this widget renders.
  final LicenseType licenseType;

  /// Label shown next to the toggle checkbox, e.g. `'Drug Licence'`.
  final String label;

  // ── Input height (matches existing screens) ───────────────────────────────────

  /// Height passed to all CustomTextField and FormDropdown children.
  final double inputHeight;

  /// Width constraint applied to text fields and dropdowns.
  final double inputWidth;

  const LicenseRegistrationSection({
    super.key,
    required this.isRegistered,
    required this.onRegisteredChanged,
    required this.numberControllers,
    required this.selectedFiles,
    required this.onFilesChanged,
    required this.errorTexts,
    required this.licenseType,
    required this.label,
    this.drugLicenceType,
    this.onDrugLicenceTypeChanged,
    this.msmeRegistrationType,
    this.onMsmeRegistrationTypeChanged,
    this.inputHeight = AppTheme.inputHeight,
    this.inputWidth = 280.0,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────────

  List<PlatformFile> _files(String key) => selectedFiles[key] ?? [];
  String? _error(String key) => errorTexts[key];

  Widget _licenceField({
    required String formRowLabel,
    required String key,
    required String hintText,
    bool numeric = false,
    String? tooltip,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZerpaiFormRow(
          label: formRowLabel,
          required: true,
          tooltipMessage: tooltip,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: inputWidth,
                child: CustomTextField(
                  height: inputHeight,
                  controller: numberControllers[key] ?? TextEditingController(),
                  errorText: _error(key),
                  forceUppercase: true,
                  hintText: hintText,
                  keyboardType: numeric
                      ? TextInputType.number
                      : TextInputType.text,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              FileUploadButton(
                files: _files(key),
                height: inputHeight,
                onFilesChanged: (updated) => onFilesChanged(key, updated),
              ),
            ],
          ),
        ),
        kZerpaiFormDivider,
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle row
        ZerpaiFormRow(
          label: '$label Registered?',
          child: Row(
            children: [
              Checkbox(
                value: isRegistered,
                activeColor: AppTheme.primaryBlueDark,
                onChanged: (v) => onRegisteredChanged(v ?? false),
              ),
              const SizedBox(width: AppTheme.space4),
              Text(
                'Registered for $label',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: AppTheme.textBody,
                ),
              ),
            ],
          ),
        ),

        // Fields shown only when registered
        if (isRegistered) ...[
          kZerpaiFormDivider,
          ..._buildFields(),
        ],
      ],
    );
  }

  List<Widget> _buildFields() {
    switch (licenseType) {
      case LicenseType.drug:
        return _buildDrugFields();
      case LicenseType.fssai:
        return _buildFssaiFields();
      case LicenseType.msme:
        return _buildMsmeFields();
    }
  }

  // ── Drug fields ───────────────────────────────────────────────────────────────

  List<Widget> _buildDrugFields() {
    final showRetail = drugLicenceType == 'Retail' ||
        drugLicenceType == 'Wholesale and Retail';
    final showWholesale = drugLicenceType == 'Wholesale' ||
        drugLicenceType == 'Wholesale and Retail';

    return [
      // Licence-type dropdown
      ZerpaiFormRow(
        label: 'Drug Licence Type',
        required: true,
        tooltipMessage: 'Select the type of drug licence.',
        child: SizedBox(
          width: inputWidth,
          child: FormDropdown<String>(
            height: inputHeight,
            value: drugLicenceType,
            hint: 'Select licence type',
            items: const ['Wholesale', 'Retail', 'Wholesale and Retail'],
            onChanged: onDrugLicenceTypeChanged ?? (_) {},
          ),
        ),
      ),
      kZerpaiFormDivider,

      // Retail forms (20, 21)
      if (showRetail) ...[
        _licenceField(
          formRowLabel: 'Drug License 20',
          key: '20',
          hintText: 'Enter the license number',
          tooltip:
              'Enter the Drug License Number (Form 20) for retail sale of drugs.',
        ),
        _licenceField(
          formRowLabel: 'Drug License 21',
          key: '21',
          hintText: 'Enter the license number',
          tooltip:
              'Enter the Drug License Number (Form 21) for retail sale of drugs.',
        ),
      ],

      // Wholesale forms (20B, 21B)
      if (showWholesale) ...[
        _licenceField(
          formRowLabel: 'Drug License 20B',
          key: '20B',
          hintText: 'Enter the license number',
          tooltip:
              'Enter the Drug License Number (Form 20B) for sale/distribution of drugs.',
        ),
        _licenceField(
          formRowLabel: 'Drug License 21B',
          key: '21B',
          hintText: 'Enter the license number',
          tooltip:
              'Enter the Drug License Number (Form 21B) for sale/distribution of drugs.',
        ),
      ],
    ];
  }

  // ── FSSAI fields ──────────────────────────────────────────────────────────────

  List<Widget> _buildFssaiFields() {
    return [
      _licenceField(
        formRowLabel: 'FSSAI Number',
        key: 'fssai',
        hintText: 'Enter the FSSAI number',
        numeric: true,
        tooltip:
            'Enter the 14-digit FSSAI (Food Safety and Standards Authority of India) license number.',
      ),
    ];
  }

  // ── MSME fields ───────────────────────────────────────────────────────────────

  List<Widget> _buildMsmeFields() {
    return [
      // Registration type dropdown
      ZerpaiFormRow(
        label: 'MSME/Udyam Registration Type',
        required: true,
        tooltipMessage: 'Select the type of MSME/Udyam registration.',
        child: SizedBox(
          width: inputWidth,
          child: FormDropdown<String>(
            height: inputHeight,
            value: msmeRegistrationType,
            hint: 'Select the registration type',
            items: const ['Micro', 'Small', 'Medium'],
            onChanged: onMsmeRegistrationTypeChanged ?? (_) {},
          ),
        ),
      ),
      kZerpaiFormDivider,

      // Registration number + file
      _licenceField(
        formRowLabel: 'MSME/Udyam Registration Number',
        key: 'msme',
        hintText: 'Enter the registration number',
        tooltip:
            'Enter the MSME/Udyam Registration Number issued by the Ministry of MSME.',
      ),
    ];
  }
}
