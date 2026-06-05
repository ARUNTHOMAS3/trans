// FILE: lib/shared/utils/gstin_prefill_utils.dart
// Centralised GSTIN prefill application, PAN extraction, and format
// validation logic shared by sales and purchases modules.

import 'package:flutter/widgets.dart';

/// Utilities for applying GSTIN lookup results to form controller maps,
/// extracting PAN numbers, and validating GSTIN format.
///
/// Eliminates the duplicated `_applyGstinPrefill()` logic in the sales and
/// purchases helper files.
class GstinPrefillUtils {
  GstinPrefillUtils._();

  // Standard 15-character GSTIN pattern:
  // 2-digit state code + 10-char PAN + 1 entity number + 1 alpha + 1 check digit
  static final RegExp _gstinRegex =
      RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');

  /// Applies GSTIN lookup result fields to the provided controller map.
  ///
  /// A controller is updated only when:
  /// - The lookup result contains a non-null, non-empty value for that field.
  /// - A matching controller key exists in [controllers] (either directly or
  ///   via [keyMapping]).
  ///
  /// [prefillData] — map of field name → value from the GSTIN lookup API.
  ///   Common keys: `legalName`, `tradeName`, `pan`, `address`, `state`,
  ///   `city`, `pincode`, `gstTreatment`, `email`, `phone`.
  ///
  /// [controllers] — map of controller key → TextEditingController.
  ///
  /// [keyMapping] — optional alias map from prefillData keys to controller keys.
  ///   e.g. `{'legalName': 'companyName', 'pan': 'panNumber'}`.
  ///
  /// Returns the list of controller keys that were actually updated.
  static List<String> applyToControllers({
    required Map<String, dynamic> prefillData,
    required Map<String, TextEditingController> controllers,
    Map<String, String>? keyMapping,
  }) {
    final updated = <String>[];

    for (final entry in prefillData.entries) {
      final rawValue = entry.value;
      if (rawValue == null) continue;

      final value = rawValue.toString().trim();
      if (value.isEmpty) continue;

      // Resolve the controller key — prefer alias from keyMapping, fall back
      // to the original prefillData key.
      final prefillKey = entry.key;
      final controllerKey =
          keyMapping != null && keyMapping.containsKey(prefillKey)
              ? keyMapping[prefillKey]!
              : prefillKey;

      final controller = controllers[controllerKey];
      if (controller == null) continue;

      controller.text = value;
      updated.add(controllerKey);
    }

    return updated;
  }

  /// Extracts the PAN number embedded in a GSTIN string.
  ///
  /// GSTIN format: `SS PPPPPNNNNP E Z C`
  ///   - SS  = 2-digit state code (indices 0–1)
  ///   - PAN = 10-character PAN (indices 2–11)
  ///   - E   = entity number (index 12)
  ///   - Z   = always 'Z' (index 13)
  ///   - C   = check digit (index 14)
  ///
  /// Returns `null` if the GSTIN is shorter than 12 characters.
  static String? extractPanFromGstin(String gstin) {
    final g = gstin.trim().toUpperCase();
    if (g.length < 12) return null;
    return g.substring(2, 12);
  }

  /// Returns `true` if [gstin] matches the standard 15-character GSTIN format.
  ///
  /// Pattern: 2-digit state code + 5 uppercase letters + 4 digits +
  ///          1 uppercase letter + 1 alphanumeric + 'Z' + 1 alphanumeric.
  static bool isValidGstinFormat(String gstin) {
    return _gstinRegex.hasMatch(gstin.trim().toUpperCase());
  }
}
