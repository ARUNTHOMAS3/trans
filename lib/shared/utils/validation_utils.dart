
import 'package:flutter/services.dart';

bool _isAsciiLetter(String value) => RegExp(r'^[A-Z]$').hasMatch(value);
bool _isDigit(String value) => RegExp(r'^[0-9]$').hasMatch(value);
bool _isAlphaNumeric(String value) => RegExp(r'^[A-Z0-9]$').hasMatch(value);

String sanitizeGstinInput(String value) {
  if (value.isEmpty) return value;

  final upperValue = value.toUpperCase();
  final buffer = StringBuffer();

  for (final rune in upperValue.runes) {
    if (buffer.length >= 15) break;

    final char = String.fromCharCode(rune);

    if (buffer.length == 13) {
      if (char == 'Z') {
        buffer.write('Z');
        continue;
      }

      if (_isAlphaNumeric(char)) {
        buffer.write('Z');
      } else {
        continue;
      }
    }

    switch (buffer.length) {
      case 0:
      case 1:
        if (_isDigit(char)) buffer.write(char);
        break;
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
        if (_isAsciiLetter(char)) buffer.write(char);
        break;
      case 7:
      case 8:
      case 9:
      case 10:
        if (_isDigit(char)) buffer.write(char);
        break;
      case 11:
        if (_isAsciiLetter(char)) buffer.write(char);
        break;
      case 12:
        if (_isAlphaNumeric(char) && char != '0') buffer.write(char);
        break;
      case 13:
        if (char == 'Z') buffer.write(char);
        break;
      case 14:
        if (_isAlphaNumeric(char)) buffer.write(char);
        break;
    }
  }

  return buffer.toString();
}

class GstinTextInputFormatter extends TextInputFormatter {
  const GstinTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final sanitized = sanitizeGstinInput(newValue.text);
    if (sanitized == newValue.text) return newValue;

    return TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length),
      composing: TextRange.empty,
    );
  }
}

/// Validates Goods and Services Tax Identification Number (GSTIN) structure for India.
/// Structure:
/// Digits 1–2: State Code (numeric, 2 digits)
/// Digits 3–12: PAN ([A-Z]{5}[0-9]{4}[A-Z]{1})
/// Digit 13: Entity Number (alphanumeric, 1 digit)
/// Digit 14: Default Character (Always 'Z')
/// Digit 15: Checksum (alphanumeric, 1 digit)
String? validateGstin(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'GSTIN / UIN is required.';
  }
  final cleanValue = value.trim().toUpperCase();
  if (cleanValue.length != 15) {
    return 'Invalid Length: GSTIN must be exactly 15 characters.';
  }

  // 1. State Code Validation (first two characters)
  final stateCodeStr = cleanValue.substring(0, 2);
  final stateCodeInt = int.tryParse(stateCodeStr);
  if (stateCodeInt == null || stateCodeInt < 1 || stateCodeInt > 38) {
    return 'Invalid State Code: The first two digits must represent a valid state code.';
  }

  // 2. PAN Format Validation (chars 3 to 12)
  final panStr = cleanValue.substring(2, 12);
  final panRegExp = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
  if (!panRegExp.hasMatch(panStr)) {
    return 'Invalid PAN Format: Characters 3 to 12 do not match standard PAN structure.';
  }

  // 3. 13th character validation (index 12)
  final entityCodeChar = cleanValue.substring(12, 13);
  final entityRegExp = RegExp(r'^[1-9A-Z]{1}$');
  if (!entityRegExp.hasMatch(entityCodeChar)) {
    return 'Invalid Format: The 13th character must be alphanumeric (excluding zero).';
  }

  // 4. 14th character validation (index 13)
  final defaultChar = cleanValue.substring(13, 14);
  if (defaultChar != 'Z') {
    return "Invalid Format: The 14th character must be 'Z'.";
  }

  // 5. 15th character validation (index 14)
  final checksumChar = cleanValue.substring(14, 15);
  final checksumRegExp = RegExp(r'^[0-9A-Z]{1}$');
  if (!checksumRegExp.hasMatch(checksumChar)) {
    return 'Invalid Format: The 15th character must be alphanumeric.';
  }

  // Overall Regex sanity check
  final overallRegExp = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
  if (!overallRegExp.hasMatch(cleanValue)) {
    return 'Invalid GSTIN format. Expected format: 29ABCDE1234F1Z5';
  }

  return null;
}
