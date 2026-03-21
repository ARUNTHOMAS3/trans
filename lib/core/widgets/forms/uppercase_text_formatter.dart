import 'package:flutter/services.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final uppercase = newValue.text.toUpperCase();
    if (newValue.text == uppercase) {
      return newValue;
    }
    return newValue.copyWith(
      text: uppercase,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
