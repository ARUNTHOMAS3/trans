import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

typedef ReportFrozenTableCellBuilder =
    Widget Function(BuildContext context, int index, bool isHovered);

class ReportFrozenFirstColumnTable extends StatefulWidget {
  final double frozenColumnWidth;
  final double scrollableWidth;
  final double bodyHeight;
  final double rowHeight;
  final int rowCount;
  final Widget frozenHeader;
  final Widget scrollableHeader;
  final ReportFrozenTableCellBuilder frozenCellBuilder;
  final ReportFrozenTableCellBuilder scrollableCellBuilder;
  final bool Function(int index)? rowHoverEnabled;
  final Widget? emptyBody;
  final bool isEmpty;

  const ReportFrozenFirstColumnTable({
    super.key,
    required this.frozenColumnWidth,
    required this.scrollableWidth,
    required this.bodyHeight,
    required this.rowHeight,
    required this.rowCount,
    required this.frozenHeader,
    required this.scrollableHeader,
    required this.frozenCellBuilder,
    required this.scrollableCellBuilder,
    this.rowHoverEnabled,
    this.emptyBody,
    this.isEmpty = false,
  });

  @override
  State<ReportFrozenFirstColumnTable> createState() =>
      _ReportFrozenFirstColumnTableState();
}

class _ReportFrozenFirstColumnTableState
    extends State<ReportFrozenFirstColumnTable> {
  static const double _scrollStep = 360;
  static const double _scrollButtonWidth = 42;
  static const double _scrollButtonHeight = 74;

  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _rightVerticalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();

  bool _isSyncingVertical = false;
  bool _isSyncingHorizontal = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;
  bool _isDisposing = false;
  bool _horizontalButtonUpdateScheduled = false;
  final ValueNotifier<int?> _hoveredIndex = ValueNotifier<int?>(null);

  @override
  void initState() {
    super.initState();
    _leftVerticalController.addListener(_syncVerticalFromLeft);
    _rightVerticalController.addListener(_syncVerticalFromRight);
    _headerHorizontalController.addListener(_syncHorizontalFromHeader);
    _bodyHorizontalController.addListener(_syncHorizontalFromBody);
    _bodyHorizontalController.addListener(_updateHorizontalButtonState);
    _scheduleHorizontalButtonStateUpdate();
  }

  @override
  void didUpdateWidget(covariant ReportFrozenFirstColumnTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleHorizontalButtonStateUpdate();
  }

  @override
  void dispose() {
    _isDisposing = true;
    _horizontalButtonUpdateScheduled = false;
    _leftVerticalController
      ..removeListener(_syncVerticalFromLeft)
      ..dispose();
    _rightVerticalController
      ..removeListener(_syncVerticalFromRight)
      ..dispose();
    _headerHorizontalController
      ..removeListener(_syncHorizontalFromHeader)
      ..dispose();
    _bodyHorizontalController
      ..removeListener(_syncHorizontalFromBody)
      ..removeListener(_updateHorizontalButtonState)
      ..dispose();
    _hoveredIndex.dispose();
    super.dispose();
  }

  void _syncVerticalFromLeft() {
    _syncScrollPosition(
      source: _leftVerticalController,
      target: _rightVerticalController,
      isSyncing: _isSyncingVertical,
      setSyncing: (value) => _isSyncingVertical = value,
    );
  }

  void _syncVerticalFromRight() {
    _syncScrollPosition(
      source: _rightVerticalController,
      target: _leftVerticalController,
      isSyncing: _isSyncingVertical,
      setSyncing: (value) => _isSyncingVertical = value,
    );
  }

  void _syncHorizontalFromHeader() {
    _syncScrollPosition(
      source: _headerHorizontalController,
      target: _bodyHorizontalController,
      isSyncing: _isSyncingHorizontal,
      setSyncing: (value) => _isSyncingHorizontal = value,
    );
    _updateHorizontalButtonState();
  }

  void _syncHorizontalFromBody() {
    _syncScrollPosition(
      source: _bodyHorizontalController,
      target: _headerHorizontalController,
      isSyncing: _isSyncingHorizontal,
      setSyncing: (value) => _isSyncingHorizontal = value,
    );
    _updateHorizontalButtonState();
  }

  void _syncScrollPosition({
    required ScrollController source,
    required ScrollController target,
    required bool isSyncing,
    required ValueChanged<bool> setSyncing,
  }) {
    if (_isDisposing || isSyncing || !source.hasClients || !target.hasClients) return;
    final maxTargetExtent = target.position.maxScrollExtent;
    final nextOffset = source.offset.clamp(0.0, maxTargetExtent).toDouble();
    if ((target.offset - nextOffset).abs() < 0.5) return;

    setSyncing(true);
    target.jumpTo(nextOffset);
    setSyncing(false);
  }

  void _scheduleHorizontalButtonStateUpdate() {
    if (_horizontalButtonUpdateScheduled || _isDisposing) return;
    _horizontalButtonUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _horizontalButtonUpdateScheduled = false;
      if (!mounted || _isDisposing) return;
      _updateHorizontalButtonState();
    });
  }

  void _updateHorizontalButtonState() {
    if (!mounted || _isDisposing) return;
    if (!_bodyHorizontalController.hasClients) return;
    final position = _bodyHorizontalController.position;
    final nextCanScrollLeft = position.pixels > 0.5;
    final nextCanScrollRight = position.pixels < position.maxScrollExtent - 0.5;
    if (_canScrollLeft == nextCanScrollLeft &&
        _canScrollRight == nextCanScrollRight) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _canScrollLeft = nextCanScrollLeft;
      _canScrollRight = nextCanScrollRight;
    });
  }

  void _scrollHorizontally(double delta) {
    if (!mounted || _isDisposing) return;
    if (!_bodyHorizontalController.hasClients) return;
    final position = _bodyHorizontalController.position;
    final target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    _bodyHorizontalController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _setHoveredIndex(int? index) {
    if (!mounted || _isDisposing || _hoveredIndex.value == index) return;
    _hoveredIndex.value = index;
  }

  bool _canHover(int index) => widget.rowHoverEnabled?.call(index) ?? true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final bodyHeight = hasBoundedHeight
            ? (constraints.maxHeight - AppTheme.space48)
                  .clamp(0.0, widget.bodyHeight)
                  .toDouble()
            : widget.bodyHeight;
        final body = widget.isEmpty
            ? _buildEmptyBody()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFrozenBody(),
                  Expanded(child: _buildScrollableBody()),
                ],
              );

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RepaintBoundary(child: _buildHeader()),
                if (hasBoundedHeight)
                  Expanded(child: RepaintBoundary(child: body))
                else
                  SizedBox(
                    height: widget.bodyHeight,
                    child: RepaintBoundary(child: body),
                  ),
              ],
            ),
            if (!widget.isEmpty)
              Positioned(
                left: widget.frozenColumnWidth + AppTheme.space8,
                top:
                    AppTheme.space48 +
                    (bodyHeight / 2) -
                    (_scrollButtonHeight / 2),
                child: _HorizontalScrollButton(
                  icon: Icons.chevron_left,
                  enabled: _canScrollLeft,
                  onPressed: () => _scrollHorizontally(-_scrollStep),
                ),
              ),
            if (!widget.isEmpty)
              Positioned(
                right: 0,
                top:
                    AppTheme.space48 +
                    (bodyHeight / 2) -
                    (_scrollButtonHeight / 2),
                child: _HorizontalScrollButton(
                  icon: Icons.chevron_right,
                  enabled: _canScrollRight,
                  onPressed: () => _scrollHorizontally(_scrollStep),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.tableHeaderBg,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: widget.frozenColumnWidth,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space20,
                vertical: AppTheme.space10,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.tableHeaderBg,
                border: Border(right: BorderSide(color: AppTheme.borderLight)),
              ),
              alignment: Alignment.centerLeft,
              child: widget.frozenHeader,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _headerHorizontalController,
                primary: false,
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: widget.scrollableWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space20,
                      vertical: AppTheme.space10,
                    ),
                    child: widget.scrollableHeader,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrozenBody() {
    return SizedBox(
      width: widget.frozenColumnWidth,
      child: ListView.builder(
        controller: _leftVerticalController,
        primary: false,
        physics: const ClampingScrollPhysics(),
        itemExtent: widget.rowHeight,
        itemCount: widget.rowCount,
        itemBuilder: (context, index) {
          return ValueListenableBuilder<int?>(
            valueListenable: _hoveredIndex,
            builder: (context, hoveredIndex, _) {
              final isHovered = hoveredIndex == index;
              return _HoverableTableRowPart(
                isHovered: isHovered,
                canHover: _canHover(index),
                onHoverChanged: (hovered) =>
                    _setHoveredIndex(hovered ? index : null),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppTheme.borderLight),
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: widget.frozenCellBuilder(context, index, isHovered),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildScrollableBody() {
    return Scrollbar(
      controller: _bodyHorizontalController,
      thumbVisibility: true,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: SingleChildScrollView(
        controller: _bodyHorizontalController,
        primary: false,
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: widget.scrollableWidth,
          child: Scrollbar(
            controller: _rightVerticalController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _rightVerticalController,
              primary: false,
              physics: const ClampingScrollPhysics(),
              itemExtent: widget.rowHeight,
              itemCount: widget.rowCount,
              itemBuilder: (context, index) {
                return ValueListenableBuilder<int?>(
                  valueListenable: _hoveredIndex,
                  builder: (context, hoveredIndex, _) {
                    final isHovered = hoveredIndex == index;
                    return _HoverableTableRowPart(
                      isHovered: isHovered,
                      canHover: _canHover(index),
                      onHoverChanged: (hovered) =>
                          _setHoveredIndex(hovered ? index : null),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: widget.scrollableCellBuilder(
                        context,
                        index,
                        isHovered,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBody() {
    return SizedBox(
      height: widget.bodyHeight,
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                width: widget.frozenColumnWidth,
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundColor,
                  border: Border(
                    right: BorderSide(color: AppTheme.borderLight),
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
              ),
              const Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned.fill(child: widget.emptyBody ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _HorizontalScrollButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _HorizontalScrollButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: _ReportFrozenFirstColumnTableState._scrollButtonWidth,
      height: _ReportFrozenFirstColumnTableState._scrollButtonHeight,
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withValues(alpha: enabled ? 0.05 : 0.03),
        borderRadius: BorderRadius.circular(AppTheme.space4),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: AppTheme.space28,
        color: enabled ? AppTheme.textSecondary : AppTheme.textMuted,
      ),
    );

    if (!enabled) {
      return MouseRegion(cursor: SystemMouseCursors.forbidden, child: button);
    }

    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: onPressed,
        hoverColor: AppTheme.bgHover,
        borderRadius: BorderRadius.circular(AppTheme.space4),
        child: button,
      ),
    );
  }
}

class _HoverableTableRowPart extends StatelessWidget {
  final bool isHovered;
  final bool canHover;
  final ValueChanged<bool> onHoverChanged;
  final Decoration decoration;
  final Widget child;

  const _HoverableTableRowPart({
    required this.isHovered,
    required this.canHover,
    required this.onHoverChanged,
    required this.decoration,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
      foregroundDecoration: decoration,
      child: child,
    );

    if (!canHover) return content;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: content,
    );
  }
}
