import 'package:flutter/material.dart';

/// Reusable ERP Currency Display with standardized symbol rendering and formatting.
///
/// Use for prices, amounts, totals in tables and forms.
///
/// Usage:
/// ```dart
/// ZCurrencyDisplay(amount: 1450.50)
/// ```
class ZCurrencyDisplay extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final String symbol;
  final int decimals;

  const ZCurrencyDisplay({
    super.key,
    required this.amount,
    this.style,
    this.symbol = '₹', // Default ERP Currency
    this.decimals = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          symbol,
          style: style?.copyWith(
                fontFamily: 'Roboto', // Ensures the symbol renders correctly
              ) ??
              const TextStyle(fontFamily: 'Roboto'),
        ),
        const SizedBox(width: 4),
        Text(
          amount.toStringAsFixed(decimals),
          style: style,
        ),
      ],
    );
  }
}
