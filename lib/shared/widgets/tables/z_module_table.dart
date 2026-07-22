import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_header_menu.dart';

typedef ZModuleCellBuilder<T> =
    Widget Function(BuildContext context, T row, ColumnConfig column);

class ZModuleTable<T> extends StatelessWidget {
  static const double _headerToolsWidth = 28;
  const ZModuleTable({
    super.key,
    required this.rows,
    required this.visibleColumns,
    required this.rowId,
    required this.headerBuilder,
    required this.cellBuilder,
    required this.isSelected,
    required this.onRowSelectChanged,
    required this.allSelected,
    required this.onAllSelectedChanged,
    required this.wrapText,
    required this.onWrapTextChanged,
    required this.onCustomizeColumns,
    required this.columnWidthBuilder,
    this.sortKey,
    this.sortAscending = true,
    this.onHeaderTap,
    this.horizontalInset = 8,
    this.onHoveredRowChanged,
  });

  final List<T> rows;
  final List<ColumnConfig> visibleColumns;
  final String Function(T row) rowId;
  final Widget Function(BuildContext context, ColumnConfig column)
  headerBuilder;
  final ZModuleCellBuilder<T> cellBuilder;
  final bool Function(String rowId) isSelected;
  final ValueChanged<bool> onAllSelectedChanged;
  final void Function(String rowId, bool selected) onRowSelectChanged;
  final bool allSelected;
  final bool wrapText;
  final ValueChanged<bool> onWrapTextChanged;
  final VoidCallback onCustomizeColumns;
  final double Function(String columnId) columnWidthBuilder;
  final String? sortKey;
  final bool sortAscending;
  final ValueChanged<String>? onHeaderTap;
  final double horizontalInset;
  final ValueChanged<String?>? onHoveredRowChanged;

  Widget _buildAlignedCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: Checkbox(
          value: value,
          onChanged: onChanged,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: Color(0xFF6B7280), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                SizedBox(width: horizontalInset),
                ZTableHeaderMenu(
                  wrapText: wrapText,
                  onWrapChange: onWrapTextChanged,
                  onCustomize: onCustomizeColumns,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: _buildAlignedCheckbox(
                    value: allSelected,
                    onChanged: (v) => onAllSelectedChanged(v ?? false),
                  ),
                ),
                ...visibleColumns.map((column) {
                  return InkWell(
                    onTap: onHeaderTap == null
                        ? null
                        : () => onHeaderTap!(column.id),
                    child: SizedBox(
                      width: columnWidthBuilder(column.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: headerBuilder(context, column)),
                            if (sortKey == column.id)
                              Icon(
                                sortAscending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 14,
                                color: AppTheme.primaryBlue,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          ...rows.map((row) {
            final id = rowId(row);
            final selected = isSelected(id);
            return MouseRegion(
              onEnter: (_) => onHoveredRowChanged?.call(id),
              onExit: (_) => onHoveredRowChanged?.call(null),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFF8FAFF) : Colors.white,
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: horizontalInset),
                    const SizedBox(width: _headerToolsWidth),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: _buildAlignedCheckbox(
                        value: selected,
                        onChanged: (v) => onRowSelectChanged(id, v ?? false),
                      ),
                    ),
                    ...visibleColumns.map((column) {
                      return SizedBox(
                        width: columnWidthBuilder(column.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: cellBuilder(context, row, column),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
