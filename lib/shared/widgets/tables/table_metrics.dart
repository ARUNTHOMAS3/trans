/// Shared layout metrics for the fixed-width overview/report tables.
///
/// These tables size a header row and every body row to one explicit
/// `_tableWidth`. That leaves no slack: if the width a table lays out to and
/// the width its rows actually consume disagree by even a pixel, Flutter
/// reports a RenderFlex overflow across the whole table.
///
/// Keeping the non-column widths in one place means the container width and the
/// row content cannot drift apart. Always build the total with [chrome] rather
/// than hardcoding a literal.
class ZTableMetrics {
  const ZTableMetrics._();

  /// Horizontal padding on the header/row container — applied to *each* side.
  static const double hPad = 16;

  /// Column-menu (sliders) icon. Header and rows both drop it while a
  /// selection is active, so the total width must follow.
  static const double menuIcon = 28;

  /// Leading select-all / select-row checkbox.
  static const double checkbox = 32;

  /// Width consumed before the first column.
  static double leading({required bool hasSelection}) =>
      (hasSelection ? 0.0 : menuIcon) + checkbox;

  /// Total width consumed around the columns: padding on both sides plus the
  /// leading widgets. Add this to the sum of the visible column widths to get
  /// the table's total width.
  static double chrome({required bool hasSelection}) =>
      (hPad * 2) + leading(hasSelection: hasSelection);
}
