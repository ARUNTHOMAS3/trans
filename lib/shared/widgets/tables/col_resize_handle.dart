import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// Right-edge resize handle. Place inside a `Stack` with `Clip.none` on each
/// header cell using `Positioned(right: 0, top: 0, bottom: 0)`.
///
/// Always shows a subtle `borderLight` right-border so columns are visually
/// separated and the resize affordance is discoverable. On hover / drag it
/// turns `primaryBlue`.
///
/// ```dart
/// SizedBox(
///   width: colWidths['name'],
///   child: Stack(
///     clipBehavior: Clip.none,
///     children: [
///       Padding(padding: EdgeInsets.only(right: 8), child: headerContent),
///       Positioned(
///         right: 0, top: 0, bottom: 0,
///         child: ColResizeHandle(onResize: (d) => _resize('name', d)),
///       ),
///     ],
///   ),
/// )
/// ```
class ColResizeHandle extends StatefulWidget {
  const ColResizeHandle({super.key, required this.onResize});

  final ValueChanged<double> onResize;

  @override
  State<ColResizeHandle> createState() => _ColResizeHandleState();
}

class _ColResizeHandleState extends State<ColResizeHandle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onHorizontalDragUpdate: (d) => widget.onResize(d.delta.dx),
        child: Container(
          width: 6,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: _hovered ? AppTheme.primaryBlue : AppTheme.borderLight,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
