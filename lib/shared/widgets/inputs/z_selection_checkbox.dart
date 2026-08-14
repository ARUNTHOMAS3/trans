import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// The standard row-selection checkbox: compact 20×20, blue fill with a white
/// tick, 3px corners.
///
/// Pass a null [value] for the indeterminate state — the "some but not all"
/// dash a select-all header shows over a partial selection.
class ZSelectionCheckbox extends StatelessWidget {
  const ZSelectionCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 20,
  });

  /// `true` checked, `false` clear, `null` indeterminate.
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Checkbox(
        value: value,
        // Only the header needs the third state; a row is checked or it is not.
        tristate: value == null,
        onChanged: onChanged,
        activeColor: AppTheme.primaryBlue,
        checkColor: Colors.white,
        side: const BorderSide(color: AppTheme.borderColorDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
