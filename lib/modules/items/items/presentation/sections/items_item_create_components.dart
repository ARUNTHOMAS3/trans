part of '../items_item_create.dart';

class _UnitRow {
  final TextEditingController unitCtrl;
  final FocusNode focusNode = FocusNode();
  String? uqcId;
  final String? unitId;
  bool isInUse;

  _UnitRow(String unit, this.uqcId, {this.unitId, this.isInUse = false})
    : unitCtrl = TextEditingController(text: unit);
}

Widget _tabTitleWithCheckbox(
  String title,
  bool value,
  ValueChanged<bool?> onChanged, {
  required bool active,
  VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? const Color(0xFF2563EB) : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? const Color(0xFF111827) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
            ),
          ),
        ],
      ),
    ),
  );
}

class _InlineCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _InlineCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(value: value, onChanged: onChanged),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: value ? FontWeight.w600 : FontWeight.w500,
              color: value ? const Color(0xFF111827) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
