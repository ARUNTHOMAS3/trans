import 'package:flutter/material.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/report/column_visibility_manager.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// Dialog that lets the user pick which columns are visible in the Items Report.
class ItemsCustomColumnsDialog extends StatefulWidget {
  final Set<String> selectedColumns;
  final ValueChanged<Set<String>> onSave;

  const ItemsCustomColumnsDialog({
    super.key,
    required this.selectedColumns,
    required this.onSave,
  });

  @override
  State<ItemsCustomColumnsDialog> createState() =>
      _ItemsCustomColumnsDialogState();
}

class _ItemsCustomColumnsDialogState extends State<ItemsCustomColumnsDialog> {
  late Set<String> _workingSelection;
  String _search = '';

  late final List<ColumnDefinition> _allColumns;
  List<ColumnDefinition> _filteredColumns = [];

  @override
  void initState() {
    super.initState();
    _workingSelection = Set<String>.from(widget.selectedColumns);
    _allColumns = ColumnVisibilityManager.getAllColumns();
    _applyFilter();
  }

  void _applyFilter() {
    final term = _search.trim().toLowerCase();
    _filteredColumns = term.isEmpty
        ? List<ColumnDefinition>.from(_allColumns)
        : _allColumns
              .where((col) => col.label.toLowerCase().contains(term))
              .toList();
  }

  @override
  Widget build(BuildContext context) {
    _applyFilter();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 560,
        height: 620,
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearch(),
            Expanded(child: _buildFlatList()),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune, size: 18, color: AppTheme.primaryBlueDark),
          const SizedBox(width: 8),
          const Text(
            'Customize Columns',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            '${_workingSelection.length} of ${_allColumns.length} Selected',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: AppTheme.textMuted,
          ),
          hintText: 'Search',
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildFlatList() {
    if (_filteredColumns.isEmpty) {
      return const Center(
        child: Text(
          'No columns match your search',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _filteredColumns.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppTheme.borderColor),
      itemBuilder: (context, i) => _buildColumnTile(_filteredColumns[i]),
    );
  }

  Widget _buildColumnTile(ColumnDefinition col) {
    final checked = _workingSelection.contains(col.key);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: const Icon(
        Icons.drag_indicator,
        size: 16,
        color: AppTheme.textMuted,
      ),
      title: Text(
        col.label,
        style: const TextStyle(fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
      trailing: col.isRequired
          ? const Icon(Icons.lock, size: 16, color: AppTheme.textMuted)
          : Checkbox(
              value: checked,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _workingSelection.add(col.key);
                } else {
                  _workingSelection.remove(col.key);
                }
              }),
              activeColor: AppTheme.primaryBlueDark,
            ),
      onTap: col.isRequired
          ? null
          : () => setState(() {
              if (checked) {
                _workingSelection.remove(col.key);
              } else {
                _workingSelection.add(col.key);
              }
            }),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              widget.onSave(_workingSelection);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
