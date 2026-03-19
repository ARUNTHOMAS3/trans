part of '../sales_generic_list.dart';

extension _SalesGenericListColumns on _SalesGenericListScreenState {
  void _initializeColumns() {
    // If it's the Customers screen, use the full list of options from the screenshot
    if (widget.title == 'Customers') {
      _allColumns = [
        ColumnDef(key: 'name', label: 'Name', isLocked: true),
        ColumnDef(key: 'company_name', label: 'Company Name'),
        ColumnDef(key: 'email', label: 'Email'),
        ColumnDef(key: 'phone', label: 'Phone'),
        ColumnDef(key: 'gst_treatment', label: 'GST Treatment'),
        ColumnDef(key: 'receivables_bcy', label: 'Receivables (BCY)'),
        ColumnDef(key: 'receivables', label: 'Receivables', isVisible: false),
        ColumnDef(
          key: 'unused_credits',
          label: 'Unused Credits',
          isVisible: false,
        ),
        ColumnDef(
          key: 'unused_credits_bcy',
          label: 'Unused Credits (BCY)',
          isVisible: false,
        ),
        ColumnDef(key: 'source', label: 'Source', isVisible: false),
        ColumnDef(key: 'credit_limit', label: 'Credit Limit', isVisible: false),
        ColumnDef(
          key: 'customer_number',
          label: 'Customer Number',
          isVisible: false,
        ),
        ColumnDef(key: 'first_name', label: 'First Name', isVisible: false),
        ColumnDef(
          key: 'gst_registration_number',
          label: 'GST Registration Number',
          isVisible: false,
        ),
        ColumnDef(key: 'last_name', label: 'Last Name', isVisible: false),
        ColumnDef(key: 'mobile_phone', label: 'Mobile Phone', isVisible: false),
        ColumnDef(
          key: 'payment_terms',
          label: 'Payment Terms',
          isVisible: false,
        ),
        ColumnDef(key: 'status', label: 'Status', isVisible: false),
        ColumnDef(key: 'website', label: 'Website', isVisible: false),
        ColumnDef(
          key: 'place_of_supply',
          label: 'Place Of Supply',
          isVisible: false,
        ),
      ];
    } else {
      // Fallback for other screens using widget.columns
      _allColumns = widget.columns
          .map((c) => ColumnDef(key: c, label: c))
          .toList();
    }

    _updateVisibleColumns();

    // Init widths
    for (var col in _allColumns) {
      if (col.key == 'name') {
        _columnWidths[col.key] = 250.0;
      } else if (col.key == 'company_name') {
        _columnWidths[col.key] = 300.0;
      } else if (col.key == 'email') {
        _columnWidths[col.key] = 200.0;
      } else if (col.key == 'receivables_bcy' || col.key == 'receivables') {
        _columnWidths[col.key] = 150.0;
      } else {
        _columnWidths[col.key] = 150.0;
      }
    }
  }

  void _updateVisibleColumns() {
    _visibleColumns = _allColumns.where((c) => c.isVisible).toList();
  }

  void _onResize(String key, double delta) {
    _state(() {
      final current = _columnWidths[key] ?? 150.0;
      final newWidth = (current + delta).clamp(50.0, 500.0);
      _columnWidths[key] = newWidth;
      _columnsResized = true;
    });
  }

  void _saveColumnPreferences() {
    _state(() {
      _columnsResized = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Column preferences saved!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _resetColumnPreferences() {
    _state(() {
      for (var col in _allColumns) {
        if (col.key == 'name') {
          _columnWidths[col.key] = 250.0;
        } else if (col.key == 'company_name') {
          _columnWidths[col.key] = 300.0;
        } else if (col.key == 'email') {
          _columnWidths[col.key] = 200.0;
        } else if (col.key == 'receivables_bcy' || col.key == 'receivables') {
          _columnWidths[col.key] = 150.0;
        } else {
          _columnWidths[col.key] = 150.0;
        }
      }
      _columnsResized = false;
    });
  }

  void _openCustomizeColumnsDialog() async {
    // Clone columns state for the dialog to allow cancel
    final List<ColumnDef> dialogColumns = _allColumns
        .map(
          (c) => ColumnDef(
            key: c.key,
            label: c.label,
            isLocked: c.isLocked,
            isVisible: c.isVisible,
          ),
        )
        .toList();

    await showDialog(
      context: context,
      builder: (context) {
        return _CustomizeColumnsDialog(
          columns: dialogColumns,
          onSave: (updatedColumns) {
            _state(() {
              _allColumns = updatedColumns;
              _updateVisibleColumns();
            });
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _CustomizeColumnsDialog extends StatefulWidget {
  final List<ColumnDef> columns;
  final ValueChanged<List<ColumnDef>> onSave;

  const _CustomizeColumnsDialog({required this.columns, required this.onSave});

  @override
  State<_CustomizeColumnsDialog> createState() =>
      _CustomizeColumnsDialogState();
}

class _CustomizeColumnsDialogState extends State<_CustomizeColumnsDialog> {
  late List<ColumnDef> _items;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.columns);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _items.where((c) => c.isVisible).length;
    final totalCount = _items.length;

    // Filter items for display
    final displayedItems = _items
        .where(
          (c) => c.label.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        LucideIcons.sliders,
                        size: 20,
                        color: AppTheme.textBody,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Customize Columns',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '$selectedCount of $totalCount Selected',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          color: AppTheme.errorRed,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Search
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  hintText: 'Search',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),

            // List
            Expanded(
              child: ReorderableListView(
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onReorder: _onReorder,
                children: [
                  for (int i = 0; i < displayedItems.length; i++)
                    _buildListItem(displayedItems[i], i),
                ],
              ),
            ),

            const Divider(height: 1),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => widget.onSave(_items),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textBody,
                      side: const BorderSide(color: AppTheme.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(ColumnDef col, int index) {
    // We use a key for ReorderableListView
    return Container(
      key: ValueKey(col.key),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.transparent),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          hoverColor: AppTheme.infoBg,
          onTap: () {
            if (!col.isLocked) {
              setState(() => col.isVisible = !col.isVisible);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(
                    LucideIcons.gripVertical,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                if (col.isLocked)
                  const Icon(
                    LucideIcons.lock,
                    size: 18,
                    color: AppTheme.textSecondary,
                  )
                else
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: col.isVisible,
                      onChanged: (v) =>
                          setState(() => col.isVisible = v ?? false),
                      activeColor: AppTheme.primaryBlueDark,
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    col.label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textBody,
                    ),
                  ),
                ),

                // Pin Button (Placeholder for now as hover logic in list requires MouseRegion per item)
                _PinButton(isActive: index == 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinButton extends StatelessWidget {
  final bool isActive;
  const _PinButton({required this.isActive});

  @override
  Widget build(BuildContext context) {
    // Only show if hovered ideally
    return isActive
        ? const Icon(LucideIcons.pin, size: 18, color: AppTheme.primaryBlueDark)
        : const SizedBox(width: 18);
  }
}
