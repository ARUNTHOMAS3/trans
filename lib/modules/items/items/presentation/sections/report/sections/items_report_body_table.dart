part of '../items_report_body.dart';

extension _ItemsReportBodyTable on _ItemsReportBodyState {
  bool _allSelected(List<ItemRow> rows) =>
      rows.isNotEmpty && _selectedIds.length == rows.length;

  void _toggleAll(List<ItemRow> rows, bool selectAll) {
    updateState(() {
      if (selectAll) {
        _selectedIds = (rows.map((e) => e.selectionId).toList() as List)
            .toSet()
            .cast<String>();
      } else {
        _selectedIds.clear();
      }
    });
  }

  List<ItemRow> _sortedItems() {
    List<ItemRow> list = List<ItemRow>.from(widget.items);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((item) {
        return item.name.toLowerCase().contains(query) ||
            (item.itemCode ?? '').toLowerCase().contains(query) ||
            (item.sku ?? '').toLowerCase().contains(query) ||
            (item.hsn ?? '').toLowerCase().contains(query) ||
            (item.brand ?? '').toLowerCase().contains(query) ||
            (item.category ?? '').toLowerCase().contains(query) ||
            (item.manufacturer ?? '').toLowerCase().contains(query) ||
            (item.preferredVendor ?? '').toLowerCase().contains(query) ||
            (item.salesDescription ?? '').toLowerCase().contains(query) ||
            (item.purchaseDescription ?? '').toLowerCase().contains(query);
      }).toList();
    }

    int compareString(String? a, String? b) =>
        (a ?? '').toLowerCase().compareTo((b ?? '').toLowerCase());

    double parseNumber(String? s) {
      if (s == null || s.trim().isEmpty) return 0;
      return double.tryParse(s.trim()) ?? 0;
    }

    list.sort((a, b) {
      int result = 0;
      switch (_currentSortField) {
        case _ItemsSortField.name:
          result = compareString(a.name, b.name);
          break;
        case _ItemsSortField.reorderLevel:
          result = parseNumber(
            a.reorderLevel,
          ).compareTo(parseNumber(b.reorderLevel));
          break;
        case _ItemsSortField.sku:
          result = compareString(a.sku, b.sku);
          break;
        case _ItemsSortField.stockOnHand:
          result = parseNumber(
            a.stockOnHand,
          ).compareTo(parseNumber(b.stockOnHand));
          break;
        case _ItemsSortField.hsnSacRate:
          result = compareString(a.hsn, b.hsn);
          break;
        case _ItemsSortField.createdTime:
          if (a.createdAt == null && b.createdAt == null) {
            result = 0;
          } else if (a.createdAt == null) {
            result = 1;
          } else if (b.createdAt == null) {
            result = -1;
          } else {
            result = a.createdAt!.compareTo(b.createdAt!);
          }
          break;
        case _ItemsSortField.lastModifiedTime:
          if (a.updatedAt == null && b.updatedAt == null) {
            result = 0;
          } else if (a.updatedAt == null) {
            result = 1;
          } else if (b.updatedAt == null) {
            result = -1;
          } else {
            result = a.updatedAt!.compareTo(b.updatedAt!);
          }
          break;
      }
      return _isAscending ? result : -result;
    });

    return list;
  }
}
