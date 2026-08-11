import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_calendar.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker_style.dart';

class ZerpaiDatePicker {
  static OverlayEntry? _activeOverlay;

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    required GlobalKey targetKey,
    LayerLink? targetLink,
    LayerLink? layerLink,
    bool openAbove = false,
    bool dismissOnBackgroundTap = true,
  }) async {
    final effectiveLink = targetLink ?? layerLink;
    final RenderBox? renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    _removeActiveOverlay();

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final overlay = Overlay.of(context, rootOverlay: true);

    final completer = Completer<DateTime?>();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            if (dismissOnBackgroundTap)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (!completer.isCompleted) {
                      completer.complete(null);
                    }
                    _removeActiveOverlay();
                  },
                  child: const SizedBox.expand(),
                ),
              ),
            if (effectiveLink != null)
              CompositedTransformFollower(
                link: effectiveLink,
                showWhenUnlinked: false,
                targetAnchor: openAbove
                    ? Alignment.topLeft
                    : Alignment.bottomLeft,
                followerAnchor: openAbove
                    ? Alignment.bottomLeft
                    : Alignment.topLeft,
                offset: Offset(
                  0,
                  openAbove
                      ? -ZerpaiDatePickerStyle.popupOffsetY
                      : ZerpaiDatePickerStyle.popupOffsetY,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ZerpaiCalendar(
                    selectedDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    onDateSelected: (date) {
                      if (!completer.isCompleted) {
                        completer.complete(date);
                      }
                      _removeActiveOverlay();
                    },
                  ),
                ),
              )
            else
              Positioned(
                left: offset.dx,
                top: openAbove
                    ? offset.dy - ZerpaiDatePickerStyle.popupOffsetY
                    : offset.dy +
                        size.height +
                        ZerpaiDatePickerStyle.popupOffsetY,
                child: Material(
                  color: Colors.transparent,
                  child: ZerpaiCalendar(
                    selectedDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    onDateSelected: (date) {
                      if (!completer.isCompleted) {
                        completer.complete(date);
                      }
                      _removeActiveOverlay();
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );

    _activeOverlay = entry;
    overlay.insert(entry);

    return completer.future;
  }

  static void _removeActiveOverlay() {
    _activeOverlay?.remove();
    _activeOverlay = null;
  }
}
