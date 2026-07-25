import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ZerpaiPaginationWidget extends StatelessWidget {
  final int totalItems;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final List<int> pageSizeOptions;

  const ZerpaiPaginationWidget({
    super.key,
    required this.totalItems,
    required this.currentPage,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.pageSizeOptions = const [20, 30, 50, 75, 100],
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = totalItems == 0 ? 1 : (totalItems / pageSize).ceil();
    final clampedPage = currentPage.clamp(1, totalPages);
    final start = totalItems == 0 ? 0 : (clampedPage - 1) * pageSize + 1;
    final end = (clampedPage * pageSize).clamp(0, totalItems);
    final pageIndicator =
        totalItems == 0 ? '0 - 0' : '$start - $end of $totalItems';

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PaginationSizeDropdown(
                value: pageSize,
                options: pageSizeOptions,
                onChanged: onPageSizeChanged,
              ),
              const SizedBox(width: 16),
              PaginationArrow(
                icon: LucideIcons.chevronLeft,
                enabled: clampedPage > 1,
                onTap: () => onPageChanged(clampedPage - 1),
              ),
              const SizedBox(width: 8),
              Text(
                pageIndicator,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 8),
              PaginationArrow(
                icon: LucideIcons.chevronRight,
                enabled: clampedPage < totalPages,
                onTap: () => onPageChanged(clampedPage + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PaginationSizeDropdown extends StatefulWidget {
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  const PaginationSizeDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  State<PaginationSizeDropdown> createState() =>
      _PaginationSizeDropdownState();
}

class _PaginationSizeDropdownState extends State<PaginationSizeDropdown> {
  OverlayEntry? _overlay;
  final LayerLink _link = LayerLink();
  int? _hoveredOption;

  void _open() {
    _close();
    _hoveredOption = null;
    final optionsCount = widget.options.length;
    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: Offset(0, -(36.0 * optionsCount + 2)),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.options.map((opt) {
                    final isSelected = opt == widget.value;
                    final isHovered = _hoveredOption == opt;
                    final bgColor = isHovered
                        ? const Color(0xFF3B82F6)
                        : (isSelected ? const Color(0xFFF3F4F6) : Colors.white);
                    final fgColor = isHovered
                        ? Colors.white
                        : const Color(0xFF111827);

                    return MouseRegion(
                      onEnter: (_) {
                        _hoveredOption = opt;
                        _overlay?.markNeedsBuild();
                      },
                      onExit: (_) {
                        if (_hoveredOption == opt) {
                          _hoveredOption = null;
                          _overlay?.markNeedsBuild();
                        }
                      },
                      child: GestureDetector(
                        onTap: () {
                          widget.onChanged(opt);
                          _close();
                        },
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: opt == widget.options.first
                                ? const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  )
                                : opt == widget.options.last
                                ? const BorderRadius.vertical(
                                    bottom: Radius.circular(4),
                                  )
                                : BorderRadius.zero,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$opt per page',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: fgColor,
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check, size: 14, color: fgColor),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.maybeOf(context)?.insert(_overlay!);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    _hoveredOption = null;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _open,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.settings_outlined,
                size: 14,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.value} per page',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaginationArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const PaginationArrow({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? const Color(0xFFD1D5DB) : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }
}
