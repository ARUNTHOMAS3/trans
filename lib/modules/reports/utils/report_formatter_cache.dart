import 'package:intl/intl.dart';

class ReportFormatterCache {
  ReportFormatterCache._();

  static final Map<String, DateFormat> _dateFormats = <String, DateFormat>{};
  static final Map<String, NumberFormat> _numberFormats = <String, NumberFormat>{};

  static DateFormat date(String pattern) {
    return _dateFormats.putIfAbsent(pattern, () => DateFormat(pattern));
  }

  static NumberFormat number(String pattern) {
    return _numberFormats.putIfAbsent(pattern, () => NumberFormat(pattern));
  }
}
