import 'package:flutter/material.dart';
import 'items_composite_filters.dart';

class CompositeItemsFilterDropdown extends StatefulWidget {
  final CompositeItemsFilter currentFilter;
  final ValueChanged<CompositeItemsFilter> onFilterChanged;

  const CompositeItemsFilterDropdown({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<CompositeItemsFilterDropdown> createState() =>
      _CompositeItemsFilterDropdownState();
}

class _CompositeItemsFilterDropdownState
    extends State<CompositeItemsFilterDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  final TextEditingController _searchCtrl = TextEditingController();

  // Local state for favorites - in a real app this might be in a controller/repo
  final Set<CompositeItemsFilter> _favoriteFilters = {
    CompositeItemsFilter.all,
    CompositeItemsFilter.active,
  };

  @override
  void dispose() {
    _removeOverlay();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _labelFor(CompositeItemsFilter f) {
    return kCompositeItemsFilterOptions
        .firstWhere(
          (opt) => opt.value == f,
          orElse: () => kCompositeItemsFilterOptions.first,
        )
        .label;
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _rebuildOverlay() {
    if (_isOpen && _overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final OverlayState overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _removeOverlay,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 42),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search box
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => _rebuildOverlay(),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 18,
                              color: Color(0xFF9CA3AF),
                            ),
                            hintText: 'Search filters',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFE5E7EB)),

                    // Scrollable sections
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_favoriteFilters.isNotEmpty) ...[
                                _SectionHeader(
                                  title: 'FAVORITES',
                                  count: _favoriteFilters.length,
                                ),
                                ...kCompositeItemsFilterOptions
                                    .where(
                                      (opt) =>
                                          _favoriteFilters.contains(opt.value),
                                    )
                                    .where(
                                      (opt) => opt.label.toLowerCase().contains(
                                        _searchCtrl.text.toLowerCase(),
                                      ),
                                    )
                                    .map(
                                      (opt) => _FilterRow(
                                        option: opt,
                                        isActive:
                                            opt.value == widget.currentFilter,
                                        isFavorite: true,
                                        onSelect: () =>
                                            _selectFilter(opt.value),
                                        onToggleFavorite: () =>
                                            _toggleFavorite(opt.value),
                                      ),
                                    ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF3F4F6),
                                ),
                              ],
                              _SectionHeader(
                                title: 'DEFAULT FILTERS',
                                count: kCompositeItemsFilterOptions.length,
                              ),
                              ...kCompositeItemsFilterOptions
                                  .where(
                                    (opt) => opt.label.toLowerCase().contains(
                                      _searchCtrl.text.toLowerCase(),
                                    ),
                                  )
                                  .map(
                                    (opt) => _FilterRow(
                                      option: opt,
                                      isActive:
                                          opt.value == widget.currentFilter,
                                      isFavorite: _favoriteFilters.contains(
                                        opt.value,
                                      ),
                                      onSelect: () => _selectFilter(opt.value),
                                      onToggleFavorite: () =>
                                          _toggleFavorite(opt.value),
                                    ),
                                  ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_isOpen) {
      setState(() => _isOpen = false);
    }
  }

  void _selectFilter(CompositeItemsFilter f) {
    widget.onFilterChanged(f);
    _removeOverlay();
  }

  void _toggleFavorite(CompositeItemsFilter f) {
    setState(() {
      if (_favoriteFilters.contains(f)) {
        _favoriteFilters.remove(f);
      } else {
        _favoriteFilters.add(f);
      }
    });
    _rebuildOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        behavior: HitTestBehavior.translucent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(4),
            border: _isOpen
                ? Border.all(color: const Color(0xFF3B82F6), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _labelFor(widget.currentFilter),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFF9FAFB),
      child: Row(
        children: [
          const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Color(0xFF374151),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final CompositeItemsFilterOption option;
  final bool isActive;
  final bool isFavorite;
  final VoidCallback onSelect;
  final VoidCallback onToggleFavorite;

  const _FilterRow({
    required this.option,
    required this.isActive,
    required this.isFavorite,
    required this.onSelect,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isActive
        ? const Color(0xFF2563EB)
        : const Color(0xFF374151);

    return InkWell(
      onTap: onSelect,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        color: isActive ? const Color(0xFFF3F7FF) : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleFavorite,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  size: 20,
                  color: isFavorite
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFD1D5DB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
