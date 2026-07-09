import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/config/recurring_expense_constants.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/models/recurring_expense_enums.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/models/recurring_expense_lookup_models.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/account_tree_dropdown_with_add_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/customer_dropdown_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/expense_account_dropdown_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/vendor_dropdown_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/providers/recurring_expense_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/shared/models/account_node.dart';
import 'package:zerpai_erp/shared/theme/app_text_styles.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class RecurringExpenseBulkUpdateResult {
  final String field;
  final String value;
  final String? displayValue;
  final int? repeatEvery;
  final RecurringRepeatType? repeatType;

  const RecurringExpenseBulkUpdateResult({
    required this.field,
    required this.value,
    this.displayValue,
    this.repeatEvery,
    this.repeatType,
  });
}

class _RecurringExpenseResizableBox extends StatefulWidget {
  const _RecurringExpenseResizableBox({
    required this.child,
    required this.initialHeight,
    required this.minHeight,
    this.maxHeight,
    this.onResize,
  });

  final Widget child;
  final double initialHeight;
  final double minHeight;
  final double? maxHeight;
  final ValueChanged<double>? onResize;

  @override
  State<_RecurringExpenseResizableBox> createState() =>
      _RecurringExpenseResizableBoxState();
}

class _RecurringExpenseResizableBoxState
    extends State<_RecurringExpenseResizableBox> {
  late double height;

  @override
  void initState() {
    super.initState();
    height = widget.initialHeight;
  }

  @override
  void didUpdateWidget(covariant _RecurringExpenseResizableBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHeight != widget.initialHeight &&
        widget.initialHeight != height) {
      height = widget.initialHeight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            right: 4,
            bottom: 4,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: (details) {
                setState(() {
                  height += details.delta.dy;
                  if (height < widget.minHeight) {
                    height = widget.minHeight;
                  }
                  if (widget.maxHeight != null && height > widget.maxHeight!) {
                    height = widget.maxHeight!;
                  }
                });
                widget.onResize?.call(height);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: const SizedBox(
                  width: 12,
                  height: 12,
                  child: CustomPaint(
                    painter: _RecurringExpenseResizeHandlePainter(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringExpenseResizeHandlePainter extends CustomPainter {
  const _RecurringExpenseResizeHandlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textMuted
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.2, size.height),
      Offset(size.width, size.height * 0.2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height),
      Offset(size.width, size.height * 0.6),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RecurringExpenseBulkUpdateDialog extends ConsumerStatefulWidget {
  const RecurringExpenseBulkUpdateDialog({super.key});

  @override
  ConsumerState<RecurringExpenseBulkUpdateDialog> createState() =>
      _RecurringExpenseBulkUpdateDialogState();
}

class _RecurringExpenseBulkUpdateDialogState
    extends ConsumerState<RecurringExpenseBulkUpdateDialog> {
  String? _selectedField;
  final TextEditingController _valueCtrl = TextEditingController();
  final GlobalKey _valueDateKey = GlobalKey();
  String? _selectedExpenseAccountId;
  String? _selectedPaidThroughId;
  RecurringExpenseVendorOption? _selectedVendor;
  RecurringExpenseCustomerOption? _selectedCustomer;
  String _selectedRepeatEvery =
      RecurringExpenseModuleDefaults.defaultRepeatEvery;
  final TextEditingController _customRepeatIntervalCtrl = TextEditingController(
    text: '1',
  );
  String _selectedCustomRepeatUnit =
      RecurringExpenseModuleDefaults.defaultCustomRepeatUnit;
  DateTime? _selectedDate;
  String _expenseType = 'Goods';
  String _billableSelection = 'Check this option';
  double _notesFieldHeight = 80.0;

  static const List<String> _fieldOptions = [
    'Expense Account',
    'Paid Through',
    'End Date',
    'Repeat Every',
    'Notes',
    'Vendor',
    'Customer',
    'Expense Type',
    'Billable',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vendorState = ref.read(vendorProvider);
      if (vendorState.vendors.isEmpty && !vendorState.isLoading) {
        ref.read(vendorProvider.notifier).loadVendors();
      }
    });
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _customRepeatIntervalCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  String _formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _pickDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: _selectedDate ?? DateUtils.dateOnly(DateTime.now()),
      targetKey: _valueDateKey,
    );
    if (picked == null) {
      return;
    }
    setState(() => _selectedDate = picked);
  }

  (int, RecurringRepeatType)? _resolveRepeatConfig() {
    if (_selectedRepeatEvery == 'Custom') {
      final interval = int.tryParse(_customRepeatIntervalCtrl.text.trim());
      if (interval == null || interval <= 0) {
        return null;
      }
      final type = switch (_selectedCustomRepeatUnit) {
        'Day(s)' => RecurringRepeatType.day,
        'Week(s)' => RecurringRepeatType.week,
        'Month(s)' => RecurringRepeatType.month,
        'Year(s)' => RecurringRepeatType.year,
        _ => RecurringRepeatType.week,
      };
      return (interval, type);
    }
    final type = switch (_selectedRepeatEvery) {
      'Day' => RecurringRepeatType.day,
      'Week' => RecurringRepeatType.week,
      'Month' => RecurringRepeatType.month,
      'Year' => RecurringRepeatType.year,
      _ => RecurringRepeatType.week,
    };
    return (1, type);
  }

  void _update() {
    final field = _selectedField;
    if (field == null) {
      return;
    }
    String? value;
    String? displayValue;
    switch (field) {
      case 'Expense Account':
        value = _selectedExpenseAccountId;
        displayValue = _findAccountName(
          buildRecurringExpenseGroupedAccountNodes(
            ref.read(recurringExpenseAccountsProvider).asData?.value ??
                const <ExpenseAccountLookupModel>[],
          ),
          _selectedExpenseAccountId,
        );
        break;
      case 'Paid Through':
        value = _selectedPaidThroughId;
        displayValue = _findAccountName(
          buildRecurringPaidThroughAccountNodes(
            ref.read(chartOfAccountsProvider).roots,
          ),
          _selectedPaidThroughId,
        );
        break;
      case 'End Date':
        value = _selectedDate == null ? null : _formatIsoDate(_selectedDate!);
        displayValue = _selectedDate == null
            ? null
            : _formatDate(_selectedDate!);
        break;
      case 'Repeat Every':
        final repeatConfig = _resolveRepeatConfig();
        if (repeatConfig == null) {
          return;
        }
        value = _selectedRepeatEvery;
        displayValue = _selectedRepeatEvery == 'Custom'
            ? '${repeatConfig.$1} ${repeatConfig.$2.customUnitLabel}'
            : repeatConfig.$2.displayLabel;
        Navigator.of(context).pop(
          RecurringExpenseBulkUpdateResult(
            field: field,
            value: value,
            displayValue: displayValue,
            repeatEvery: repeatConfig.$1,
            repeatType: repeatConfig.$2,
          ),
        );
        return;
      case 'Notes':
        value = _valueCtrl.text.trim();
        break;
      case 'Vendor':
        value = _selectedVendor?.id;
        displayValue = _selectedVendor?.displayName;
        break;
      case 'Customer':
        value = _selectedCustomer?.id;
        displayValue = _selectedCustomer?.displayName;
        break;
      case 'Expense Type':
        value = _expenseType == 'Services' ? 'SERVICES' : 'GOODS';
        displayValue = _expenseType;
        break;
      case 'Billable':
        value = _billableSelection;
        displayValue = _billableSelection;
        break;
    }
    if (value == null || value.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      RecurringExpenseBulkUpdateResult(
        field: field,
        value: value,
        displayValue: displayValue,
      ),
    );
  }

  void _resetValueState() {
    _valueCtrl.clear();
    _selectedExpenseAccountId = null;
    _selectedPaidThroughId = null;
    _selectedVendor = null;
    _selectedCustomer = null;
    _selectedRepeatEvery = RecurringExpenseModuleDefaults.defaultRepeatEvery;
    _customRepeatIntervalCtrl.text = '1';
    _selectedCustomRepeatUnit =
        RecurringExpenseModuleDefaults.defaultCustomRepeatUnit;
    _selectedDate = null;
    _expenseType = 'Goods';
    _billableSelection = 'Check this option';
    _notesFieldHeight = 80.0;
  }

  List<AccountNode> _expenseAccountsFromProvider() {
    final accounts =
        ref.watch(recurringExpenseAccountsProvider).asData?.value ??
        const <ExpenseAccountLookupModel>[];
    return buildRecurringExpenseGroupedAccountNodes(accounts);
  }

  List<AccountNode> _paidThroughAccountsFromProvider() {
    final chartState = ref.watch(chartOfAccountsProvider);
    return buildRecurringPaidThroughAccountNodes(chartState.roots);
  }

  List<RecurringExpenseVendorOption> _vendorOptions() {
    final vendorState = ref.watch(vendorProvider);
    return vendorState.vendors
        .map(RecurringExpenseVendorOption.fromVendor)
        .toList();
  }

  List<RecurringExpenseCustomerOption> _customerOptions() {
    final List<SalesCustomer> customers =
        ref.watch(salesCustomersProvider).asData?.value ??
        const <SalesCustomer>[];
    return customers
        .map(RecurringExpenseCustomerOption.fromSalesCustomer)
        .toList();
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

  Widget _buildDateField({String hintText = 'DD-MM-YY'}) {
    final selectedDate = _selectedDate;
    return GestureDetector(
      key: _valueDateKey,
      onTap: _pickDate,
      child: Container(
        height: 32,
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
              selectedDate == null ? hintText : _formatDate(selectedDate),
              style: AppTextStyles.body.copyWith(
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

  Widget _buildRepeatField() {
    final repeatDropdown = FormDropdown<String>(
      height: 32,
      value: _selectedRepeatEvery,
      items: const ['Week', 'Month', 'Year', 'Day', 'Custom'],
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() => _selectedRepeatEvery = value);
      },
    );

    if (_selectedRepeatEvery != 'Custom') {
      return repeatDropdown;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        repeatDropdown,
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 56,
              child: CustomTextField(
                controller: _customRepeatIntervalCtrl,
                height: 32,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 148,
              child: FormDropdown<String>(
                height: 32,
                value: _selectedCustomRepeatUnit,
                items: const ['Day(s)', 'Week(s)', 'Month(s)', 'Year(s)'],
                showSearch: false,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selectedCustomRepeatUnit = value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseTypeField() {
    return ZerpaiRadioGroup<String>(
      options: const ['Goods', 'Services'],
      current: _expenseType,
      onChanged: (value) => setState(() => _expenseType = value),
    );
  }

  Widget _buildBillableField() {
    return ZerpaiRadioGroup<String>(
      options: const ['Check this option', 'Uncheck this option'],
      current: _billableSelection,
      onChanged: (value) => setState(() => _billableSelection = value),
    );
  }

  Widget _buildNotesField() {
    return _RecurringExpenseResizableBox(
      initialHeight: _notesFieldHeight,
      minHeight: 80,
      maxHeight: 220,
      onResize: (height) => setState(() => _notesFieldHeight = height),
      child: CustomTextField(
        controller: _valueCtrl,
        hintText: 'Max. 500 characters',
        maxLines: 4,
        height: _notesFieldHeight,
        padding: const EdgeInsets.only(
          left: 10,
          top: 10,
          right: 24,
          bottom: 24,
        ),
        contentCase: ContentCase.sentence,
      ),
    );
  }

  Widget _valueField() {
    final expenseAccounts = _expenseAccountsFromProvider();
    final paidThroughAccounts = _paidThroughAccountsFromProvider();
    final vendors = _vendorOptions();
    final customers = _customerOptions();

    switch (_selectedField) {
      case 'Expense Account':
        return ExpenseAccountDropdownWidget(
          value: _selectedExpenseAccountId,
          nodes: expenseAccounts,
          onChanged: (value) =>
              setState(() => _selectedExpenseAccountId = value),
        );
      case 'Paid Through':
        return AccountTreeDropdownWithAddButton(
          value: _selectedPaidThroughId,
          nodes: paidThroughAccounts,
          height: 32,
          hint: 'Select an account',
          highlightSearchMatches: false,
          onChanged: (value) => setState(() => _selectedPaidThroughId = value),
        );
      case 'End Date':
        return _buildDateField();
      case 'Vendor':
        return VendorDropdownWidget(
          value: _selectedVendor,
          items: vendors,
          isLoading: ref.watch(vendorProvider).isLoading,
          hint: 'Select a Vendor',
          onChanged: (value) => setState(() => _selectedVendor = value),
        );
      case 'Customer':
        return CustomerDropdownWidget(
          value: _selectedCustomer,
          items: customers,
          isLoading: ref.watch(salesCustomersProvider).isLoading,
          hint: 'Select Customer',
          onChanged: (value) => setState(() => _selectedCustomer = value),
        );
      case 'Expense Type':
        return _buildExpenseTypeField();
      case 'Billable':
        return _buildBillableField();
      case 'Repeat Every':
        return _buildRepeatField();
      case 'Notes':
        return _buildNotesField();
      default:
        return CustomTextField(controller: _valueCtrl, height: 32);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 4),
      backgroundColor: AppTheme.backgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 750,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 26),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Text(
                    'Bulk Update Recurring Expenses',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(
                        Icons.close,
                        color: AppTheme.errorRed,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 28, 26, 42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a field from the dropdown and update with new information.',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 332,
                        child: FormDropdown<String>(
                          value: _selectedField,
                          items: _fieldOptions,
                          hint: 'Select a field',
                          height: 32,
                          showSearch: true,
                          menuWidth: 332,
                          menuMaxHeight: 345,
                          itemHeight: 45,
                          onChanged: (value) {
                            setState(() {
                              _selectedField = value;
                              _resetValueState();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 38),
                      Expanded(child: _valueField()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Note: ',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                        const TextSpan(
                          text:
                              'All the selected recurring expenses will be updated with the new\ninformation and you cannot undo this action.',
                        ),
                      ],
                    ),
                    style: AppTextStyles.body.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 98,
              padding: const EdgeInsets.symmetric(horizontal: 26),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  ZButton.primary(label: 'Update', onPressed: _update),
                  const SizedBox(width: 10),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
