part of '../sales_customer_overview.dart';

extension _OverviewLeftPanel on _SalesCustomerOverviewScreenState {
  Widget _buildLeftPanel(
    List<SalesCustomer> customers,
    SalesCustomer selected,
    bool isExpanded,
  ) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header with filter/plus
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isExpanded)
                  Row(
                    children: [
                      const Text(
                        'All Customers',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    if (isExpanded) ...[
                      InkWell(
                        onTap: () => context.goNamed(
                          AppRoutes.salesCustomersCreate,
                          pathParameters: {'orgSystemId': _orgSystemId},
                        ),
                        child: _smallIconButton(
                          LucideIcons.plus,
                          const Color(0xFF22C55E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _smallIconButton(
                        LucideIcons.moreHorizontal,
                        const Color(0xFF374151),
                      ),
                      const SizedBox(width: 8),
                    ],
                    InkWell(
                      onTap: () =>
                          _state(() => _isPanelCollapsed = !_isPanelCollapsed),
                      child: _smallIconButton(
                        _isPanelCollapsed
                            ? LucideIcons.chevronsRight
                            : LucideIcons.chevronsLeft,
                        const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: ListView.separated(
              itemCount: customers.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 40),
              itemBuilder: (context, index) {
                final c = customers[index];
                final isSelected = c.id == selected.id;
                return InkWell(
                  onTap: () => context.goNamed(
                    AppRoutes.salesCustomersDetail,
                    pathParameters: {
                      'orgSystemId': _orgSystemId,
                      'id': c.id,
                    },
                  ),

                  child: Container(
                    color: isSelected ? Colors.white : Colors.transparent,
                    padding: EdgeInsets.symmetric(
                      horizontal: isExpanded ? 16 : 12,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: false,
                            onChanged: (_) {},
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        if (isExpanded) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.displayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF374151),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  NumberFormat.currency(
                                    symbol: 'rs',
                                  ).format(c.receivables),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallIconButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(4),
        color: icon == LucideIcons.plus ? color : Colors.white,
      ),
      child: Icon(
        icon,
        size: 14,
        color: icon == LucideIcons.plus ? Colors.white : color,
      ),
    );
  }
}
