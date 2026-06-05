// FILE: lib/shared/utils/display_name_utils.dart
// Centralised display name generation logic shared by sales customers and
// purchases vendors modules (Zoho-style name combination).

/// Utilities for generating display name option lists from individual name parts.
///
/// Eliminates the duplicated `_refreshDisplayNameOptions` /
/// `_buildDisplayNameOptions` logic in the sales and purchases helper files.
class DisplayNameUtils {
  DisplayNameUtils._();

  /// Generates a list of display name options from the given name parts.
  ///
  /// Follows Zoho-style name combination logic. All combinations are built
  /// from non-empty parts only. Duplicates and empty strings are removed.
  ///
  /// Example — salutation='Mr.', firstName='John', lastName='Doe':
  /// ```
  /// ['John Doe', 'Doe John', 'Mr. John Doe', 'John', 'Doe']
  /// ```
  ///
  /// If [companyName] is provided and non-empty, it is appended as the last
  /// option (unless it would be a duplicate).
  static List<String> generateOptions({
    required String salutation,
    required String firstName,
    required String lastName,
    String? companyName,
  }) {
    final s = salutation.trim();
    final f = firstName.trim();
    final l = lastName.trim();
    final c = companyName?.trim() ?? '';

    final candidates = <String>[];

    // firstName + lastName
    if (f.isNotEmpty && l.isNotEmpty) {
      candidates.add('$f $l');
    }

    // lastName + firstName
    if (l.isNotEmpty && f.isNotEmpty) {
      candidates.add('$l $f');
    }

    // salutation + firstName + lastName
    if (s.isNotEmpty && f.isNotEmpty && l.isNotEmpty) {
      candidates.add('$s $f $l');
    } else if (s.isNotEmpty && f.isNotEmpty) {
      candidates.add('$s $f');
    } else if (s.isNotEmpty && l.isNotEmpty) {
      candidates.add('$s $l');
    }

    // firstName alone
    if (f.isNotEmpty) {
      candidates.add(f);
    }

    // lastName alone
    if (l.isNotEmpty) {
      candidates.add(l);
    }

    // company name (appended last)
    if (c.isNotEmpty) {
      candidates.add(c);
    }

    // Deduplicate while preserving insertion order.
    final seen = <String>{};
    return candidates
        .where((name) => name.isNotEmpty && seen.add(name))
        .toList();
  }

  /// Returns the best default display name for the given name parts.
  ///
  /// Priority:
  /// 1. salutation + firstName + lastName (all three present)
  /// 2. firstName + lastName (both present)
  /// 3. firstName alone
  /// 4. lastName alone
  /// 5. Empty string if all parts are empty
  static String defaultOption({
    required String salutation,
    required String firstName,
    required String lastName,
  }) {
    final s = salutation.trim();
    final f = firstName.trim();
    final l = lastName.trim();

    if (s.isNotEmpty && f.isNotEmpty && l.isNotEmpty) {
      return '$s $f $l';
    }
    if (f.isNotEmpty && l.isNotEmpty) {
      return '$f $l';
    }
    if (f.isNotEmpty) return f;
    if (l.isNotEmpty) return l;
    return '';
  }
}
