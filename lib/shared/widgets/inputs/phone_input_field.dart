// FILE: lib/shared/widgets/inputs/phone_input_field.dart
//
// Reusable phone input combining a country-code FormDropdown and a digits-only
// CustomTextField.  Based on the pattern used in:
//   lib/modules/sales/presentation/sections/sales_customer_builders.dart
//   lib/modules/purchases/vendors/presentation/sections/purchases_vendors_helpers.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/shared/constants/phone_prefixes.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

/// A compound phone-number input that pairs a country-code selector (90 px wide)
/// with a digit-only text field that enforces the per-country max-digit limit.
///
/// Usage:
/// ```dart
/// PhoneInputField(
///   selectedPrefix: _prefix,         // e.g. '+91'
///   controller: _phoneController,
///   onPrefixChanged: (v) => setState(() => _prefix = v ?? '+91'),
/// )
/// ```
class PhoneInputField extends StatelessWidget {
  /// Currently selected country code, e.g. `'+91'`. Defaults to first option
  /// in [phonePrefixOptions] when null.
  final String? selectedPrefix;

  /// Controller for the phone number digits field.
  final TextEditingController controller;

  /// Called when the country-code prefix is changed.
  final void Function(String?)? onPrefixChanged;
  final ValueChanged<String>? onChanged;

  /// Placeholder text for the digit field. Defaults to `'Phone number'`.
  final String? hintText;
  final String? errorText;

  /// Whether both sub-fields are interactive. Defaults to `true`.
  final bool enabled;

  /// Validator applied to the digit text field.
  final String? Function(String?)? validator;

  /// Optional external [FocusNode] for the digit text field.
  final FocusNode? focusNode;

  const PhoneInputField({
    super.key,
    this.selectedPrefix,
    required this.controller,
    this.onPrefixChanged,
    this.onChanged,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.validator,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final String effectivePrefix = selectedPrefix ?? phonePrefixOptions.first;
    final int maxDigits = phonePrefixMaxDigits[effectivePrefix] ?? 15;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Country code dropdown ──────────────────────────────────────────
        SizedBox(
          width: 72,
          child: FormDropdown<String>(
            value: effectivePrefix,
            items: phonePrefixOptions,
            enabled: enabled,
            hint: '+91',
            // Show the raw code (e.g. '+91') in the closed button.
            displayStringForValue: (v) => v,
            // Show the full labelled string (flag + name) in the list items.
            searchStringForValue: (v) =>
                phonePrefixLabels[v] ?? v,
            itemBuilder: (item, isSelected, isHovered) {
              return _PrefixListRow(
                code: item,
                label: phonePrefixLabels[item] ?? item,
                isSelected: isSelected,
                isHovered: isHovered,
              );
            },
            onChanged: (v) => onPrefixChanged?.call(v),
            // Remove outer borders on right side so the row looks unified.
            showRightBorder: false,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            menuWidth: 260,
          ),
        ),

        // ── Digit text field ───────────────────────────────────────────────
        Expanded(
          child: CustomTextField(
            controller: controller,
            hintText: hintText ?? 'Phone number',
            errorText: errorText,
            keyboardType: TextInputType.phone,
            enabled: enabled,
            focusNode: focusNode,
            onChanged: onChanged,
            validator: validator ?? (effectivePrefix == '+91'
                ? (val) {
                    if (val != null && val.isNotEmpty) {
                      if (val.length < 10) return 'Must be 10 digits';
                      if (!RegExp(r'^[6-9]').hasMatch(val)) {
                        return 'Must start with 6, 7, 8, or 9';
                      }
                    }
                    return null;
                  }
                : null),
            // Digits-only + length cap from the country map.
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(maxDigits),
            ],
            // Suppress the auto-uppercase that CustomTextField applies by
            // default for non-number fields.
            contentCase: ContentCase.none,
            // Remove left border so the two widgets visually merge.
            showLeftBorder: false,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Internal list-row widget ────────────────────────────────────────────────

class _PrefixListRow extends StatelessWidget {
  final String code;
  final String label;
  final bool isSelected;
  final bool isHovered;

  const _PrefixListRow({
    required this.code,
    required this.label,
    required this.isSelected,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isHovered
        ? const Color(0xFF3B82F6) // AppTheme.infoBlue equivalent
        : Colors.transparent;
    final Color textColor = isHovered ? Colors.white : const Color(0xFF111827);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: bg,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight:
                    isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check,
              size: 16,
              color: isHovered ? Colors.white : const Color(0xFF1D4ED8),
            ),
        ],
      ),
    );
  }
}
