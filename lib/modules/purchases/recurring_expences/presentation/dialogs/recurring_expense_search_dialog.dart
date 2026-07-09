import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/models/recurring_expense_lookup_models.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/providers/recurring_expense_provider.dart';
import 'package:zerpai_erp/shared/theme/app_text_styles.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

import '../models/recurring_expense_search_filters.dart';

class RecurringExpenseSearchDialog extends ConsumerStatefulWidget {
  final RecurringExpenseSearchFilters initialFilters;

  const RecurringExpenseSearchDialog({super.key, required this.initialFilters});

  @override
  ConsumerState<RecurringExpenseSearchDialog> createState() =>
      _RecurringExpenseSearchDialogState();
}

class _RecurringExpenseSearchDialogState
    extends ConsumerState<RecurringExpenseSearchDialog> {
  late String _module;
  String? _scopeFilter;
  String? _expenseAccount;
  String? _status;
  String? _customerName;
  String? _vendor;
  String? _tax;
  String? _gstTreatment;
  String? _sourceOfSupply;
  String? _destinationOfSupply;
  DateTime? _startDateFrom;
  DateTime? _startDateTo;
  DateTime? _endDateFrom;
  DateTime? _endDateTo;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _totalFromCtrl = TextEditingController();
  final TextEditingController _totalToCtrl = TextEditingController();
  final TextEditingController _startFromCtrl = TextEditingController();
  final TextEditingController _startToCtrl = TextEditingController();
  final TextEditingController _endFromCtrl = TextEditingController();
  final TextEditingController _endToCtrl = TextEditingController();

  final GlobalKey _startFromKey = GlobalKey();
  final GlobalKey _startToKey = GlobalKey();
  final GlobalKey _endFromKey = GlobalKey();
  final GlobalKey _endToKey = GlobalKey();

  static const List<String> _moduleOptions = ['Recurring Expenses'];
  static const List<String> _filterOptions = [
    'All',
    'Active',
    'Stopped',
    'Expired',
  ];
  static const List<String> _statusOptions = [
    'ACTIVE',
    'STOPPED',
    'EXPIRED',
  ];
  static const List<String> _taxOptions = ['Select a Tax', 'GST 18%'];

  @override
  void initState() {
    super.initState();
    final filters = widget.initialFilters;
    _module = filters.module;
    _scopeFilter = filters.scopeFilter;
    _expenseAccount = filters.expenseAccount;
    _status = filters.status;
    _customerName = filters.customerName;
    _vendor = filters.vendor;
    _tax = filters.tax;
    _gstTreatment = filters.gstTreatment;
    _sourceOfSupply = filters.sourceOfSupply;
    _destinationOfSupply = filters.destinationOfSupply;
    _startDateFrom = filters.startDateFrom;
    _startDateTo = filters.startDateTo;
    _endDateFrom = filters.endDateFrom;
    _endDateTo = filters.endDateTo;
    _nameCtrl.text = filters.name;
    _notesCtrl.text = filters.notes;
    _totalFromCtrl.text = filters.totalFrom?.toString() ?? '';
    _totalToCtrl.text = filters.totalTo?.toString() ?? '';
    _startFromCtrl.text = _formatDate(_startDateFrom);
    _startToCtrl.text = _formatDate(_startDateTo);
    _endFromCtrl.text = _formatDate(_endDateFrom);
    _endToCtrl.text = _formatDate(_endDateTo);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _totalFromCtrl.dispose();
    _totalToCtrl.dispose();
    _startFromCtrl.dispose();
    _startToCtrl.dispose();
    _endFromCtrl.dispose();
    _endToCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  double? _parseAmount(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed);
  }

  Future<void> _pickDate({
    required GlobalKey key,
    required DateTime? currentDate,
    required ValueChanged<DateTime?> onChanged,
    required TextEditingController controller,
  }) async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: currentDate ?? DateTime.now(),
      targetKey: key,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      onChanged(picked);
      controller.text = _formatDate(picked);
    });
  }

  void _submit() {
    Navigator.of(context).pop(
      RecurringExpenseSearchFilters(
        module: _module,
        scopeFilter: _scopeFilter,
        name: _nameCtrl.text,
        startDateFrom: _startDateFrom,
        startDateTo: _startDateTo,
        endDateFrom: _endDateFrom,
        endDateTo: _endDateTo,
        totalFrom: _parseAmount(_totalFromCtrl.text),
        totalTo: _parseAmount(_totalToCtrl.text),
        expenseAccount: _expenseAccount,
        status: _status,
        customerName: _customerName,
        vendor: _vendor,
        notes: _notesCtrl.text,
        tax: _tax == 'Select a Tax' ? null : _tax,
        gstTreatment: _gstTreatment,
        sourceOfSupply: _sourceOfSupply,
        destinationOfSupply: _destinationOfSupply,
      ),
    );
  }

  Widget _fieldRow(String label, Widget child) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: AppTextStyles.body.copyWith(
              color: AppTheme.textBody,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(child: child),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return CustomTextField(
      controller: controller,
      hintText: hint,
      height: 42,
      keyboardType: keyboardType,
    );
  }

  Widget _dropdown({
    required String? value,
    required List<String> items,
    String? hint,
    required ValueChanged<String?> onChanged,
  }) {
    return FormDropdown<String>(
      value: value,
      items: items,
      hint: hint,
      showSearch: false,
      height: 32,
      onChanged: onChanged,
    );
  }

  T? _selectedLookup<T>(
    List<T> items,
    String? selectedId,
    String Function(T item) idOf,
  ) {
    if (selectedId == null || selectedId.isEmpty) {
      return null;
    }
    for (final item in items) {
      if (idOf(item) == selectedId) {
        return item;
      }
    }
    return null;
  }

  Widget _dateField({
    required GlobalKey key,
    required TextEditingController controller,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return KeyedSubtree(
      key: key,
      child: CustomTextField(
        controller: controller,
        hintText: 'dd-MM-yyyy',
        height: 42,
        readOnly: true,
        onTap: () => _pickDate(
          key: key,
          currentDate: value,
          onChanged: onChanged,
          controller: controller,
        ),
      ),
    );
  }

  Widget _rangeFields(Widget start, Widget end) {
    return Row(
      children: [
        Expanded(child: start),
        const SizedBox(width: 18),
        Text('-', style: AppTextStyles.body.copyWith(color: AppTheme.textBody)),
        const SizedBox(width: 18),
        Expanded(child: end),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(recurringExpenseAccountsProvider);
    final vendorsAsync = ref.watch(recurringExpenseVendorsProvider);
    final customersAsync = ref.watch(recurringExpenseCustomersProvider);
    final gstTreatmentsAsync = ref.watch(recurringExpenseGstTreatmentsProvider);
    final statesAsync = ref.watch(recurringExpenseStatesProvider('IN'));

    final accounts = accountsAsync.value ?? const <ExpenseAccountLookupModel>[];
    final vendors = vendorsAsync.value ?? const <VendorLookupModel>[];
    final customers = customersAsync.value ?? const <CustomerLookupModel>[];
    final gstTreatments =
        gstTreatmentsAsync.value ?? const <GstTreatmentLookupModel>[];
    final states = statesAsync.value ?? const <StateLookupModel>[];

    return Align(
      alignment: Alignment.topCenter,
      child: Dialog(
        insetPadding: const EdgeInsets.only(left: 8, right: 8),
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
        ),
        child: SizedBox(
          width: 1288,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 74,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                decoration: const BoxDecoration(
                  color: AppTheme.bgLight,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 160,
                      child: Text(
                        'Search',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.body,
                      ),
                    ),
                    const SizedBox(width: 32),
                    SizedBox(
                      width: 376,
                      child: _dropdown(
                        value: _module,
                        items: _moduleOptions,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _module = value);
                        },
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(
                      width: 80,
                      child: Text(
                        'Filter',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.body,
                      ),
                    ),
                    const SizedBox(width: 32),
                    SizedBox(
                      width: 364,
                      child: _dropdown(
                        value: _scopeFilter,
                        items: _filterOptions,
                        onChanged: (value) =>
                            setState(() => _scopeFilter = value),
                      ),
                    ),
                    const SizedBox(width: 34),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: Icon(
                          Icons.close,
                          size: 22,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 26, 62, 42),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _fieldRow('Name', _textField(_nameCtrl)),
                          const SizedBox(height: 16),
                          _fieldRow(
                            'End Date Range',
                            _rangeFields(
                              _dateField(
                                key: _endFromKey,
                                controller: _endFromCtrl,
                                value: _endDateFrom,
                                onChanged: (date) => _endDateFrom = date,
                              ),
                              _dateField(
                                key: _endToKey,
                                controller: _endToCtrl,
                                value: _endDateTo,
                                onChanged: (date) => _endDateTo = date,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _fieldRow(
                            'Expense Account',
                            FormDropdown<ExpenseAccountLookupModel>(
                              value: _selectedLookup<ExpenseAccountLookupModel>(
                                accounts,
                                _expenseAccount,
                                (item) => item.id,
                              ),
                              items: accounts,
                              hint: accounts.isEmpty
                                  ? 'No accounts available'
                                  : 'Select an account',
                              showSearch: false,
                              height: 32,
                              displayStringForValue: (item) => item.displayName,
                              onChanged: (value) =>
                                  setState(() => _expenseAccount = value?.id),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _fieldRow(
                            'Customer Name',
                            FormDropdown<CustomerLookupModel>(
                              value: _selectedLookup<CustomerLookupModel>(
                                customers,
                                _customerName,
                                (item) => item.id,
                              ),
                              items: customers,
                              hint: customers.isEmpty
                                  ? 'No customers available'
                                  : 'Select customer',
                              showSearch: false,
                              height: 32,
                              displayStringForValue: (item) => item.displayName,
                              onChanged: (value) =>
                                  setState(() => _customerName = value?.id),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _fieldRow('Notes', _textField(_notesCtrl)),
                          const SizedBox(height: 16),
                          _fieldRow(
                            'GST Treatment',
                            FormDropdown<GstTreatmentLookupModel>(
                              value: _selectedLookup<GstTreatmentLookupModel>(
                                gstTreatments,
                                _gstTreatment,
                                (item) => item.code,
                              ),
                              items: gstTreatments,
                              hint: gstTreatmentsAsync.isLoading
                                  ? 'Loading GST Treatments...'
                                  : gstTreatments.isEmpty
                                  ? 'No GST Treatments Found'
                                  : 'Specify',
                              showSearch: false,
                              height: 32,
                              isLoading: gstTreatmentsAsync.isLoading,
                              displayStringForValue: (item) => item.label,
                              onChanged: (value) =>
                                  setState(() => _gstTreatment = value?.code),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _fieldRow(
                            'Destination of Supply',
                            FormDropdown<StateLookupModel>(
                              value: _selectedLookup<StateLookupModel>(
                                states,
                                _destinationOfSupply,
                                (item) => item.name,
                              ),
                              items: states,
                              hint: statesAsync.isLoading
                                  ? 'Loading States...'
                                  : states.isEmpty
                                  ? 'No States Found'
                                  : 'Select state',
                              showSearch: false,
                              height: 32,
                              isLoading: statesAsync.isLoading,
                              displayStringForValue: (item) =>
                                  item.displayLabel,
                              onChanged: (value) => setState(
                                () => _destinationOfSupply = value?.name,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 64),
                    Expanded(
                      child: Column(
                        children: [
                          _fieldRow(
                            'Start Date Range',
                            _rangeFields(
                              _dateField(
                                key: _startFromKey,
                                controller: _startFromCtrl,
                                value: _startDateFrom,
                                onChanged: (date) => _startDateFrom = date,
                              ),
                              _dateField(
                                key: _startToKey,
                                controller: _startToCtrl,
                                value: _startDateTo,
                                onChanged: (date) => _startDateTo = date,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _fieldRow(
                            'Total Range',
                            _rangeFields(
                              _textField(
                                _totalFromCtrl,
                                keyboardType: TextInputType.number,
                              ),
                              _textField(
                                _totalToCtrl,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _fieldRow(
                            'Status',
                            _dropdown(
                              value: _status,
                              items: _statusOptions,
                              onChanged: (value) =>
                                  setState(() => _status = value),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _fieldRow(
                            'Vendor',
                            FormDropdown<VendorLookupModel>(
                              value: _selectedLookup<VendorLookupModel>(
                                vendors,
                                _vendor,
                                (item) => item.id,
                              ),
                              items: vendors,
                              hint: vendors.isEmpty
                                  ? 'No vendors available'
                                  : 'Select vendor',
                              showSearch: false,
                              height: 32,
                              displayStringForValue: (item) => item.displayName,
                              onChanged: (value) =>
                                  setState(() => _vendor = value?.id),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _fieldRow(
                            'Tax',
                            _dropdown(
                              value: _tax,
                              items: _taxOptions,
                              hint: 'Select a Tax',
                              onChanged: (value) =>
                                  setState(() => _tax = value),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _fieldRow(
                            'Source of Supply',
                            FormDropdown<StateLookupModel>(
                              value: _selectedLookup<StateLookupModel>(
                                states,
                                _sourceOfSupply,
                                (item) => item.name,
                              ),
                              items: states,
                              hint: statesAsync.isLoading
                                  ? 'Loading States...'
                                  : states.isEmpty
                                  ? 'No States Found'
                                  : 'Select state',
                              showSearch: false,
                              height: 32,
                              isLoading: statesAsync.isLoading,
                              displayStringForValue: (item) =>
                                  item.displayLabel,
                              onChanged: (value) =>
                                  setState(() => _sourceOfSupply = value?.name),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 98,
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ZButton.primary(label: 'Search', onPressed: _submit),
                    const SizedBox(width: 8),
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
      ),
    );
  }
}
