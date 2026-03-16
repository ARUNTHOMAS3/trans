// FILE: lib/modules/items/presentation/items_filter_dropdown.dart

import 'package:flutter/material.dart';
import 'items_filters.dart';

// -----------------------------------------------------------
// CUSTOM FILTER DROPDOWN (zerpai STYLE PANEL)
// -----------------------------------------------------------

class ItemsFilterDropdown extends StatefulWidget {
  final ItemsFilter currentFilter;
  final ValueChanged<ItemsFilter> onFilterChanged;

  const ItemsFilterDropdown({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<ItemsFilterDropdown> createState() => _ItemsFilterDropdownState();
}

class _ItemsFilterDropdownState extends State<ItemsFilterDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  final TextEditingController _searchCtrl = TextEditingController();

  // Example favourites – you can change this or persist later
  final Set<ItemsFilter> _favoriteFilters = {
    ItemsFilter.all,
    ItemsFilter.service,
    ItemsFilter.inactive,
  };

  @override
  void dispose() {
    _removeOverlay();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _labelFor(ItemsFilter f) {
    return kItemsFilterOptions
        .firstWhere(
          (opt) => opt.value == f,
          orElse: () => kItemsFilterOptions.first,
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

    _overlayEntry = OverlayEntry(builder: (context) => _buildOverlayContent());

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

  void _selectFilter(ItemsFilter f) {
    widget.onFilterChanged(f);
    _removeOverlay();
  }

  void _toggleFavorite(ItemsFilter f) {
    setState(() {
      if (_favoriteFilters.contains(f)) {
        _favoriteFilters.remove(f);
      } else {
        _favoriteFilters.add(f);
      }
    });
    _rebuildOverlay();
  }

  Widget _buildOverlayContent() {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size size = box.size;
    final Offset position = box.localToGlobal(Offset.zero);

    final String query = _searchCtrl.text.toLowerCase().trim();

    List<ItemsFilterOption> favoriteOptions = kItemsFilterOptions
        .where((opt) => _favoriteFilters.contains(opt.value))
        .where((opt) => opt.label.toLowerCase().contains(query))
        .toList();

    List<ItemsFilterOption> defaultOptions = kItemsFilterOptions
        .where((opt) => !_favoriteFilters.contains(opt.value))
        .where((opt) => opt.label.toLowerCase().contains(query))
        .toList();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeOverlay,
            child: const SizedBox.shrink(),
          ),
        ),
        Positioned(
          left: position.dx,
          top: position.dy + size.height + 4,
          width: 320,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 220, maxHeight: 420),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Search box
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) {
                            setState(() {});
                            _rebuildOverlay();
                          },
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
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Sectioner(
                              title: 'FAVORITES',
                              count: favoriteOptions.length,
                            ),
                            ...favoriteOptions.map(
                              (opt) => _FilterRow(
                                option: opt,
                                isActive: opt.value == widget.currentFilter,
                                isFavorite: _favoriteFilters.contains(
                                  opt.value,
                                ),
                                onSelect: () => _selectFilter(opt.value),
                                onToggleFavorite: () =>
                                    _toggleFavorite(opt.value),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1, color: Color(0xFFE5E7EB)),
                            const SizedBox(height: 8),
                            _Sectioner(
                              title: 'DEFAULT FILTERS',
                              count: defaultOptions.length,
                            ),
                            ...defaultOptions.map(
                              (opt) => _FilterRow(
                                option: opt,
                                isActive: opt.value == widget.currentFilter,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        behavior: HitTestBehavior.translucent,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isOpen
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFD1D5DB),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _labelFor(widget.currentFilter),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 22,
                color: const Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sectioner extends StatelessWidget {
  final String title;
  final int count;

  const _Sectioner({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ).copyWith(top: 6, bottom: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final ItemsFilterOption option;
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
        : const Color(0xFF111827);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onSelect,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  option.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: textColor,
                  ),
                ),
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
                size: 18,
                color: isFavorite
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFD1D5DB),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
