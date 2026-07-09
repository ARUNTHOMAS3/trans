import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/purchases/expenses/providers/expenses_provider.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/models/recurring_expense_lookup_models.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/account_tree_dropdown_with_add_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/customer_dropdown_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/expense_account_dropdown_widget.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/shared/models/account_node.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class ExpensesBulkUpdateDialog extends ConsumerStatefulWidget {
  final List<String> fields;
  final void Function(String field, String value) onUpdate;

  const ExpensesBulkUpdateDialog({
    super.key,
    required this.fields,
    required this.onUpdate,
  });

  @override
  ConsumerState<ExpensesBulkUpdateDialog> createState() =>
      _ExpensesBulkUpdateDialogState();
}

class _ExpensesBulkUpdateDialogState
    extends ConsumerState<ExpensesBulkUpdateDialog> {
  String? _selectedField;
  final TextEditingController _valueController = TextEditingController();
  final GlobalKey _datePickerKey = GlobalKey();
  String? _selectedExpenseAccountId;
  String? _selectedPaidThroughAccountId;
  RecurringExpenseCustomerOption? _selectedCustomer;
  DateTime? _selectedDate;
  String _billableSelection = 'Check this option';

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _resetValueState() {
    _valueController.clear();
    _selectedExpenseAccountId = null;
    _selectedPaidThroughAccountId = null;
    _selectedCustomer = null;
    _selectedDate = null;
    _billableSelection = 'Check this option';
  }

  List<AccountNode> _expenseAccountNodes() {
    final accounts = ref
        .watch(expensesExpenseAccountsProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => const <ExpenseAccountLookupModel>[],
        );
    return buildRecurringExpenseGroupedAccountNodes(accounts);
  }

  List<AccountNode> _paidThroughNodes() {
    final chartState = ref.watch(chartOfAccountsProvider);
    return buildRecurringPaidThroughAccountNodes(chartState.roots);
  }

  List<RecurringExpenseCustomerOption> _customerOptions() {
    final List<SalesCustomer> customers = ref
        .watch(salesCustomersProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => const <SalesCustomer>[],
        );
    return customers
        .map(RecurringExpenseCustomerOption.fromSalesCustomer)
        .toList(growable: false);
  }

  String? _findAccountName(List<AccountNode> nodes, String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final node in nodes) {
      if (node.id == id && node.selectable) {
        return node.name;
      }
      final childMatch = _findAccountName(node.children, id);
      if (childMatch != null) {
        return childMatch;
      }
    }
    return null;
  }

  Future<void> _selectDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: _selectedDate ?? DateTime.now(),
      targetKey: _datePickerKey,
    );
    if (picked == null) return;

    final formatted =
        '${picked.day.toString().padLeft(2, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-${picked.year}';
    setState(() {
      _selectedDate = picked;
      _valueController.text = formatted;
    });
  }

  Widget _buildTextInput({
    required String hintText,
    int maxLines = 1,
    double height = 32,
    bool enabled = true,
  }) {
    return CustomTextField(
      controller: _valueController,
      hintText: hintText,
      maxLines: maxLines,
      height: height,
      enabled: enabled,
    );
  }

  Widget _buildDateField() {
    final selectedDate = _selectedDate;
    return GestureDetector(
      key: _datePickerKey,
      onTap: _selectDate,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: selectedDate == null
                  ? AppTheme.textSecondary
                  : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              selectedDate == null
                  ? 'DD-MM-YY'
                  : '${selectedDate.day.toString().padLeft(2, '0')}-'
                        '${selectedDate.month.toString().padLeft(2, '0')}-'
                        '${selectedDate.year}',
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: selectedDate == null
                    ? AppTheme.textMuted
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightInput() {
    if (_selectedField == null) {
      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    switch (_selectedField) {
      case 'Date':
        return _buildDateField();
      case 'Billable':
        return ZerpaiRadioGroup<String>(
          options: const ['Check this option', 'Uncheck this option'],
          current: _billableSelection,
          onChanged: (value) => setState(() => _billableSelection = value),
        );
      case 'Expense Account':
        return ExpenseAccountDropdownWidget(
          value: _selectedExpenseAccountId,
          nodes: _expenseAccountNodes(),
          hint: 'Select an account',
          onChanged: (value) =>
              setState(() => _selectedExpenseAccountId = value),
        );
      case 'Paid Through':
        return AccountTreeDropdownWithAddButton(
          value: _selectedPaidThroughAccountId,
          nodes: _paidThroughNodes(),
          height: 32,
          hint: 'Select an account',
          highlightSearchMatches: false,
          onChanged: (value) =>
              setState(() => _selectedPaidThroughAccountId = value),
        );
      case 'Reference#':
        return _buildTextInput(hintText: 'Enter reference#');
      case 'Notes':
        return _buildTextInput(
          hintText: 'Enter notes',
          maxLines: 4,
          height: 80,
        );
      case 'Customer Name':
        final customersAsync = ref.watch(salesCustomersProvider);
        final customerOptions = _customerOptions();
        return CustomerDropdownWidget(
          value: _selectedCustomer,
          items: customerOptions,
          isLoading: customersAsync.isLoading,
          hint: customersAsync.isLoading
              ? 'Loading Customers...'
              : customersAsync.hasError
              ? 'Unable to load customers'
              : customerOptions.isEmpty
              ? 'No Customers Found'
              : 'Select Customer',
          onChanged: (value) => setState(() => _selectedCustomer = value),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _submit() {
    final field = _selectedField;
    if (field == null) {
      return;
    }
    String? value;
    switch (field) {
      case 'Expense Account':
        value = _findAccountName(
          _expenseAccountNodes(),
          _selectedExpenseAccountId,
        );
        break;
      case 'Paid Through':
        value = _findAccountName(
          _paidThroughNodes(),
          _selectedPaidThroughAccountId,
        );
        break;
      case 'Billable':
        value = _billableSelection == 'Check this option'
            ? 'BILLABLE'
            : 'NON-BILLABLE';
        break;
      case 'Customer Name':
        value = _selectedCustomer?.displayName;
        break;
      default:
        value = _valueController.text.trim();
        break;
    }
    if (value == null || value.trim().isEmpty) {
      return;
    }
    widget.onUpdate(field, value.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      surfaceTintColor: AppTheme.backgroundColor,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Container(
        width: 560,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Bulk Update Expenses',
                      style: AppTextStyles.title,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.errorRed),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            const SizedBox(height: 18),
            Text(
              'Choose a field from the dropdown and update with new information.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FormDropdown<String>(
                    value: _selectedField,
                    items: widget.fields,
                    placeholder: 'Select field',
                    height: 32,
                    onChanged: (value) {
                      setState(() {
                        _selectedField = value;
                        _resetValueState();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(child: _buildRightInput()),
              ],
            ),
            const SizedBox(height: 20),
            RichText(
              text: TextSpan(
                style: AppTextStyles.body.copyWith(height: 1.5),
                children: [
                  const TextSpan(
                    text: 'Note: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text:
                        'All the selected expenses will be updated with the new '
                        'information and you cannot undo this action.',
                    style: AppTextStyles.body.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ZButton.primary(label: 'Update', onPressed: _submit),
                const SizedBox(width: 12),
                ZButton.secondary(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
