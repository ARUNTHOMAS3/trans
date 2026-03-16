import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_calendar.dart';

class ZerpaiDatePicker {
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    required GlobalKey targetKey,
  }) async {
    final RenderBox? renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    DateTime? result;

    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.translucent,
              ),
            ),
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 4,
              child: Material(
                color: Colors.transparent,
                child: ZerpaiCalendar(
                  selectedDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  onDateSelected: (date) {
                    result = date;
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    return result;
  }
}
