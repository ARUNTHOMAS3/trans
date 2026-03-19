part of '../sales_generic_list.dart';

extension _SalesGenericListTableLogic on _SalesGenericListScreenState {
  void _toggleSelectAll(bool? value, List<dynamic> data) {
    _state(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedIds.addAll(
          data
              .map((e) => _getItemId(e))
              .where((id) => id != null)
              .cast<String>(),
        );
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelectOne(String? id, bool? value) {
    if (id == null) return;
    _state(() {
      if (value == true) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
        _selectAll = false;
      }
    });
  }

  String? _getItemId(dynamic item) {
    if (item is SalesOrder) return item.id;
    if (item is SalesPayment) return item.paymentNumber;
    if (item is SalesEWayBill) return item.billNumber;
    if (item is SalesPaymentLink) return item.linkNumber;
    if (item is SalesCustomer) return item.id;
    return null;
  }

  Widget _buildCheckboxCell({
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      width: 40,
      constraints: const BoxConstraints(minHeight: 44),
      alignment: Alignment.center,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        activeColor: AppTheme.primaryBlueDark,
        side: const BorderSide(color: AppTheme.borderColor),
      ),
    );
  }

  dynamic _getSortValue(dynamic item, String key) {
    if (item is SalesCustomer) {
      if (key == 'name') {
        return item.displayName;
      }
      if (key == 'company_name') {
        return item.companyName;
      }
      if (key == 'email') {
        return item.email;
      }
      if (key == 'phone') {
        return item.phone;
      }
      if (key == 'gst_treatment') {
        return item.customerType;
      }
      if (key == 'receivables_bcy' || key == 'receivables') {
        return item.receivables;
      }
    }
    // Generic fallback for other types
    try {
      return item.toJson()[key];
    } catch (_) {
      return null;
    }
  }

  void _onSort(String key) {
    _state(() {
      if (_sortColumn == key) {
        _isAscending = !_isAscending;
      } else {
        _sortColumn = key;
        _isAscending = true;
      }
    });
  }
}
