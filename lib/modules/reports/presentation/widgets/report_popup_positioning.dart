import 'dart:math' as math;

import 'package:flutter/material.dart';

class ReportPopupPlacement {
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Offset offset;

  const ReportPopupPlacement({
    required this.targetAnchor,
    required this.followerAnchor,
    required this.offset,
  });
}

ReportPopupPlacement resolveReportPopupPlacement({
  required BuildContext context,
  required RenderBox anchorBox,
  required double popupWidth,
  required double popupHeight,
  double screenPadding = 8,
  double popupGap = 4,
  bool allowAbove = true,
}) {
  if (!anchorBox.hasSize) {
    return ReportPopupPlacement(
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: Offset(0, popupGap),
    );
  }

  final targetGlobal = anchorBox.localToGlobal(Offset.zero);
  final anchorRect = targetGlobal & anchorBox.size;
  final screenSize = MediaQuery.of(context).size;

  final rightSpace = screenSize.width - screenPadding - anchorRect.left;
  final leftSpace = anchorRect.right - screenPadding;
  final openRight = rightSpace >= popupWidth || rightSpace >= leftSpace;

  final showBelow =
      !allowAbove ||
      _hasMoreVerticalSpaceBelow(
        anchorRect: anchorRect,
        popupHeight: popupHeight,
        screenHeight: screenSize.height,
        screenPadding: screenPadding,
      );

  if (openRight) {
    return ReportPopupPlacement(
      targetAnchor: showBelow ? Alignment.bottomLeft : Alignment.topLeft,
      followerAnchor: showBelow ? Alignment.topLeft : Alignment.bottomLeft,
      offset: Offset(
        _clampPreferredOffset(
          minOffset: screenPadding - anchorRect.left,
          maxOffset:
              screenSize.width - screenPadding - anchorRect.left - popupWidth,
        ),
        showBelow ? popupGap : -popupGap,
      ),
    );
  }

  return ReportPopupPlacement(
    targetAnchor: showBelow ? Alignment.bottomRight : Alignment.topRight,
    followerAnchor: showBelow ? Alignment.topRight : Alignment.bottomRight,
    offset: Offset(
      _clampPreferredOffset(
        minOffset: screenPadding + popupWidth - anchorRect.right,
        maxOffset: screenSize.width - screenPadding - anchorRect.right,
      ),
      showBelow ? popupGap : -popupGap,
    ),
  );
}

bool _hasMoreVerticalSpaceBelow({
  required Rect anchorRect,
  required double popupHeight,
  required double screenHeight,
  required double screenPadding,
}) {
  final spaceBelow = screenHeight - anchorRect.bottom - screenPadding;
  final spaceAbove = anchorRect.top - screenPadding;
  return spaceBelow >= popupHeight || spaceBelow >= spaceAbove;
}

double _clampPreferredOffset({
  required double minOffset,
  required double maxOffset,
}) {
  if (minOffset > maxOffset) {
    return math.min(minOffset, maxOffset);
  }

  return 0.0.clamp(minOffset, maxOffset).toDouble();
}
