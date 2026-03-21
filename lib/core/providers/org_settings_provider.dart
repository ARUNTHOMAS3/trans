import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';

// TODO(auth): Remove once auth is enabled — dev-mode default org UUID.
const String _kDevOrgId = '00000000-0000-0000-0000-000000000002';

/// Fetches and caches the current organization's profile settings.
/// Keyed by orgId so invalidation is clean on org switch.
final orgSettingsProvider =
    FutureProvider.autoDispose<OrgSettings?>((ref) async {
  final user = ref.watch(authUserProvider);
  // TODO(auth): Remove _kDevOrgId fallback once auth is enabled.
  final orgId =
      (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;

  final api = ref.watch(apiClientProvider);
  final response = await api.get('/lookups/org/$orgId');

  if (response.statusCode == 200 && response.data != null) {
    final data = response.data as Map<String, dynamic>;
    return OrgSettings.fromJson(data);
  }
  return null;
});

/// Convenience provider — returns the org's base currency code (e.g. 'INR').
/// Falls back to 'INR' while loading or on error.
final orgCurrencyCodeProvider = Provider<String>((ref) {
  return ref
          .watch(orgSettingsProvider)
          .whenOrNull(data: (s) => s?.baseCurrency) ??
      'INR';
});

/// Convenience provider — returns the org's resolved date format pattern
/// with the separator applied. Ready to pass straight into DateFormat().
final orgDateFormatProvider = Provider<String>((ref) {
  final settings = ref.watch(orgSettingsProvider).whenOrNull(data: (s) => s);
  if (settings == null) return 'dd MMM yyyy';
  return _applyDateSeparator(settings.dateFormat, settings.dateSeparator);
});

/// Replaces '-' in numeric-only date format patterns with the chosen separator.
/// Long formats (those using MMM / MMMM / EEE / EEEE) are left unchanged
/// because they rely on space/comma delimiters, not dashes.
String _applyDateSeparator(String pattern, String separator) {
  if (separator == '-') return pattern;
  final isNumericPattern = !pattern.contains('MMM') &&
      !pattern.contains('MMMM') &&
      !pattern.contains('EEE') &&
      !pattern.contains('EEEE');
  return isNumericPattern ? pattern.replaceAll('-', separator) : pattern;
}
