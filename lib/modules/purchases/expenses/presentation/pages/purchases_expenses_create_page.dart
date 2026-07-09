import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_attachment_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_employee_option.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_item_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_mileage_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/widgets/z_expenses_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_record.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_request_models.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/widgets/expense_attachment_card_widget.dart';
import 'package:zerpai_erp/modules/purchases/expenses/providers/expenses_provider.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/recurring_expense_loading_indicator_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/models/recurring_expense_enums.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/models/recurring_expense_lookup_models.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/models/recurring_expense_details_model.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/dialogs/add_account_dialog.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/providers/recurring_expense_provider.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/amount_input_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/account_tree_dropdown_with_add_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/customer_dropdown_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/expense_account_dropdown_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/recurring_expense_form_metrics.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/recurring_expense_gst_option_row.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/vendor_dropdown_widget.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/advanced_customer_search_dialog.dart';
import 'package:zerpai_erp/shared/models/account_node.dart';

final mileageEmployeesProvider = FutureProvider<List<ExpenseEmployeeOption>>((
  ref,
) async {
  final repository = ref.read(expensesRepositoryProvider);
  return repository.getEmployees();
});

class ExpensesCreatePage extends ConsumerStatefulWidget {
  const ExpensesCreatePage({super.key});

  @override
  ConsumerState<ExpensesCreatePage> createState() => _ExpensesCreatePageState();
}

class _ExpensesCreatePageState extends ConsumerState<ExpensesCreatePage> {
  final _formKey = GlobalKey<FormState>();

  bool _didApplyRouteDefaults = false;
  bool _isSubmitting = false;
  bool _isLoadingEditExpense = false;
  ExpenseRecord? _editingExpense;
  String? _prefillRecurringExpenseId;

  // ── Field state ─────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  String? _selectedCategoryAccountId;
  String? _selectedPaidThroughAccountId;
  String _currency = 'INR';
  final TextEditingController _amountController = TextEditingController();
  String _expenseType = 'Services';
  final TextEditingController _sacController = TextEditingController();
  VendorItem? _selectedVendorItem;
  String? _selectedVendorId;
  String? _gstTreatment;
  final TextEditingController _vendorGstinController = TextEditingController();
  String _sourceOfSupply = 'State/Province';
  String _destinationOfSupply = '[KL] - Kerala';
  bool _reverseCharge = false;
  String? _selectedTax;
  final TextEditingController _exemptionReasonController =
      TextEditingController();
  String? _exemptionReasonErrorText;
  String _amountIs = 'Tax Exclusive';
  final TextEditingController _invoiceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _selectedCustomer;
  String? _selectedCustomerId;
  bool _isCustomerBillable = false;
  final TextEditingController _markupByController = TextEditingController();
  final FocusNode _markupByFocusNode = FocusNode();
  bool _isMarkupByHovered = false;
  List<PlatformFile> _selectedReceiptFiles = const <PlatformFile>[];

  bool _isItemized = false;
  String _taxOverrideLevel = 'At Transaction Level';
  final List<ExpenseItemRow> _itemizedRows = [];
  int? _draggingItemizedRowIndex;
  int? _hoveredReadOnlyItemTaxIndex;
  int? _editingItemizedHsnSacIndex;
  OverlayEntry? _itemizedHsnSacOverlayEntry;
  final LayerLink _itemizedTotalTaxLayerLink = LayerLink();
  OverlayEntry? _itemizedTotalTaxOverlayEntry;
  final GlobalKey _itemizedTotalTaxAnchorKey = GlobalKey();
  final LayerLink _taxAmountLayerLink = LayerLink();
  OverlayEntry? _taxAmountOverlayEntry;
  final GlobalKey _taxAmountAnchorKey = GlobalKey();
  double? _taxAmountOverride;
  String? _taxAmountOverrideTaxId;
  String? _taxAmountOverrideAmountText;
  final LayerLink _itcLayerLink = LayerLink();
  OverlayEntry? _itcOverlayEntry;
  final GlobalKey _itcAnchorKey = GlobalKey();
  String _selectedItcStatus = 'Eligible For ITC';
  Map<String, double> _itemizedTaxOverrides = {};
  Color _itemizeBgColor = AppTheme.backgroundColor;
  Timer? _yellowShadeTimer;

  String _mileageUnit = 'Km';
  final List<MileageRateRow> _mileageRates = [];
  static const List<String> _itcOptions = <String>[
    'Eligible For ITC',
    'Ineligible - As per Section 17 (5)',
    'Ineligible - Others',
  ];

  int _activeTab = 0; // 0 = Record Expense, 1 = Record Mileage
  String? _selectedEmployee;
  String? _selectedVehicle;
  String _calculationMethod = 'Distance travelled';
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _startOdometerController =
      TextEditingController();
  final TextEditingController _endOdometerController = TextEditingController();
  final FocusNode _endOdometerFocusNode = FocusNode();
  final TextEditingController _mileageAmountController = TextEditingController(
    text: '0.00',
  );
  final GlobalKey<FormState> _mileageFormKey = GlobalKey<FormState>();

  static const List<String> _vehicles = [
    'Honda Activa',
    'Maruti Swift',
    'Hyundai i20',
  ];
  static const double _receiptCardTopOffset = 24;
  static const double _receiptCardRightOffset = 122;
  static const double _receiptCardWidth = 246;
  static const double _receiptCardHeight = 330;

  @override
  void initState() {
    super.initState();
    _itemizedRows.add(_newItemizedRow(expenseType: _expenseType));
    _mileageRates.add(MileageRateRow());
    _endOdometerFocusNode.addListener(_handleEndOdometerFocusChange);
    _markupByFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    Future.microtask(() => ref.read(vendorProvider.notifier).loadVendors());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplyRouteDefaults) {
      return;
    }
    _didApplyRouteDefaults = true;

    final routeState = GoRouterState.of(context);
    if (routeState.uri.queryParameters['mode'] == 'edit') {
      final expenseId = routeState.uri.queryParameters['id'];
      if (expenseId == null || expenseId.isEmpty) {
        return;
      }
      _loadEditExpense(expenseId);
      return;
    }

    if (routeState.uri.queryParameters['mode'] == 'clone') {
      final expenseId = routeState.uri.queryParameters['id'];
      if (expenseId == null || expenseId.isEmpty) {
        return;
      }
      _loadCloneExpensePrefill(expenseId);
      return;
    }

    final recurringId = routeState.uri.queryParameters['recurringId'];
    if (recurringId == null || recurringId.isEmpty) {
      return;
    }
    _loadRecurringExpensePrefill(recurringId);
  }

  // ── Options ─────────────────────────────────────────────────────────────

  final List<VendorItem> _vendorsList = [
    const VendorItem(
      name: 'ARUN THOMAS',
      code: 'VEN-01',
      email: 'arunthomas@gmail.om',
    ),
    const VendorItem(
      name: 'Evanto',
      code: 'VEN-00002',
      email: 'demo@gmail.com',
      extraSubtitle: 'Evanto',
    ),
    const VendorItem(
      name: 'FIRST LOGIC META LAB PRIVATE LIMITED',
      code: 'VEN-00004',
      extraSubtitle: 'FIRST LOGIC META LAB PRIVATE LIMITED',
    ),
    const VendorItem(
      name: 'Freelancer-Jaseem',
      code: 'VEN-00003',
      extraSubtitle: 'Freelancer-Jaseem',
    ),
  ];
  RecurringExpenseVendorOption _toVendorOption(VendorItem item) {
    return RecurringExpenseVendorOption(
      id: item.code,
      displayName: item.name,
      vendorNumber: item.code,
      companyName: item.extraSubtitle,
      firstName: item.name,
    );
  }

  List<ExpenseAccountLookupModel> get _expenseAccountCatalog => ref
      .watch(expensesExpenseAccountsProvider)
      .maybeWhen(
        data: (value) => value,
        orElse: () => const <ExpenseAccountLookupModel>[],
      );

  List<ExpenseAccountLookupModel> get _flattenedExpenseAccounts =>
      _flattenExpenseAccounts(_expenseAccountCatalog);

  List<AccountNode> get _paidThroughAccountsList {
    final chartOfAccountsState = ref.watch(chartOfAccountsProvider);
    final nodes = List<AccountNode>.from(
      buildRecurringPaidThroughAccountNodes(chartOfAccountsState.roots),
    );

    bool containsAccount(List<AccountNode> items, String id) {
      for (final node in items) {
        if (node.id == id || containsAccount(node.children, id)) {
          return true;
        }
      }
      return false;
    }

    final fallbackId =
        _selectedPaidThroughAccountId ?? _editingExpense?.paidThroughAccountId;
    final fallbackName = _editingExpense?.paidThrough;
    if (fallbackId != null &&
        fallbackId.isNotEmpty &&
        !containsAccount(nodes, fallbackId)) {
      nodes.insert(
        0,
        AccountNode(
          id: fallbackId,
          name: (fallbackName != null && fallbackName.isNotEmpty)
              ? fallbackName
              : fallbackId,
          selectable: true,
        ),
      );
    }

    return nodes;
  }

  List<VendorLookupModel> get _vendorCatalog => ref
      .watch(vendorProvider)
      .vendors
      .map(VendorLookupModel.fromVendor)
      .toList(growable: false);

  List<RecurringExpenseCustomerOption> get _customerCatalog => ref
      .watch(salesCustomersProvider)
      .maybeWhen(
        data: (value) => value
            .map(RecurringExpenseCustomerOption.fromSalesCustomer)
            .toList(growable: false),
        orElse: () => const <RecurringExpenseCustomerOption>[],
      );

  List<RecurringExpenseVendorOption> get _vendorOptions => _vendorCatalog;

  List<RecurringExpenseCustomerOption> get _customerOptions {
    final options = List<RecurringExpenseCustomerOption>.from(_customerCatalog);
    final selected = _selectedCustomerOption;
    if (selected != null && !options.any((item) => item.id == selected.id)) {
      options.insert(0, selected);
    }
    return options;
  }

  List<CurrencyLookupModel> get _expenseCurrencyOptions => ref
      .watch(expensesCurrenciesProvider)
      .maybeWhen(
        data: (value) => value,
        orElse: () => _currencies
            .map(
              (code) => CurrencyLookupModel(id: code, code: code, name: code),
            )
            .toList(growable: false),
      );

  List<GstTreatmentLookupModel> get _gstTreatmentCatalog => ref
      .watch(expensesGstTreatmentsProvider)
      .maybeWhen(
        data: (value) => value,
        orElse: () => const <GstTreatmentLookupModel>[],
      );

  List<StateLookupModel> get _stateCatalog => ref
      .watch(expensesStatesProvider('IN'))
      .maybeWhen(
        data: (value) => value,
        orElse: () => const <StateLookupModel>[],
      );

  List<RecurringExpenseTaxOption> get _taxCatalog => ref
      .watch(expensesTaxesProvider)
      .maybeWhen(
        data: (value) => value,
        orElse: () => const <RecurringExpenseTaxOption>[],
      );

  List<RecurringExpenseTaxOption> get _visibleTaxCatalog {
    final sourceState = _selectedStateOption(_sourceOfSupply);
    final destinationState = _selectedStateOption(_destinationOfSupply);
    if (sourceState == null || destinationState == null) {
      return _taxCatalog;
    }
    final isIntrastate =
        sourceState.code.trim().toUpperCase() ==
        destinationState.code.trim().toUpperCase();
    final List<RecurringExpenseTaxOption> ungroupedTaxes = _taxCatalog
        .where((item) => item.isUngrouped)
        .where(_isNonTaxableOption)
        .toList(growable: false);
    final List<RecurringExpenseTaxOption> rateTaxes = _taxCatalog
        .where((item) => item.isTaxRate)
        .where(
          (item) => isIntrastate
              ? _isVisibleIntrastateTax(item)
              : _isVisibleInterstateTax(item),
        )
        .toList(growable: false);
    final List<RecurringExpenseTaxOption> groupTaxes = _taxCatalog
        .where((item) => item.isTaxGroup)
        .where(
          (item) => isIntrastate
              ? _isVisibleIntrastateTax(item)
              : _isVisibleInterstateTax(item),
        )
        .toList(growable: false);
    final filtered = <RecurringExpenseTaxOption>[
      ...ungroupedTaxes,
      if (rateTaxes.isNotEmpty)
        const RecurringExpenseTaxOption(
          id: '__tax_header__',
          label: 'Tax',
          isHeader: true,
          section: RecurringExpenseTaxOption.sectionTaxRate,
        ),
      ...rateTaxes,
      if (groupTaxes.isNotEmpty)
        const RecurringExpenseTaxOption(
          id: '__tax_group_header__',
          label: 'Tax Group',
          isHeader: true,
          section: RecurringExpenseTaxOption.sectionTaxGroup,
        ),
      ...groupTaxes,
    ];
    return filtered.any((item) => item.isSelectable) ? filtered : _taxCatalog;
  }

  List<String> get _taxOptions =>
      _visibleTaxCatalog.where((item) => item.isSelectable).isNotEmpty
      ? _visibleTaxCatalog
            .where((item) => item.isSelectable)
            .map((item) => item.displayLabel)
            .toList(growable: false)
      : _taxes;

  String? _lastLoggedTaxCatalogFingerprint;
  String? _lastLoggedTaxOptionsFingerprint;

  void _logTaxDebug(String stage, Object? value) {
    debugPrint('========== TAX DEBUG ==========');
    debugPrint('Stage: $stage');
    debugPrint('Value: $value');
    debugPrint('==============================');
  }

  void _logTaxCatalogSnapshot() {
    final entries = _taxCatalog
        .map(
          (item) =>
              'id=${item.id} tax_name=${item.label} displayLabel=${item.displayLabel} rate=${item.rate}',
        )
        .join(' || ');
    if (_lastLoggedTaxCatalogFingerprint == entries) {
      return;
    }
    _lastLoggedTaxCatalogFingerprint = entries;
    _logTaxDebug('_taxCatalog', entries.isEmpty ? '[]' : entries);
  }

  void _logTaxOptionsSnapshot() {
    final options = _taxOptions.join(' || ');
    if (_lastLoggedTaxOptionsFingerprint == options) {
      return;
    }
    _lastLoggedTaxOptionsFingerprint = options;
    _logTaxDebug('_taxOptions', options.isEmpty ? '[]' : options);
  }

  String? _resolveGstTreatmentLabel(String? value) {
    if (value == null || value.isEmpty) {
      return value;
    }
    for (final option in _gstTreatmentCatalog) {
      if (option.code == value || option.label == value) {
        return option.label;
      }
    }
    return value;
  }

  String? _resolveGstTreatmentCode(String? value) {
    if (value == null || value.isEmpty) {
      return value;
    }
    for (final option in _gstTreatmentCatalog) {
      if (option.code == value || option.label == value) {
        return option.code;
      }
    }
    return value;
  }

  String? _normalizeStateName(String? value) {
    if (value == null || value.isEmpty) {
      return value;
    }
    final bracketSeparatorIndex = value.indexOf('] - ');
    if (value.startsWith('[') && bracketSeparatorIndex != -1) {
      return value.substring(bracketSeparatorIndex + 4).trim();
    }
    return value;
  }

  String _defaultStateName() {
    for (final item in _stateCatalog) {
      if (item.code.toUpperCase() == 'KL') {
        return item.name;
      }
    }
    if (_stateCatalog.isNotEmpty) {
      return _stateCatalog.first.name;
    }
    return 'Kerala';
  }

  StateLookupModel? _selectedStateOption(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final normalized = _normalizeStateName(value)?.trim().toLowerCase();
    for (final option in _stateCatalog) {
      if (option.displayLabel.toLowerCase() == normalized ||
          option.name.toLowerCase() == normalized ||
          option.code.toLowerCase() == normalized) {
        return option;
      }
    }
    return null;
  }

  bool _isNonTaxableOption(RecurringExpenseTaxOption item) {
    final label = item.label.trim().toUpperCase();
    return label == 'NON-TAXABLE' || label == 'NON TAXABLE';
  }

  bool _isCgstTax(RecurringExpenseTaxOption item) {
    final taxType = item.taxType?.trim().toUpperCase();
    if (taxType == 'CGST') {
      return true;
    }
    final label = item.label.trim().toUpperCase();
    return label.contains('CGST');
  }

  bool _isSgstTax(RecurringExpenseTaxOption item) {
    final taxType = item.taxType?.trim().toUpperCase();
    if (taxType == 'SGST') {
      return true;
    }
    final label = item.label.trim().toUpperCase();
    return label.contains('SGST');
  }

  bool _isVisibleIntrastateTax(RecurringExpenseTaxOption item) {
    if (item.isTaxGroup) {
      return true;
    }
    if (!item.isTaxRate) {
      return true;
    }
    return false;
  }

  bool _isVisibleInterstateTax(RecurringExpenseTaxOption item) {
    if (item.isTaxGroup) {
      return false;
    }
    if (!item.isTaxRate) {
      return true;
    }
    return !_isCgstTax(item) && !_isSgstTax(item);
  }

  bool _isTaxVisibleForCurrentStates(RecurringExpenseTaxOption item) {
    final sourceState = _selectedStateOption(_sourceOfSupply);
    final destinationState = _selectedStateOption(_destinationOfSupply);
    if (sourceState == null || destinationState == null) {
      return true;
    }
    final isIntrastate =
        sourceState.code.trim().toUpperCase() ==
        destinationState.code.trim().toUpperCase();
    return isIntrastate
        ? _isVisibleIntrastateTax(item)
        : _isVisibleInterstateTax(item);
  }

  void _pruneHiddenTaxSelections() {
    final selectedTaxOption = _selectedTaxOption();
    if (selectedTaxOption != null &&
        !_isTaxVisibleForCurrentStates(selectedTaxOption)) {
      _selectedTax = null;
      _clearExemptionReason();
      _clearTaxAmountOverride();
      _hideTaxAmountEditor();
      _hideItcEditor();
    }
    for (final row in _itemizedRows) {
      final rowTaxOption = _findTaxByLabel(row.tax);
      if (rowTaxOption != null &&
          !_isTaxVisibleForCurrentStates(rowTaxOption)) {
        row.tax = null;
      }
    }
  }

  GstTreatmentLookupModel? _selectedGstTreatmentOption() {
    for (final option in _gstTreatmentCatalog) {
      if (option.code == _gstTreatment || option.label == _gstTreatment) {
        return option;
      }
    }
    return null;
  }

  ExpenseEmployeeOption? _selectedEmployeeOption(
    List<ExpenseEmployeeOption> employees,
  ) {
    final selectedEmployeeId = _selectedEmployee?.trim();
    if (selectedEmployeeId == null || selectedEmployeeId.isEmpty) {
      return null;
    }
    for (final employee in employees) {
      if (employee.id == selectedEmployeeId) {
        return employee;
      }
    }
    return null;
  }

  GstTreatmentLookupModel? _findMatchingGstTreatmentOption(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final resolvedLabel = _resolveGstTreatmentLabel(
      value,
    )?.trim().toLowerCase();
    final trimmedValue = value.trim().toLowerCase();
    for (final option in _gstTreatmentCatalog) {
      if (option.code.trim().toLowerCase() == trimmedValue ||
          option.label.trim().toLowerCase() == trimmedValue ||
          option.label.trim().toLowerCase() == resolvedLabel) {
        return option;
      }
    }
    return null;
  }

  void _applyGstTreatmentSelection(GstTreatmentLookupModel? value) {
    _gstTreatment = value?.label;
    _destinationOfSupply = value?.label == 'Registered Business - Regular'
        ? ''
        : _defaultStateName();
    if (!_showSourceOfSupply) {
      _sourceOfSupply = '';
    } else if (_sourceOfSupply.trim().isEmpty) {
      _sourceOfSupply = _defaultStateName();
    }
    if (!_showReverseCharge) {
      _reverseCharge = false;
    }
    if (!_showTax) {
      _selectedTax = null;
      _clearExemptionReason();
      _clearTaxAmountOverride();
      _hideTaxAmountEditor();
      _hideItcEditor();
    }
    if (_taxFieldReadOnly) {
      _hideTaxAmountEditor();
      _hideItcEditor();
    }
    if (_showReverseCharge && _reverseCharge) {
      _amountIs = 'Tax Exclusive';
    }
  }

  void _applySourceOfSupplySelection(StateLookupModel? value) {
    _sourceOfSupply = value?.name ?? '';
    _pruneHiddenTaxSelections();
  }

  void _applyVendorLinkedDropdownSelections({
    String? gstTreatment,
    String? sourceOfSupply,
  }) {
    final matchingGstTreatment = _findMatchingGstTreatmentOption(gstTreatment);
    if (matchingGstTreatment != null) {
      _applyGstTreatmentSelection(matchingGstTreatment);
    }
    final matchingSourceOfSupply = _selectedStateOption(sourceOfSupply);
    if (matchingSourceOfSupply != null && _showSourceOfSupply) {
      _applySourceOfSupplySelection(matchingSourceOfSupply);
    }
  }

  String? _optionalInvoiceNumber() {
    final trimmed = _invoiceController.text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool _isUuid(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return false;
    }
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[89abAB][0-9a-fA-F]{3}-'
      r'[0-9a-fA-F]{12}$',
    ).hasMatch(trimmed);
  }

  VendorLookupModel? _findVendorCatalogMatch(
    String? identifier, {
    List<VendorLookupModel>? catalog,
    String? displayName,
    String? companyName,
  }) {
    final trimmedIdentifier = identifier?.trim();
    final trimmedDisplayName = displayName?.trim();
    final trimmedCompanyName = companyName?.trim();
    final candidates = catalog ?? _vendorCatalog;
    for (final vendor in candidates) {
      if (trimmedIdentifier != null &&
          trimmedIdentifier.isNotEmpty &&
          (vendor.id == trimmedIdentifier ||
              vendor.vendorNumber == trimmedIdentifier)) {
        return vendor;
      }
      if (trimmedDisplayName != null &&
          trimmedDisplayName.isNotEmpty &&
          vendor.displayName == trimmedDisplayName) {
        return vendor;
      }
      if (trimmedCompanyName != null &&
          trimmedCompanyName.isNotEmpty &&
          vendor.companyName == trimmedCompanyName) {
        return vendor;
      }
    }
    return null;
  }

  String? _resolveSelectedVendorId(RecurringExpenseVendorOption? value) {
    if (value == null) {
      return null;
    }
    final matchedVendor = _findVendorCatalogMatch(
      value.id,
      displayName: value.displayName,
      companyName: value.companyName,
    );
    if (matchedVendor != null) {
      return matchedVendor.id;
    }
    return _isUuid(value.id) ? value.id : null;
  }

  Future<String?> _normalizedVendorUuid() async {
    final trimmed = _selectedVendorId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final selectedItem = _selectedVendorItem;
    final matchedFromCurrentCatalog = _findVendorCatalogMatch(
      trimmed,
      displayName: selectedItem?.name ?? _editingExpense?.vendorName,
      companyName: selectedItem?.extraSubtitle,
    );
    if (matchedFromCurrentCatalog != null) {
      return matchedFromCurrentCatalog.id;
    }

    try {
      final vendorNotifier = ref.read(vendorProvider.notifier);
      final vendorState = ref.read(vendorProvider);
      if (vendorState.vendors.isEmpty && !vendorState.isLoading) {
        await vendorNotifier.loadVendors();
      }
      final loadedCatalog = ref
          .read(vendorProvider)
          .vendors
          .map(VendorLookupModel.fromVendor)
          .toList(growable: false);
      final matched = _findVendorCatalogMatch(
        trimmed,
        catalog: loadedCatalog,
        displayName: selectedItem?.name ?? _editingExpense?.vendorName,
        companyName: selectedItem?.extraSubtitle,
      );
      if (matched != null) {
        return matched.id;
      }
    } catch (_) {
      return _isUuid(trimmed) ? trimmed : null;
    }
    return _isUuid(trimmed) ? trimmed : null;
  }

  Widget _buildRecurringStyleGstTreatmentDropdown({
    required ValueChanged<GstTreatmentLookupModel?> onChanged,
  }) {
    final gstTreatmentsAsync = ref.watch(expensesGstTreatmentsProvider);
    final gstTreatmentOptions = _gstTreatmentCatalog;
    final selectedOption = _selectedGstTreatmentOption();

    return FormDropdown<GstTreatmentLookupModel>(
      height: kRecurringExpenseCompactFieldHeight,
      value: selectedOption,
      items: gstTreatmentOptions,
      hint: gstTreatmentsAsync.isLoading
          ? 'Loading GST Treatments...'
          : gstTreatmentOptions.isEmpty
          ? 'No GST Treatments Found'
          : 'Select treatment',
      menuMaxHeight: kRecurringExpenseGstMenuMaxHeight,
      itemHeight: kRecurringExpenseGstOptionHeight,
      isLoading: gstTreatmentsAsync.isLoading,
      displayStringForValue: (item) => item.label,
      textStyle: selectedOption == null ? null : AppTextStyles.input,
      itemBuilder: (item, isSelected, isHovered) {
        return buildRecurringExpenseGstOptionRow(
          item: item.label,
          isSelected: isSelected,
          isHovered: isHovered,
          height: kRecurringExpenseGstOptionContentHeight,
          useStandardDropdownTypography: true,
        );
      },
      onChanged: onChanged,
    );
  }

  bool get _showSourceOfSupply {
    return switch (_resolveGstTreatmentLabel(_gstTreatment)) {
      'Out Of Scope' || 'Overseas' => false,
      _ => true,
    };
  }

  bool get _showVendorGstin {
    return switch (_resolveGstTreatmentLabel(_gstTreatment)) {
      'Registered Business - Regular' ||
      'Registered Business - Composition' ||
      'Deemed Export' ||
      'Overseas' ||
      'Special Economic Zone' ||
      'SEZ Developer' ||
      'Tax Deductor' => true,
      _ => false,
    };
  }

  bool get _vendorGstinRequired {
    return _showVendorGstin &&
        _resolveGstTreatmentLabel(_gstTreatment) != 'Overseas';
  }

  bool get _showDestinationOfSupply {
    return _resolveGstTreatmentLabel(_gstTreatment) != 'Out Of Scope';
  }

  bool get _showReverseCharge {
    return switch (_resolveGstTreatmentLabel(_gstTreatment)) {
      null ||
      'Registered Business - Regular' ||
      'Unregistered Business' ||
      'Consumer' ||
      'Overseas' ||
      'Special Economic Zone' ||
      'SEZ Developer' ||
      'Tax Deductor' ||
      'Input Service Distributor' => true,
      _ => false,
    };
  }

  bool get _showTax {
    return switch (_resolveGstTreatmentLabel(_gstTreatment)) {
      null ||
      'Registered Business - Regular' ||
      'Unregistered Business' ||
      'Consumer' ||
      'Overseas' ||
      'Special Economic Zone' ||
      'Deemed Export' ||
      'Tax Deductor' ||
      'SEZ Developer' ||
      'Input Service Distributor' => true,
      _ => false,
    };
  }

  bool get _taxRequired {
    return switch (_resolveGstTreatmentLabel(_gstTreatment)) {
      'Registered Business - Regular' ||
      'Special Economic Zone' ||
      'Deemed Export' ||
      'Tax Deductor' ||
      'SEZ Developer' => true,
      _ => false,
    };
  }

  bool get _itemizedTaxEditable => _showTax;

  bool get _taxFieldReadOnly {
    return switch (_resolveGstTreatmentLabel(_gstTreatment)) {
      'Unregistered Business' || 'Unregistered' => true,
      _ => false,
    };
  }

  bool get _showAmountIs {
    return switch (_resolveGstTreatmentLabel(_gstTreatment)) {
      null ||
      'Registered Business - Regular' ||
      'Unregistered Business' ||
      'Consumer' ||
      'Overseas' ||
      'Special Economic Zone' ||
      'Deemed Export' ||
      'Tax Deductor' ||
      'SEZ Developer' ||
      'Input Service Distributor' => true,
      _ => false,
    };
  }

  RecurringExpenseVendorOption? get _selectedVendorOption {
    final selectedId = _selectedVendorId?.trim();
    if (selectedId != null && selectedId.isNotEmpty) {
      for (final option in _vendorOptions) {
        if (option.id == selectedId) {
          return option;
        }
      }

      final matchedVendor = _findVendorCatalogMatch(
        selectedId,
        displayName: _selectedVendorItem?.name ?? _editingExpense?.vendorName,
        companyName: _selectedVendorItem?.extraSubtitle,
      );
      if (matchedVendor != null) {
        return matchedVendor;
      }

      final fallbackVendorName = _editingExpense?.vendorName.trim();
      if (_isUuid(selectedId) &&
          fallbackVendorName != null &&
          fallbackVendorName.isNotEmpty) {
        return VendorLookupModel(
          id: selectedId,
          displayName: fallbackVendorName,
          companyName: fallbackVendorName,
        );
      }
    }
    final selected = _selectedVendorItem;
    if (selected == null) return null;
    return _toVendorOption(selected);
  }

  RecurringExpenseCustomerOption? get _selectedCustomerOption {
    final selectedId = _selectedCustomerId;
    if (selectedId != null && selectedId.isNotEmpty) {
      for (final option in _customerCatalog) {
        if (option.id == selectedId) {
          return option;
        }
      }
    }
    final selected = _selectedCustomer;
    if (selected == null || selected.isEmpty) return null;
    return RecurringExpenseCustomerOption(
      id: (selectedId != null && selectedId.isNotEmpty) ? selectedId : selected,
      displayName: selected,
      firstName: selected,
    );
  }

  static const List<String> _taxes = [
    'GST 5%',
    'GST 12%',
    'GST 18%',
    'GST 28%',
  ];
  static const List<String> _currencies = ['INR', 'USD', 'EUR'];
  static const List<String> _languages = [
    'English',
    'Hindi',
    'Spanish',
    'French',
  ];
  static const List<String> _phoneCodes = ['+91', '+1', '+44', '+971'];
  static const List<String> _gstTreatmentsList = [
    'Select a GST treatment',
    'Registered Business',
    'Unregistered Business',
    'Consumer',
    'Overseas',
    'Special Economic Zone',
    'SEZ Developer',
    'Deemed Export',
  ];
  static const List<String> _placesOfSupply = [
    'Select place of supply',
    '[KL] - Kerala',
    '[TN] - Tamil Nadu',
    '[KA] - Karnataka',
  ];
  static const List<String> _currenciesList = [
    'INR- Indian Rupee',
    'USD- United States Dollar',
    'EUR- Euro',
  ];
  static const List<String> _paymentTermsList = [
    'Due on Receipt',
    'Net 15',
    'Net 30',
    'Net 45',
    'Net 60',
    'Net 360',
  ];
  static const List<String> _priceLists = [
    'Select a price list',
    'Standard Price List',
    'Wholesale Price List',
  ];

  // ── New Customer dialog fields state ──────────────────────────────────────
  String _custType = 'Individual';
  String _custSalutation = 'Salutation';
  final TextEditingController _custFirstNameController =
      TextEditingController();
  final TextEditingController _custLastNameController = TextEditingController();
  final TextEditingController _custCompanyNameController =
      TextEditingController();
  final TextEditingController _custDisplayNameController =
      TextEditingController();
  final TextEditingController _custEmailController = TextEditingController();
  final TextEditingController _custNumberController = TextEditingController(
    text: 'CUS-00023',
  );
  String _custWorkPhoneCode = '+91';
  final TextEditingController _custWorkPhoneController =
      TextEditingController();
  String _custMobilePhoneCode = '+91';
  final TextEditingController _custMobilePhoneController =
      TextEditingController();
  String _custLanguage = 'English';

  String _custActiveTab = 'Other Details';

  // Other Details
  String _custGstTreatment = 'Select a GST treatment';
  String _custPlaceOfSupply = 'Select place of supply';
  final TextEditingController _custPanController = TextEditingController();
  String _custTaxPreference = 'Taxable';
  String _custCurrency = 'INR- Indian Rupee';
  final TextEditingController _custCreditLimitController =
      TextEditingController();
  String _custPaymentTerms = 'Net 360';
  String _custPriceList = 'Select a price list';
  bool _custEnablePortal = false;
  List<String> _custUploadedFiles = [];
  final TextEditingController _custDemoFieldController =
      TextEditingController();
  final TextEditingController _custRemarksController = TextEditingController();
  String _custAdgf = 'None';
  String _custSchedule = 'None';
  String _custDemoAdvanced = 'None';

  // Billing Address
  final TextEditingController _custBillAttention = TextEditingController();
  String? _custBillCountry;
  final TextEditingController _custBillStreet1 = TextEditingController();
  final TextEditingController _custBillStreet2 = TextEditingController();
  final TextEditingController _custBillCity = TextEditingController();
  String? _custBillState;
  final TextEditingController _custBillPinCode = TextEditingController();
  final TextEditingController _custBillPhone = TextEditingController();
  final TextEditingController _custBillFax = TextEditingController();

  // Shipping Address
  final TextEditingController _custShipAttention = TextEditingController();
  String? _custShipCountry;
  final TextEditingController _custShipStreet1 = TextEditingController();
  final TextEditingController _custShipStreet2 = TextEditingController();
  final TextEditingController _custShipCity = TextEditingController();
  String? _custShipState;
  final TextEditingController _custShipPinCode = TextEditingController();
  final TextEditingController _custShipPhone = TextEditingController();
  final TextEditingController _custShipFax = TextEditingController();

  // ── New Vendor dialog fields state ────────────────────────────────────────
  String _vendSalutation = 'Salutation';
  final TextEditingController _vendFirstNameController =
      TextEditingController();
  final TextEditingController _vendLastNameController = TextEditingController();
  final TextEditingController _vendCompanyNameController =
      TextEditingController();
  final TextEditingController _vendDisplayNameController =
      TextEditingController();
  final TextEditingController _vendEmailController = TextEditingController();
  final TextEditingController _vendNumberController = TextEditingController(
    text: 'VEN-02',
  );
  String _vendWorkPhoneCode = '+91';
  final TextEditingController _vendWorkPhoneController =
      TextEditingController();
  String _vendMobilePhoneCode = '+91';
  final TextEditingController _vendMobilePhoneController =
      TextEditingController();
  String _vendLanguage = 'English';

  String _vendActiveTab = 'Other Details';

  // Other Details
  String _vendGstTreatment = 'Select a GST treatment';
  String _vendSourceOfSupply = 'Select source of supply';
  final TextEditingController _vendPanController = TextEditingController();
  bool _vendMsmeRegistered = false;
  String _vendCurrency = 'INR- Indian Rupee';
  String _vendPaymentTerms = 'Net 360';
  String? _vendTds;
  String _vendPriceList = 'Select a price list';
  bool _vendEnablePortal = false;
  List<String> _vendUploadedFiles = [];
  final TextEditingController _vendDemoFieldController =
      TextEditingController();
  final TextEditingController _vendRemarksController = TextEditingController();
  String _vendAdgf = 'None';
  String _vendSchedule = 'None';
  String _vendDemoAdvanced = 'None';

  // Billing Address
  final TextEditingController _vendBillAttention = TextEditingController();
  String? _vendBillCountry;
  final TextEditingController _vendBillStreet1 = TextEditingController();
  final TextEditingController _vendBillStreet2 = TextEditingController();
  final TextEditingController _vendBillCity = TextEditingController();
  String? _vendBillState;
  final TextEditingController _vendBillPinCode = TextEditingController();
  final TextEditingController _vendBillPhone = TextEditingController();
  final TextEditingController _vendBillFax = TextEditingController();

  // Shipping Address
  final TextEditingController _vendShipAttention = TextEditingController();
  String? _vendShipCountry;
  final TextEditingController _vendShipStreet1 = TextEditingController();
  final TextEditingController _vendShipStreet2 = TextEditingController();
  final TextEditingController _vendShipCity = TextEditingController();
  String? _vendShipState;
  final TextEditingController _vendShipPinCode = TextEditingController();
  final TextEditingController _vendShipPhone = TextEditingController();
  final TextEditingController _vendShipFax = TextEditingController();

  List<ExpenseAccountLookupModel> _flattenExpenseAccounts(
    Iterable<ExpenseAccountLookupModel> accounts,
  ) {
    final flattened = <ExpenseAccountLookupModel>[];
    for (final account in accounts) {
      if (account.displayName.trim().isNotEmpty) {
        flattened.add(account);
      }
      if (account.children.isNotEmpty) {
        flattened.addAll(_flattenExpenseAccounts(account.children));
      }
    }
    return flattened;
  }

  ExpenseAccountLookupModel? _findExpenseAccountByLabel(String? label) {
    if (label == null || label.trim().isEmpty) {
      return null;
    }
    for (final account in _flattenedExpenseAccounts) {
      if (account.displayName == label) {
        return account;
      }
    }
    return null;
  }

  ExpenseAccountLookupModel? _findExpenseAccountById(String? id) {
    if (id == null || id.trim().isEmpty) {
      return null;
    }
    for (final account in _flattenedExpenseAccounts) {
      if (account.id == id) {
        return account;
      }
    }
    return null;
  }

  VendorLookupModel? _findVendorById(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    return _findVendorCatalogMatch(id);
  }

  RecurringExpenseCustomerOption? _findCustomerById(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final item in _customerCatalog) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  RecurringExpenseTaxOption? _findTaxByLabel(String? label) {
    _logTaxDebug('_findTaxByLabel incoming label', label);
    if (label == null || label.trim().isEmpty) {
      _logTaxDebug('_findTaxByLabel matched tax object', 'null');
      return null;
    }
    for (final item in _taxCatalog) {
      if (!item.isSelectable) {
        continue;
      }
      if (item.id == label ||
          item.displayLabel == label ||
          item.label == label) {
        _logTaxDebug(
          '_findTaxByLabel matched tax object',
          'id=${item.id} label=${item.label} displayLabel=${item.displayLabel} rate=${item.rate}',
        );
        return item;
      }
    }
    _logTaxDebug('_findTaxByLabel matched tax object', 'null');
    return null;
  }

  RecurringExpenseTaxOption? _selectedTaxOption() {
    return _findTaxByLabel(_selectedTax);
  }

  bool get _showExemptionReasonField =>
      _selectedTaxOption() != null &&
      _isNonTaxableOption(_selectedTaxOption()!) &&
      !_isItemized;

  bool get _showTaxSummarySections =>
      _selectedTaxOption() != null &&
      !_isNonTaxableOption(_selectedTaxOption()!);

  void _clearExemptionReason() {
    _exemptionReasonController.clear();
    _exemptionReasonErrorText = null;
  }

  bool _validateExemptionReasonIfNeeded() {
    if (!_showExemptionReasonField) {
      return true;
    }
    final hasValue = _exemptionReasonController.text.trim().isNotEmpty;
    setState(() {
      _exemptionReasonErrorText = hasValue
          ? null
          : 'Exemption Reason is required';
    });
    return hasValue;
  }

  double? _resolvedMarkupByValue() {
    if (_selectedCustomerId == null || !_isCustomerBillable) {
      return null;
    }
    final raw = _markupByController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw);
  }

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  String? _normalizedTaxId(RecurringExpenseTaxOption? option) {
    _logTaxDebug(
      '_normalizedTaxId incoming object',
      option == null
          ? 'null'
          : 'id=${option.id} label=${option.label} displayLabel=${option.displayLabel} rate=${option.rate}',
    );
    final raw = option?.id.trim();
    if (raw == null || raw.isEmpty) {
      _logTaxDebug('_normalizedTaxId outgoing UUID', 'null');
      return null;
    }
    final normalized = _uuidPattern.hasMatch(raw) ? raw : null;
    _logTaxDebug('_normalizedTaxId outgoing UUID', normalized);
    return normalized;
  }

  double _calculateDisplayedTaxAmountFromValue(String rawAmount) {
    final double amount = double.tryParse(rawAmount.trim()) ?? 0.0;
    final RecurringExpenseTaxOption? selectedTax = _selectedTaxOption();
    final double rate = selectedTax?.rate ?? 0.0;
    if (amount <= 0 || rate <= 0) {
      return 0.0;
    }
    if (_amountIs == 'Tax Inclusive') {
      return amount * rate / (100 + rate);
    }
    return amount * rate / 100;
  }

  double _resolvedDisplayedTaxAmount(String amountText) {
    final selectedTaxOption = _selectedTaxOption();
    final amountKey = amountText.trim();
    if (_taxAmountOverride != null &&
        _taxAmountOverrideTaxId == selectedTaxOption?.id &&
        _taxAmountOverrideAmountText == amountKey) {
      return _taxAmountOverride!;
    }
    return _calculateDisplayedTaxAmountFromValue(amountText);
  }

  void _clearTaxAmountOverride() {
    _taxAmountOverride = null;
    _taxAmountOverrideTaxId = null;
    _taxAmountOverrideAmountText = null;
  }

  void _hideTaxAmountEditor() {
    _taxAmountOverlayEntry?.remove();
    _taxAmountOverlayEntry = null;
  }

  void _hideItcEditor() {
    _itcOverlayEntry?.remove();
    _itcOverlayEntry = null;
  }

  void _showTaxAmountEditor({required String amountText}) {
    final selectedTaxOption = _selectedTaxOption();
    if (selectedTaxOption == null) {
      return;
    }
    _hideItcEditor();
    if (_taxAmountOverlayEntry != null) {
      _hideTaxAmountEditor();
      return;
    }

    final overlay = Overlay.of(context);
    final controller = TextEditingController(
      text: _resolvedDisplayedTaxAmount(amountText).toStringAsFixed(2),
    );
    final amountSnapshot = amountText.trim();
    final taxIdSnapshot = selectedTaxOption.id;
    final popoverShadow = AppTheme.textPrimary.withValues(alpha: 0.12);
    final anchorContext = _taxAmountAnchorKey.currentContext;
    final anchorBox = anchorContext?.findRenderObject() as RenderBox?;
    final anchorOffset = anchorBox?.localToGlobal(Offset.zero);
    final anchorHeight = anchorBox?.size.height ?? 0;
    const popupHeight = 164.0;
    final viewportHeight = MediaQuery.of(context).size.height;
    final showAbove =
        anchorOffset != null &&
        anchorOffset.dy + anchorHeight + popupHeight + 16 > viewportHeight &&
        anchorOffset.dy > popupHeight;

    void closeEditor() {
      _hideTaxAmountEditor();
      controller.dispose();
    }

    _taxAmountOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: closeEditor,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _taxAmountLayerLink,
              showWhenUnlinked: false,
              targetAnchor: showAbove
                  ? Alignment.topRight
                  : Alignment.bottomRight,
              followerAnchor: showAbove
                  ? Alignment.bottomRight
                  : Alignment.topRight,
              offset: showAbove ? const Offset(0, -12) : const Offset(0, 12),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: 332,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: 12,
                        top: showAbove ? null : 0,
                        bottom: showAbove ? 0 : null,
                        child: Transform.rotate(
                          angle: showAbove ? math.pi : 0,
                          child: CustomPaint(
                            size: const Size(18, 10),
                            painter: _ItemizedHsnSacPopoverArrowPainter(
                              fillColor: AppTheme.backgroundColor,
                              borderColor: AppTheme.borderLight,
                              shadowColor: popoverShadow,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: showAbove
                            ? const EdgeInsets.only(bottom: 8)
                            : const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: popoverShadow,
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                color: AppTheme.bgLight,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Update Taxes Amount (in INR)',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: closeEditor,
                                    child: const Icon(
                                      LucideIcons.x,
                                      size: 16,
                                      color: AppTheme.errorRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                16,
                                14,
                                16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedTaxOption.displayLabel,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 140,
                                    height: _expenseCreateCompactFieldHeight,
                                    child: CustomTextField(
                                      controller: controller,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      hintText: '',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                color: AppTheme.bgLight,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                12,
                              ),
                              child: Center(
                                child: ZButton.primary(
                                  label: 'Update',
                                  onPressed: () {
                                    final parsed = double.tryParse(
                                      controller.text.trim(),
                                    );
                                    closeEditor();
                                    if (!mounted) {
                                      return;
                                    }
                                    setState(() {
                                      _taxAmountOverride = parsed ?? 0.0;
                                      _taxAmountOverrideTaxId = taxIdSnapshot;
                                      _taxAmountOverrideAmountText =
                                          amountSnapshot;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_taxAmountOverlayEntry!);
  }

  void _showItcEditor() {
    final selectedTaxOption = _selectedTaxOption();
    if (selectedTaxOption == null) {
      return;
    }
    _hideTaxAmountEditor();
    if (_itcOverlayEntry != null) {
      _hideItcEditor();
      return;
    }

    final overlay = Overlay.of(context);
    String currentSelection = _selectedItcStatus;
    final popoverShadow = AppTheme.textPrimary.withValues(alpha: 0.12);
    final anchorContext = _itcAnchorKey.currentContext;
    final anchorBox = anchorContext?.findRenderObject() as RenderBox?;
    final anchorOffset = anchorBox?.localToGlobal(Offset.zero);
    final anchorHeight = anchorBox?.size.height ?? 0;
    const popupHeight = 206.0;
    final viewportHeight = MediaQuery.of(context).size.height;
    final showAbove =
        anchorOffset != null &&
        anchorOffset.dy + anchorHeight + popupHeight + 16 > viewportHeight &&
        anchorOffset.dy > popupHeight;

    void closeEditor() {
      _hideItcEditor();
    }

    _itcOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: closeEditor,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _itcLayerLink,
              showWhenUnlinked: false,
              targetAnchor: showAbove
                  ? Alignment.topLeft
                  : Alignment.bottomLeft,
              followerAnchor: showAbove
                  ? Alignment.bottomLeft
                  : Alignment.topLeft,
              offset: showAbove ? const Offset(0, -12) : const Offset(0, 12),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: 296,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 12,
                        top: showAbove ? null : 0,
                        bottom: showAbove ? 0 : null,
                        child: Transform.rotate(
                          angle: showAbove ? math.pi : 0,
                          child: CustomPaint(
                            size: const Size(18, 10),
                            painter: _ItemizedHsnSacPopoverArrowPainter(
                              fillColor: AppTheme.backgroundColor,
                              borderColor: AppTheme.borderLight,
                              shadowColor: popoverShadow,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: showAbove
                            ? const EdgeInsets.only(bottom: 8)
                            : const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: popoverShadow,
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                color: AppTheme.bgLight,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Input Tax Credit',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: closeEditor,
                                    child: const Icon(
                                      LucideIcons.x,
                                      size: 16,
                                      color: AppTheme.errorRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ZerpaiRadioGroup<String>(
                                    options: _itcOptions,
                                    current: currentSelection,
                                    orientation: Axis.vertical,
                                    onChanged: (value) {
                                      currentSelection = value;
                                      _itcOverlayEntry?.markNeedsBuild();
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  ZButton.primary(
                                    label: 'OK',
                                    onPressed: () {
                                      closeEditor();
                                      if (!mounted) {
                                        return;
                                      }
                                      setState(() {
                                        _selectedItcStatus = currentSelection;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_itcOverlayEntry!);
  }

  Widget _buildRecurringStyledTaxDropdown({required String amountText}) {
    final selectedTaxOption = _selectedTaxOption();
    final displayedTaxAmount = _resolvedDisplayedTaxAmount(
      amountText,
    ).toStringAsFixed(2);
    Widget buildSummaryRow({
      required String text,
      bool editable = false,
      VoidCallback? onTap,
      LayerLink? layerLink,
      GlobalKey? anchorKey,
      EdgeInsetsGeometry padding = EdgeInsets.zero,
    }) {
      final summaryLink = layerLink ?? _taxAmountLayerLink;
      final summaryKey = anchorKey ?? _taxAmountAnchorKey;
      final summaryTap =
          onTap ?? (() => _showTaxAmountEditor(amountText: amountText));
      return Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            if (editable)
              CompositedTransformTarget(
                link: summaryLink,
                child: InkWell(
                  key: summaryKey,
                  onTap: summaryTap,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      LucideIcons.pencil,
                      size: 12,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              )
            else
              const Icon(
                LucideIcons.pencil,
                size: 12,
                color: AppTheme.primaryBlue,
              ),
          ],
        ),
      );
    }

    final taxField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormDropdown<RecurringExpenseTaxOption>(
          height: _expenseCreateCompactFieldHeight,
          value: selectedTaxOption,
          items: _visibleTaxCatalog,
          hint: 'Select a Tax',
          enabled: !_taxFieldReadOnly,
          fillColor: _taxFieldReadOnly ? AppTheme.bgDisabled : null,
          allowClear: true,
          showArrowOnSelection: true,
          showSearch: true,
          isItemEnabled: (item) => item.isSelectable,
          displayStringForValue: (item) => item.displayLabel,
          searchStringForValue: (item) => item.searchLabel,
          textStyle: _taxFieldReadOnly
              ? AppTextStyles.input.copyWith(color: AppTheme.textMuted)
              : null,
          itemHeight: 56.0,
          onChanged: (val) => setState(() {
            _selectedTax = val?.id;
            if (val != null && _isNonTaxableOption(val)) {
              _exemptionReasonErrorText = null;
              _hideTaxAmountEditor();
              _hideItcEditor();
            } else {
              _clearExemptionReason();
            }
            _clearTaxAmountOverride();
            _logTaxDebug(
              'header tax selected in dropdown',
              val == null
                  ? 'selected display label=null selected id=null'
                  : 'selected display label=${val.displayLabel} selected id=${val.id} selected rate=${val.rate}',
            );
          }),
          itemBuilder: (item, isSelected, isHovered) {
            if (item.isHeader) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                  ),
                ),
              );
            }
            final Color backgroundColor = isHovered
                ? const Color(0xFF3B82F6)
                : (isSelected ? const Color(0xFFF3F4F6) : Colors.white);
            final Color primaryTextColor = isHovered
                ? Colors.white
                : AppTheme.textPrimary;
            final Color secondaryTextColor = isHovered
                ? Colors.white.withValues(alpha: 0.85)
                : AppTheme.textSecondary;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.displayLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: primaryTextColor,
                    ),
                  ),
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        if (_showTaxSummarySections) ...[
          const SizedBox(height: 8),
          buildSummaryRow(
            text: 'Tax Amount = $displayedTaxAmount INR',
            editable: true,
          ),
          const SizedBox(height: 4),
          buildSummaryRow(
            text: _selectedItcStatus,
            editable: true,
            onTap: _showItcEditor,
            layerLink: _itcLayerLink,
            anchorKey: _itcAnchorKey,
          ),
        ],
      ],
    );
    return MouseRegion(
      cursor: _taxFieldReadOnly
          ? SystemMouseCursors.forbidden
          : MouseCursor.defer,
      child: Focus(
        canRequestFocus: !_taxFieldReadOnly,
        descendantsAreFocusable: !_taxFieldReadOnly,
        child: AbsorbPointer(absorbing: _taxFieldReadOnly, child: taxField),
      ),
    );
  }

  String? _findTaxLabelById(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final item in _taxCatalog) {
      if (item.id == id) {
        return item.displayLabel;
      }
    }
    return null;
  }

  StateLookupModel? _findStateByLabel(String? label) {
    if (label == null || label.trim().isEmpty) {
      return null;
    }
    for (final item in _stateCatalog) {
      if (item.displayLabel == label ||
          item.name == label ||
          item.code == label) {
        return item;
      }
    }
    return null;
  }

  String _formatApiDate(DateTime value) {
    return value.toIso8601String().split('T').first;
  }

  DateTime? _parseApiDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  double _selectedTaxRate(String? selectedTax) {
    return _findTaxByLabel(selectedTax)?.rate ?? 0;
  }

  double _computeTaxAmount({
    required double amount,
    required double rate,
    required bool inclusive,
  }) {
    if (amount <= 0 || rate <= 0) {
      return 0;
    }
    if (inclusive) {
      return amount - (amount / (1 + (rate / 100)));
    }
    return amount * (rate / 100);
  }

  Future<void> _loadEditExpense(String expenseId) async {
    if (mounted) {
      setState(() {
        _isLoadingEditExpense = true;
      });
    }
    try {
      final expense = await ref.read(expenseDetailsProvider(expenseId).future);
      if (!mounted) {
        return;
      }
      if (expense == null) {
        ErrorHandler.showErrorSnackBar(context, 'Expense not found.');
        context.pop();
        return;
      }
      _hydrateExpense(expense);
    } catch (error) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Failed to load expense: ${ErrorHandler.getFriendlyMessage(error)}',
        );
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEditExpense = false;
        });
      }
    }
  }

  Future<void> _loadRecurringExpensePrefill(String recurringId) async {
    if (mounted) {
      setState(() {
        _isLoadingEditExpense = true;
      });
    }
    try {
      final recurring = await ref.read(
        recurringExpenseDetailsProvider(recurringId).future,
      );
      if (!mounted) {
        return;
      }
      if (recurring == null) {
        ErrorHandler.showErrorSnackBar(context, 'Recurring expense not found.');
        context.pop();
        return;
      }
      _hydrateRecurringExpense(recurring);
    } catch (error) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Failed to load recurring expense: ${ErrorHandler.getFriendlyMessage(error)}',
        );
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEditExpense = false;
        });
      }
    }
  }

  Future<void> _loadCloneExpensePrefill(String expenseId) async {
    if (mounted) {
      setState(() {
        _isLoadingEditExpense = true;
      });
    }
    try {
      final expense = await ref.read(expenseDetailsProvider(expenseId).future);
      if (!mounted) {
        return;
      }
      if (expense == null) {
        ErrorHandler.showErrorSnackBar(context, 'Expense not found.');
        context.pop();
        return;
      }
      _hydrateExpense(expense, isClonePrefill: true);
    } catch (error) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Failed to load expense: ${ErrorHandler.getFriendlyMessage(error)}',
        );
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEditExpense = false;
        });
      }
    }
  }

  void _hydrateExpense(ExpenseRecord expense, {bool isClonePrefill = false}) {
    for (final row in _itemizedRows) {
      row.dispose();
    }
    _itemizedRows.clear();
    if (expense.items.isNotEmpty) {
      for (final item in expense.items) {
        _itemizedRows.add(
          ExpenseItemRow(
            expenseAccountId: item.expenseAccountId,
            notesController: TextEditingController(text: item.notes ?? ''),
            tax: _findTaxLabelById(item.taxId),
            amountController: TextEditingController(
              text: item.amount == 0 ? '' : item.amount.toStringAsFixed(2),
            ),
            expenseType: expense.expenseType == 'GOODS' ? 'Goods' : 'Services',
          ),
        );
      }
    } else {
      _itemizedRows.add(
        _newItemizedRow(
          expenseType: expense.expenseType == 'GOODS' ? 'Goods' : 'Services',
        ),
      );
    }

    final expenseDate = _parseApiDate(expense.date);
    final mileage = expense.mileage;
    final vendor = _findVendorById(expense.vendorId);
    final customer = _findCustomerById(expense.customerId);
    final stateLabel = _findStateByLabel(
      expense.destinationOfSupply,
    )?.displayLabel;
    final taxLabel = _findTaxLabelById(expense.taxId);

    setState(() {
      _itemizedTaxOverrides = {};
      _hideTaxAmountEditor();
      _editingExpense = isClonePrefill ? null : expense;
      _prefillRecurringExpenseId = isClonePrefill
          ? null
          : expense.recurringExpenseId.isNotEmpty
          ? expense.recurringExpenseId
          : null;
      _selectedDate = expenseDate ?? _selectedDate;
      _activeTab = expense.expenseMode == 'RECORD_MILEAGE' ? 1 : 0;
      _selectedCategory = expense.expenseAccount;
      _selectedCategoryAccountId = expense.expenseAccountId;
      _selectedPaidThroughAccountId = expense.paidThroughAccountId;
      _currency = expense.currencyCode.isNotEmpty
          ? expense.currencyCode
          : _currency;
      _amountController.text = expense.amount == 0
          ? ''
          : expense.amount.toStringAsFixed(2);
      _expenseType = expense.expenseType == 'GOODS' ? 'Goods' : 'Services';
      _sacController.text = expense.hsnSacCode;
      _selectedVendorId = expense.vendorId.isNotEmpty
          ? expense.vendorId
          : vendor?.id;
      _selectedVendorItem = null;
      _gstTreatment = _resolveGstTreatmentLabel(expense.gstTreatment);
      _vendorGstinController.clear();
      _sourceOfSupply = expense.sourceOfSupply.isNotEmpty
          ? _normalizeStateName(expense.sourceOfSupply) ??
                expense.sourceOfSupply
          : _sourceOfSupply;
      _destinationOfSupply =
          stateLabel ??
          _normalizeStateName(expense.destinationOfSupply) ??
          expense.destinationOfSupply;
      _reverseCharge = expense.reverseCharge;
      _selectedTax = taxLabel ?? expense.taxId;
      _taxAmountOverride = expense.taxId.isNotEmpty ? expense.taxAmount : null;
      _taxAmountOverrideTaxId = expense.taxId.isNotEmpty ? expense.taxId : null;
      _taxAmountOverrideAmountText = expense.amount == 0
          ? ''
          : expense.amount.toStringAsFixed(2);
      _amountIs = expense.amountTaxMode == 'INCLUSIVE'
          ? 'Tax Inclusive'
          : 'Tax Exclusive';
      _invoiceController.text = expense.invoiceNumber;
      _notesController.text = expense.notes;
      _selectedCustomerId = expense.customerId.isNotEmpty
          ? expense.customerId
          : customer?.id;
      _selectedCustomer = expense.customerName.isNotEmpty
          ? expense.customerName
          : customer?.displayName;
      _isCustomerBillable =
          (expense.customerId.isNotEmpty || customer != null) &&
          expense.isBillable;
      _markupByController.text = expense.markupBy;
      _isItemized = expense.isItemized;
      _selectedEmployee = mileage?.employeeId?.trim().isNotEmpty == true
          ? mileage!.employeeId!.trim()
          : null;
      _calculationMethod = mileage?.calculationType == 'ODOMETER_READING'
          ? 'Odometer reading'
          : 'Distance travelled';
      _mileageUnit = mileage?.distanceUnit == 'MILE' ? 'Mile' : 'Km';
      _distanceController.text = mileage == null || mileage.distance == 0
          ? ''
          : mileage.distance.toStringAsFixed(2);
      _startOdometerController.text = mileage?.odometerStart == null
          ? ''
          : mileage!.odometerStart!.toStringAsFixed(2);
      _endOdometerController.text = mileage?.odometerEnd == null
          ? ''
          : mileage!.odometerEnd!.toStringAsFixed(2);
      _mileageAmountController.text = expense.amount == 0
          ? '0.00'
          : expense.amount.toStringAsFixed(2);
      if (_mileageRates.isEmpty) {
        _mileageRates.add(MileageRateRow());
      }
      _mileageRates.first.rateController.text =
          mileage == null || mileage.ratePerKm <= 0
          ? _mileageRates.first.rateController.text
          : _formatMileageRateInput(mileage.ratePerKm);
      _selectedReceiptFiles = const <PlatformFile>[];
    });
  }

  void _hydrateRecurringExpense(RecurringExpenseDetails recurring) {
    for (final row in _itemizedRows) {
      row.dispose();
    }
    _itemizedRows
      ..clear()
      ..add(
        _newItemizedRow(
          expenseType: recurring.expenseType == ExpenseType.goods
              ? 'Goods'
              : 'Services',
        ),
      );

    final customer = recurring.customerId == null
        ? null
        : _findCustomerById(recurring.customerId!);
    final expenseAccount = recurring.expenseAccountId == null
        ? null
        : _findExpenseAccountById(recurring.expenseAccountId!);
    final taxLabel = _findTaxLabelById(recurring.taxId);
    final destinationState =
        _normalizeStateName(recurring.destinationOfSupply) ??
        recurring.destinationOfSupply ??
        '';

    setState(() {
      _itemizedTaxOverrides = {};
      _hideTaxAmountEditor();
      _editingExpense = null;
      _prefillRecurringExpenseId = recurring.id;
      _selectedDate = _selectedDate;
      _activeTab = 0;
      _selectedCategoryAccountId = recurring.expenseAccountId;
      _selectedCategory =
          recurring.expenseAccountName?.trim().isNotEmpty == true
          ? recurring.expenseAccountName
          : expenseAccount?.displayName;
      _selectedPaidThroughAccountId = recurring.paidThroughAccountId;
      _currency = recurring.currencyCode.isNotEmpty
          ? recurring.currencyCode
          : _currency;
      _amountController.text = recurring.amount == 0
          ? ''
          : recurring.amount.toStringAsFixed(2);
      _expenseType = recurring.expenseType == ExpenseType.goods
          ? 'Goods'
          : 'Services';
      _sacController.text = recurring.hsnSacCode ?? '';
      _selectedVendorId = recurring.vendorId;
      _selectedVendorItem = null;
      _gstTreatment = _resolveGstTreatmentLabel(recurring.gstTreatment);
      _vendorGstinController.clear();
      _sourceOfSupply =
          _normalizeStateName(recurring.sourceOfSupply) ??
          recurring.sourceOfSupply ??
          _sourceOfSupply;
      _destinationOfSupply = destinationState.isNotEmpty
          ? destinationState
          : _destinationOfSupply;
      _reverseCharge = recurring.reverseCharge;
      _selectedTax = taxLabel ?? recurring.taxId;
      _clearTaxAmountOverride();
      _amountIs = recurring.amountTaxMode == AmountTaxMode.inclusive
          ? 'Tax Inclusive'
          : 'Tax Exclusive';
      _invoiceController.text = recurring.invoiceNumber ?? '';
      _notesController.text = recurring.notes;
      _selectedCustomerId = recurring.customerId;
      _selectedCustomer = recurring.customerNameRaw?.trim().isNotEmpty == true
          ? recurring.customerNameRaw
          : customer?.displayName;
      _isCustomerBillable =
          (recurring.customerId?.isNotEmpty ?? false) && recurring.isBillable;
      _markupByController.clear();
      _isItemized = false;
      _selectedReceiptFiles = const <PlatformFile>[];
      _distanceController.clear();
      _startOdometerController.clear();
      _endOdometerController.clear();
      _selectedEmployee = null;
      _selectedVehicle = null;
      _mileageAmountController.text = '0.00';
      _calculationMethod = 'Distance travelled';
      _mileageUnit = 'Km';
      if (_mileageRates.isEmpty) {
        _mileageRates.add(MileageRateRow());
      }
      _mileageRates.first.rateController.clear();
    });
  }

  @override
  void dispose() {
    _itemizedHsnSacOverlayEntry?.remove();
    _itemizedHsnSacOverlayEntry = null;
    _itemizedTotalTaxOverlayEntry?.remove();
    _itemizedTotalTaxOverlayEntry = null;
    _taxAmountOverlayEntry?.remove();
    _taxAmountOverlayEntry = null;
    _itcOverlayEntry?.remove();
    _itcOverlayEntry = null;
    _amountController.dispose();
    _sacController.dispose();
    _invoiceController.dispose();
    _vendorGstinController.dispose();
    _notesController.dispose();
    _exemptionReasonController.dispose();
    _markupByFocusNode.dispose();
    _markupByController.dispose();
    _yellowShadeTimer?.cancel();
    for (final row in _itemizedRows) {
      row.dispose();
    }
    for (final row in _mileageRates) {
      row.dispose();
    }
    _distanceController.dispose();
    _endOdometerFocusNode.removeListener(_handleEndOdometerFocusChange);
    _endOdometerFocusNode.dispose();
    _startOdometerController.dispose();
    _endOdometerController.dispose();
    _mileageAmountController.dispose();
    _custFirstNameController.dispose();
    _custLastNameController.dispose();
    _custCompanyNameController.dispose();
    _custDisplayNameController.dispose();
    _custEmailController.dispose();
    _custNumberController.dispose();
    _custWorkPhoneController.dispose();
    _custMobilePhoneController.dispose();
    _custPanController.dispose();
    _custCreditLimitController.dispose();
    _custDemoFieldController.dispose();
    _custRemarksController.dispose();

    _custBillAttention.dispose();
    _custBillStreet1.dispose();
    _custBillStreet2.dispose();
    _custBillCity.dispose();
    _custBillPinCode.dispose();
    _custBillPhone.dispose();
    _custBillFax.dispose();

    _custShipAttention.dispose();
    _custShipStreet1.dispose();
    _custShipStreet2.dispose();
    _custShipCity.dispose();
    _custShipPinCode.dispose();
    _custShipPhone.dispose();
    _custShipFax.dispose();

    _vendFirstNameController.dispose();
    _vendLastNameController.dispose();
    _vendCompanyNameController.dispose();
    _vendDisplayNameController.dispose();
    _vendEmailController.dispose();
    _vendNumberController.dispose();
    _vendWorkPhoneController.dispose();
    _vendMobilePhoneController.dispose();
    _vendPanController.dispose();
    _vendDemoFieldController.dispose();
    _vendRemarksController.dispose();

    _vendBillAttention.dispose();
    _vendBillStreet1.dispose();
    _vendBillStreet2.dispose();
    _vendBillCity.dispose();
    _vendBillPinCode.dispose();
    _vendBillPhone.dispose();
    _vendBillFax.dispose();

    _vendShipAttention.dispose();
    _vendShipStreet1.dispose();
    _vendShipStreet2.dispose();
    _vendShipCity.dispose();
    _vendShipPinCode.dispose();
    _vendShipPhone.dispose();
    _vendShipFax.dispose();

    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty && mounted) {
      setState(() {
        _selectedReceiptFiles = <PlatformFile>[
          ..._selectedReceiptFiles,
          ...result.files.where((file) => file.bytes != null),
        ];
      });
      ZerpaiToast.success(
        context,
        '${result.files.length} receipt file(s) selected successfully',
      );
    }
  }

  Future<void> _deleteExistingAttachment(
    ExpenseAttachmentModel attachment,
  ) async {
    final expenseId = _editingExpense?.id;
    if (expenseId == null || expenseId.isEmpty) {
      return;
    }

    try {
      final repository = ref.read(expensesRepositoryProvider);
      final deleted = await repository.deleteAttachment(
        expenseId: expenseId,
        attachmentId: attachment.id,
      );
      if (!mounted) {
        return;
      }
      if (!deleted) {
        ZerpaiToast.error(context, 'Failed to delete attachment.');
        return;
      }

      final current = _editingExpense;
      if (current != null) {
        final updatedAttachments = current.attachments
            .where((item) => item.id != attachment.id)
            .toList(growable: false);
        setState(() {
          _editingExpense = current.copyWith(attachments: updatedAttachments);
        });
      }

      ref.invalidate(expenseDetailsProvider(expenseId));
      ref.invalidate(expenseJournalProvider(expenseId));
      ref.invalidate(expenseAttachmentsProvider(expenseId));
      await ref.read(expensesProvider.notifier).refresh();
      if (!mounted) {
        return;
      }
      ZerpaiToast.success(context, 'Attachment deleted successfully.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ZerpaiToast.error(context, 'Failed to delete attachment: $error');
    }
  }

  Future<void> _saveExpense({bool andNew = false}) async {
    if (_isSubmitting) {
      return;
    }
    if ((_gstTreatment ?? '').trim().isEmpty) {
      ZerpaiToast.error(context, 'Please select a GST treatment');
      return;
    }
    if (_showSourceOfSupply && _selectedStateOption(_sourceOfSupply) == null) {
      ZerpaiToast.error(context, 'Please select a Source of Supply');
      return;
    }
    if (_showDestinationOfSupply &&
        _selectedStateOption(_destinationOfSupply) == null) {
      ZerpaiToast.error(context, 'Please select a Destination of Supply');
      return;
    }
    if (!_isItemized &&
        _showTax &&
        _taxRequired &&
        (_selectedTax ?? '').trim().isEmpty) {
      ZerpaiToast.error(context, 'Please select a Tax');
      return;
    }
    if (!_validateExemptionReasonIfNeeded()) {
      return;
    }

    final repository = ref.read(expensesRepositoryProvider);
    final recurringExpenseId =
        _editingExpense?.recurringExpenseId.isNotEmpty == true
        ? _editingExpense!.recurringExpenseId
        : _prefillRecurringExpenseId;
    final expenseAccountId =
        _selectedCategoryAccountId ??
        _findExpenseAccountByLabel(_selectedCategory)?.id ??
        _editingExpense?.expenseAccountId;
    final paidThroughAccountId =
        _selectedPaidThroughAccountId ??
        _editingExpense?.paidThroughAccountId ??
        expenseAccountId ??
        (_flattenedExpenseAccounts.isNotEmpty
            ? _flattenedExpenseAccounts.first.id
            : null);

    if (_activeTab != 1 &&
        !_isItemized &&
        (expenseAccountId == null || expenseAccountId.isEmpty)) {
      ZerpaiToast.error(context, 'Please select an Expense Account');
      return;
    }
    if (paidThroughAccountId == null || paidThroughAccountId.isEmpty) {
      ZerpaiToast.error(context, 'No account is available for Paid Through');
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      final selectedTax = _selectedTaxOption();
      final selectedTaxRate = _selectedTaxRate(_selectedTax);
      final isInclusive = _amountIs == 'Tax Inclusive';
      final vendorId = await _normalizedVendorUuid();
      final request = _activeTab == 1
          ? _buildMileageExpenseRequest(
              expenseAccountId: expenseAccountId,
              paidThroughAccountId: paidThroughAccountId,
              recurringExpenseId: recurringExpenseId,
              vendorId: vendorId,
              selectedTax: selectedTax,
              selectedTaxRate: selectedTaxRate,
              isInclusive: isInclusive,
            )
          : _buildRecordExpenseRequest(
              expenseAccountId: expenseAccountId,
              paidThroughAccountId: paidThroughAccountId,
              recurringExpenseId: recurringExpenseId,
              vendorId: vendorId,
              selectedTax: selectedTax,
              selectedTaxRate: selectedTaxRate,
              isInclusive: isInclusive,
            );

      final ExpenseRecord record;
      if (_editingExpense == null || _editingExpense!.id.isEmpty) {
        record = await repository.createExpense(request);
      } else {
        record =
            (await repository.updateExpense(
              UpdateExpenseRequest(id: _editingExpense!.id, expense: request),
            )) ??
            _editingExpense!;
      }

      if (_selectedReceiptFiles.isNotEmpty) {
        await repository.uploadReceiptFiles(
          expenseId: record.id,
          files: _selectedReceiptFiles,
        );
      }

      ref.invalidate(expenseDetailsProvider(record.id));
      ref.invalidate(expenseHistoryProvider(record.id));
      ref.invalidate(expenseJournalProvider(record.id));
      ref.invalidate(expenseAttachmentsProvider(record.id));
      await ref.read(expensesProvider.notifier).fetchExpenses();

      if (!mounted) {
        return;
      }

      ZerpaiToast.success(
        context,
        _activeTab == 1
            ? (_editingExpense == null
                  ? 'Mileage recorded successfully'
                  : 'Mileage updated successfully')
            : (_editingExpense == null
                  ? 'Expense saved successfully'
                  : 'Expense updated successfully'),
      );

      if (andNew) {
        _resetCreateForm();
        return;
      }

      final orgId =
          GoRouterState.of(context).pathParameters['orgSystemId'] ??
          '6000000000';
      context.go('/$orgId/purchases/expenses/${record.id}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ErrorHandler.showErrorSnackBar(
        context,
        ErrorHandler.getFriendlyMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  UpsertExpenseRequest _buildRecordExpenseRequest({
    required String? expenseAccountId,
    required String paidThroughAccountId,
    required String? recurringExpenseId,
    required String? vendorId,
    required RecurringExpenseTaxOption? selectedTax,
    required double selectedTaxRate,
    required bool isInclusive,
  }) {
    if (_isItemized) {
      if (_itemizedRows.isEmpty) {
        throw Exception('Please add at least one itemized row');
      }
      final items = <ExpenseItemModel>[];
      double subtotal = 0;
      double taxAmount = 0;
      for (int index = 0; index < _itemizedRows.length; index += 1) {
        final row = _itemizedRows[index];
        final rowAccount = _findExpenseAccountById(row.expenseAccountId);
        if (rowAccount == null) {
          throw Exception(
            'Please select an Expense Account for row ${index + 1}',
          );
        }
        final amount = double.tryParse(row.amountController.text.trim());
        if (amount == null || amount <= 0) {
          throw Exception(
            'Please enter a valid amount > 0 for row ${index + 1}',
          );
        }
        final rowTax = _findTaxByLabel(row.tax);
        final rowTaxRate = _selectedTaxRate(row.tax);
        final rowTaxAmount = _computeTaxAmount(
          amount: amount,
          rate: rowTaxRate,
          inclusive: isInclusive,
        );
        final normalizedRowTaxId = _normalizedTaxId(rowTax);
        _logTaxDebug(
          'before creating ExpenseItemModel',
          'row=${index + 1} description=${row.notesController.text.trim()} '
              'account=${rowAccount.id}/${rowAccount.displayName} tax label=${row.tax} '
              'resolved tax object=${rowTax == null ? 'null' : 'id=${rowTax.id} label=${rowTax.label} displayLabel=${rowTax.displayLabel} rate=${rowTax.rate}'} '
              'tax UUID=$normalizedRowTaxId',
        );
        subtotal += amount;
        taxAmount += rowTaxAmount;
        items.add(
          ExpenseItemModel(
            id: '',
            lineNo: index + 1,
            expenseAccountId: rowAccount.id,
            expenseAccountName: rowAccount.displayName,
            notes: row.notesController.text.trim(),
            taxId: normalizedRowTaxId,
            taxAmount: rowTaxAmount,
            amount: amount,
          ),
        );
      }
      return UpsertExpenseRequest(
        expenseNumber: _editingExpense?.expenseNumber,
        expenseDate: _formatApiDate(_selectedDate),
        expenseMode: 'RECORD_EXPENSE',
        expenseAccountId: expenseAccountId,
        paidThroughAccountId: paidThroughAccountId,
        amount: subtotal,
        expenseType: _itemizedExpenseTypeCode(),
        invoiceNumber: _optionalInvoiceNumber(),
        currencyCode: _currency,
        hsnSacCode: _sacController.text.trim(),
        vendorId: vendorId,
        customerId: _selectedCustomerId,
        markUpBy: _resolvedMarkupByValue(),
        gstTreatment: _resolveGstTreatmentCode(_gstTreatment),
        sourceOfSupply: _showSourceOfSupply ? _sourceOfSupply : null,
        destinationOfSupply: _showDestinationOfSupply
            ? (_findStateByLabel(_destinationOfSupply)?.code ??
                  _destinationOfSupply)
            : null,
        reverseCharge: _showReverseCharge ? _reverseCharge : false,
        taxId: _showTax ? _normalizedTaxId(selectedTax) : null,
        amountTaxMode: _showAmountIs && !(_showReverseCharge && _reverseCharge)
            ? (isInclusive ? 'INCLUSIVE' : 'EXCLUSIVE')
            : 'EXCLUSIVE',
        notes: _notesController.text.trim(),
        isBillable: _selectedCustomerId != null && _isCustomerBillable,
        subtotal: subtotal,
        taxAmount: taxAmount,
        totalAmount: subtotal + taxAmount,
        recurringExpenseId: recurringExpenseId,
        isItemized: true,
        items: items,
      );
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      throw Exception('Please enter a valid amount > 0');
    }
    if (expenseAccountId == null || expenseAccountId.isEmpty) {
      throw Exception('Please select an Expense Account');
    }
    final taxAmount = _resolvedDisplayedTaxAmount(_amountController.text);
    return UpsertExpenseRequest(
      expenseNumber: _editingExpense?.expenseNumber,
      expenseDate: _formatApiDate(_selectedDate),
      expenseMode: 'RECORD_EXPENSE',
      expenseAccountId: expenseAccountId,
      paidThroughAccountId: paidThroughAccountId,
      amount: amount,
      expenseType: _expenseType == 'Goods' ? 'GOODS' : 'SERVICES',
      invoiceNumber: _optionalInvoiceNumber(),
      currencyCode: _currency,
      hsnSacCode: _sacController.text.trim(),
      vendorId: vendorId,
      customerId: _selectedCustomerId,
      markUpBy: _resolvedMarkupByValue(),
      gstTreatment: _resolveGstTreatmentCode(_gstTreatment),
      sourceOfSupply: _showSourceOfSupply ? _sourceOfSupply : null,
      destinationOfSupply: _showDestinationOfSupply
          ? (_findStateByLabel(_destinationOfSupply)?.code ??
                _destinationOfSupply)
          : null,
      reverseCharge: _showReverseCharge ? _reverseCharge : false,
      taxId: _showTax ? _normalizedTaxId(selectedTax) : null,
      amountTaxMode: _showAmountIs && !(_showReverseCharge && _reverseCharge)
          ? (isInclusive ? 'INCLUSIVE' : 'EXCLUSIVE')
          : 'EXCLUSIVE',
      notes: _notesController.text.trim(),
      isBillable: _selectedCustomerId != null && _isCustomerBillable,
      subtotal: amount,
      taxAmount: taxAmount,
      totalAmount: amount + taxAmount,
      recurringExpenseId: recurringExpenseId,
      isItemized: false,
    );
  }

  UpsertExpenseRequest _buildMileageExpenseRequest({
    required String? expenseAccountId,
    required String paidThroughAccountId,
    required String? recurringExpenseId,
    required String? vendorId,
    required RecurringExpenseTaxOption? selectedTax,
    required double selectedTaxRate,
    required bool isInclusive,
  }) {
    final distance = _calculateDistance();
    if (distance <= 0) {
      if (_calculationMethod == 'Distance travelled') {
        throw Exception('Please enter a valid distance > 0');
      }
      throw Exception('End odometer must be greater than start odometer');
    }
    final amount = double.tryParse(_mileageAmountController.text.trim());
    if (amount == null || amount <= 0) {
      throw Exception('Please enter or calculate a valid amount > 0');
    }
    final taxAmount = _resolvedDisplayedTaxAmount(
      _mileageAmountController.text,
    );
    return UpsertExpenseRequest(
      expenseNumber: _editingExpense?.expenseNumber,
      expenseDate: _formatApiDate(_selectedDate),
      expenseMode: 'RECORD_MILEAGE',
      expenseAccountId: expenseAccountId,
      paidThroughAccountId: paidThroughAccountId,
      amount: amount,
      expenseType: 'SERVICES',
      invoiceNumber: _optionalInvoiceNumber(),
      currencyCode: _currency,
      hsnSacCode: _sacController.text.trim(),
      vendorId: vendorId,
      customerId: _selectedCustomerId,
      markUpBy: _resolvedMarkupByValue(),
      gstTreatment: _resolveGstTreatmentCode(_gstTreatment),
      sourceOfSupply: _showSourceOfSupply ? _sourceOfSupply : null,
      destinationOfSupply: _showDestinationOfSupply
          ? (_findStateByLabel(_destinationOfSupply)?.code ??
                _destinationOfSupply)
          : null,
      reverseCharge: _showReverseCharge ? _reverseCharge : false,
      taxId: _showTax ? _normalizedTaxId(selectedTax) : null,
      amountTaxMode: _showAmountIs && !(_showReverseCharge && _reverseCharge)
          ? (isInclusive ? 'INCLUSIVE' : 'EXCLUSIVE')
          : 'EXCLUSIVE',
      notes: _notesController.text.trim(),
      recurringExpenseId: recurringExpenseId,
      subtotal: amount,
      taxAmount: taxAmount,
      totalAmount: amount + taxAmount,
      mileage: ExpenseMileageModel(
        id: _editingExpense?.mileage?.id ?? '',
        employeeId: _selectedEmployee?.trim().isNotEmpty == true
            ? _selectedEmployee!.trim()
            : null,
        calculationType: _calculationMethod == 'Odometer reading'
            ? 'ODOMETER_READING'
            : 'DISTANCE_TRAVELLED',
        distance: distance,
        distanceUnit: _mileageUnit == 'Mile' ? 'MILE' : 'KM',
        ratePerKm: _getApplicableMileageRate(_selectedDate),
        odometerStart: _startOdometerController.text.trim().isEmpty
            ? null
            : double.tryParse(_startOdometerController.text.trim()),
        odometerEnd: _endOdometerController.text.trim().isEmpty
            ? null
            : double.tryParse(_endOdometerController.text.trim()),
      ),
    );
  }

  void _resetCreateForm() {
    _hideItemizedHsnSacEditor();
    _hideItemizedTotalTaxEditor();
    _hideTaxAmountEditor();
    setState(() {
      _editingExpense = null;
      _prefillRecurringExpenseId = null;
      _selectedDate = DateTime.now();
      _selectedCategory = null;
      _selectedCategoryAccountId = null;
      _selectedPaidThroughAccountId = null;
      _currency = 'INR';
      _amountController.clear();
      _expenseType = 'Services';
      _sacController.clear();
      _selectedVendorItem = null;
      _selectedVendorId = null;
      _gstTreatment = null;
      _vendorGstinController.clear();
      _sourceOfSupply = 'State/Province';
      _destinationOfSupply = '[KL] - Kerala';
      _reverseCharge = false;
      _selectedTax = null;
      _clearExemptionReason();
      _clearTaxAmountOverride();
      _amountIs = 'Tax Exclusive';
      _invoiceController.clear();
      _notesController.clear();
      _selectedCustomer = null;
      _selectedCustomerId = null;
      _isCustomerBillable = false;
      _markupByController.clear();
      _selectedReceiptFiles = const <PlatformFile>[];
      _isItemized = false;
      _itemizedTaxOverrides = {};
      _distanceController.clear();
      _startOdometerController.clear();
      _endOdometerController.clear();
      _selectedEmployee = null;
      _selectedVehicle = null;
      _mileageAmountController.text = '0.00';
      _calculationMethod = 'Distance travelled';
      _mileageUnit = 'Km';
      for (final row in _itemizedRows) {
        row.dispose();
      }
      _itemizedRows
        ..clear()
        ..add(_newItemizedRow(expenseType: _expenseType));
    });
  }

  void _cancel() {
    final orgId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    context.go('/$orgId/purchases/expenses');
  }

  void _openAdvancedCustomerSearch(
    List<RecurringExpenseCustomerOption> customersList,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Advanced Customer Search',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) => AdvancedCustomerSearchDialog(
        customers: customersList
            .map((customer) => customer.toSalesCustomer())
            .toList(),
        onSelect: (customer) {
          final selected = RecurringExpenseCustomerOption.fromSalesCustomer(
            customer,
          );
          setState(() {
            _selectedCustomer = selected.displayName;
            _selectedCustomerId = selected.id;
          });
        },
      ),
    );
  }

  Widget _buildRecurringStyledCustomerFieldRow() {
    final customersAsync = ref.watch(salesCustomersProvider);
    final selectedCustomer = _selectedCustomerOption;
    final showBillable = selectedCustomer != null;
    final showMarkupBy = showBillable && _isCustomerBillable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldRow(
          _label('Customer Name'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: _expenseCreateLookupInputWidth,
                    child: Container(
                      height: _expenseCreateCompactFieldHeight,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                      child: CustomerDropdownWidget(
                        value: selectedCustomer,
                        items: _customerOptions,
                        isLoading: customersAsync.isLoading,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                        hint: customersAsync.isLoading
                            ? 'Loading Customers...'
                            : customersAsync.hasError
                            ? 'Unable to load customers'
                            : _customerOptions.isEmpty
                            ? 'No Customers Found'
                            : 'Select Customer',
                        onChanged: (value) => setState(() {
                          _selectedCustomer = value?.displayName;
                          _selectedCustomerId = value?.id;
                          if (value == null) {
                            _isCustomerBillable = false;
                          }
                        }),
                        onAddCustomer: () => _showNewCustomerDialog(context),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openAdvancedCustomerSearch(_customerOptions),
                    child: Container(
                      width: _expenseCreateLookupActionWidth,
                      height: _expenseCreateCompactFieldHeight,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentGreen,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.search,
                        size: 16,
                        color: AppTheme.backgroundColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (showBillable) ...[
                const SizedBox(width: 16),
                SizedBox(
                  height: _expenseCreateCompactFieldHeight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(
                            horizontal: -4,
                            vertical: -4,
                          ),
                        ),
                        child: Checkbox(
                          value: _isCustomerBillable,
                          onChanged: (value) => setState(
                            () => _isCustomerBillable = value ?? false,
                          ),
                          activeColor: AppTheme.primaryBlueDark,
                          side: const BorderSide(
                            color: AppTheme.textSubtle,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Billable',
                        style: AppTextStyles.body.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          fixHeight: false,
          fieldWidth: showBillable
              ? _expenseCreateLookupFieldWidth + 126
              : _expenseCreateLookupFieldWidth,
        ),
        if (showMarkupBy)
          _fieldRow(
            _labelWithTooltip(
              'Mark up by',
              'Enter the percentage by which you want to mark up this expense amount while invoicing the customer.',
            ),
            SizedBox(
              width: _expenseCreateMarkupFieldWidth,
              child: _buildMarkupByInput(),
            ),
            fieldWidth: _expenseCreateMarkupFieldWidth,
          ),
      ],
    );
  }

  Widget _buildMarkupByInput() {
    final bool hasFocus = _markupByFocusNode.hasFocus;
    final Color borderColor = hasFocus
        ? AppTheme.primaryBlueDark
        : (_isMarkupByHovered ? AppTheme.infoBlue : AppTheme.borderColor);

    return SizedBox(
      height: _expenseCreateCompactFieldHeight,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isMarkupByHovered = true),
        onExit: (_) => setState(() => _isMarkupByHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: AppTheme.inputFill,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Center(
                    child: TextFormField(
                      focusNode: _markupByFocusNode,
                      controller: _markupByController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final text = newValue.text;
                          if (text.isEmpty ||
                              RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
                            return newValue;
                          }
                          return oldValue;
                        }),
                      ],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        fillColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () => setState(() {}),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ),
              Container(
                width: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppTheme.tableHeaderBg,
                  border: Border(
                    left: BorderSide(color: AppTheme.borderColor, width: 1),
                  ),
                ),
                child: Text(
                  '%',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  /// Tab item matching payment-receives style (underline indicator).
  Widget _tabItem(
    String text, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.bgLight : AppTheme.backgroundColor,
          border: isActive
              ? const Border(
                  top: BorderSide(color: AppTheme.primaryBlue, width: 3),
                  left: BorderSide(color: AppTheme.borderColor, width: 1),
                  right: BorderSide(color: AppTheme.borderColor, width: 1),
                  bottom: BorderSide(color: AppTheme.bgLight, width: 1),
                )
              : const Border(
                  bottom: BorderSide(color: AppTheme.borderColor, width: 1),
                ),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: isActive ? 3.0 : 0.0),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// Label widget — red asterisk for required.
  Widget _label(String text, {bool required = false}) {
    if (!required) {
      return Text(
        text,
        style: AppTextStyles.label.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: AppTextStyles.labelRequired.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const TextSpan(
            text: '*',
            style: TextStyle(color: AppTheme.errorRed, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _labelWithTooltip(String text, String tooltipMessage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _label(text),
        const SizedBox(width: AppTheme.space6),
        ZTooltip(message: tooltipMessage),
      ],
    );
  }

  static const double _expenseCreateLabelWidth = 164.0;
  static const double _expenseCreateStandardFieldWidth = 396.0;
  static const double _expenseCreateLookupInputWidth = 396.0;
  static const double _expenseCreateLookupActionWidth = 36.0;
  static const double _expenseCreateLookupFieldWidth =
      _expenseCreateLookupInputWidth + 8.0 + _expenseCreateLookupActionWidth;
  static const double _expenseCreateMarkupFieldWidth =
      _expenseCreateStandardFieldWidth * 0.4;
  static const double _expenseCreateCompactFieldHeight = 32.0;
  static const double _expenseCreateDenseRowVerticalPadding = 4.0;
  static const double _expenseCreateRecurringCompositeFieldWidth = 732.0;

  Widget _fieldRow(
    Widget label,
    Widget field, {
    bool fixHeight = true,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double fieldWidth = _expenseCreateStandardFieldWidth,
    double verticalPadding = 8.0,
  }) {
    Widget content = fixHeight
        ? SizedBox(height: _expenseCreateCompactFieldHeight, child: field)
        : field;
    content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: fieldWidth),
      child: content,
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          SizedBox(
            width: _expenseCreateLabelWidth,
            child: Align(alignment: Alignment.centerLeft, child: label),
          ),
          const SizedBox(width: 12),
          content,
        ],
      ),
    );
  }

  Widget _parityLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: required ? AppTheme.errorRed : AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            : const [],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      height: 48,
      color: AppTheme.backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 24,
            height: 48,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor, width: 1),
              ),
            ),
          ),
          _tabItem(
            'Record Expense',
            isActive: _activeTab == 0,
            onTap: () {
              setState(() {
                _activeTab = 0;
              });
            },
          ),
          Container(
            width: 8,
            height: 48,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor, width: 1),
              ),
            ),
          ),
          _tabItem(
            'Record Mileage',
            isActive: _activeTab == 1,
            onTap: () {
              setState(() {
                _activeTab = 1;
              });
            },
          ),
          Expanded(
            child: Container(
              height: 48,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderColor, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Record Expense form ───────────────────────────────────────────────────

  Widget _buildRecordExpenseForm() {
    return Form(
      key: _formKey,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upper Section (Grey background)
              Container(
                color: AppTheme.bgLight,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
                      _fieldRow(
                        _label('Date', required: true),
                        ZExpensesDatePicker(
                          selectedDate: _selectedDate,
                          onDateSelected: (d) =>
                              setState(() => _selectedDate = d),
                        ),
                      ),

                      if (!_isItemized) ...[
                        // Expense Account + Itemize link
                        _fieldRow(
                          _label('Expense Account', required: true),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: _expenseCreateStandardFieldWidth,
                                child: ExpenseAccountDropdownWidget(
                                  value: _selectedCategoryAccountId,
                                  nodes:
                                      buildRecurringExpenseGroupedAccountNodes(
                                        _expenseAccountCatalog,
                                      ),
                                  hint: 'Select an account',
                                  onChanged: (v) => setState(() {
                                    _selectedCategoryAccountId = v;
                                    _selectedCategory = _findExpenseAccountById(
                                      v,
                                    )?.displayName;
                                  }),
                                  onAddAccount: () async {
                                    final createdAccountName =
                                        await AddAccountDialog.show(context);
                                    if (createdAccountName != null && mounted) {
                                      ref.invalidate(
                                        expensesExpenseAccountsProvider,
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isItemized = true;
                                    _itemizeBgColor = AppTheme.warningBg;
                                    if (_itemizedRows.isNotEmpty) {
                                      if (_selectedCategoryAccountId != null) {
                                        _itemizedRows[0].expenseAccountId =
                                            _selectedCategoryAccountId;
                                      }
                                      if (_amountController.text.isNotEmpty) {
                                        _itemizedRows[0].amountController.text =
                                            _amountController.text;
                                      }
                                    }
                                  });
                                  _yellowShadeTimer?.cancel();
                                  _yellowShadeTimer = Timer(
                                    const Duration(seconds: 1),
                                    () {
                                      if (!mounted) return;
                                      setState(() {
                                        _itemizeBgColor =
                                            AppTheme.backgroundColor;
                                      });
                                    },
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.listOrdered,
                                      size: 13,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Itemize',
                                      style: AppTextStyles.label.copyWith(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          fixHeight: false,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          fieldWidth: _expenseCreateStandardFieldWidth,
                        ),

                        _fieldRow(
                          _label('Amount', required: true),
                          SizedBox(
                            width: _expenseCreateStandardFieldWidth,
                            child: AmountInputWidget(
                              controller: _amountController,
                              selectedCurrency: _currency,
                              currencies: _expenseCurrencyOptions,
                              enableCurrencySelection: false,
                              onCurrencyChanged: (_) {},
                              hintText: '',
                            ),
                          ),
                          fixHeight: false,
                          fieldWidth: _expenseCreateStandardFieldWidth,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Lower Section (White background)
              Container(
                color: AppTheme.backgroundColor,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldRow(
                      _label('Paid Through', required: true),
                      SizedBox(
                        width: _expenseCreateStandardFieldWidth,
                        child: AccountTreeDropdownWithAddButton(
                          value: _selectedPaidThroughAccountId,
                          nodes: _paidThroughAccountsList,
                          height: _expenseCreateCompactFieldHeight,
                          hint: 'Select an account',
                          highlightSearchMatches: false,
                          onChanged: (value) {
                            setState(
                              () => _selectedPaidThroughAccountId = value,
                            );
                          },
                          onAddAccount: () async {
                            final createdAccountName =
                                await AddAccountDialog.show(context);
                            if (createdAccountName != null && mounted) {
                              ref.invalidate(chartOfAccountsProvider);
                            }
                          },
                        ),
                      ),
                      fixHeight: false,
                      fieldWidth: _expenseCreateStandardFieldWidth,
                    ),

                    if (!_isItemized)
                      _fieldRow(
                        _label('Expense Type', required: true),
                        RadioGroup<String>(
                          groupValue: _expenseType,
                          onChanged: (v) {
                            if (v != null) setState(() => _expenseType = v);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: 'Goods',
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'Goods',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Radio<String>(
                                value: 'Services',
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'Services',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        fixHeight: false,
                        fieldWidth: _expenseCreateStandardFieldWidth,
                      ),

                    if (!_isItemized)
                      _fieldRow(
                        _label(_expenseType == 'Goods' ? 'HSN Code' : 'SAC'),
                        CustomTextField(
                          controller: _sacController,
                          hintText: '',
                        ),
                      ),

                    // Vendor + search button
                    _fieldRow(
                      _label('Vendor'),
                      SizedBox(
                        width: _expenseCreateLookupFieldWidth,
                        child: Row(
                          children: [
                            SizedBox(
                              width: _expenseCreateLookupInputWidth,
                              child: VendorDropdownWidget(
                                value: _selectedVendorOption,
                                items: _vendorOptions,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  bottomLeft: Radius.circular(4),
                                ),
                                onAddVendor: () =>
                                    _showNewVendorDialog(context),
                                onChanged: (value) {
                                  final selectedItem = value == null
                                      ? null
                                      : VendorItem(
                                          name: value.displayName,
                                          code: value.id,
                                          extraSubtitle: value.companyName,
                                        );
                                  setState(() {
                                    _selectedVendorItem = selectedItem;
                                    _selectedVendorId =
                                        _resolveSelectedVendorId(value);
                                    _applyVendorLinkedDropdownSelections(
                                      gstTreatment: value?.gstTreatment,
                                      sourceOfSupply: value?.sourceOfSupply,
                                    );
                                  });
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: _expenseCreateLookupActionWidth,
                                height: _expenseCreateCompactFieldHeight,
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentGreen,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.search,
                                  size: 16,
                                  color: AppTheme.backgroundColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      fixHeight: false,
                      fieldWidth: _expenseCreateLookupFieldWidth,
                    ),

                    // GST Treatment
                    _fieldRow(
                      _label('GST Treatment', required: true),
                      _buildRecurringStyleGstTreatmentDropdown(
                        onChanged: (v) {
                          setState(() {
                            _applyGstTreatmentSelection(v);
                          });
                        },
                      ),
                    ),

                    if (_showVendorGstin)
                      _fieldRow(
                        _parityLabel(
                          'Vendor GSTIN',
                          required: _vendorGstinRequired,
                        ),
                        SizedBox(
                          width: _expenseCreateRecurringCompositeFieldWidth,
                          child: Row(
                            children: [
                              SizedBox(
                                width: _expenseCreateStandardFieldWidth,
                                child: CustomTextField(
                                  controller: _vendorGstinController,
                                  height: _expenseCreateCompactFieldHeight,
                                  forceUppercase: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.infoBlue,
                                  padding: EdgeInsets.zero,
                                  textStyle: AppTextStyles.body.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                                child: const Text('Get Taxpayer details'),
                              ),
                            ],
                          ),
                        ),
                        fixHeight: false,
                        fieldWidth: _expenseCreateRecurringCompositeFieldWidth,
                        verticalPadding: _expenseCreateDenseRowVerticalPadding,
                      ),

                    // Source of Supply
                    if (_showSourceOfSupply)
                      _fieldRow(
                        _label('Source of Supply', required: true),
                        FormDropdown<StateLookupModel>(
                          value: _selectedStateOption(_sourceOfSupply),
                          items: _stateCatalog,
                          hint: _stateCatalog.isEmpty
                              ? 'No States Found'
                              : 'Select source state',
                          displayStringForValue: (item) => item.displayLabel,
                          onChanged: (v) {
                            setState(() {
                              _applySourceOfSupplySelection(v);
                            });
                          },
                        ),
                      ),

                    // Destination of Supply
                    if (_showDestinationOfSupply)
                      _fieldRow(
                        _label('Destination of Supply', required: true),
                        FormDropdown<StateLookupModel>(
                          value: _selectedStateOption(_destinationOfSupply),
                          items: _stateCatalog,
                          hint: _stateCatalog.isEmpty
                              ? 'No States Found'
                              : 'State/Province',
                          displayStringForValue: (item) => item.displayLabel,
                          onChanged: (v) {
                            setState(() {
                              _destinationOfSupply = v?.name ?? '';
                              _pruneHiddenTaxSelections();
                            });
                          },
                        ),
                      ),

                    // Reverse Charge checkbox
                    if (_showReverseCharge)
                      _fieldRow(
                        _label('Reverse Charge'),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: Checkbox(
                                value: _reverseCharge,
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) => setState(() {
                                  _reverseCharge = v ?? false;
                                  if (_reverseCharge) {
                                    _amountIs = 'Tax Exclusive';
                                  }
                                }),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'This transaction is applicable for reverse charge',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        fixHeight: false,
                        fieldWidth: 340,
                      ),

                    if (!_isItemized && _showTax) ...[
                      _fieldRow(
                        _label('Tax', required: _taxRequired),
                        _buildRecurringStyledTaxDropdown(
                          amountText: _amountController.text,
                        ),
                        fixHeight: false,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                      if (_showExemptionReasonField)
                        _fieldRow(
                          _label('Exemption Reason', required: true),
                          CustomTextField(
                            controller: _exemptionReasonController,
                            hintText: '',
                            errorText: _exemptionReasonErrorText,
                            onChanged: (value) {
                              if (_exemptionReasonErrorText != null &&
                                  value.trim().isNotEmpty) {
                                setState(() {
                                  _exemptionReasonErrorText = null;
                                });
                              }
                            },
                          ),
                        ),
                    ],

                    if (_showAmountIs && !_reverseCharge)
                      _fieldRow(
                        _label('Amount Is'),
                        RadioGroup<String>(
                          groupValue: _amountIs,
                          onChanged: (v) {
                            if (v != null) setState(() => _amountIs = v);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: 'Tax Inclusive',
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'Tax Inclusive',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Radio<String>(
                                value: 'Tax Exclusive',
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'Tax Exclusive',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        fixHeight: false,
                        fieldWidth: 280,
                      ),

                    if (_isItemized) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: _buildItemizeBox(),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Invoice#
                    _fieldRow(
                      _label('Invoice#'),
                      CustomTextField(
                        controller: _invoiceController,
                        hintText: '',
                      ),
                    ),

                    if (!_isItemized)
                      _fieldRow(
                        _label('Notes'),
                        CustomTextField(
                          controller: _notesController,
                          hintText: 'Max. 500 characters',
                          maxLines: 4,
                          height: 80,
                        ),
                        fixHeight: false,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),

                    const SizedBox(height: 24),
                    const Divider(color: AppTheme.borderColor),
                    const SizedBox(height: 24),
                    _buildRecurringStyledCustomerFieldRow(),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: _receiptCardTopOffset,
            right: _receiptCardRightOffset,
            child: _buildReceiptCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerUploadButton(
    StateSetter dialogSetState,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DottedBorder(
              color: AppTheme.borderColor,
              strokeWidth: 1.2,
              dashPattern: const [4, 3],
              borderType: BorderType.RRect,
              radius: const Radius.circular(4),
              child: Container(
                height: 32,
                color: AppTheme.backgroundColor,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.any,
                          allowMultiple: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          dialogSetState(() {
                            for (final file in result.files) {
                              if (_custUploadedFiles.length < 10) {
                                _custUploadedFiles.add(file.name);
                              }
                            }
                          });
                          ZerpaiToast.success(
                            context,
                            '${result.files.length} file(s) selected',
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              LucideIcons.upload,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Upload File',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: AppTheme.borderLight,
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Upload options',
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      splashRadius: 16,
                      color: AppTheme.backgroundColor,
                      onSelected: (val) async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.any,
                          allowMultiple: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          dialogSetState(() {
                            for (final file in result.files) {
                              if (_custUploadedFiles.length < 10) {
                                _custUploadedFiles.add(file.name);
                              }
                            }
                          });
                          ZerpaiToast.success(
                            context,
                            '${result.files.length} file(s) selected',
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'device',
                          child: Text(
                            'From Device',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'You can upload a maximum of 10 files, 10MB each',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        if (_custUploadedFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _custUploadedFiles.map((filename) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgDisabled,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        filename,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        dialogSetState(() {
                          _custUploadedFiles.remove(filename);
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildVendorUploadButton(
    StateSetter dialogSetState,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DottedBorder(
              color: AppTheme.borderColor,
              strokeWidth: 1.2,
              dashPattern: const [4, 3],
              borderType: BorderType.RRect,
              radius: const Radius.circular(4),
              child: Container(
                height: 32,
                color: AppTheme.backgroundColor,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.any,
                          allowMultiple: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          dialogSetState(() {
                            for (final file in result.files) {
                              if (_vendUploadedFiles.length < 10) {
                                _vendUploadedFiles.add(file.name);
                              }
                            }
                          });
                          ZerpaiToast.success(
                            context,
                            '${result.files.length} file(s) selected',
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              LucideIcons.upload,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Upload File',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: AppTheme.borderLight,
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Upload options',
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      splashRadius: 16,
                      color: AppTheme.backgroundColor,
                      onSelected: (val) async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.any,
                          allowMultiple: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          dialogSetState(() {
                            for (final file in result.files) {
                              if (_vendUploadedFiles.length < 10) {
                                _vendUploadedFiles.add(file.name);
                              }
                            }
                          });
                          ZerpaiToast.success(
                            context,
                            '${result.files.length} file(s) selected',
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'device',
                          child: Text(
                            'From Device',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'You can upload a maximum of 10 files, 10MB each',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        if (_vendUploadedFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _vendUploadedFiles.map((filename) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgDisabled,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        filename,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        dialogSetState(() {
                          _vendUploadedFiles.remove(filename);
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _showNewVendorDialog(BuildContext context) {
    // Reset vendor fields on entry
    _vendSalutation = 'Salutation';
    _vendFirstNameController.clear();
    _vendLastNameController.clear();
    _vendCompanyNameController.clear();
    _vendDisplayNameController.clear();
    _vendEmailController.clear();
    _vendNumberController.text = 'VEN-02';
    _vendWorkPhoneCode = '+91';
    _vendWorkPhoneController.clear();
    _vendMobilePhoneCode = '+91';
    _vendMobilePhoneController.clear();
    _vendLanguage = 'English';
    _vendActiveTab = 'Other Details';

    _vendGstTreatment = 'Select a GST treatment';
    _vendSourceOfSupply = 'Select source of supply';
    _vendPanController.clear();
    _vendMsmeRegistered = false;
    _vendCurrency = 'INR- Indian Rupee';
    _vendPaymentTerms = 'Net 360';
    _vendTds = null;
    _vendPriceList = 'Select a price list';
    _vendEnablePortal = false;
    _vendUploadedFiles = [];
    _vendDemoFieldController.clear();
    _vendRemarksController.clear();
    _vendAdgf = 'None';
    _vendSchedule = 'None';
    _vendDemoAdvanced = 'None';

    _vendBillAttention.clear();
    _vendBillCountry = null;
    _vendBillStreet1.clear();
    _vendBillStreet2.clear();
    _vendBillCity.clear();
    _vendBillState = null;
    _vendBillPinCode.clear();
    _vendBillPhone.clear();
    _vendBillFax.clear();

    _vendShipAttention.clear();
    _vendShipCountry = null;
    _vendShipStreet1.clear();
    _vendShipStreet2.clear();
    _vendShipCity.clear();
    _vendShipState = null;
    _vendShipPinCode.clear();
    _vendShipPhone.clear();
    _vendShipFax.clear();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          alignment: Alignment.topCenter,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
          child: StatefulBuilder(
            builder: (context, dialogSetState) {
              return Container(
                width: 750,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header: Title + Close Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'New Vendor',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warningTextDark,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 20,
                              color: AppTheme.errorRed,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Primary Contact
                      _dialogFieldRow(
                        _dialogLabel('Primary Contact', showInfo: true),
                        Row(
                          children: [
                            SizedBox(
                              width: 110,
                              height: 36,
                              child: FormDropdown<String>(
                                value: _vendSalutation == 'Salutation'
                                    ? null
                                    : _vendSalutation,
                                items: const [
                                  'Mr.',
                                  'Mrs.',
                                  'Ms.',
                                  'Miss',
                                  'Dr.',
                                ],
                                hint: 'Salutation',
                                showSearch: false,
                                onChanged: (v) {
                                  if (v != null)
                                    dialogSetState(() => _vendSalutation = v);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: CustomTextField(
                                  controller: _vendFirstNameController,
                                  hintText: 'First Name',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: CustomTextField(
                                  controller: _vendLastNameController,
                                  hintText: 'Last Name',
                                ),
                              ),
                            ),
                          ],
                        ),
                        fixHeight: false,
                      ),

                      // Company Name
                      _dialogFieldRow(
                        _dialogLabel('Company Name'),
                        CustomTextField(
                          controller: _vendCompanyNameController,
                          hintText: '',
                        ),
                      ),

                      // Display Name*
                      _dialogFieldRow(
                        _dialogLabel(
                          'Display Name',
                          required: true,
                          showInfo: true,
                        ),
                        CustomTextField(
                          controller: _vendDisplayNameController,
                          hintText: 'Select or type to add',
                        ),
                      ),

                      // Email Address
                      _dialogFieldRow(
                        _dialogLabel('Email Address', showInfo: true),
                        CustomTextField(
                          controller: _vendEmailController,
                          hintText: '',
                          prefixIcon: LucideIcons.mail,
                        ),
                      ),

                      // Vendor Number*
                      _dialogFieldRow(
                        _dialogLabel('Vendor Number', required: true),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _vendNumberController,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.borderColor),
                                borderRadius: BorderRadius.circular(4),
                                color: AppTheme.backgroundColor,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  LucideIcons.settings,
                                  size: 14,
                                  color: AppTheme.primaryBlue,
                                ),
                                onPressed: () {
                                  dialogSetState(() {
                                    final randomNum =
                                        10000 +
                                        (DateTime.now().millisecond % 90000);
                                    _vendNumberController.text =
                                        'VEN-$randomNum';
                                  });
                                },
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        fixHeight: false,
                      ),

                      // Phone
                      _dialogFieldRow(
                        _dialogLabel('Phone', showInfo: true),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 75,
                                    height: 36,
                                    child: FormDropdown<String>(
                                      value: _vendWorkPhoneCode,
                                      items: _phoneCodes,
                                      onChanged: (v) {
                                        if (v != null)
                                          dialogSetState(
                                            () => _vendWorkPhoneCode = v,
                                          );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: CustomTextField(
                                        controller: _vendWorkPhoneController,
                                        hintText: 'Work Phone',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 75,
                                    height: 36,
                                    child: FormDropdown<String>(
                                      value: _vendMobilePhoneCode,
                                      items: _phoneCodes,
                                      onChanged: (v) {
                                        if (v != null)
                                          dialogSetState(
                                            () => _vendMobilePhoneCode = v,
                                          );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: CustomTextField(
                                        controller: _vendMobilePhoneController,
                                        hintText: 'Mobile',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        fixHeight: false,
                      ),

                      // Vendor Language
                      _dialogFieldRow(
                        _dialogLabel('Vendor Language', showInfo: true),
                        FormDropdown<String>(
                          value: _vendLanguage,
                          items: _languages,
                          onChanged: (v) {
                            if (v != null)
                              dialogSetState(() => _vendLanguage = v);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Middle Tabs
                      _buildVendorMiddleTabs(dialogSetState),
                      const SizedBox(height: 0),

                      // Tab Content
                      _buildVendorTabContent(dialogSetState, context),
                      const SizedBox(height: 24),

                      const Divider(color: AppTheme.borderColor),
                      const SizedBox(height: 16),

                      // Footer Save & Cancel
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              final displayName = _vendDisplayNameController
                                  .text
                                  .trim();
                              final vendorNo = _vendNumberController.text
                                  .trim();

                              if (displayName.isEmpty) {
                                ZerpaiToast.error(
                                  context,
                                  'Display Name is required',
                                );
                                return;
                              }
                              if (vendorNo.isEmpty) {
                                ZerpaiToast.error(
                                  context,
                                  'Vendor Number is required',
                                );
                                return;
                              }
                              if (_vendGstTreatment ==
                                  'Select a GST treatment') {
                                ZerpaiToast.error(
                                  context,
                                  'GST Treatment is required',
                                );
                                return;
                              }
                              if (_vendSourceOfSupply ==
                                  'Select source of supply') {
                                ZerpaiToast.error(
                                  context,
                                  'Source of Supply is required',
                                );
                                return;
                              }
                              if (_vendPriceList == 'Select a price list') {
                                ZerpaiToast.error(
                                  context,
                                  'Price List is required',
                                );
                                return;
                              }

                              final newItem = VendorItem(
                                name: displayName,
                                code: vendorNo,
                                email:
                                    _vendEmailController.text.trim().isNotEmpty
                                    ? _vendEmailController.text.trim()
                                    : null,
                              );

                              setState(() {
                                _vendorsList.add(newItem);
                                _selectedVendorItem = newItem;
                                _selectedVendorId = vendorNo;
                                _applyVendorLinkedDropdownSelections(
                                  gstTreatment:
                                      _vendGstTreatment ==
                                          'Select a GST treatment'
                                      ? null
                                      : _vendGstTreatment,
                                  sourceOfSupply:
                                      _vendSourceOfSupply ==
                                          'Select source of supply'
                                      ? null
                                      : _vendSourceOfSupply,
                                );
                              });

                              ZerpaiToast.success(
                                context,
                                'Vendor created successfully',
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentGreen,
                              foregroundColor: AppTheme.backgroundColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textBody,
                              side: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVendorMiddleTabs(StateSetter dialogSetState) {
    final tabs = [
      'Other Details',
      'Address',
      'Bank Details',
      'Custom Fields',
      'Reporting Tags',
      'Remarks',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: tabs.map((tab) {
            final isSelected = _vendActiveTab == tab;
            return InkWell(
              onTap: () {
                dialogSetState(() {
                  _vendActiveTab = tab;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryBlueDark
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primaryBlueDark
                        : AppTheme.textSubtle,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
      ],
    );
  }

  Widget _buildVendorTabContent(
    StateSetter dialogSetState,
    BuildContext context,
  ) {
    switch (_vendActiveTab) {
      case 'Other Details':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogFieldRow(
              _dialogLabel('GST Treatment', required: true),
              FormDropdown<String>(
                value: _vendGstTreatment,
                items: _gstTreatmentsList,
                onChanged: (v) {
                  if (v != null) dialogSetState(() => _vendGstTreatment = v);
                },
              ),
            ),
            _dialogFieldRow(
              _dialogLabel('Source of Supply', required: true),
              FormDropdown<String>(
                value: _vendSourceOfSupply,
                items: const [
                  'Select source of supply',
                  'State/Province',
                  'Union Territory',
                ],
                onChanged: (v) {
                  if (v != null) dialogSetState(() => _vendSourceOfSupply = v);
                },
              ),
            ),
            _dialogFieldRow(
              _dialogLabel('PAN', showInfo: true),
              CustomTextField(controller: _vendPanController, hintText: ''),
            ),
            _dialogFieldRow(
              _dialogLabel('MSME Registered?', showInfo: true),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: Checkbox(
                      value: _vendMsmeRegistered,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (v) => dialogSetState(
                        () => _vendMsmeRegistered = v ?? false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'This vendor is MSME registered',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              fixHeight: false,
            ),
            _dialogFieldRow(
              _dialogLabel('Currency'),
              FormDropdown<String>(
                value: _vendCurrency,
                items: _currenciesList,
                onChanged: (v) {
                  if (v != null) dialogSetState(() => _vendCurrency = v);
                },
              ),
            ),
            _dialogFieldRow(
              _dialogLabel('Payment Terms'),
              FormDropdown<String>(
                value: _vendPaymentTerms,
                items: _paymentTermsList,
                onChanged: (v) {
                  if (v != null) dialogSetState(() => _vendPaymentTerms = v);
                },
              ),
            ),
            _dialogFieldRow(
              _dialogLabel('TDS'),
              FormDropdown<String>(
                value: _vendTds,
                items: _taxes,
                hint: 'Select a Tax',
                onChanged: (v) {
                  if (v != null) dialogSetState(() => _vendTds = v);
                },
              ),
            ),
            _dialogFieldRow(
              _dialogLabel('Price List', required: true),
              FormDropdown<String>(
                value: _vendPriceList,
                items: _priceLists,
                onChanged: (v) {
                  if (v != null) dialogSetState(() => _vendPriceList = v);
                },
              ),
            ),
            _dialogFieldRow(
              _dialogLabel('Enable Portal?', showInfo: true),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: Checkbox(
                      value: _vendEnablePortal,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (v) =>
                          dialogSetState(() => _vendEnablePortal = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Allow portal access for this vendor',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            _dialogFieldRow(
              _dialogLabel('Documents'),
              _buildVendorUploadButton(dialogSetState, context),
              fixHeight: false,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      ZerpaiToast.success(
                        context,
                        'No additional details tabs configured',
                      );
                    },
                    child: const Text(
                      'Add more details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 'Address':
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Billing Address',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _addressFieldRow(
                          'Attention',
                          CustomTextField(
                            controller: _vendBillAttention,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'Country/Region',
                          FormDropdown<String>(
                            value: _vendBillCountry,
                            items: const [
                              'India',
                              'United States',
                              'United Kingdom',
                              'Canada',
                              'United Arab Emirates',
                            ],
                            hint: 'Select',
                            showSearch: false,
                            onChanged: (v) =>
                                dialogSetState(() => _vendBillCountry = v),
                          ),
                        ),
                        _addressFieldRow(
                          'Address',
                          Column(
                            children: [
                              SizedBox(
                                height: 50,
                                child: CustomTextField(
                                  controller: _vendBillStreet1,
                                  hintText: 'Street 1',
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 50,
                                child: CustomTextField(
                                  controller: _vendBillStreet2,
                                  hintText: 'Street 2',
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                          fixHeight: false,
                        ),
                        _addressFieldRow(
                          'City',
                          CustomTextField(
                            controller: _vendBillCity,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'State',
                          FormDropdown<String>(
                            value: _vendBillState,
                            items: const [
                              'Kerala',
                              'Tamil Nadu',
                              'Karnataka',
                              'Maharashtra',
                              'Delhi',
                            ],
                            hint: 'Select or type to add',
                            allowCustomValue: true,
                            showSearch: true,
                            onChanged: (v) =>
                                dialogSetState(() => _vendBillState = v),
                          ),
                        ),
                        _addressFieldRow(
                          'Pin Code',
                          CustomTextField(
                            controller: _vendBillPinCode,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'Phone',
                          CustomTextField(
                            controller: _vendBillPhone,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'Fax',
                          CustomTextField(
                            controller: _vendBillFax,
                            hintText: '',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Shipping Address',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                dialogSetState(() {
                                  _vendShipAttention.text =
                                      _vendBillAttention.text;
                                  _vendShipCountry = _vendBillCountry;
                                  _vendShipStreet1.text = _vendBillStreet1.text;
                                  _vendShipStreet2.text = _vendBillStreet2.text;
                                  _vendShipCity.text = _vendBillCity.text;
                                  _vendShipState = _vendBillState;
                                  _vendShipPinCode.text = _vendBillPinCode.text;
                                  _vendShipPhone.text = _vendBillPhone.text;
                                  _vendShipFax.text = _vendBillFax.text;
                                });
                                ZerpaiToast.success(
                                  context,
                                  'Billing address copied to shipping address',
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    '( ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_downward,
                                    size: 12,
                                    color: AppTheme.primaryBlue,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'Copy billing address',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryBlue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  Text(
                                    ' )',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _addressFieldRow(
                          'Attention',
                          CustomTextField(
                            controller: _vendShipAttention,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'Country/Region',
                          FormDropdown<String>(
                            value: _vendShipCountry,
                            items: const [
                              'India',
                              'United States',
                              'United Kingdom',
                              'Canada',
                              'United Arab Emirates',
                            ],
                            hint: 'Select',
                            showSearch: false,
                            onChanged: (v) =>
                                dialogSetState(() => _vendShipCountry = v),
                          ),
                        ),
                        _addressFieldRow(
                          'Address',
                          Column(
                            children: [
                              SizedBox(
                                height: 50,
                                child: CustomTextField(
                                  controller: _vendShipStreet1,
                                  hintText: 'Street 1',
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 50,
                                child: CustomTextField(
                                  controller: _vendShipStreet2,
                                  hintText: 'Street 2',
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                          fixHeight: false,
                        ),
                        _addressFieldRow(
                          'City',
                          CustomTextField(
                            controller: _vendShipCity,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'State',
                          FormDropdown<String>(
                            value: _vendShipState,
                            items: const [
                              'Kerala',
                              'Tamil Nadu',
                              'Karnataka',
                              'Maharashtra',
                              'Delhi',
                            ],
                            hint: 'Select or type to add',
                            allowCustomValue: true,
                            showSearch: true,
                            onChanged: (v) =>
                                dialogSetState(() => _vendShipState = v),
                          ),
                        ),
                        _addressFieldRow(
                          'Pin Code',
                          CustomTextField(
                            controller: _vendShipPinCode,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'Phone',
                          CustomTextField(
                            controller: _vendShipPhone,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'Fax',
                          CustomTextField(
                            controller: _vendShipFax,
                            hintText: '',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildAddressNote(),
            ],
          ),
        );

      case 'Bank Details':
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Add your vendor's bank details and make payments.",
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    ZerpaiToast.info(
                      context,
                      'Bank Account addition is coming soon',
                    );
                  },
                  child: const Text(
                    '+ Add Bank Account',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );

      case 'Custom Fields':
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogFieldRow(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'demo feild',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(width: 4),
                    ZTooltip(message: 'This is a demo custom field.'),
                  ],
                ),
                CustomTextField(
                  controller: _vendDemoFieldController,
                  hintText: '',
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 12, height: 1.5),
                  children: [
                    TextSpan(
                      text: 'Note: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorRed,
                      ),
                    ),
                    TextSpan(
                      text:
                          'You can add additional fields for your Customers and Vendors and have these show up on your PDF by going to ',
                      style: TextStyle(color: AppTheme.textSubtle),
                    ),
                    TextSpan(
                      text: 'Settings ➔ Preferences ➔ Customers and Vendors',
                      style: TextStyle(
                        color: AppTheme.textSubtle,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    TextSpan(
                      text:
                          '. You can also refine the address format of your Customers and Vendors from there.',
                      style: TextStyle(color: AppTheme.textSubtle),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'Reporting Tags':
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogFieldRow(
                const Text(
                  'ADGF',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                FormDropdown<String>(
                  value: _vendAdgf,
                  items: const ['None'],
                  onChanged: (v) {
                    if (v != null) dialogSetState(() => _vendAdgf = v);
                  },
                ),
              ),
              _dialogFieldRow(
                const Text(
                  'shedule',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                FormDropdown<String>(
                  value: _vendSchedule,
                  items: const ['None'],
                  onChanged: (v) {
                    if (v != null) dialogSetState(() => _vendSchedule = v);
                  },
                ),
              ),
              _dialogFieldRow(
                const Text(
                  'demo adavced\nreporting tag',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
                FormDropdown<String>(
                  value: _vendDemoAdvanced,
                  items: const ['None'],
                  onChanged: (v) {
                    if (v != null) dialogSetState(() => _vendDemoAdvanced = v);
                  },
                ),
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            ],
          ),
        );

      case 'Remarks':
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Remarks (For Internal Use)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _vendRemarksController,
                hintText: '',
                maxLines: 4,
                height: 90,
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// The receipt upload card, rendered separately and positioned top-right.
  Widget _buildReceiptCard() {
    return ExpenseAttachmentCardWidget(
      attachments:
          _editingExpense?.attachments ?? const <ExpenseAttachmentModel>[],
      onDelete: _editingExpense == null ? null : _deleteExistingAttachment,
      onUploadTap: _pickFile,
      enableHeaderUpload: true,
      width: _receiptCardWidth,
      height: _receiptCardHeight,
    );
  }

  // ── Record Mileage ────────────────────────────────────────────

  double _calculateDistance() {
    if (_calculationMethod == 'Distance travelled') {
      return double.tryParse(_distanceController.text.trim()) ?? 0.0;
    } else {
      final start =
          double.tryParse(_startOdometerController.text.trim()) ?? 0.0;
      final end = double.tryParse(_endOdometerController.text.trim()) ?? 0.0;
      final dist = end - start;
      return dist < 0 ? 0.0 : dist;
    }
  }

  double? _parseOdometerValue(TextEditingController controller) {
    final raw = controller.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw);
  }

  bool get _isEndOdometerInvalid {
    final start = _parseOdometerValue(_startOdometerController);
    final end = _parseOdometerValue(_endOdometerController);
    if (start == null || end == null) {
      return false;
    }
    return end < start;
  }

  String _formatOdometerInput(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  void _handleEndOdometerFocusChange() {
    if (_endOdometerFocusNode.hasFocus) {
      return;
    }
    _autocorrectEndOdometerIfNeeded();
  }

  void _autocorrectEndOdometerIfNeeded() {
    if (!_isEndOdometerInvalid) {
      return;
    }
    final start = _parseOdometerValue(_startOdometerController);
    if (start == null) {
      return;
    }
    final correctedValue = _formatOdometerInput(start);
    _endOdometerController
      ..text = correctedValue
      ..selection = TextSelection.collapsed(offset: correctedValue.length);
    _updateMileageAmount();
  }

  String _formatMileageRateInput(double value) {
    if (value <= 0) {
      return '';
    }
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _formatMileageRateDisplay(double value) {
    if (value <= 0) {
      return '0';
    }
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  MileageRateRow _resolveEditableMileageRateRow(DateTime date) {
    if (_mileageRates.isEmpty) {
      final row = MileageRateRow();
      _mileageRates.add(row);
      return row;
    }

    MileageRateRow? defaultRow;
    MileageRateRow? matchingRow;
    DateTime? matchingDate;

    for (final row in _mileageRates) {
      if (row.startDate == null) {
        defaultRow ??= row;
        continue;
      }
      if (!row.startDate!.isAfter(date) &&
          (matchingDate == null || row.startDate!.isAfter(matchingDate))) {
        matchingDate = row.startDate;
        matchingRow = row;
      }
    }

    return matchingRow ?? defaultRow ?? _mileageRates.first;
  }

  Widget _buildMileageRateHint() {
    final currentRate = _getApplicableMileageRate(_selectedDate);
    final unitLabel = _mileageUnit == 'Km' ? 'km' : 'mile';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Rate per $unitLabel = ₹${_formatMileageRateDisplay(currentRate)}',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _showMileagePreferencesDialog(context),
          child: const Text(
            'Change',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryBlueDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMileageDistanceFieldRow({required Widget field}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _expenseCreateLabelWidth,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _label('Distance', required: true),
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _expenseCreateStandardFieldWidth,
                ),
                child: field,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: _expenseCreateLabelWidth + 12,
              top: 6,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _expenseCreateStandardFieldWidth,
              ),
              child: _buildMileageRateHint(),
            ),
          ),
        ],
      ),
    );
  }

  void _updateMileageAmount() {
    final distance = _calculateDistance();
    final rate = _getApplicableMileageRate(_selectedDate);
    final amt = distance * rate;
    setState(() {
      if (_calculationMethod == 'Odometer reading') {
        _distanceController.text = distance <= 0
            ? ''
            : distance.toStringAsFixed(2);
      }
      _mileageAmountController.text = amt.toStringAsFixed(2);
    });
  }

  double _getApplicableMileageRate(DateTime date) {
    double? defaultRate;
    double? matchingRate;
    DateTime? matchingDate;

    for (final row in _mileageRates) {
      final rateVal = double.tryParse(row.rateController.text.trim()) ?? 0.0;
      if (row.startDate == null) {
        defaultRate = rateVal;
      } else {
        if (!row.startDate!.isAfter(date)) {
          if (matchingDate == null || row.startDate!.isAfter(matchingDate)) {
            matchingDate = row.startDate;
            matchingRate = rateVal;
          }
        }
      }
    }
    return matchingRate ?? defaultRate ?? 0.0;
  }

  Widget _buildRecordMileageForm() {
    final employeesAsync = ref.watch(mileageEmployeesProvider);
    final employeeOptions =
        employeesAsync.asData?.value ?? const <ExpenseEmployeeOption>[];

    return Form(
      key: _mileageFormKey,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upper Section (Grey background)
              Container(
                color: AppTheme.bgLight,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
                      _fieldRow(
                        _label('Date', required: true),
                        ZExpensesDatePicker(
                          selectedDate: _selectedDate,
                          onDateSelected: (d) {
                            setState(() {
                              _selectedDate = d;
                              _updateMileageAmount();
                            });
                          },
                        ),
                      ),

                      // Employee
                      _fieldRow(
                        _label('Employee'),
                        FormDropdown<ExpenseEmployeeOption>(
                          value: _selectedEmployeeOption(employeeOptions),
                          items: employeeOptions,
                          hint: employeesAsync.isLoading
                              ? 'Loading Employees...'
                              : employeeOptions.isEmpty
                              ? 'No Employees Found'
                              : 'Select an Employee',
                          isLoading: employeesAsync.isLoading,
                          displayStringForValue: (item) => item.fullName,
                          onChanged: (v) =>
                              setState(() => _selectedEmployee = v?.id),
                        ),
                      ),

                      _fieldRow(
                        _label('Vehicle'),
                        FormDropdown<String>(
                          value: _selectedVehicle,
                          items: _vehicles,
                          hint: 'Select a Vehicle',
                          onChanged: (v) =>
                              setState(() => _selectedVehicle = v),
                        ),
                      ),

                      // Calculate mileage using
                      _fieldRow(
                        _label('Calculate mileage using', required: true),
                        RadioGroup<String>(
                          groupValue: _calculationMethod,
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _calculationMethod = v;
                                _updateMileageAmount();
                              });
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: 'Distance travelled',
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Distance travelled',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Radio<String>(
                                value: 'Odometer reading',
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Odometer reading',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        fixHeight: false,
                        fieldWidth: _expenseCreateStandardFieldWidth,
                      ),

                      if (_calculationMethod == 'Distance travelled') ...[
                        // Distance
                        _buildMileageDistanceFieldRow(
                          field: MileageDistanceInputField(
                            controller: _distanceController,
                            unitLabel: _mileageUnit == 'Km'
                                ? 'Kilometer(s)'
                                : 'Mile(s)',
                            onChanged: (v) => _updateMileageAmount(),
                          ),
                        ),
                      ] else ...[
                        // Odometer reading
                        _fieldRow(
                          _label('Odometer reading', required: true),
                          SizedBox(
                            width: _expenseCreateStandardFieldWidth,
                            child: Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _startOdometerController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    hintText: 'Start reading',
                                    onChanged: (v) => _updateMileageAmount(),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'To',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: CustomTextField(
                                    controller: _endOdometerController,
                                    focusNode: _endOdometerFocusNode,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    hintText: 'End reading',
                                    border: _isEndOdometerInvalid
                                        ? Border.all(
                                            color: AppTheme.errorRed,
                                            width: 1,
                                          )
                                        : null,
                                    onChanged: (v) => _updateMileageAmount(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          fixHeight: false,
                          fieldWidth: _expenseCreateStandardFieldWidth,
                        ),
                        // Distance (read-only in odometer mode)
                        _buildMileageDistanceFieldRow(
                          field: Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _distanceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  hintText: '',
                                  readOnly: true,
                                ),
                              ),
                              Container(
                                height: _expenseCreateCompactFieldHeight,
                                margin: const EdgeInsets.only(left: 8),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgLight,
                                  border: Border.all(
                                    color: AppTheme.borderColor,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _mileageUnit == 'Km'
                                      ? 'Kilometer(s)'
                                      : 'Mile(s)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Amount
                      _fieldRow(
                        _label('Amount', required: true),
                        CustomTextField(
                          controller: _mileageAmountController,
                          readOnly: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          prefixBox: true,
                          prefixWidget: const Text(
                            'INR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        fieldWidth: _expenseCreateStandardFieldWidth,
                      ),
                    ],
                  ),
                ),
              ),

              // Lower Section (White background)
              Container(
                color: AppTheme.backgroundColor,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldRow(
                      _label('Paid Through', required: true),
                      SizedBox(
                        width: _expenseCreateStandardFieldWidth,
                        child: AccountTreeDropdownWithAddButton(
                          value: _selectedPaidThroughAccountId,
                          nodes: _paidThroughAccountsList,
                          height: _expenseCreateCompactFieldHeight,
                          hint: 'Select an account',
                          highlightSearchMatches: false,
                          onChanged: (value) {
                            setState(
                              () => _selectedPaidThroughAccountId = value,
                            );
                          },
                          onAddAccount: () async {
                            final createdAccountName =
                                await AddAccountDialog.show(context);
                            if (createdAccountName != null && mounted) {
                              ref.invalidate(chartOfAccountsProvider);
                            }
                          },
                        ),
                      ),
                      fixHeight: false,
                      fieldWidth: _expenseCreateStandardFieldWidth,
                    ),

                    if (!_isItemized)
                      _fieldRow(
                        _label('SAC'),
                        CustomTextField(
                          controller: _sacController,
                          hintText: '',
                        ),
                      ),

                    // Vendor + search button
                    _fieldRow(
                      _label('Vendor'),
                      SizedBox(
                        width: _expenseCreateLookupFieldWidth,
                        child: Row(
                          children: [
                            SizedBox(
                              width: _expenseCreateLookupInputWidth,
                              child: VendorDropdownWidget(
                                value: _selectedVendorOption,
                                items: _vendorOptions,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  bottomLeft: Radius.circular(4),
                                ),
                                onAddVendor: () =>
                                    _showNewVendorDialog(context),
                                onChanged: (value) {
                                  final selectedItem = value == null
                                      ? null
                                      : VendorItem(
                                          name: value.displayName,
                                          code: value.id,
                                          extraSubtitle: value.companyName,
                                        );
                                  setState(() {
                                    _selectedVendorItem = selectedItem;
                                    _selectedVendorId =
                                        _resolveSelectedVendorId(value);
                                    _applyVendorLinkedDropdownSelections(
                                      gstTreatment: value?.gstTreatment,
                                      sourceOfSupply: value?.sourceOfSupply,
                                    );
                                  });
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: _expenseCreateLookupActionWidth,
                                height: _expenseCreateCompactFieldHeight,
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentGreen,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.search,
                                  size: 16,
                                  color: AppTheme.backgroundColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      fixHeight: false,
                      fieldWidth: _expenseCreateLookupFieldWidth,
                    ),

                    // GST Treatment
                    _fieldRow(
                      _label('GST Treatment', required: true),
                      _buildRecurringStyleGstTreatmentDropdown(
                        onChanged: (v) {
                          setState(() {
                            _applyGstTreatmentSelection(v);
                          });
                        },
                      ),
                    ),

                    if (_showVendorGstin)
                      _fieldRow(
                        _parityLabel(
                          'Vendor GSTIN',
                          required: _vendorGstinRequired,
                        ),
                        SizedBox(
                          width: _expenseCreateRecurringCompositeFieldWidth,
                          child: Row(
                            children: [
                              SizedBox(
                                width: _expenseCreateStandardFieldWidth,
                                child: CustomTextField(
                                  controller: _vendorGstinController,
                                  height: _expenseCreateCompactFieldHeight,
                                  forceUppercase: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.infoBlue,
                                  padding: EdgeInsets.zero,
                                  textStyle: AppTextStyles.body.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                                child: const Text('Get Taxpayer details'),
                              ),
                            ],
                          ),
                        ),
                        fixHeight: false,
                        fieldWidth: _expenseCreateRecurringCompositeFieldWidth,
                        verticalPadding: _expenseCreateDenseRowVerticalPadding,
                      ),

                    // Source of Supply
                    if (_showSourceOfSupply)
                      _fieldRow(
                        _label('Source of Supply', required: true),
                        FormDropdown<StateLookupModel>(
                          value: _selectedStateOption(_sourceOfSupply),
                          items: _stateCatalog,
                          hint: _stateCatalog.isEmpty
                              ? 'No States Found'
                              : 'Select source state',
                          displayStringForValue: (item) => item.displayLabel,
                          onChanged: (v) {
                            setState(() {
                              _applySourceOfSupplySelection(v);
                            });
                          },
                        ),
                      ),

                    // Destination of Supply
                    if (_showDestinationOfSupply)
                      _fieldRow(
                        _label('Destination of Supply', required: true),
                        FormDropdown<StateLookupModel>(
                          value: _selectedStateOption(_destinationOfSupply),
                          items: _stateCatalog,
                          hint: _stateCatalog.isEmpty
                              ? 'No States Found'
                              : 'State/Province',
                          displayStringForValue: (item) => item.displayLabel,
                          onChanged: (v) {
                            setState(() {
                              _destinationOfSupply = v?.name ?? '';
                              _pruneHiddenTaxSelections();
                            });
                          },
                        ),
                      ),

                    if (_showReverseCharge)
                      _fieldRow(
                        _label('Reverse Charge'),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: Checkbox(
                                value: _reverseCharge,
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) => setState(() {
                                  _reverseCharge = v ?? false;
                                  if (_reverseCharge) {
                                    _amountIs = 'Tax Exclusive';
                                  }
                                }),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'This transaction is applicable for reverse charge',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        fixHeight: false,
                        fieldWidth: 340,
                      ),

                    if (_showTax) ...[
                      _fieldRow(
                        _label('Tax', required: _taxRequired),
                        _buildRecurringStyledTaxDropdown(
                          amountText: _mileageAmountController.text,
                        ),
                        fixHeight: false,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                      if (_showExemptionReasonField)
                        _fieldRow(
                          _label('Exemption Reason', required: true),
                          CustomTextField(
                            controller: _exemptionReasonController,
                            hintText: '',
                            errorText: _exemptionReasonErrorText,
                            onChanged: (value) {
                              if (_exemptionReasonErrorText != null &&
                                  value.trim().isNotEmpty) {
                                setState(() {
                                  _exemptionReasonErrorText = null;
                                });
                              }
                            },
                          ),
                        ),
                    ],

                    if (_showAmountIs && !_reverseCharge)
                      _fieldRow(
                        _label('Amounts are'),
                        RadioGroup<String>(
                          groupValue: _amountIs,
                          onChanged: (v) {
                            if (v != null) setState(() => _amountIs = v);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: 'Tax Inclusive',
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'Tax Inclusive',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Radio<String>(
                                value: 'Tax Exclusive',
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'Tax Exclusive',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        fixHeight: false,
                        fieldWidth: 280,
                      ),

                    // Invoice#
                    _fieldRow(
                      _label('Invoice#'),
                      CustomTextField(
                        controller: _invoiceController,
                        hintText: '',
                      ),
                    ),

                    // Notes
                    _fieldRow(
                      _label('Notes'),
                      CustomTextField(
                        controller: _notesController,
                        hintText: 'Max. 500 characters',
                        maxLines: 4,
                        height: 80,
                      ),
                      fixHeight: false,
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: AppTheme.borderColor),
                    const SizedBox(height: 24),

                    _buildRecurringStyledCustomerFieldRow(),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: _receiptCardTopOffset,
            right: _receiptCardRightOffset,
            child: _buildReceiptCard(),
          ),
        ],
      ),
    );
  }

  // ── Record Mileage Preferences Dialog ───────────────────────

  void _showMileagePreferencesDialog(BuildContext context) {
    final targetRow = _resolveEditableMileageRateRow(_selectedDate);
    final rateController = TextEditingController(
      text: targetRow.rateController.text.trim().isNotEmpty
          ? targetRow.rateController.text.trim()
          : _formatMileageRateInput(_getApplicableMileageRate(_selectedDate)),
    );
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          alignment: Alignment.topCenter,
          backgroundColor: AppTheme.backgroundColor,
          insetPadding: const EdgeInsets.fromLTRB(0, 140, 0, 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: StatefulBuilder(
            builder: (context, dialogSetState) {
              return Container(
                width: 340,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                      decoration: const BoxDecoration(
                        color: AppTheme.bgLight,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        border: Border(
                          bottom: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Edit Mileage Rate',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                LucideIcons.x,
                                size: 18,
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Mileage rate (in INR)*',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.errorRed,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: CustomTextField(
                              controller: rateController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              height: _expenseCreateCompactFieldHeight,
                              hintText: '',
                              errorText: errorText,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ZButton.primary(
                            label: 'Save',
                            onPressed: () {
                              final parsed = double.tryParse(
                                rateController.text.trim(),
                              );
                              if (parsed == null) {
                                dialogSetState(() {
                                  errorText = 'Mileage rate is required';
                                });
                                return;
                              }
                              if (parsed <= 0) {
                                dialogSetState(() {
                                  errorText =
                                      'Mileage rate must be greater than zero';
                                });
                                return;
                              }
                              targetRow.rateController.text =
                                  _formatMileageRateInput(parsed);
                              _updateMileageAmount();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((_) => rateController.dispose());
  }

  void _showNewCustomerDialog(BuildContext context) {
    // Reset dialog fields on entry
    _custType = 'Individual';
    _custSalutation = 'Salutation';
    _custFirstNameController.clear();
    _custLastNameController.clear();
    _custCompanyNameController.clear();
    _custDisplayNameController.clear();
    _custEmailController.clear();
    _custNumberController.text = 'CUS-00023';
    _custWorkPhoneCode = '+91';
    _custWorkPhoneController.clear();
    _custMobilePhoneCode = '+91';
    _custMobilePhoneController.clear();
    _custLanguage = 'English';
    _custActiveTab = 'Other Details';

    _custGstTreatment = 'Select a GST treatment';
    _custPlaceOfSupply = 'Select place of supply';
    _custPanController.clear();
    _custTaxPreference = 'Taxable';
    _custCurrency = 'INR- Indian Rupee';
    _custCreditLimitController.clear();
    _custPaymentTerms = 'Net 360';
    _custPriceList = 'Select a price list';
    _custEnablePortal = false;
    _custUploadedFiles = [];
    _custDemoFieldController.clear();
    _custRemarksController.clear();
    _custAdgf = 'None';
    _custSchedule = 'None';
    _custDemoAdvanced = 'None';

    _custBillAttention.clear();
    _custBillCountry = null;
    _custBillStreet1.clear();
    _custBillStreet2.clear();
    _custBillCity.clear();
    _custBillState = null;
    _custBillPinCode.clear();
    _custBillPhone.clear();
    _custBillFax.clear();

    _custShipAttention.clear();
    _custShipCountry = null;
    _custShipStreet1.clear();
    _custShipStreet2.clear();
    _custShipCity.clear();
    _custShipState = null;
    _custShipPinCode.clear();
    _custShipPhone.clear();
    _custShipFax.clear();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          alignment: Alignment.topCenter,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
          child: StatefulBuilder(
            builder: (context, dialogSetState) {
              return Container(
                width: 750,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header: Title + Close Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'New Customer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warningTextDark,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 20,
                              color: AppTheme.errorRed,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Customer Type
                      _dialogFieldRow(
                        _dialogLabel('Customer Type', showInfo: true),
                        RadioGroup<String>(
                          groupValue: _custType,
                          onChanged: (v) {
                            if (v != null) dialogSetState(() => _custType = v);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: 'Business',
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'Business',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Radio<String>(
                                value: 'Individual',
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'Individual',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        fixHeight: false,
                      ),

                      // Primary Contact
                      _dialogFieldRow(
                        _dialogLabel('Primary Contact', showInfo: true),
                        Row(
                          children: [
                            SizedBox(
                              width: 110,
                              height: 36,
                              child: FormDropdown<String>(
                                value: _custSalutation == 'Salutation'
                                    ? null
                                    : _custSalutation,
                                items: const [
                                  'Mr.',
                                  'Mrs.',
                                  'Ms.',
                                  'Miss',
                                  'Dr.',
                                ],
                                hint: 'Salutation',
                                showSearch: false,
                                onChanged: (v) {
                                  if (v != null)
                                    dialogSetState(() => _custSalutation = v);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: CustomTextField(
                                  controller: _custFirstNameController,
                                  hintText: 'First Name',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: CustomTextField(
                                  controller: _custLastNameController,
                                  hintText: 'Last Name',
                                ),
                              ),
                            ),
                          ],
                        ),
                        fixHeight: false,
                      ),

                      // Company Name
                      _dialogFieldRow(
                        _dialogLabel('Company Name'),
                        CustomTextField(
                          controller: _custCompanyNameController,
                          hintText: '',
                        ),
                      ),

                      // Display Name*
                      _dialogFieldRow(
                        _dialogLabel(
                          'Display Name',
                          required: true,
                          showInfo: true,
                        ),
                        CustomTextField(
                          controller: _custDisplayNameController,
                          hintText: 'Select or type to add',
                        ),
                      ),

                      // Email Address
                      _dialogFieldRow(
                        _dialogLabel('Email Address', showInfo: true),
                        CustomTextField(
                          controller: _custEmailController,
                          hintText: '',
                          prefixIcon: LucideIcons.mail,
                        ),
                      ),

                      // Customer Number*
                      _dialogFieldRow(
                        _dialogLabel('Customer Number', required: true),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _custNumberController,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.borderColor),
                                borderRadius: BorderRadius.circular(4),
                                color: AppTheme.backgroundColor,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  LucideIcons.settings,
                                  size: 14,
                                  color: AppTheme.primaryBlue,
                                ),
                                onPressed: () {
                                  dialogSetState(() {
                                    final randomNum =
                                        10000 +
                                        (DateTime.now().millisecond % 90000);
                                    _custNumberController.text =
                                        'CUS-$randomNum';
                                  });
                                },
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        fixHeight: false,
                      ),

                      // Phone
                      _dialogFieldRow(
                        _dialogLabel('Phone', showInfo: true),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 75,
                                    height: 36,
                                    child: FormDropdown<String>(
                                      value: _custWorkPhoneCode,
                                      items: _phoneCodes,
                                      onChanged: (v) {
                                        if (v != null)
                                          dialogSetState(
                                            () => _custWorkPhoneCode = v,
                                          );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: CustomTextField(
                                        controller: _custWorkPhoneController,
                                        hintText: 'Work Phone',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 75,
                                    height: 36,
                                    child: FormDropdown<String>(
                                      value: _custMobilePhoneCode,
                                      items: _phoneCodes,
                                      onChanged: (v) {
                                        if (v != null)
                                          dialogSetState(
                                            () => _custMobilePhoneCode = v,
                                          );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: CustomTextField(
                                        controller: _custMobilePhoneController,
                                        hintText: 'Mobile',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        fixHeight: false,
                      ),

                      // Customer Language
                      _dialogFieldRow(
                        _dialogLabel('Customer Language', showInfo: true),
                        FormDropdown<String>(
                          value: _custLanguage,
                          items: _languages,
                          onChanged: (v) {
                            if (v != null)
                              dialogSetState(() => _custLanguage = v);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Middle Tabs
                      _buildMiddleTabs(dialogSetState),
                      const SizedBox(height: 16),

                      // Tab Content
                      _buildTabContent(dialogSetState, context),
                      const SizedBox(height: 24),

                      const Divider(color: AppTheme.borderColor),
                      const SizedBox(height: 16),

                      // Footer Save & Cancel
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              final displayName = _custDisplayNameController
                                  .text
                                  .trim();
                              final customerNo = _custNumberController.text
                                  .trim();

                              if (displayName.isEmpty) {
                                ZerpaiToast.error(
                                  context,
                                  'Display Name is required',
                                );
                                return;
                              }
                              if (customerNo.isEmpty) {
                                ZerpaiToast.error(
                                  context,
                                  'Customer Number is required',
                                );
                                return;
                              }
                              if (_custGstTreatment ==
                                  'Select a GST treatment') {
                                ZerpaiToast.error(
                                  context,
                                  'GST Treatment is required',
                                );
                                return;
                              }
                              if (_custPlaceOfSupply ==
                                  'Select place of supply') {
                                ZerpaiToast.error(
                                  context,
                                  'Place of Supply is required',
                                );
                                return;
                              }
                              if (_custPriceList == 'Select a price list') {
                                ZerpaiToast.error(
                                  context,
                                  'Price List is required',
                                );
                                return;
                              }

                              // Success path
                              setState(() {
                                _selectedCustomer = displayName;
                                _selectedCustomerId = null;
                              });
                              ZerpaiToast.success(
                                context,
                                'Customer created successfully',
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentGreen,
                              foregroundColor: AppTheme.backgroundColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textBody,
                              side: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _dialogFieldRow(
    Widget label,
    Widget field, {
    bool fixHeight = true,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double fieldWidth = 480,
  }) {
    Widget content = fixHeight ? SizedBox(height: 36, child: field) : field;
    content = SizedBox(width: fieldWidth, child: content);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          SizedBox(
            width: 160,
            child: Align(alignment: Alignment.centerLeft, child: label),
          ),
          const SizedBox(width: 16),
          content,
        ],
      ),
    );
  }

  Widget _addressFieldRow(String label, Widget field, {bool fixHeight = true}) {
    final content = fixHeight ? SizedBox(height: 36, child: field) : field;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _dialogLabel(
    String text, {
    bool required = false,
    bool showInfo = false,
  }) {
    final textStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: required ? AppTheme.errorRed : AppTheme.textPrimary,
    );

    final textWidget = required
        ? RichText(
            text: TextSpan(
              children: [
                TextSpan(text: text, style: textStyle),
                const TextSpan(
                  text: '*',
                  style: TextStyle(color: AppTheme.errorRed, fontSize: 13),
                ),
              ],
            ),
          )
        : Text(text, style: textStyle);

    if (showInfo) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(child: textWidget),
          const SizedBox(width: 4),
          const Icon(LucideIcons.info, size: 13, color: AppTheme.textMuted),
        ],
      );
    }
    return textWidget;
  }

  Widget _buildMiddleTabs(StateSetter dialogSetState) {
    final tabs = [
      'Other Details',
      'Address',
      'Custom Fields',
      'Reporting Tags',
      'Remarks',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: tabs.map((tab) {
            final isSelected = _custActiveTab == tab;
            return InkWell(
              onTap: () {
                dialogSetState(() {
                  _custActiveTab = tab;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryBlueDark
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primaryBlueDark
                        : AppTheme.textSubtle,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
      ],
    );
  }

  Widget _buildTabContent(StateSetter dialogSetState, BuildContext context) {
    switch (_custActiveTab) {
      case 'Other Details':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogFieldRow(
              _dialogLabel('GST Treatment', required: true),
              FormDropdown<String>(
                value: _custGstTreatment,
                items: _gstTreatmentsList,
                onChanged: (v) {
                  if (v != null) dialogSetState(() => _custGstTreatment = v);
                },
              ),
            ),
            _dialogFieldRow(
              _dialogLabel('Place of Supply', required: true),
              FormDropdown<String>(
                value: _custPlaceOfSupply,
                items: _placesOfSupply,
                onChanged: (v) {
                  if (v != null) dialogSetState(() => _custPlaceOfSupply = v);
                },
              ),
            ),
            _dialogFieldRow(
              _dialogLabel('PAN', showInfo: true),
              CustomTextField(controller: _custPanController, hintText: ''),
            ),
            _dialogFieldRow(
              _dialogLabel('Tax Preference', required: true),
              RadioGroup<String>(
                groupValue: _custTaxPreference,
                onChanged: (v) {
                  if (v != null) dialogSetState(() => _custTaxPreference = v);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: 'Taxable',
                      activeColor: AppTheme.primaryBlue,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text(
                      'Taxable',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Radio<String>(
                      value: 'Tax Exempt',
                      activeColor: AppTheme.primaryBlue,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text(
                      'Tax Exempt',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              fixHeight: false,
            ),
            _dialogFieldRow(
              _dialogLabel('Currency'),
              FormDropdown<String>(
                value: _custCurrency,
                items: _currenciesList,
                onChanged: (v) {
                  if (v != null) dialogSetState(() => _custCurrency = v);
                },
              ),
            ),
            _dialogFieldRow(
              _dialogLabel('Credit Limit', showInfo: true),
              CustomTextField(
                controller: _custCreditLimitController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixBox: true,
                prefixWidget: const Text(
                  'INR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            _dialogFieldRow(
              _dialogLabel('Payment Terms'),
              FormDropdown<String>(
                value: _custPaymentTerms,
                items: _paymentTermsList,
                onChanged: (v) {
                  if (v != null) dialogSetState(() => _custPaymentTerms = v);
                },
              ),
            ),
            _dialogFieldRow(
              _dialogLabel('Price List', required: true),
              FormDropdown<String>(
                value: _custPriceList,
                items: _priceLists,
                onChanged: (v) {
                  if (v != null) dialogSetState(() => _custPriceList = v);
                },
              ),
            ),
            _dialogFieldRow(
              _dialogLabel('Enable Portal?', showInfo: true),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: Checkbox(
                      value: _custEnablePortal,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (v) =>
                          dialogSetState(() => _custEnablePortal = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Allow portal access for this customer',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            _dialogFieldRow(
              _dialogLabel('Documents'),
              _buildCustomerUploadButton(dialogSetState, context),
              fixHeight: false,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      ZerpaiToast.success(
                        context,
                        'No additional details tabs configured',
                      );
                    },
                    child: const Text(
                      'Add more details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'Address':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Billing Address',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _addressFieldRow(
                          'Attention',
                          CustomTextField(
                            controller: _custBillAttention,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'Country/Region',
                          FormDropdown<String>(
                            value: _custBillCountry,
                            items: const [
                              'India',
                              'United States',
                              'United Kingdom',
                              'Canada',
                              'United Arab Emirates',
                            ],
                            hint: 'Select',
                            showSearch: false,
                            onChanged: (v) =>
                                dialogSetState(() => _custBillCountry = v),
                          ),
                        ),
                        _addressFieldRow(
                          'Address',
                          Column(
                            children: [
                              SizedBox(
                                height: 50,
                                child: CustomTextField(
                                  controller: _custBillStreet1,
                                  hintText: 'Street 1',
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 50,
                                child: CustomTextField(
                                  controller: _custBillStreet2,
                                  hintText: 'Street 2',
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                          fixHeight: false,
                        ),
                        _addressFieldRow(
                          'City',
                          CustomTextField(
                            controller: _custBillCity,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'State',
                          FormDropdown<String>(
                            value: _custBillState,
                            items: const [
                              'Kerala',
                              'Tamil Nadu',
                              'Karnataka',
                              'Maharashtra',
                              'Delhi',
                            ],
                            hint: 'Select or type to add',
                            allowCustomValue: true,
                            showSearch: true,
                            onChanged: (v) =>
                                dialogSetState(() => _custBillState = v),
                          ),
                        ),
                        _addressFieldRow(
                          'Pin Code',
                          CustomTextField(
                            controller: _custBillPinCode,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'Phone',
                          CustomTextField(
                            controller: _custBillPhone,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'Fax',
                          CustomTextField(
                            controller: _custBillFax,
                            hintText: '',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Shipping Address',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                dialogSetState(() {
                                  _custShipAttention.text =
                                      _custBillAttention.text;
                                  _custShipCountry = _custBillCountry;
                                  _custShipStreet1.text = _custBillStreet1.text;
                                  _custShipStreet2.text = _custBillStreet2.text;
                                  _custShipCity.text = _custBillCity.text;
                                  _custShipState = _custBillState;
                                  _custShipPinCode.text = _custBillPinCode.text;
                                  _custShipPhone.text = _custBillPhone.text;
                                  _custShipFax.text = _custBillFax.text;
                                });
                                ZerpaiToast.success(
                                  context,
                                  'Billing address copied to shipping address',
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    '( ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_downward,
                                    size: 12,
                                    color: AppTheme.primaryBlue,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'Copy billing address',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryBlue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  Text(
                                    ' )',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _addressFieldRow(
                          'Attention',
                          CustomTextField(
                            controller: _custShipAttention,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'Country/Region',
                          FormDropdown<String>(
                            value: _custShipCountry,
                            items: const [
                              'India',
                              'United States',
                              'United Kingdom',
                              'Canada',
                              'United Arab Emirates',
                            ],
                            hint: 'Select',
                            showSearch: false,
                            onChanged: (v) =>
                                dialogSetState(() => _custShipCountry = v),
                          ),
                        ),
                        _addressFieldRow(
                          'Address',
                          Column(
                            children: [
                              SizedBox(
                                height: 50,
                                child: CustomTextField(
                                  controller: _custShipStreet1,
                                  hintText: 'Street 1',
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 50,
                                child: CustomTextField(
                                  controller: _custShipStreet2,
                                  hintText: 'Street 2',
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                          fixHeight: false,
                        ),
                        _addressFieldRow(
                          'City',
                          CustomTextField(
                            controller: _custShipCity,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'State',
                          FormDropdown<String>(
                            value: _custShipState,
                            items: const [
                              'Kerala',
                              'Tamil Nadu',
                              'Karnataka',
                              'Maharashtra',
                              'Delhi',
                            ],
                            hint: 'Select or type to add',
                            allowCustomValue: true,
                            showSearch: true,
                            onChanged: (v) =>
                                dialogSetState(() => _custShipState = v),
                          ),
                        ),
                        _addressFieldRow(
                          'Pin Code',
                          CustomTextField(
                            controller: _custShipPinCode,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'Phone',
                          CustomTextField(
                            controller: _custShipPhone,
                            hintText: '',
                          ),
                        ),
                        _addressFieldRow(
                          'Fax',
                          CustomTextField(
                            controller: _custShipFax,
                            hintText: '',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildAddressNote(),
            ],
          ),
        );

      case 'Custom Fields':
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogFieldRow(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'demo feild',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(width: 4),
                    ZTooltip(message: 'This is a demo custom field.'),
                  ],
                ),
                CustomTextField(
                  controller: _custDemoFieldController,
                  hintText: '',
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 12, height: 1.5),
                  children: [
                    TextSpan(
                      text: 'Note: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorRed,
                      ),
                    ),
                    TextSpan(
                      text:
                          'You can add additional fields for your Customers and Vendors and have these show up on your PDF by going to ',
                      style: TextStyle(color: AppTheme.textSubtle),
                    ),
                    TextSpan(
                      text: 'Settings ➔ Preferences ➔ Customers and Vendors',
                      style: TextStyle(
                        color: AppTheme.textSubtle,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    TextSpan(
                      text:
                          '. You can also refine the address format of your Customers and Vendors from there.',
                      style: TextStyle(color: AppTheme.textSubtle),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'Reporting Tags':
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogFieldRow(
                const Text(
                  'ADGF',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                FormDropdown<String>(
                  value: _custAdgf,
                  items: const ['None'],
                  onChanged: (v) {
                    if (v != null) dialogSetState(() => _custAdgf = v);
                  },
                ),
              ),
              _dialogFieldRow(
                const Text(
                  'shedule',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                FormDropdown<String>(
                  value: _custSchedule,
                  items: const ['None'],
                  onChanged: (v) {
                    if (v != null) dialogSetState(() => _custSchedule = v);
                  },
                ),
              ),
              _dialogFieldRow(
                const Text(
                  'demo adavced\nreporting tag',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
                FormDropdown<String>(
                  value: _custDemoAdvanced,
                  items: const ['None'],
                  onChanged: (v) {
                    if (v != null) dialogSetState(() => _custDemoAdvanced = v);
                  },
                ),
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            ],
          ),
        );

      case 'Remarks':
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Remarks (For Internal Use)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _custRemarksController,
                hintText: '',
                maxLines: 4,
                height: 90,
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAddressNote() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppTheme.warningOrange, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Note:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '• ',
                style: TextStyle(fontSize: 13, color: AppTheme.textSubtle),
              ),
              Expanded(
                child: Text(
                  'Add and manage additional addresses from this Customers and Vendors details section.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSubtle,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '• ',
                style: TextStyle(fontSize: 13, color: AppTheme.textSubtle),
              ),
              Expanded(
                child: Text(
                  'You can customise how customers\' addresses are displayed in transaction PDFs. To do this, go to Settings > Preferences > Customers and Vendors, and navigate to the Address Format sections.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSubtle,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _itemizedUsesInclusiveTax =>
      _showAmountIs && !_reverseCharge && _amountIs == 'Tax Inclusive';

  double _calculateItemizedSubtotal() {
    double subtotal = 0.0;
    for (final row in _itemizedRows) {
      final amount = double.tryParse(row.amountController.text.trim()) ?? 0.0;
      final taxAmount = _computeTaxAmount(
        amount: amount,
        rate: _selectedTaxRate(row.tax),
        inclusive: _itemizedUsesInclusiveTax,
      );
      subtotal += _itemizedUsesInclusiveTax ? (amount - taxAmount) : amount;
    }
    return subtotal;
  }

  bool get _hasSelectedItemizedTax =>
      _itemizedRows.any((row) => (row.tax?.trim().isNotEmpty ?? false));

  List<MapEntry<String, double>> _itemizedTaxSummaryRows() {
    final totalsByLabel = <String, double>{};
    for (final row in _itemizedRows) {
      final label = row.tax?.trim() ?? '';
      if (label.isEmpty) {
        continue;
      }
      final amount = double.tryParse(row.amountController.text.trim()) ?? 0.0;
      final taxAmount = _computeTaxAmount(
        amount: amount,
        rate: _selectedTaxRate(row.tax),
        inclusive: _itemizedUsesInclusiveTax,
      );
      totalsByLabel[label] = (totalsByLabel[label] ?? 0.0) + taxAmount;
    }
    return totalsByLabel.entries.toList(growable: false);
  }

  List<MapEntry<String, double>> _displayItemizedTaxSummaryRows() {
    final computedRows = _itemizedTaxSummaryRows();
    return computedRows
        .map(
          (entry) => MapEntry(
            entry.key,
            _itemizedTaxOverrides[entry.key] ?? entry.value,
          ),
        )
        .toList(growable: false);
  }

  double _displayItemizedTaxTotal() {
    return _displayItemizedTaxSummaryRows().fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );
  }

  double _displayItemizedExpenseTotal() {
    return _calculateItemizedSubtotal() + _displayItemizedTaxTotal();
  }

  void _hideItemizedTotalTaxEditor() {
    _itemizedTotalTaxOverlayEntry?.remove();
    _itemizedTotalTaxOverlayEntry = null;
  }

  void _showItemizedTotalTaxEditor() {
    final summaryRows = _displayItemizedTaxSummaryRows();
    if (summaryRows.isEmpty) {
      return;
    }
    if (_itemizedTotalTaxOverlayEntry != null) {
      _hideItemizedTotalTaxEditor();
      return;
    }

    final overlay = Overlay.of(context);

    final controllers = <String, TextEditingController>{
      for (final row in summaryRows)
        row.key: TextEditingController(text: row.value.toStringAsFixed(2)),
    };
    final popoverShadow = AppTheme.textPrimary.withValues(alpha: 0.12);
    final anchorContext = _itemizedTotalTaxAnchorKey.currentContext;
    final anchorBox = anchorContext?.findRenderObject() as RenderBox?;
    final anchorOffset = anchorBox?.localToGlobal(Offset.zero);
    final anchorHeight = anchorBox?.size.height ?? 0;
    final popupHeight =
        82 + (summaryRows.length * 46) + (summaryRows.length > 1 ? 38 : 0) + 72;
    final viewportHeight = MediaQuery.of(context).size.height;
    final showAbove =
        anchorOffset != null &&
        anchorOffset.dy + anchorHeight + popupHeight + 16 > viewportHeight &&
        anchorOffset.dy > popupHeight;

    void closeEditor() {
      _hideItemizedTotalTaxEditor();
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }

    for (final controller in controllers.values) {
      controller.addListener(() {
        _itemizedTotalTaxOverlayEntry?.markNeedsBuild();
      });
    }

    _itemizedTotalTaxOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final totalTaxAmount = controllers.values.fold<double>(
          0,
          (sum, controller) =>
              sum + (double.tryParse(controller.text.trim()) ?? 0.0),
        );
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: closeEditor,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _itemizedTotalTaxLayerLink,
              showWhenUnlinked: false,
              targetAnchor: showAbove
                  ? Alignment.topRight
                  : Alignment.bottomRight,
              followerAnchor: showAbove
                  ? Alignment.bottomRight
                  : Alignment.topRight,
              offset: showAbove ? const Offset(0, -12) : const Offset(0, 12),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: 332,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: 12,
                        top: showAbove ? null : 0,
                        bottom: showAbove ? 0 : null,
                        child: Transform.rotate(
                          angle: showAbove ? math.pi : 0,
                          child: CustomPaint(
                            size: const Size(18, 10),
                            painter: _ItemizedHsnSacPopoverArrowPainter(
                              fillColor: AppTheme.backgroundColor,
                              borderColor: AppTheme.borderLight,
                              shadowColor: popoverShadow,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: showAbove
                            ? const EdgeInsets.only(bottom: 8)
                            : const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: popoverShadow,
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Update Taxes Amount ( in INR )',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: closeEditor,
                                    child: const Icon(
                                      LucideIcons.x,
                                      size: 16,
                                      color: AppTheme.errorRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                              child: Column(
                                children: [
                                  for (final summaryRow in summaryRows)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              summaryRow.key,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    fontSize: 13,
                                                    color: AppTheme.textPrimary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: 110,
                                            height:
                                                _expenseCreateCompactFieldHeight,
                                            child: TextField(
                                              controller:
                                                  controllers[summaryRow.key],
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              textAlign: TextAlign.right,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 9,
                                                    ),
                                                filled: true,
                                                fillColor:
                                                    AppTheme.backgroundColor,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  borderSide: const BorderSide(
                                                    color: AppTheme.borderLight,
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: AppTheme
                                                                .borderLight,
                                                          ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: AppTheme
                                                                .primaryBlue,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (summaryRows.length > 1) ...[
                                    const Divider(
                                      height: 18,
                                      color: AppTheme.borderLight,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Total Tax Amount',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                            ),
                                          ),
                                          Text(
                                            totalTaxAmount.toStringAsFixed(2),
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                              child: Align(
                                alignment: Alignment.center,
                                child: ZButton.primary(
                                  label: 'Update',
                                  onPressed: () {
                                    final overrides = <String, double>{};
                                    for (final summaryRow in summaryRows) {
                                      final controller =
                                          controllers[summaryRow.key];
                                      overrides[summaryRow.key] =
                                          double.tryParse(
                                            controller?.text.trim() ?? '',
                                          ) ??
                                          summaryRow.value;
                                    }
                                    closeEditor();
                                    if (!mounted) {
                                      return;
                                    }
                                    setState(() {
                                      _itemizedTaxOverrides = overrides;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_itemizedTotalTaxOverlayEntry!);
  }

  ExpenseItemRow _cloneItemizedRow(ExpenseItemRow source) {
    return ExpenseItemRow(
      expenseAccountId: source.expenseAccountId,
      notesController: TextEditingController(text: source.notesController.text),
      tax: source.tax,
      amountController: TextEditingController(
        text: source.amountController.text,
      ),
      expenseType: source.expenseType,
      showAdditionalInformation: source.showAdditionalInformation,
    );
  }

  ExpenseItemRow _newItemizedRow({String? expenseType}) {
    return ExpenseItemRow(
      expenseType: expenseType ?? _itemizedExpenseTypeLabel(),
    );
  }

  String _itemizedExpenseTypeCode() {
    final type = _itemizedRows.isNotEmpty
        ? _itemizedRows.first.expenseType
        : _expenseType;
    return type == 'Goods' ? 'GOODS' : 'SERVICES';
  }

  String _itemizedExpenseTypeLabel() {
    return _itemizedRows.isNotEmpty
        ? _itemizedRows.first.expenseType
        : _expenseType;
  }

  String _itemizedHsnSacLabel(ExpenseItemRow row) {
    return row.expenseType == 'Goods' ? 'HSN Code' : 'SAC';
  }

  void _hideItemizedHsnSacEditor() {
    _itemizedHsnSacOverlayEntry?.remove();
    _itemizedHsnSacOverlayEntry = null;
    if (_editingItemizedHsnSacIndex != null && mounted) {
      setState(() => _editingItemizedHsnSacIndex = null);
    }
  }

  void _reorderItemizedRows(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final row = _itemizedRows.removeAt(oldIndex);
      _itemizedRows.insert(newIndex, row);
      _draggingItemizedRowIndex = null;
    });
  }

  void _showItemizedHsnSacEditor(ExpenseItemRow row, int index) {
    if (_editingItemizedHsnSacIndex == index &&
        _itemizedHsnSacOverlayEntry != null) {
      _hideItemizedHsnSacEditor();
      return;
    }

    _hideItemizedHsnSacEditor();

    final overlay = Overlay.of(context);
    final popoverShadow = AppTheme.textPrimary.withValues(alpha: 0.12);

    _itemizedHsnSacOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideItemizedHsnSacEditor,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: row.hsnSacLayerLink,
              showWhenUnlinked: false,
              followerAnchor: Alignment.topLeft,
              targetAnchor: Alignment.bottomLeft,
              offset: const Offset(0, 6),
              child: Material(
                elevation: 0,
                color: Colors.transparent,
                child: SizedBox(
                  width: 196,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 20,
                        top: 0,
                        child: CustomPaint(
                          size: const Size(18, 10),
                          painter: _ItemizedHsnSacPopoverArrowPainter(
                            fillColor: AppTheme.backgroundColor,
                            borderColor: AppTheme.borderLight,
                            shadowColor: popoverShadow,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: popoverShadow,
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: CustomTextField(
                                controller: _sacController,
                                hintText: '',
                                autoFocus: true,
                                height: _expenseCreateCompactFieldHeight,
                                fillColor: AppTheme.backgroundColor,
                                textStyle: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                onSubmitted: (_) {
                                  _hideItemizedHsnSacEditor();
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ZButton.primary(
                                label: 'OK',
                                onPressed: _hideItemizedHsnSacEditor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_itemizedHsnSacOverlayEntry!);
    setState(() => _editingItemizedHsnSacIndex = index);
  }

  Widget _buildItemizedHsnSacRow(ExpenseItemRow row, int index) {
    final codeValue = _sacController.text.trim();
    final labelStyle = AppTextStyles.bodySmall.copyWith(
      fontSize: 13,
      color: AppTheme.textMuted,
      fontWeight: FontWeight.w500,
    );
    final valueStyle = AppTextStyles.bodySmall.copyWith(
      fontSize: 13,
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w500,
    );
    final linkStyle = AppTextStyles.bodySmall.copyWith(
      fontSize: 13,
      color: AppTheme.primaryBlue,
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: CompositedTransformTarget(
        link: row.hsnSacLayerLink,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Text('${_itemizedHsnSacLabel(row)}:', style: labelStyle),
            InkWell(
              onTap: () => _showItemizedHsnSacEditor(row, index),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    codeValue.isEmpty ? 'Update' : codeValue,
                    style: codeValue.isEmpty ? linkStyle : valueStyle,
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    LucideIcons.pencil,
                    size: 12,
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemizedReportingTagsRow(ExpenseItemRow row) {
    final linkStyle = AppTextStyles.body.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppTheme.textPrimary,
    );
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(28, 12, 12, 12),
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.tag, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Text('Reporting Tags', style: linkStyle),
          const SizedBox(width: 6),
          Icon(
            row.showAdditionalInformation
                ? LucideIcons.chevronDown
                : LucideIcons.chevronRight,
            size: 14,
            color: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }

  ButtonStyle _itemizeRowMenuItemStyle() {
    return ButtonStyle(
      animationDuration: Duration.zero,
      minimumSize: const WidgetStatePropertyAll(Size(188, 40)),
      maximumSize: const WidgetStatePropertyAll(Size(188, 40)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14),
      ),
      alignment: Alignment.centerLeft,
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return AppTheme.primaryBlue;
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return AppTheme.backgroundColor;
        }
        return AppTheme.textPrimary;
      }),
      textStyle: WidgetStatePropertyAll(
        AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _buildItemizeBox() {
    const double itemizeFieldHeight = 32;
    const double itemizeNotesHeight = 48;

    final backLinkStyle = AppTextStyles.bodySmall.copyWith(
      color: AppTheme.primaryBlue,
      fontWeight: FontWeight.w500,
    );
    final sectionLabelStyle = AppTextStyles.body.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w500,
    );
    final optionStyle = AppTextStyles.bodySmall.copyWith(
      color: AppTheme.textPrimary,
    );
    final headerStyle = AppTextStyles.label.copyWith(
      fontWeight: FontWeight.w700,
      color: AppTheme.textSecondary,
    );
    final emphasisHeaderStyle = headerStyle.copyWith(color: AppTheme.errorRed);

    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      width: 748,
      decoration: BoxDecoration(color: _itemizeBgColor),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isItemized = false;
                if (_itemizedRows.isNotEmpty) {
                  _selectedCategoryAccountId =
                      _itemizedRows[0].expenseAccountId;
                  _selectedCategory = _findExpenseAccountById(
                    _itemizedRows[0].expenseAccountId,
                  )?.displayName;
                  _amountController.text =
                      _itemizedRows[0].amountController.text;
                }
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.chevron_left,
                  size: 14,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 4),
                Text('Back to single expense view', style: backLinkStyle),
              ],
            ),
          ),
          const SizedBox(height: 18),
          RadioGroup<String>(
            groupValue: _taxOverrideLevel,
            onChanged: (v) {
              if (v != null) setState(() => _taxOverrideLevel = v);
            },
            child: Row(
              children: [
                Text('Apply Tax Override', style: sectionLabelStyle),
                const SizedBox(width: 16),
                Radio<String>(
                  value: 'At Transaction Level',
                  activeColor: AppTheme.primaryBlue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                Text('At Transaction Level', style: optionStyle),
                const SizedBox(width: 16),
                Radio<String>(
                  value: 'At Line Item Level',
                  activeColor: AppTheme.primaryBlue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                Text('At Line Item Level', style: optionStyle),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
            decoration: const BoxDecoration(
              color: AppTheme.bgLight,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 22),
                Expanded(
                  flex: 8,
                  child: Text('EXPENSE ACCOUNT', style: emphasisHeaderStyle),
                ),
                const SizedBox(width: 14),
                Expanded(flex: 8, child: Text('NOTES', style: headerStyle)),
                const SizedBox(width: 14),
                Expanded(
                  flex: 5,
                  child: _showTax && _taxRequired
                      ? Text('TAX', style: emphasisHeaderStyle)
                      : Text('TAX', style: headerStyle),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('AMOUNT', style: emphasisHeaderStyle),
                  ),
                ),
                const SizedBox(width: 28),
              ],
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _itemizedRows.length,
              proxyDecorator: (child, index, animation) => child,
              onReorderStart: (index) {
                _hideItemizedHsnSacEditor();
                _hideItemizedTotalTaxEditor();
                setState(() => _draggingItemizedRowIndex = index);
              },
              onReorderEnd: (index) {
                if (_draggingItemizedRowIndex != null) {
                  setState(() => _draggingItemizedRowIndex = null);
                }
              },
              onReorder: _reorderItemizedRows,
              itemBuilder: (context, index) {
                final row = _itemizedRows[index];
                final isDragging = _draggingItemizedRowIndex == index;
                return Container(
                  key: ValueKey(row),
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ReorderableDragStartListener(
                              index: index,
                              child: MouseRegion(
                                cursor: isDragging
                                    ? SystemMouseCursors.grabbing
                                    : SystemMouseCursors.grab,
                                child: const Icon(
                                  LucideIcons.gripVertical,
                                  size: 16,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: itemizeFieldHeight,
                                  child: ExpenseAccountDropdownWidget(
                                    value: row.expenseAccountId,
                                    nodes:
                                        buildRecurringExpenseGroupedAccountNodes(
                                          _expenseAccountCatalog,
                                        ),
                                    hint: 'Select an account',
                                    onChanged: (v) => setState(() {
                                      row.expenseAccountId = v;
                                    }),
                                    onAddAccount: () async {
                                      final createdAccountName =
                                          await AddAccountDialog.show(context);
                                      if (createdAccountName != null &&
                                          mounted) {
                                        ref.invalidate(
                                          expensesExpenseAccountsProvider,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 110,
                                  height: itemizeFieldHeight,
                                  child: FormDropdown<String>(
                                    value: row.expenseType,
                                    items: const ['Goods', 'Services'],
                                    hint: '',
                                    fillColor: AppTheme.bgDisabled,
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => row.expenseType = v);
                                    },
                                  ),
                                ),
                                _buildItemizedHsnSacRow(row, index),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 8,
                            child: CustomTextField(
                              controller: row.notesController,
                              hintText: 'Max. 500 characters',
                              maxLines: 2,
                              resizable: true,
                              minHeight: itemizeNotesHeight,
                              height: itemizeNotesHeight,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 5,
                            child: MouseRegion(
                              cursor: _itemizedTaxEditable
                                  ? MouseCursor.defer
                                  : SystemMouseCursors.forbidden,
                              onEnter: _itemizedTaxEditable
                                  ? null
                                  : (_) => setState(
                                      () =>
                                          _hoveredReadOnlyItemTaxIndex = index,
                                    ),
                              onExit: _itemizedTaxEditable
                                  ? null
                                  : (_) => setState(() {
                                      if (_hoveredReadOnlyItemTaxIndex ==
                                          index) {
                                        _hoveredReadOnlyItemTaxIndex = null;
                                      }
                                    }),
                              child: Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  IgnorePointer(
                                    ignoring: !_itemizedTaxEditable,
                                    child: SizedBox(
                                      height: itemizeFieldHeight,
                                      child: FormDropdown<String>(
                                        value: row.tax,
                                        items: _taxOptions,
                                        hint: 'Select a Tax',
                                        enabled: _itemizedTaxEditable,
                                        onChanged: (v) => setState(() {
                                          _hideItemizedTotalTaxEditor();
                                          row.tax = v;
                                          _itemizedTaxOverrides = {};
                                          _logTaxDebug(
                                            'item row tax selected in dropdown',
                                            'row.tax=$v selected display label=$v',
                                          );
                                        }),
                                      ),
                                    ),
                                  ),
                                  if (!_itemizedTaxEditable &&
                                      _hoveredReadOnlyItemTaxIndex == index &&
                                      (row.tax?.trim().isNotEmpty ?? false))
                                    const Padding(
                                      padding: EdgeInsets.only(right: 30),
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 4,
                            child: SizedBox(
                              height: itemizeFieldHeight,
                              child: CustomTextField(
                                controller: row.amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.right,
                                hintText: '0.00',
                                onChanged: (val) => setState(() {
                                  _hideItemizedTotalTaxEditor();
                                  _itemizedTaxOverrides = {};
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 28,
                            height: itemizeFieldHeight,
                            child: MenuAnchor(
                              crossAxisUnconstrained: false,
                              style: MenuStyle(
                                backgroundColor: const WidgetStatePropertyAll(
                                  AppTheme.backgroundColor,
                                ),
                                surfaceTintColor: const WidgetStatePropertyAll(
                                  AppTheme.backgroundColor,
                                ),
                                padding: const WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(vertical: 8),
                                ),
                                minimumSize: const WidgetStatePropertyAll(
                                  Size(188, 0),
                                ),
                                side: const WidgetStatePropertyAll(
                                  BorderSide(color: AppTheme.borderLight),
                                ),
                                elevation: const WidgetStatePropertyAll(8),
                                shadowColor: WidgetStatePropertyAll(
                                  AppTheme.textPrimary.withValues(alpha: 0.14),
                                ),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              menuChildren: [
                                MenuItemButton(
                                  style: _itemizeRowMenuItemStyle(),
                                  onPressed: () {
                                    setState(() {
                                      _itemizedHsnSacOverlayEntry?.remove();
                                      _itemizedHsnSacOverlayEntry = null;
                                      _hideItemizedTotalTaxEditor();
                                      _editingItemizedHsnSacIndex = null;
                                      _itemizedTaxOverrides = {};
                                      _itemizedRows.insert(
                                        index + 1,
                                        _cloneItemizedRow(row),
                                      );
                                    });
                                  },
                                  child: const Text('Clone'),
                                ),
                                MenuItemButton(
                                  style: _itemizeRowMenuItemStyle(),
                                  onPressed: () {
                                    setState(() {
                                      _itemizedHsnSacOverlayEntry?.remove();
                                      _itemizedHsnSacOverlayEntry = null;
                                      _hideItemizedTotalTaxEditor();
                                      _editingItemizedHsnSacIndex = null;
                                      _itemizedTaxOverrides = {};
                                      _itemizedRows.insert(
                                        index + 1,
                                        _newItemizedRow(
                                          expenseType: row.expenseType,
                                        ),
                                      );
                                    });
                                  },
                                  child: const Text('Insert New Row'),
                                ),
                                MenuItemButton(
                                  style: _itemizeRowMenuItemStyle(),
                                  onPressed: () {
                                    setState(() {
                                      row.showAdditionalInformation =
                                          !row.showAdditionalInformation;
                                    });
                                  },
                                  child: Text(
                                    row.showAdditionalInformation
                                        ? 'Hide Additional Information'
                                        : 'Show Additional Information',
                                  ),
                                ),
                                MenuItemButton(
                                  style: _itemizeRowMenuItemStyle(),
                                  onPressed: () {
                                    setState(() {
                                      _itemizedHsnSacOverlayEntry?.remove();
                                      _itemizedHsnSacOverlayEntry = null;
                                      _hideItemizedTotalTaxEditor();
                                      _editingItemizedHsnSacIndex = null;
                                      _itemizedTaxOverrides = {};
                                      if (_itemizedRows.length > 1) {
                                        final removed = _itemizedRows.removeAt(
                                          index,
                                        );
                                        removed.dispose();
                                      } else {
                                        ZerpaiToast.error(
                                          context,
                                          'At least one row is required',
                                        );
                                      }
                                    });
                                  },
                                  child: const Text('Remove'),
                                ),
                              ],
                              builder: (context, controller, child) {
                                return InkWell(
                                  onTap: () {
                                    controller.isOpen
                                        ? controller.close()
                                        : controller.open();
                                  },
                                  child: const Center(
                                    child: Icon(
                                      LucideIcons.moreVertical,
                                      size: 16,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      if (row.showAdditionalInformation)
                        _buildItemizedReportingTagsRow(row),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final subtotal = _calculateItemizedSubtotal();
              final totalTax = _displayItemizedTaxTotal();
              final expenseTotal = _displayItemizedExpenseTotal();
              final summaryRows = _displayItemizedTaxSummaryRows();

              final addRowButton = Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      setState(() {
                        _hideItemizedTotalTaxEditor();
                        _itemizedTaxOverrides = {};
                        _itemizedRows.add(_newItemizedRow());
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.plusCircle,
                            size: 13,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add New Row',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              Widget buildSummaryValueRow(
                String label,
                String value, {
                bool emphasize = false,
              }) {
                return Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: emphasize
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: emphasize ? 15 : 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          value,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: emphasize
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: emphasize ? 15 : 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                  ],
                );
              }

              Widget buildTotalTaxAmountSummaryRow(String value) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Total Tax Amount',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 102,
                              height: 34,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppTheme.borderLight,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  color: AppTheme.backgroundColor,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          value,
                                          textAlign: TextAlign.right,
                                          style: AppTextStyles.body.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                              color: AppTheme.borderLight,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'INR',
                                          style: AppTextStyles.body.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CompositedTransformTarget(
                              link: _itemizedTotalTaxLayerLink,
                              child: InkWell(
                                key: _itemizedTotalTaxAnchorKey,
                                onTap: _showItemizedTotalTaxEditor,
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    LucideIcons.pencil,
                                    size: 13,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: addRowButton),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            if (!_reverseCharge && _hasSelectedItemizedTax) ...[
                              buildSummaryValueRow(
                                'Sub Total',
                                subtotal.toStringAsFixed(2),
                              ),
                              const SizedBox(height: 12),
                              for (final summaryRow in summaryRows) ...[
                                buildSummaryValueRow(
                                  summaryRow.key,
                                  summaryRow.value.toStringAsFixed(2),
                                ),
                                const SizedBox(height: 12),
                              ],
                              buildTotalTaxAmountSummaryRow(
                                totalTax.toStringAsFixed(2),
                              ),
                              const SizedBox(height: 12),
                            ],
                            buildSummaryValueRow(
                              'Expense Total ( ₹ )',
                              expenseTotal.toStringAsFixed(2),
                              emphasize: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
        ],
      ),
    );
  }

  Widget _buildDockedActions() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(top: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Save (Alt+S)
          ElevatedButton(
            onPressed: _isSubmitting || _isLoadingEditExpense
                ? null
                : () => _saveExpense(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              foregroundColor: AppTheme.backgroundColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Save (Alt+S)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          // Save and New (Alt+N)
          OutlinedButton(
            onPressed: _isSubmitting || _isLoadingEditExpense
                ? null
                : () => _saveExpense(andNew: true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textBody,
              side: const BorderSide(color: AppTheme.borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Save and New (Alt+N)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          // Cancel
          OutlinedButton(
            onPressed: _isSubmitting ? null : _cancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textBody,
              side: const BorderSide(color: AppTheme.borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _logTaxCatalogSnapshot();
    _logTaxOptionsSnapshot();
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoadingEditExpense
          ? const RecurringExpenseLoadingIndicator(fillAvailableSpace: true)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTabBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: _activeTab == 0
                        ? _buildRecordExpenseForm()
                        : _buildRecordMileageForm(),
                  ),
                ),
                _buildDockedActions(),
              ],
            ),
    );
  }
}

class ExpenseItemRow {
  String? expenseAccountId;
  final TextEditingController notesController;
  String? tax;
  final TextEditingController amountController;
  String expenseType;
  bool showAdditionalInformation;
  final LayerLink hsnSacLayerLink;

  ExpenseItemRow({
    this.expenseAccountId,
    TextEditingController? notesController,
    this.tax,
    TextEditingController? amountController,
    this.expenseType = 'Services',
    this.showAdditionalInformation = true,
    LayerLink? hsnSacLayerLink,
  }) : notesController = notesController ?? TextEditingController(),
       amountController = amountController ?? TextEditingController(),
       hsnSacLayerLink = hsnSacLayerLink ?? LayerLink();

  void dispose() {
    notesController.dispose();
    amountController.dispose();
  }
}

class _ItemizedHsnSacPopoverArrowPainter extends CustomPainter {
  const _ItemizedHsnSacPopoverArrowPainter({
    required this.fillColor,
    required this.borderColor,
    required this.shadowColor,
  });

  final Color fillColor;
  final Color borderColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(1, size.height)
      ..lineTo(size.width / 2, 1)
      ..lineTo(size.width - 1, size.height)
      ..close();

    canvas.drawShadow(path, shadowColor, 6, false);

    final fillPaint = Paint()
      ..color = fillColor
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = borderColor
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ItemizedHsnSacPopoverArrowPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}

class MileageRateRow {
  DateTime? startDate;
  final TextEditingController rateController;

  MileageRateRow({this.startDate, TextEditingController? rateController})
    : rateController = rateController ?? TextEditingController();

  void dispose() {
    rateController.dispose();
  }
}

class MileageDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;
  final GlobalKey _targetKey = GlobalKey();

  MileageDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final displayStr = selectedDate == null
        ? 'dd-MM-yyyy'
        : '${selectedDate!.day.toString().padLeft(2, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.year}';

    return InkWell(
      key: _targetKey,
      onTap: () async {
        final date = await ZerpaiDatePicker.show(
          context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          targetKey: _targetKey,
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(4),
          color: AppTheme.backgroundColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayStr,
              style: TextStyle(
                fontSize: 13,
                color: selectedDate == null
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
              ),
            ),
            const Icon(
              LucideIcons.calendar,
              size: 14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class MileageDistanceInputField extends StatefulWidget {
  const MileageDistanceInputField({
    super.key,
    required this.controller,
    required this.unitLabel,
    this.onChanged,
  });

  final TextEditingController controller;
  final String unitLabel;
  final ValueChanged<String>? onChanged;

  @override
  State<MileageDistanceInputField> createState() =>
      _MileageDistanceInputFieldState();
}

class _MileageDistanceInputFieldState extends State<MileageDistanceInputField> {
  static const double _fieldHeight = 32;
  static const double _unitWidth = 126;
  static const double _maxBorderWidth = 1.5;

  late final FocusNode _focusNode;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;
    final borderColor = hasFocus
        ? AppTheme.primaryBlueDark
        : (_isHovered ? AppTheme.infoBlue : AppTheme.borderColor);
    final borderWidth = hasFocus ? _maxBorderWidth : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: SizedBox(
        height: _fieldHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(3),
                          bottomLeft: Radius.circular(3),
                        ),
                      ),
                      child: CustomTextField(
                        focusNode: _focusNode,
                        controller: widget.controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        hintText: '',
                        hideBorderDefault: true,
                        fillColor: Colors.transparent,
                        border: Border.all(
                          color: Colors.transparent,
                          width: 0,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        onChanged: widget.onChanged,
                      ),
                    ),
                  ),
                  Container(
                    width: _unitWidth,
                    height: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: const BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                      border: Border(
                        left: BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.unitLabel,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor, width: borderWidth),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VendorItem {
  final String name;
  final String code;
  final String? email;
  final String? extraSubtitle;

  const VendorItem({
    required this.name,
    required this.code,
    this.email,
    this.extraSubtitle,
  });

  @override
  String toString() => name;
}
