part of '../sales_generic_list.dart';

extension _SalesGenericListFilter on _SalesGenericListScreenState {
  void _hideFilterMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleFilterMenu() {
    if (_overlayEntry == null) {
      _showFilterMenu();
    } else {
      _hideFilterMenu();
    }
  }

  void _showFilterMenu() {
    final defaultFilters = [
      'All Customers',
      'Active Customers',
      'CRM Customers',
      'Duplicate Customers',
      'Inactive Customers',
      'Overdue Customers',
      'Unpaid Customers',
      'Credit Limit Exceeded',
    ];

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _hideFilterMenu,
            behavior: HitTestBehavior.opaque,
            child: Container(),
          ),
          Positioned(
            width: 250,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 35),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_favoriteFilters.isNotEmpty) ...[
                                _buildFilterSection(
                                  title: 'FAVORITES',
                                  count: _favoriteFilters.length,
                                  filters: _favoriteFilters.toList(),
                                  isFavorites: true,
                                ),
                                const Divider(height: 1),
                              ],
                              _buildFilterSection(
                                title: 'DEFAULT FILTERS',
                                count: defaultFilters.length,
                                filters: defaultFilters,
                                isFavorites: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      InkWell(
                        onTap: () {
                          _hideFilterMenu();
                          // TODO: Implement custom view creation
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.plus,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'New Custom View',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildFilterSection({
    required String title,
    required int count,
    required List<String> filters,
    required bool isFavorites,
  }) {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      childrenPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
          letterSpacing: 0.5,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isFavorites
              ? const Color(0xFF10B981)
              : const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(10),
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
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        final isFavorite = _favoriteFilters.contains(filter);

        return InkWell(
          onTap: () {
            _hideFilterMenu();
            _state(() {
              _selectedFilter = filter;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            color: isSelected ? const Color(0xFFEFF6FF) : null,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF374151),
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    _state(() {
                      if (isFavorite) {
                        _favoriteFilters.remove(filter);
                      } else {
                        _favoriteFilters.add(filter);
                      }
                    });
                  },
                  child: Icon(
                    isFavorite ? LucideIcons.star : LucideIcons.star,
                    size: 18,
                    color: isFavorite
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}


