// import 'package:flutter/material.dart';

// class ZerpaiRadioGroup<T> extends StatelessWidget {
//   final List<T> options;
//   final T current;
//   final ValueChanged<T> onChanged;
//   final String Function(T)? labelBuilder;
//   final Color activeColor;
//   final Axis orientation;

//   const ZerpaiRadioGroup({
//     super.key,
//     required this.options,
//     required this.current,
//     required this.onChanged,
//     this.labelBuilder,
//     this.activeColor = const Color(0xFF2563EB),
//     this.orientation = Axis.horizontal,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final children = options.map((option) {
//       final label = labelBuilder?.call(option) ?? option.toString();
//       return InkWell(
//         onTap: () => onChanged(option),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Radio<T>(
//               value: option,
//               activeColor: activeColor,
//               visualDensity: VisualDensity.compact,
//               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             ),
//             const SizedBox(width: 4),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: Color(0xFF1F2937), // text-gray-800
//               ),
//             ),
//           ],
//         ),
//       );
//     }).toList();

//     Widget group = orientation == Axis.vertical
//         ? Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: children
//                 .map(
//                   (e) => Padding(
//                     padding: const EdgeInsets.only(bottom: 8),
//                     child: e,
//                   ),
//                 )
//                 .toList(),
//           )
//         : Wrap(spacing: 16, runSpacing: 8, children: children);

//     return RadioGroup<T>(
//       groupValue: current,
//       onChanged: (v) {
//         if (v != null) onChanged(v);
//       },
//       child: group,
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'radio_group.dart';

class ZerpaiRadioGroup<T> extends StatelessWidget {
  final List<T> options;
  final T current;
  final ValueChanged<T> onChanged;
  final String Function(T)? labelBuilder;
  final Color activeColor;
  final Axis orientation;

  const ZerpaiRadioGroup({
    super.key,
    required this.options,
    required this.current,
    required this.onChanged,
    this.labelBuilder,
    this.activeColor = const Color(0xFF2563EB),
    this.orientation = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final children = options.map((option) {
      return RadioGroupItem<T>(
        value: option,
        label: labelBuilder?.call(option) ?? option.toString(),
        activeColor: activeColor,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }).toList();

    Widget groupBody;
    if (orientation == Axis.vertical) {
      groupBody = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map(
              (e) =>
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: e),
            )
            .toList(),
      );
    } else {
      groupBody = Wrap(spacing: 16, runSpacing: 8, children: children);
    }

    return RadioScope<T>(
      value: current,
      onChanged: onChanged,
      child: groupBody,
    );
  }
}
