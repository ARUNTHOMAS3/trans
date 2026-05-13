// FILE: lib/shared/widgets/sections/address_section.dart
//
// Reusable address-section widget that consolidates the identical billing /
// shipping address blocks previously duplicated in:
//   lib/modules/sales/presentation/sections/sales_customer_address_section.dart
//   lib/modules/purchases/vendors/presentation/sections/purchases_vendors_address_section.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/form_row.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/phone_input_field.dart';

// ─── Widget ───────────────────────────────────────────────────────────────────

/// A self-contained address card widget.
///
/// Renders a [ZerpaiFormCard] with a heading ([title]) and the standard
/// address field set in [ZerpaiFormRow] layout:
///
/// 1. Attention
/// 2. Street Address 1
/// 3. Street Address 2
/// 4. City
/// 5. Pin Code
/// 6. Country / Region   — [FormDropdown]
/// 7. State / UT         — [FormDropdown], dependent on country
/// 8. Phone              — [PhoneInputField]
///
/// If [showCopyFromBilling] is `true`, a "Copy billing address" ink-well link
/// is displayed in the card heading row, and [onCopyFromBilling] is called when
/// tapped.
///
/// All country and state option lists are supplied by the parent screen so the
/// widget stays pure and testable.
///
/// Usage:
/// ```dart
/// AddressSection(
///   title: 'Billing Address',
///   attentionCtrl: _billingAttentionCtrl,
///   street1Ctrl: _billingStreet1Ctrl,
///   street2Ctrl: _billingStreet2Ctrl,
///   cityCtrl: _billingCityCtrl,
///   pincodeCtrl: _billingPinCtrl,
///   phoneCtrl: _billingPhoneCtrl,
///   phonePrefix: _billingPhoneCode,
///   onPhonePrefixChanged: (v) => setState(() => _billingPhoneCode = v ?? '+91'),
///   selectedCountry: _billingCountry,
///   selectedState: _billingState,
///   onCountryChanged: (v) => setState(() { _billingCountry = v; _billingState = null; }),
///   onStateChanged: (v) => setState(() => _billingState = v),
///   countryOptions: _countries,
///   stateOptions: _states,
/// )
/// ```
class AddressSection extends StatelessWidget {
  // ── Section heading ──────────────────────────────────────────────────────────

  /// Card heading, e.g. `'Billing Address'` or `'Shipping Address'`.
  final String title;

  // ── Text controllers ─────────────────────────────────────────────────────────

  final TextEditingController attentionCtrl;
  final TextEditingController street1Ctrl;
  final TextEditingController street2Ctrl;
  final TextEditingController cityCtrl;
  final TextEditingController pincodeCtrl;
  final TextEditingController phoneCtrl;

  // ── Phone prefix ──────────────────────────────────────────────────────────────

  /// Currently selected country-code prefix, e.g. `'+91'`.
  final String phonePrefix;

  /// Called when the user selects a different country-code prefix.
  final void Function(String?)? onPhonePrefixChanged;

  // ── Dropdown values & callbacks ───────────────────────────────────────────────

  final String? selectedCountry;
  final String? selectedState;

  final void Function(String?)? onCountryChanged;

  /// Called when the state changes. Receives the new state name.
  /// Pass `allowCustomValue: true` when your state dropdown allows free-text.
  final void Function(String?)? onStateChanged;

  // ── Dropdown option lists ─────────────────────────────────────────────────────

  /// Country names to populate the country [FormDropdown].
  final List<String> countryOptions;

  /// State / UT names to populate the state [FormDropdown].
  final List<String> stateOptions;

  /// Whether the state [FormDropdown] is still loading.
  final bool statesLoading;

  // ── Copy from billing ─────────────────────────────────────────────────────────

  /// If `true`, a "Copy billing address" link is shown in the card heading.
  final bool showCopyFromBilling;

  /// Called when "Copy billing address" is tapped.
  final VoidCallback? onCopyFromBilling;

  // ── Enabled state ─────────────────────────────────────────────────────────────

  /// Whether the section's fields are interactive.
  final bool enabled;

  // ── Input height ──────────────────────────────────────────────────────────────

  final double inputHeight;

  const AddressSection({
    super.key,
    required this.title,
    required this.attentionCtrl,
    required this.street1Ctrl,
    required this.street2Ctrl,
    required this.cityCtrl,
    required this.pincodeCtrl,
    required this.phoneCtrl,
    this.phonePrefix = '+91',
    this.onPhonePrefixChanged,
    this.selectedCountry,
    this.selectedState,
    this.onCountryChanged,
    this.onStateChanged,
    this.countryOptions = const [],
    this.stateOptions = const [],
    this.statesLoading = false,
    this.showCopyFromBilling = false,
    this.onCopyFromBilling,
    this.enabled = true,
    this.inputHeight = AppTheme.inputHeight,
  });

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ZerpaiFormCard(
      children: [
        // Card heading row
        _buildHeading(),
        kZerpaiFormDivider,

        // Attention
        ZerpaiFormRow(
          label: 'Attention',
          child: CustomTextField(
            height: inputHeight,
            controller: attentionCtrl,
            forceUppercase: false,
            enabled: enabled,
          ),
        ),
        kZerpaiFormDivider,

        // Street
        ZerpaiFormRow(
          label: 'Street Address 1',
          child: CustomTextField(
            height: inputHeight,
            controller: street1Ctrl,
            hintText: 'Street',
            forceUppercase: false,
            enabled: enabled,
          ),
        ),
        kZerpaiFormDivider,

        // Place
        ZerpaiFormRow(
          label: 'Street Address 2',
          child: CustomTextField(
            height: inputHeight,
            controller: street2Ctrl,
            hintText: 'Place',
            forceUppercase: false,
            enabled: enabled,
          ),
        ),
        kZerpaiFormDivider,

        // City
        ZerpaiFormRow(
          label: 'City',
          child: CustomTextField(
            height: inputHeight,
            controller: cityCtrl,
            forceUppercase: false,
            enabled: enabled,
          ),
        ),
        kZerpaiFormDivider,

        // Pin code
        ZerpaiFormRow(
          label: 'Pin Code',
          child: CustomTextField(
            height: inputHeight,
            controller: pincodeCtrl,
            forceUppercase: false,
            keyboardType: TextInputType.number,
            enabled: enabled,
          ),
        ),
        kZerpaiFormDivider,

        // Country / Region
        ZerpaiFormRow(
          label: 'Country / Region',
          child: FormDropdown<String>(
            height: inputHeight,
            value: (selectedCountry?.isNotEmpty ?? false)
                ? selectedCountry
                : null,
            hint: 'Select',
            items: countryOptions,
            enabled: enabled,
            onChanged: onCountryChanged ?? (_) {},
          ),
        ),
        kZerpaiFormDivider,

        // State / Union territory
        ZerpaiFormRow(
          label: 'State / Union territory',
          child: FormDropdown<String>(
            height: inputHeight,
            value: (selectedState?.isNotEmpty ?? false) ? selectedState : null,
            hint: 'Select or type to add',
            items: stateOptions,
            allowCustomValue: true,
            isLoading: statesLoading,
            enabled: enabled,
            onChanged: onStateChanged ?? (_) {},
          ),
        ),
        kZerpaiFormDivider,

        // Phone
        ZerpaiFormRow(
          label: 'Phone',
          child: PhoneInputField(
            selectedPrefix: phonePrefix,
            controller: phoneCtrl,
            enabled: enabled,
            onPrefixChanged: onPhonePrefixChanged,
          ),
        ),
      ],
    );
  }

  // ── Heading ──────────────────────────────────────────────────────────────────

  Widget _buildHeading() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTheme.sectionHeader,
          ),
          if (showCopyFromBilling && onCopyFromBilling != null) ...[
            const SizedBox(width: AppTheme.space8),
            Text(
              '(',
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              LucideIcons.arrowDown,
              size: 14,
              color: AppTheme.primaryBlueDark,
            ),
            const SizedBox(width: AppTheme.space4),
            InkWell(
              onTap: onCopyFromBilling,
              borderRadius: BorderRadius.circular(2),
              child: Text(
                'Copy billing address',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space4),
            Text(
              ')',
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
