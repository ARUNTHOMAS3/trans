import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// Provides group value and onChanged to descendant [RadioGroupItem] widgets.
class RadioScope<T> extends InheritedWidget {
  final T value;
  final ValueChanged<T> onChanged;

  const RadioScope({
    super.key,
    required this.value,
    required this.onChanged,
    required super.child,
  });

  static RadioScope<T>? maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RadioScope<T>>();
  }

  static RadioScope<T> of<T>(BuildContext context) {
    final result = maybeOf<T>(context);
    assert(result != null, 'No RadioScope found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(RadioScope<T> oldWidget) {
    return value != oldWidget.value || onChanged != oldWidget.onChanged;
  }
}

/// A [Radio] wrapper that reads group value/onChanged from the nearest
/// [RadioScope] ancestor and uses Flutter's [RadioGroup] to avoid deprecated params.
class RadioGroupItem<T> extends StatelessWidget {
  final T value;
  final String? label;
  final Color? activeColor;
  final VisualDensity? visualDensity;
  final MaterialTapTargetSize? materialTapTargetSize;

  const RadioGroupItem({
    super.key,
    required this.value,
    this.label,
    this.activeColor,
    this.visualDensity,
    this.materialTapTargetSize,
  });

  @override
  Widget build(BuildContext context) {
    final group = RadioScope.of<T>(context);

    final radio = RadioGroup<T>(
      groupValue: group.value,
      onChanged: (v) {
        if (v != null) group.onChanged(v);
      },
      child: Radio<T>(
        value: value,
        activeColor: activeColor,
        visualDensity: visualDensity,
        materialTapTargetSize: materialTapTargetSize,
      ),
    );

    if (label == null) return radio;

    return InkWell(
      onTap: () => group.onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          radio,
          const SizedBox(width: 4),
          Text(
            label!,
            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
