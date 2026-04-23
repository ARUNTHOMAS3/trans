import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';

/// Global date formatter that respects the organization's date format
/// and date separator settings.
///
/// Usage (in a ConsumerWidget / ConsumerState):
///   AppDateFormatter.of(ref).format(date)
///
/// Or statically with explicit settings:
///   AppDateFormatter.formatWith(date, pattern: 'dd MMM yyyy', separator: '-')
class AppDateFormatter {
  final String _pattern;

  const AppDateFormatter._(this._pattern);

  /// Resolves formatter from the current org settings via Riverpod.
  factory AppDateFormatter.of(WidgetRef ref) {
    final pattern = ref.watch(orgDateFormatProvider);
    return AppDateFormatter._(pattern);
  }

  /// Formats [date] using the org's resolved pattern.
  String format(DateTime date) => DateFormat(_pattern).format(date);

  /// Formats [date] using an explicit pattern + separator.
  /// Useful when the caller already knows the pattern (e.g. API date fields).
  static String formatWith(
    DateTime date, {
    String pattern = 'dd MMM yyyy',
    String separator = '-',
  }) {
    final resolved = _applyDateSeparator(pattern, separator);
    return DateFormat(resolved).format(date);
  }

  static String _applyDateSeparator(String pattern, String separator) {
    if (separator == '-') return pattern;
    final isNumeric = !pattern.contains('MMM') &&
        !pattern.contains('MMMM') &&
        !pattern.contains('EEE') &&
        !pattern.contains('EEEE');
    return isNumeric ? pattern.replaceAll('-', separator) : pattern;
  }
}
