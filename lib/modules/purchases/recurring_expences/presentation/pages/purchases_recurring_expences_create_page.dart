import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/amount_input_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/dialogs/add_account_dialog.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/models/recurring_expense_lookup_models.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/recurring_expense_form_metrics.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/recurring_expense_gst_option_row.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/widgets/z_expenses_date_picker.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/vendor_dropdown_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/customer_dropdown_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/account_tree_dropdown_with_add_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/expense_account_dropdown_widget.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/widgets/recurring_expense_loading_indicator_widget.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/pages/purchases_vendors_vendor_create.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/customers/presentation/pages/sales_customer_create.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/advanced_customer_search_dialog.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/models/account_node.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/advanced_vendor_search_dialog.dart';
import '../../config/recurring_expense_constants.dart';
import '../../config/recurring_expense_routes.dart';
import '../../models/create_recurring_expense_request.dart';
import '../../models/recurring_expense_details_model.dart';
import '../../models/recurring_expense_enums.dart';
import '../../models/update_recurring_expense_request.dart';
import '../../providers/recurring_expense_provider.dart';

const double _recurringExpenseStandardFieldWidth = 396.0;
const double _recurringExpenseWideFieldWidth = 396.0;
const double _recurringExpenseCompactFieldWidth = 180.0;
const double _recurringExpenseFieldHeight = kRecurringExpenseCompactFieldHeight;
const double _recurringExpenseMultilineFieldMinHeight = 80.0;
const double _recurringExpenseCustomRepeatMaxWidth = 732.0;
const double _recurringExpenseCustomRepeatIntervalWidth = 76.0;
const double _recurringExpenseCustomRepeatUnitWidth =
    _recurringExpenseCompactFieldWidth;
const double _recurringExpenseLookupInputWidth =
    _recurringExpenseStandardFieldWidth;
const double _recurringExpenseLookupActionWidth = 36.0;
const double _recurringExpenseLookupFieldWidth =
    _recurringExpenseLookupInputWidth + _recurringExpenseLookupActionWidth;
const double _recurringExpenseGstMenuMaxHeight =
    kRecurringExpenseGstMenuMaxHeight;
const double _recurringExpenseGstOptionHeight =
    kRecurringExpenseGstOptionHeight;
const double _recurringExpenseGstOptionContentHeight =
    kRecurringExpenseGstOptionContentHeight;
const double _recurringExpenseReportingTagRowBreakPoint = 960.0;
const double _recurringExpenseReportingTagColumnGap = 48.0;
const double _recurringExpenseReportingTagFieldWidth = 344.0;
const double _recurringExpenseRowVerticalPadding = 8.0;
const double _recurringExpenseDenseSectionRowVerticalPadding = 4.0;
const double _recurringExpenseFormTopPadding = 12.0;
const double _recurringExpenseChildStartGap = 12.0;

class _RecurringExpenseFormRow extends StatelessWidget {
  const _RecurringExpenseFormRow({
    required this.label,
    required this.child,
    this.required = false,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.verticalPadding = _recurringExpenseRowVerticalPadding,
  });

  final String label;
  final Widget child;
  final bool required;
  final CrossAxisAlignment crossAxisAlignment;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: verticalPadding,
      ),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          SizedBox(
            width: 164,
            child: RichText(
              text: TextSpan(
                text: label,
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
            ),
          ),
          const SizedBox(width: _recurringExpenseChildStartGap),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RecurringExpensePopoverArrowPainter extends CustomPainter {
  const _RecurringExpensePopoverArrowPainter({
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
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawShadow(path, shadowColor, 4, false);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(
    covariant _RecurringExpensePopoverArrowPainter oldDelegate,
  ) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}

class _ReportingTagFieldConfig {
  final String id;
  final String label;

  const _ReportingTagFieldConfig({required this.id, required this.label});
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

class PurchasesRecurringExpensesCreatePage extends ConsumerStatefulWidget {
  const PurchasesRecurringExpensesCreatePage({super.key});

  @override
  ConsumerState<PurchasesRecurringExpensesCreatePage> createState() =>
      _PurchasesRecurringExpensesCreatePageState();
}

class _PurchasesRecurringExpensesCreatePageState
    extends ConsumerState<PurchasesRecurringExpensesCreatePage> {
  final _formKey = GlobalKey<FormState>();

  // New Fields Form State
  final _profileNameCtrl = TextEditingController();
  // String _selectedLocation = 'ZABNIX PRIVATE LIMITED';
  String _selectedRepeatEvery =
      RecurringExpenseModuleDefaults.defaultRepeatEvery;
  final _customRepeatIntervalCtrl = TextEditingController(text: '1');
  String _selectedCustomRepeatUnit =
      RecurringExpenseModuleDefaults.defaultCustomRepeatUnit;
  DateTime _startDate = DateUtils.dateOnly(DateTime.now());
  DateTime? _endDate;
  bool _neverExpires = false;
  String? _selectedExpenseAccount;

  // New Fields Form State (Part 2)
  RecurringExpenseCustomerOption? _selectedCustomer;
  bool _isCustomerBillable = false;
  final Map<String, String?> _selectedReportingTagValues = {};
  final List<_ReportingTagFieldConfig> _reportingTagFields = const [
    _ReportingTagFieldConfig(id: 'adgf', label: 'ADGF'),
    _ReportingTagFieldConfig(id: 'schedule', label: 'schedule'),
    _ReportingTagFieldConfig(
      id: 'demo_reporting_tag',
      label: 'demo advanced reporting tag',
    ),
  ];

  // Form State values
  String _selectedCurrency = RecurringExpenseModuleDefaults.defaultCurrency;
  final _amountCtrl = TextEditingController();
  String? _selectedPaidThrough;
  String _expenseType = RecurringExpenseModuleDefaults.defaultExpenseType;
  final _hsnCodeCtrl = TextEditingController();
  RecurringExpenseVendorOption? _selectedVendor;
  String? _selectedGstTreatment;
  String? _selectedSourceOfSupply;
  String? _selectedDestinationOfSupply;
  bool _reverseCharge = false;
  String? _selectedTax;
  final _exemptionReasonCtrl = TextEditingController();
  String? _exemptionReasonErrorText;
  String _amountIs = RecurringExpenseModuleDefaults.defaultAmountIs;
  String _selectedItcOption = RecurringExpenseModuleDefaults.defaultItcOption;
  final LayerLink _itcLayerLink = LayerLink();
  OverlayEntry? _itcOverlayEntry;
  final GlobalKey _itcAnchorKey = GlobalKey();
  final _notesCtrl = TextEditingController();
  double _notesFieldHeight = _recurringExpenseMultilineFieldMinHeight;
  final _dummyItems = <String>[];
  RecurringExpenseDetails? _editingProfile;
  bool _isSubmitting = false;
  bool _isLoadingEditProfile = false;
  bool _didApplyKeralaDefault = false;
  bool _vendorSelectionCleared = false;
  bool _customerSelectionCleared = false;
  List<GstTreatmentLookupModel> _gstTreatmentCatalog =
      const <GstTreatmentLookupModel>[];
  List<AccountNode> _cachedPaidThroughAccountsList = const <AccountNode>[];
  List<dynamic> _lastPaidThroughRootsIdentity = const <dynamic>[];
  String? _lastPaidThroughFallbackId;
  String? _lastPaidThroughFallbackName;
  String _resolvedRouteMode = 'create';
  String? _resolvedRouteProfileId;
  int _routeEpoch = 0;

  void _handleAmountValueChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(_handleAmountValueChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vendorProvider.notifier).loadVendors();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeState = GoRouterState.of(context);
    final routeMode = routeState.uri.queryParameters['mode'] ?? 'create';
    final profileId = routeState.uri.queryParameters['id'];
    if (_resolvedRouteMode == routeMode &&
        _resolvedRouteProfileId == profileId) {
      return;
    }
    _resolvedRouteMode = routeMode;
    _resolvedRouteProfileId = profileId;
    _routeEpoch++;

    if (routeMode != 'edit' || profileId == null || profileId.isEmpty) {
      _resetCreateModeState();
      return;
    }
    _loadEditProfile(profileId, _routeEpoch);
  }

  void _resetCreateModeState() {
    ref.read(recurringExpenseFormNotifierProvider.notifier).reset();
    _editingProfile = null;
    _isSubmitting = false;
    _isLoadingEditProfile = false;
    _didApplyKeralaDefault = false;
    _vendorSelectionCleared = false;
    _customerSelectionCleared = false;
    _profileNameCtrl.clear();
    _selectedRepeatEvery = RecurringExpenseModuleDefaults.defaultRepeatEvery;
    _customRepeatIntervalCtrl.text = '1';
    _selectedCustomRepeatUnit =
        RecurringExpenseModuleDefaults.defaultCustomRepeatUnit;
    _startDate = DateUtils.dateOnly(DateTime.now());
    _endDate = null;
    _neverExpires = false;
    _selectedExpenseAccount = null;
    _selectedReportingTagValues.clear();
    _selectedCustomer = null;
    _isCustomerBillable = false;
    _selectedCurrency = RecurringExpenseModuleDefaults.defaultCurrency;
    _amountCtrl.clear();
    _selectedPaidThrough = null;
    _expenseType = RecurringExpenseModuleDefaults.defaultExpenseType;
    _hsnCodeCtrl.clear();
    _selectedVendor = null;
    _selectedGstTreatment = null;
    _selectedSourceOfSupply = null;
    _selectedDestinationOfSupply = null;
    _reverseCharge = false;
    _selectedTax = null;
    _clearExemptionReason();
    _amountIs = RecurringExpenseModuleDefaults.defaultAmountIs;
    _selectedItcOption = RecurringExpenseModuleDefaults.defaultItcOption;
    _hideItcEditor();
    _notesCtrl.clear();
    _notesFieldHeight = _recurringExpenseMultilineFieldMinHeight;
  }

  Future<void> _loadEditProfile(String profileId, int routeEpoch) async {
    if (mounted) {
      setState(() {
        _isLoadingEditProfile = true;
      });
    }
    try {
      final RecurringExpenseDetails? profile = await ref.read(
        recurringExpenseDetailsProvider(profileId).future,
      );
      if (!mounted || routeEpoch != _routeEpoch) return;
      if (profile == null) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Recurring expense profile not found.',
        );
        context.pop();
        return;
      }
      ref.read(recurringExpenseFormNotifierProvider.notifier).hydrate(profile);
      final hydratedState = ref.read(recurringExpenseFormNotifierProvider);
      setState(() {
        _editingProfile = profile;
        _vendorSelectionCleared = false;
        _customerSelectionCleared = false;
        _profileNameCtrl.text = hydratedState.profileName;
        _selectedRepeatEvery = hydratedState.selectedRepeatEvery;
        _customRepeatIntervalCtrl.text = hydratedState.customRepeatInterval
            .toString();
        _selectedCustomRepeatUnit = hydratedState.selectedCustomRepeatUnit;
        _startDate = hydratedState.startDate;
        _endDate = hydratedState.endDate;
        _neverExpires = hydratedState.neverExpires;
        _selectedExpenseAccount = hydratedState.selectedExpenseAccount;
        _amountCtrl.text = hydratedState.amount.toStringAsFixed(0);
        _selectedCurrency = hydratedState.selectedCurrency;
        _selectedPaidThrough = hydratedState.selectedPaidThrough;
        _selectedGstTreatment = hydratedState.selectedGstTreatment;
        _selectedSourceOfSupply = hydratedState.selectedSourceOfSupply;
        _selectedDestinationOfSupply =
            hydratedState.selectedDestinationOfSupply ??
            _selectedDestinationOfSupply;
        _selectedItcOption = hydratedState.selectedItcOption;
        _selectedTax = hydratedState.selectedTax;
        _clearExemptionReason();
        _amountIs = hydratedState.amountIs;
        _reverseCharge = hydratedState.reverseCharge;
        _notesCtrl.text = hydratedState.notes;
        _isCustomerBillable = hydratedState.isBillable;
        if (hydratedState.selectedVendor != null) {
          _selectedVendor = hydratedState.selectedVendor;
        }
        if (hydratedState.selectedCustomer != null) {
          _selectedCustomer = hydratedState.selectedCustomer;
        }
      });
    } catch (error) {
      if (mounted && routeEpoch == _routeEpoch) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Failed to load recurring expense: ${ErrorHandler.getFriendlyMessage(error)}',
        );
        context.pop();
      }
    } finally {
      if (mounted && routeEpoch == _routeEpoch) {
        setState(() {
          _isLoadingEditProfile = false;
        });
      }
    }
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

  List<StateLookupModel> _currentStateOptions() {
    return <StateLookupModel>[
      ...?ref.read(recurringExpenseStatesProvider('IN')).valueOrNull,
    ];
  }

  List<RecurringExpenseTaxOption> _currentTaxOptions() {
    return ref.read(recurringExpenseTaxesProvider).valueOrNull ??
        const <RecurringExpenseTaxOption>[];
  }

  StateLookupModel? _findMatchingStateOption(
    String? value, {
    List<StateLookupModel>? stateOptions,
  }) {
    final normalizedName = _normalizeStateName(value)?.trim().toLowerCase();
    if (normalizedName == null || normalizedName.isEmpty) {
      return null;
    }
    for (final option in stateOptions ?? _currentStateOptions()) {
      if (option.name.trim().toLowerCase() == normalizedName ||
          option.displayLabel.trim().toLowerCase() == normalizedName ||
          option.code.trim().toLowerCase() == normalizedName) {
        return option;
      }
    }
    return null;
  }

  String? _defaultStateName({List<StateLookupModel>? stateOptions}) {
    final options = stateOptions ?? _currentStateOptions();
    if (options.isEmpty) return null;
    final kerala = options.firstWhere(
      (s) => s.name == 'Kerala',
      orElse: () => options.first,
    );
    return kerala.name;
  }

  void _pruneHiddenTaxSelection({
    String? nextSource,
    String? nextDestination,
    List<StateLookupModel>? stateOptions,
    List<RecurringExpenseTaxOption>? taxes,
  }) {
    final nextSourceState = _findMatchingStateOption(
      nextSource ?? _selectedSourceOfSupply,
      stateOptions: stateOptions,
    );
    final nextDestinationState = _findMatchingStateOption(
      nextDestination ?? _selectedDestinationOfSupply,
      stateOptions: stateOptions,
    );
    final currentTax = _selectedTaxOption(taxes ?? _currentTaxOptions());
    if (currentTax != null &&
        !_isVisibleForStates(
          currentTax,
          nextSourceState,
          nextDestinationState,
        )) {
      _selectedTax = null;
      _clearExemptionReason();
      _hideItcEditor();
    }
  }

  void _applyGstTreatmentSelection(
    GstTreatmentLookupModel? value, {
    List<StateLookupModel>? stateOptions,
    List<RecurringExpenseTaxOption>? taxes,
  }) {
    _selectedGstTreatment = value?.label;
    _selectedDestinationOfSupply =
        value?.label == 'Registered Business - Regular'
        ? null
        : _defaultStateName(stateOptions: stateOptions);
    if (!_showTax) {
      _selectedTax = null;
      _clearExemptionReason();
    }
    if (!_showTax || _taxFieldReadOnly) {
      _hideItcEditor();
    }
  }

  void _applySourceOfSupplySelection(
    StateLookupModel? value, {
    List<StateLookupModel>? stateOptions,
    List<RecurringExpenseTaxOption>? taxes,
  }) {
    _selectedSourceOfSupply = value?.name;
    _pruneHiddenTaxSelection(
      nextSource: _selectedSourceOfSupply,
      stateOptions: stateOptions,
      taxes: taxes,
    );
  }

  void _applyVendorLinkedDropdownSelections(
    RecurringExpenseVendorOption? vendor, {
    List<StateLookupModel>? stateOptions,
    List<RecurringExpenseTaxOption>? taxes,
  }) {
    final matchingGstTreatment = _findMatchingGstTreatmentOption(
      vendor?.gstTreatment,
    );
    if (matchingGstTreatment != null) {
      _applyGstTreatmentSelection(
        matchingGstTreatment,
        stateOptions: stateOptions,
        taxes: taxes,
      );
    }
    final matchingSourceOfSupply = _findMatchingStateOption(
      vendor?.sourceOfSupply,
      stateOptions: stateOptions,
    );
    if (matchingSourceOfSupply != null && _showSourceOfSupply) {
      _applySourceOfSupplySelection(
        matchingSourceOfSupply,
        stateOptions: stateOptions,
        taxes: taxes,
      );
    }
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

  bool _isVisibleForStates(
    RecurringExpenseTaxOption item,
    StateLookupModel? sourceState,
    StateLookupModel? destinationState,
  ) {
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

  bool _isNonTaxableOption(RecurringExpenseTaxOption item) {
    final label = item.label.trim().toUpperCase();
    return label == 'NON-TAXABLE' || label == 'NON TAXABLE';
  }

  String _formatDisplayDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    return '$day-$month-$year';
  }

  String _formatApiDate(DateTime value) {
    final normalized = DateUtils.dateOnly(value);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  RecurringRepeatType _resolveRepeatType() {
    if (_selectedRepeatEvery == 'Custom') {
      return switch (_selectedCustomRepeatUnit) {
        'Day(s)' => RecurringRepeatType.day,
        'Week(s)' => RecurringRepeatType.week,
        'Month(s)' => RecurringRepeatType.month,
        'Year(s)' => RecurringRepeatType.year,
        _ => RecurringRepeatType.week,
      };
    }

    return switch (_selectedRepeatEvery) {
      'Day' => RecurringRepeatType.day,
      'Week' => RecurringRepeatType.week,
      'Month' => RecurringRepeatType.month,
      'Year' => RecurringRepeatType.year,
      _ => RecurringRepeatType.week,
    };
  }

  DateTime _addMonths(DateTime value, int months) {
    final totalMonths = (value.year * 12) + value.month - 1 + months;
    final year = totalMonths ~/ 12;
    final month = (totalMonths % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = value.day.clamp(1, lastDay);
    return DateTime(year, month, day);
  }

  DateTime _nextRecurringExpenseDate() {
    if (_selectedRepeatEvery == 'Custom') {
      final interval = int.tryParse(_customRepeatIntervalCtrl.text.trim()) ?? 1;
      switch (_selectedCustomRepeatUnit) {
        case 'Day(s)':
          return _startDate.add(Duration(days: interval));
        case 'Week(s)':
          return _startDate.add(Duration(days: interval * 7));
        case 'Month(s)':
          return _addMonths(_startDate, interval);
        case 'Year(s)':
          return DateTime(
            _startDate.year + interval,
            _startDate.month,
            _startDate.day,
          );
      }
    }

    switch (_selectedRepeatEvery) {
      case 'Day':
        return _startDate.add(const Duration(days: 1));
      case 'Week':
        return _startDate.add(const Duration(days: 7));
      case 'Month':
        return _addMonths(_startDate, 1);
      case 'Year':
        return DateTime(_startDate.year + 1, _startDate.month, _startDate.day);
      default:
        return _startDate;
    }
  }

  String get _nextRecurringExpenseDateText =>
      'The recurring expense will be created on '
      '${_formatDisplayDate(_nextRecurringExpenseDate())}';

  bool get _shouldShowRecurringScheduleHint {
    if (_selectedRepeatEvery.isEmpty) {
      return false;
    }

    final DateTime nextDate = _nextRecurringExpenseDate();

    if (_neverExpires) {
      return true;
    }

    if (_endDate == null) {
      return false;
    }

    return !nextDate.isAfter(DateUtils.dateOnly(_endDate!));
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_handleAmountValueChanged);
    _hideItcEditor();
    _profileNameCtrl.dispose();
    _customRepeatIntervalCtrl.dispose();
    _amountCtrl.dispose();
    _hsnCodeCtrl.dispose();
    _notesCtrl.dispose();
    _exemptionReasonCtrl.dispose();
    super.dispose();
  }

  RecurringExpenseTaxOption? _selectedTaxOption(
    List<RecurringExpenseTaxOption> taxes,
  ) {
    for (final tax in taxes) {
      if (tax.isSelectable && tax.id == _selectedTax) {
        return tax;
      }
    }
    return null;
  }

  bool _showExemptionReasonField(List<RecurringExpenseTaxOption> taxes) =>
      _selectedTaxOption(taxes) != null &&
      _isNonTaxableOption(_selectedTaxOption(taxes)!);

  bool _showRecurringTaxAmountRow(List<RecurringExpenseTaxOption> taxes) =>
      _selectedTaxOption(taxes) != null &&
      !_isNonTaxableOption(_selectedTaxOption(taxes)!);

  void _clearExemptionReason() {
    _exemptionReasonCtrl.clear();
    _exemptionReasonErrorText = null;
  }

  bool _validateExemptionReasonIfNeeded(List<RecurringExpenseTaxOption> taxes) {
    if (!_showExemptionReasonField(taxes)) {
      return true;
    }
    final hasValue = _exemptionReasonCtrl.text.trim().isNotEmpty;
    setState(() {
      _exemptionReasonErrorText = hasValue
          ? null
          : 'Exemption Reason is required';
    });
    return hasValue;
  }

  double _calculateDisplayedTaxAmount(List<RecurringExpenseTaxOption> taxes) {
    final double amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    final RecurringExpenseTaxOption? selectedTax = _selectedTaxOption(taxes);
    final double rate = selectedTax?.rate ?? 0.0;

    if (amount <= 0 || rate <= 0) {
      return 0.0;
    }

    if (_amountIs == 'Tax Inclusive') {
      return amount * rate / (100 + rate);
    }

    return amount * rate / 100;
  }

  String _formatDisplayedTaxAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  void _hideItcEditor() {
    _itcOverlayEntry?.remove();
    _itcOverlayEntry = null;
  }

  void _safePop() {
    try {
      context.pop();
      return;
    } catch (_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return;
      }
    }

    final routeState = GoRouterState.of(context);
    final returnTo = routeState.uri.queryParameters['returnTo'];
    if (returnTo != null && returnTo.isNotEmpty) {
      context.go(returnTo);
      return;
    }

    if (mounted) {
      context.go(
        '/${RecurringExpenseModuleDefaults.orgSystemId}${RecurringExpenseRoutes.list}',
      );
    }
  }

  void _syncStateToNotifier() {
    final notifier = ref.read(recurringExpenseFormNotifierProvider.notifier);
    final repeatType = _resolveRepeatType();
    final repeatEvery = _selectedRepeatEvery == 'Custom'
        ? int.tryParse(_customRepeatIntervalCtrl.text.trim()) ?? 1
        : 1;

    notifier.updateProfileName(_profileNameCtrl.text.trim());
    notifier.updateRepeatEvery(_selectedRepeatEvery);
    notifier.updateCustomRepeatInterval(repeatEvery);
    notifier.updateCustomRepeatUnit(repeatType.customUnitLabel);
    notifier.updateStartDate(_startDate);
    notifier.updateEndDate(_neverExpires ? null : _endDate);
    notifier.updateNeverExpires(_neverExpires);
    notifier.updateExpenseAccount(_selectedExpenseAccount);
    notifier.updateAmount(double.tryParse(_amountCtrl.text.trim()) ?? 0.0);
    notifier.updateCurrency(_selectedCurrency);
    notifier.updatePaidThrough(_selectedPaidThrough);
    notifier.updateExpenseType(_expenseType);
    notifier.updateHsnCode(
      _hsnCodeCtrl.text.trim().isEmpty ? null : _hsnCodeCtrl.text.trim(),
    );
    notifier.updateVendor(_selectedVendor);
    notifier.updateCustomer(_selectedCustomer);
    notifier.updateGstTreatment(_selectedGstTreatment);
    notifier.updateSourceOfSupply(_selectedSourceOfSupply);
    notifier.updateDestinationOfSupply(_selectedDestinationOfSupply);
    notifier.updateReverseCharge(_reverseCharge);
    notifier.updateTax(_selectedTax);
    notifier.updateAmountTaxMode(_amountIs);
    notifier.updateItcOption(_selectedItcOption);
    notifier.updateNotes(_notesCtrl.text.trim());
    notifier.updateIsBillable(_selectedCustomer != null && _isCustomerBillable);
  }

  CreateRecurringExpenseRequest _buildRequestFromNotifier() {
    final formState = ref.read(recurringExpenseFormNotifierProvider);
    return CreateRecurringExpenseRequest(
      profileName: formState.profileName,
      entityId: null,
      repeatEvery: formState.customRepeatInterval,
      repeatType: formState.selectedRepeatEvery == 'Custom'
          ? switch (formState.selectedCustomRepeatUnit) {
              'Day(s)' => RecurringRepeatType.day,
              'Week(s)' => RecurringRepeatType.week,
              'Month(s)' => RecurringRepeatType.month,
              'Year(s)' => RecurringRepeatType.year,
              _ => RecurringRepeatType.week,
            }
          : switch (formState.selectedRepeatEvery) {
              'Day' => RecurringRepeatType.day,
              'Week' => RecurringRepeatType.week,
              'Month' => RecurringRepeatType.month,
              'Year' => RecurringRepeatType.year,
              _ => RecurringRepeatType.week,
            },
      startDate: _formatApiDate(formState.startDate),
      endDate: formState.neverExpires || formState.endDate == null
          ? null
          : _formatApiDate(formState.endDate!),
      neverExpires: formState.neverExpires,
      status: _editingProfile?.status ?? RecurringExpenseStatus.active,
      expenseAccountId: formState.selectedExpenseAccount,
      amount: formState.amount,
      currencyCode: formState.selectedCurrency,
      paidThroughAccountId: formState.selectedPaidThrough,
      expenseType: formState.expenseType == 'Services'
          ? ExpenseType.services
          : ExpenseType.goods,
      hsnSacCode: formState.hsnCode,
      vendorId: formState.selectedVendor?.id,
      gstTreatment: _resolveGstTreatmentCode(formState.selectedGstTreatment),
      sourceOfSupply: formState.selectedSourceOfSupply,
      destinationOfSupply: formState.selectedDestinationOfSupply,
      reverseCharge: formState.reverseCharge,
      taxId: formState.selectedTax,
      amountTaxMode: formState.amountIs == 'Tax Inclusive'
          ? AmountTaxMode.inclusive
          : AmountTaxMode.exclusive,
      invoiceNumber: null,
      notes: formState.notes,
      customerId: formState.selectedCustomer?.id,
      includeCustomerIdField:
          _editingProfile != null && _customerSelectionCleared,
      isBillable: formState.selectedCustomer != null && formState.isBillable,
      autoCreate: true,
    );
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final taxes =
        ref.read(recurringExpenseTaxesProvider).valueOrNull ??
        const <RecurringExpenseTaxOption>[];
    if (!_validateExemptionReasonIfNeeded(taxes)) {
      return;
    }

    _syncStateToNotifier();
    final notifier = ref.read(recurringExpenseFormNotifierProvider.notifier);
    notifier.setSaving(true);

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = _buildRequestFromNotifier();
      if (_editingProfile == null) {
        await ref.read(createRecurringExpenseProvider(request).future);
      } else {
        await ref.read(
          updateRecurringExpenseProvider(
            UpdateRecurringExpenseRequest(
              id: _editingProfile!.id,
              recurringExpense: request,
            ),
          ).future,
        );
      }

      if (!mounted) {
        return;
      }

      ref.invalidate(recurringExpensesProvider);
      if (_editingProfile != null) {
        ref.invalidate(recurringExpenseDetailsProvider(_editingProfile!.id));
        ref.invalidate(recurringExpenseHistoryProvider(_editingProfile!.id));
        ref.invalidate(recurringExpenseRunsProvider(_editingProfile!.id));
      }

      ErrorHandler.showSuccessSnackBar(
        context,
        _editingProfile == null
            ? 'Recurring expense saved successfully.'
            : 'Recurring expense updated successfully.',
      );
      _safePop();
    } catch (error) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          ErrorHandler.getFriendlyMessage(error),
        );
      }
    } finally {
      notifier.setSaving(false);
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _onCancel() {
    _safePop();
  }

  Widget _fieldWidth(double width, Widget child) {
    final compactChild = _usesCompactFieldHeight(child)
        ? SizedBox(height: _recurringExpenseFieldHeight, child: child)
        : child;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: compactChild,
      ),
    );
  }

  bool _usesCompactFieldHeight(Widget child) {
    if (child is CustomTextField) {
      return child.maxLines == null || child.maxLines == 1;
    }
    return child is FormDropdown ||
        child is ZExpensesDatePicker ||
        child is AccountTreeDropdownWithAddButton ||
        child is ExpenseAccountDropdownWidget ||
        child is CustomerDropdownWidget ||
        child is VendorDropdownWidget;
  }

  Widget _w(Widget child) =>
      _fieldWidth(_recurringExpenseStandardFieldWidth, child);

  Widget _wWide(Widget child) =>
      _fieldWidth(_recurringExpenseWideFieldWidth, child);

  Widget _wLookup(Widget child) =>
      _fieldWidth(_recurringExpenseLookupFieldWidth, child);

  Widget _selectionField(Widget child) => SizedBox(
    height: _recurringExpenseFieldHeight,
    child: Align(alignment: Alignment.centerLeft, child: child),
  );

  Widget _buildNeverExpiresToggle() {
    return InkWell(
      onTap: () {
        setState(() {
          _neverExpires = !_neverExpires;
          if (_neverExpires) {
            _endDate = null;
          }
        });
      },
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
              ),
              child: SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: _neverExpires,
                  onChanged: (val) {
                    setState(() {
                      _neverExpires = val ?? false;
                      if (_neverExpires) {
                        _endDate = null;
                      }
                    });
                  },
                  activeColor: AppTheme.primaryBlueDark,
                  side: const BorderSide(
                    color: AppTheme.borderColorDark,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Never Expires',
              style: AppTextStyles.body.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItcEditor() {
    final selectedTaxOption = _selectedTaxOption(_currentTaxOptions());
    if (selectedTaxOption == null) {
      return;
    }
    if (_itcOverlayEntry != null) {
      _hideItcEditor();
      return;
    }

    final overlay = Overlay.of(context);
    String currentSelection = _selectedItcOption;
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
                            painter: _RecurringExpensePopoverArrowPainter(
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
                                    options: RecurringExpenseModuleDefaults
                                        .inputTaxCreditOptions,
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
                                        _selectedItcOption = currentSelection;
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

  Widget _buildRecurringTaxSummaryRow({
    required String text,
    required LayerLink layerLink,
    required GlobalKey anchorKey,
    required VoidCallback onTap,
  }) {
    return Row(
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
        CompositedTransformTarget(
          link: layerLink,
          child: InkWell(
            key: anchorKey,
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                LucideIcons.pencil,
                size: 12,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringTaxSummarySection({
    required String taxAmountText,
    required bool showItc,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.space20 + 164 + _recurringExpenseChildStartGap,
        right: AppTheme.space20,
        bottom: _recurringExpenseDenseSectionRowVerticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tax Amount = $taxAmountText INR',
            style: AppTextStyles.body.copyWith(color: AppTheme.textSecondary),
          ),
          if (showItc) ...[
            const SizedBox(height: 4),
            _buildRecurringTaxSummaryRow(
              text: _selectedItcOption,
              layerLink: _itcLayerLink,
              anchorKey: _itcAnchorKey,
              onTap: _showItcEditor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportingTagDropdown(_ReportingTagFieldConfig field) {
    return _fieldWidth(
      _recurringExpenseReportingTagFieldWidth,
      FormDropdown<String>(
        height: _recurringExpenseFieldHeight,
        value: _selectedReportingTagValues[field.id],
        items: _dummyItems,
        hint: _dummyItems.isEmpty ? 'None' : 'Select',
        onChanged: (val) {
          setState(() => _selectedReportingTagValues[field.id] = val);
        },
        showSearch: false,
      ),
    );
  }

  Widget _buildReportingTagField(_ReportingTagFieldConfig field) {
    return _RecurringExpenseFormRow(
      label: field.label,
      crossAxisAlignment: CrossAxisAlignment.start,
      child: _buildReportingTagDropdown(field),
    );
  }

  Widget _buildReportingTagDesktopField(_ReportingTagFieldConfig field) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 164,
          child: Text(
            field.label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: _recurringExpenseChildStartGap),
        Expanded(child: _buildReportingTagDropdown(field)),
      ],
    );
  }

  List<Widget> _buildReportingTagRows() {
    if (_reportingTagFields.isEmpty) {
      return const [];
    }

    final rows = <Widget>[];
    for (var index = 0; index < _reportingTagFields.length; index += 2) {
      final leftField = _reportingTagFields[index];
      final _ReportingTagFieldConfig? rightField =
          index + 1 < _reportingTagFields.length
          ? _reportingTagFields[index + 1]
          : null;

      rows.add(
        _row(
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow =
                  constraints.maxWidth <
                  _recurringExpenseReportingTagRowBreakPoint;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReportingTagField(leftField),
                    if (rightField != null) _buildReportingTagField(rightField),
                  ],
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space20,
                  vertical: _recurringExpenseRowVerticalPadding,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildReportingTagDesktopField(leftField)),
                    if (rightField != null) ...[
                      const SizedBox(
                        width: _recurringExpenseReportingTagColumnGap,
                      ),
                      Expanded(
                        child: _buildReportingTagDesktopField(rightField),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          isGray: false,
        ),
      );
    }
    return rows;
  }

  void _openAdvancedVendorSearch(
    List<RecurringExpenseVendorOption> vendorsList,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AdvancedVendorSearchDialog(
        vendors: vendorsList.map((vendor) => vendor.toVendor()).toList(),
        onSelect: (vendor) {
          setState(() {
            _selectedVendor = RecurringExpenseVendorOption.fromVendor(vendor);
            _applyVendorLinkedDropdownSelections(
              _selectedVendor,
              stateOptions: _currentStateOptions(),
              taxes: _currentTaxOptions(),
            );
          });
        },
      ),
    );
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
          setState(() {
            _selectedCustomer =
                RecurringExpenseCustomerOption.fromSalesCustomer(customer);
            if (_selectedCustomer == null) {
              _isCustomerBillable = false;
            }
          });
        },
      ),
    );
  }

  Future<void> _showNewVendorDialog() async {
    final newVendor = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.only(
          top: 0,
          bottom: 24,
          left: 40,
          right: 40,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const PurchasesVendorsVendorCreateScreen(isDialog: true),
          ),
        ),
      ),
    );
    if (!mounted || newVendor == null) {
      return;
    }
    setState(() {
      _selectedVendor = RecurringExpenseVendorOption.fromVendor(newVendor);
      _applyVendorLinkedDropdownSelections(
        _selectedVendor,
        stateOptions: _currentStateOptions(),
        taxes: _currentTaxOptions(),
      );
    });
  }

  Future<void> _openNewCustomer() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 200,
        ).copyWith(top: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SalesCustomerCreateScreen(
            showLayout: false,
            onSaveSuccess: (newCustomer) {
              Navigator.of(dialogContext).pop();
              ref.invalidate(salesCustomersProvider);
              if (!mounted) return;
              setState(() {
                _selectedCustomer =
                    RecurringExpenseCustomerOption.fromSalesCustomer(
                      newCustomer,
                    );
                _isCustomerBillable = false;
              });
            },
          ),
        ),
      ),
    );
  }

  bool get _showVendorGstin {
    return switch (_resolveGstTreatmentLabel(_selectedGstTreatment)) {
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
        _resolveGstTreatmentLabel(_selectedGstTreatment) != 'Overseas';
  }

  bool get _showSourceOfSupply {
    return switch (_resolveGstTreatmentLabel(_selectedGstTreatment)) {
      'Out Of Scope' || 'Overseas' => false,
      _ => true,
    };
  }

  bool get _showDestinationOfSupply {
    return _resolveGstTreatmentLabel(_selectedGstTreatment) != 'Out Of Scope';
  }

  bool get _showReverseCharge {
    return switch (_resolveGstTreatmentLabel(_selectedGstTreatment)) {
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
    return switch (_resolveGstTreatmentLabel(_selectedGstTreatment)) {
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
    return switch (_resolveGstTreatmentLabel(_selectedGstTreatment)) {
      'Registered Business - Regular' ||
      'Special Economic Zone' ||
      'Deemed Export' ||
      'Tax Deductor' ||
      'SEZ Developer' => true,
      _ => false,
    };
  }

  bool get _showEligibleForItc =>
      _selectedTaxOption(_currentTaxOptions()) != null &&
      !_isNonTaxableOption(_selectedTaxOption(_currentTaxOptions())!);

  bool get _taxFieldReadOnly {
    return switch (_resolveGstTreatmentLabel(_selectedGstTreatment)) {
      'Unregistered Business' || 'Unregistered' => true,
      _ => false,
    };
  }

  bool get _showAmountIs {
    return switch (_resolveGstTreatmentLabel(_selectedGstTreatment)) {
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

  Widget _row(
    Widget child, {
    required bool isGray,
    bool inheritBackground = false,
  }) {
    return Container(
      color: inheritBackground
          ? Colors.transparent
          : (isGray ? AppTheme.bgLight : AppTheme.backgroundColor),
      width: double.infinity,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(recurringExpenseAccountsProvider);
    final chartOfAccountsState = ref.watch(chartOfAccountsProvider);
    final vendorState = ref.watch(vendorProvider);
    final customersAsync = ref.watch(salesCustomersProvider);
    final currenciesAsync = ref.watch(recurringExpenseCurrenciesProvider);
    final gstTreatmentsAsync = ref.watch(recurringExpenseGstTreatmentsProvider);
    final statesAsync = ref.watch(recurringExpenseStatesProvider('IN'));
    final taxesAsync = ref.watch(recurringExpenseTaxesProvider);

    final List<AccountNode> accountsList = mapRecurringExpenseAccountNodes(
      accountsAsync.asData?.value ?? const <ExpenseAccountLookupModel>[],
    );
    final List<AccountNode> expenseAccountsList =
        buildRecurringExpenseGroupedAccountNodes(
          accountsAsync.asData?.value ?? const <ExpenseAccountLookupModel>[],
        );
    final String? paidThroughFallbackId = _editingProfile?.paidThroughId;
    final String? paidThroughFallbackName = _editingProfile?.paidThrough;
    if (!identical(_lastPaidThroughRootsIdentity, chartOfAccountsState.roots) ||
        _lastPaidThroughFallbackId != paidThroughFallbackId ||
        _lastPaidThroughFallbackName != paidThroughFallbackName) {
      _cachedPaidThroughAccountsList = buildRecurringPaidThroughAccountNodes(
        chartOfAccountsState.roots,
      );
      _lastPaidThroughRootsIdentity = chartOfAccountsState.roots;
      _lastPaidThroughFallbackId = paidThroughFallbackId;
      _lastPaidThroughFallbackName = paidThroughFallbackName;
    }
    final List<AccountNode> paidThroughAccountsList = List<AccountNode>.from(
      _cachedPaidThroughAccountsList,
    );
    bool containsAccount(List<AccountNode> nodes, String id) {
      for (final node in nodes) {
        if (node.id == id || containsAccount(node.children, id)) {
          return true;
        }
      }
      return false;
    }

    if (_editingProfile != null) {
      if (_editingProfile!.expenseAccountId != null &&
          !containsAccount(accountsList, _editingProfile!.expenseAccountId!)) {
        accountsList.insert(
          0,
          AccountNode(
            id: _editingProfile!.expenseAccountId!,
            name: _editingProfile!.expenseAccount,
            selectable: true,
          ),
        );
      }
      if (_editingProfile!.paidThroughId != null &&
          !containsAccount(
            paidThroughAccountsList,
            _editingProfile!.paidThroughId!,
          )) {
        paidThroughAccountsList.insert(
          0,
          AccountNode(
            id: _editingProfile!.paidThroughId!,
            name: _editingProfile!.paidThrough,
            selectable: true,
          ),
        );
      }
    }

    final vendorsList = vendorState.vendors
        .map(RecurringExpenseVendorOption.fromVendor)
        .toList();
    bool containsVendor(List<RecurringExpenseVendorOption> items, String id) {
      return items.any((item) => item.id == id);
    }

    if (_editingProfile?.vendorId != null && !_vendorSelectionCleared) {
      final vendorId = _editingProfile!.vendorId!;
      if (_selectedVendor == null) {
        _selectedVendor = vendorsList
            .cast<RecurringExpenseVendorOption?>()
            .firstWhere(
              (item) => item?.id == vendorId,
              orElse: () => RecurringExpenseVendorOption(
                id: vendorId,
                displayName: _editingProfile!.vendorName,
              ),
            );
      } else if (!containsVendor(vendorsList, _selectedVendor!.id)) {
        vendorsList.insert(0, _selectedVendor!);
      }
    }

    final customersList = (customersAsync.asData?.value ?? const [])
        .map(RecurringExpenseCustomerOption.fromSalesCustomer)
        .toList();
    bool containsCustomer(
      List<RecurringExpenseCustomerOption> items,
      String id,
    ) {
      return items.any((item) => item.id == id);
    }

    if (_editingProfile?.customerId != null && !_customerSelectionCleared) {
      final customerId = _editingProfile!.customerId!;
      final RecurringExpenseCustomerOption? matchingCustomer = customersList
          .cast<RecurringExpenseCustomerOption?>()
          .firstWhere((item) => item?.id == customerId, orElse: () => null);
      final bool isUsingSavedCustomerSelection =
          _selectedCustomer == null || _selectedCustomer!.id == customerId;

      if (isUsingSavedCustomerSelection) {
        if (matchingCustomer != null) {
          _selectedCustomer = matchingCustomer;
        } else if (_selectedCustomer == null ||
            _selectedCustomer!.displayName.trim().isEmpty) {
          _selectedCustomer = RecurringExpenseCustomerOption(
            id: customerId,
            displayName: _editingProfile!.customerName,
          );
        }
      }

      if (_selectedCustomer != null &&
          !containsCustomer(customersList, _selectedCustomer!.id)) {
        customersList.insert(0, _selectedCustomer!);
      }
    }

    final currencyOptions = <CurrencyLookupModel>[
      ...?currenciesAsync.asData?.value,
    ];
    final gstTreatmentOptions = <GstTreatmentLookupModel>[
      ...?gstTreatmentsAsync.asData?.value,
    ];
    final stateOptions = <StateLookupModel>[...?statesAsync.asData?.value];
    _gstTreatmentCatalog = gstTreatmentOptions;

    // Auto-select Kerala as Destination of Supply on create (one-shot, not edit).
    if (!_didApplyKeralaDefault &&
        _editingProfile == null &&
        stateOptions.isNotEmpty &&
        _selectedDestinationOfSupply == null) {
      final kerala = stateOptions.firstWhere(
        (s) => s.name == 'Kerala',
        orElse: () => stateOptions.first,
      );
      _didApplyKeralaDefault = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedDestinationOfSupply = kerala.name);
      });
    }

    GstTreatmentLookupModel? selectedGstTreatmentOption() {
      return _findMatchingGstTreatmentOption(_selectedGstTreatment);
    }

    StateLookupModel? selectedStateOption(String? name) {
      return _findMatchingStateOption(name, stateOptions: stateOptions);
    }

    final List<RecurringExpenseTaxOption> taxesList =
        taxesAsync.asData?.value ?? const <RecurringExpenseTaxOption>[];
    final sourceStateOption = selectedStateOption(_selectedSourceOfSupply);
    final destinationStateOption = selectedStateOption(
      _selectedDestinationOfSupply,
    );
    final List<RecurringExpenseTaxOption> visibleTaxesList =
        sourceStateOption == null || destinationStateOption == null
        ? taxesList
        : <RecurringExpenseTaxOption>[
            ...taxesList
                .where((item) => item.isUngrouped)
                .where(_isNonTaxableOption),
            ...(() {
              final rateTaxes = taxesList
                  .where((item) => item.isTaxRate)
                  .where(
                    (item) => _isVisibleForStates(
                      item,
                      sourceStateOption,
                      destinationStateOption,
                    ),
                  )
                  .toList(growable: false);
              return <RecurringExpenseTaxOption>[
                if (rateTaxes.isNotEmpty)
                  const RecurringExpenseTaxOption(
                    id: '__tax_header__',
                    label: 'Tax',
                    isHeader: true,
                    section: RecurringExpenseTaxOption.sectionTaxRate,
                  ),
                ...rateTaxes,
              ];
            }()),
            ...(() {
              final groupTaxes = taxesList
                  .where((item) => item.isTaxGroup)
                  .where(
                    (item) => _isVisibleForStates(
                      item,
                      sourceStateOption,
                      destinationStateOption,
                    ),
                  )
                  .toList(growable: false);
              return <RecurringExpenseTaxOption>[
                if (groupTaxes.isNotEmpty)
                  const RecurringExpenseTaxOption(
                    id: '__tax_group_header__',
                    label: 'Tax Group',
                    isHeader: true,
                    section: RecurringExpenseTaxOption.sectionTaxGroup,
                  ),
                ...groupTaxes,
              ];
            }()),
          ];

    void pruneHiddenTaxSelection({
      String? nextSource,
      String? nextDestination,
    }) {
      _pruneHiddenTaxSelection(
        nextSource: nextSource,
        nextDestination: nextDestination,
        stateOptions: stateOptions,
        taxes: taxesList,
      );
    }

    final RecurringExpenseTaxOption? selectedTaxOption = _selectedTaxOption(
      taxesList,
    );
    final String displayedTaxAmount = _formatDisplayedTaxAmount(
      _calculateDisplayedTaxAmount(taxesList),
    );

    return ZerpaiLayout(
      pageTitle: '', // Set empty to use custom title widget
      enableBodyScroll: !_isLoadingEditProfile,
      useHorizontalPadding: false,
      useTopPadding: false,
      titlePadding: const EdgeInsets.only(left: 24),
      titleWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.bookOpen,
            size: 20,
            color: AppTheme.textPrimary,
          ),
          const SizedBox(width: 8),
          Text(
            _editingProfile == null
                ? 'New Recurring Expense'
                : 'Edit Recurring Expense',
            style: AppTextStyles.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            LucideIcons.x,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          onPressed: _onCancel,
          tooltip: 'Close',
        ),
      ],
      footer: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border(top: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Row(
          children: [
            ZButton.primary(
              label: 'Save',
              loading: _isSubmitting,
              onPressed: _onSave,
            ),
            const SizedBox(width: 12),
            ZButton.secondary(
              label: 'Cancel',
              onPressed: _isSubmitting ? null : _onCancel,
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: _recurringExpenseFormTopPadding),
        child: _isLoadingEditProfile
            ? const RecurringExpenseLoadingIndicator(fillAvailableSpace: true)
            : Form(
                key: _formKey,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        color: AppTheme.bgLight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _row(
                              _RecurringExpenseFormRow(
                                label: 'Profile Name',
                                required: true,
                                child: _w(
                                  CustomTextField(
                                    controller: _profileNameCtrl,
                                    hintText: 'Enter profile name',
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Profile Name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              isGray: false,
                              inheritBackground: true,
                            ),
                            // _row(
                            //   ZerpaiFormRow(
                            //     label: 'Location',
                            //     child: _w(
                            //       FormDropdown<String>(
                            //         value: _selectedLocation,
                            //         items: const ['ZABNIX PRIVATE LIMITED'],
                            //         onChanged: (val) {
                            //           if (val != null) {
                            //             setState(() => _selectedLocation = val);
                            //           }
                            //         },
                            //       ),
                            //     ),
                            //   ),
                            //   isGray: false,
                            //   inheritBackground: true,
                            // ),
                            _row(
                              _RecurringExpenseFormRow(
                                label: 'Repeat Every',
                                required: true,
                                child: _selectedRepeatEvery == 'Custom'
                                    ? Align(
                                        alignment: Alignment.centerLeft,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth:
                                                _recurringExpenseCustomRepeatMaxWidth,
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width:
                                                    _recurringExpenseStandardFieldWidth,
                                                child: FormDropdown<String>(
                                                  height:
                                                      _recurringExpenseFieldHeight,
                                                  value: _selectedRepeatEvery,
                                                  items: const [
                                                    'Week',
                                                    'Month',
                                                    'Year',
                                                    'Day',
                                                    'Custom',
                                                  ],
                                                  onChanged: (val) {
                                                    if (val != null) {
                                                      setState(
                                                        () =>
                                                            _selectedRepeatEvery =
                                                                val,
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(
                                                width: AppTheme.space20,
                                              ),
                                              SizedBox(
                                                width:
                                                    _recurringExpenseCustomRepeatIntervalWidth,
                                                child: CustomTextField(
                                                  controller:
                                                      _customRepeatIntervalCtrl,
                                                  height:
                                                      _recurringExpenseFieldHeight,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.allow(
                                                      RegExp(r'[1-9][0-9]*'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                width: AppTheme.space20,
                                              ),
                                              SizedBox(
                                                width:
                                                    _recurringExpenseCustomRepeatUnitWidth,
                                                child: FormDropdown<String>(
                                                  height:
                                                      _recurringExpenseFieldHeight,
                                                  value:
                                                      _selectedCustomRepeatUnit,
                                                  items: const [
                                                    'Day(s)',
                                                    'Week(s)',
                                                    'Month(s)',
                                                    'Year(s)',
                                                  ],
                                                  showSearch: false,
                                                  onChanged: (val) {
                                                    if (val != null) {
                                                      setState(
                                                        () =>
                                                            _selectedCustomRepeatUnit =
                                                                val,
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : _w(
                                        FormDropdown<String>(
                                          height: _recurringExpenseFieldHeight,
                                          value: _selectedRepeatEvery,
                                          items: const [
                                            'Week',
                                            'Month',
                                            'Year',
                                            'Day',
                                            'Custom',
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(
                                                () =>
                                                    _selectedRepeatEvery = val,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                              ),
                              isGray: false,
                              inheritBackground: true,
                            ),
                            _row(
                              _RecurringExpenseFormRow(
                                label: 'Start Date',
                                verticalPadding:
                                    _recurringExpenseDenseSectionRowVerticalPadding,
                                child: _wWide(
                                  ZExpensesDatePicker(
                                    height: _recurringExpenseFieldHeight,
                                    selectedDate: _startDate,
                                    onDateSelected: (date) {
                                      setState(() => _startDate = date);
                                    },
                                  ),
                                ),
                              ),
                              isGray: false,
                              inheritBackground: true,
                            ),
                            if (_shouldShowRecurringScheduleHint)
                              _row(
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppTheme.space20,
                                    0,
                                    AppTheme.space20,
                                    AppTheme.space8,
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width:
                                            164 +
                                            _recurringExpenseChildStartGap,
                                      ),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: Text(
                                            _nextRecurringExpenseDateText,
                                            style: AppTextStyles.body.copyWith(
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                isGray: false,
                                inheritBackground: true,
                              ),
                            _row(
                              _RecurringExpenseFormRow(
                                label: 'Ends On',
                                verticalPadding:
                                    _recurringExpenseDenseSectionRowVerticalPadding,
                                child: _wWide(
                                  _neverExpires
                                      ? Container(
                                          height: _recurringExpenseFieldHeight,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.bgDisabled,
                                            border: Border.all(
                                              color: AppTheme.borderLight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_outlined,
                                                size: 14,
                                                color: AppTheme.textMuted,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'dd-MM-yyyy',
                                                style: AppTextStyles.body
                                                    .copyWith(
                                                      color: AppTheme.textMuted,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _endDate == null
                                      ? ZExpensesDatePicker(
                                          height: _recurringExpenseFieldHeight,
                                          selectedDate: null,
                                          onDateSelected: (date) {
                                            setState(() => _endDate = date);
                                          },
                                        )
                                      : ZExpensesDatePicker(
                                          height: _recurringExpenseFieldHeight,
                                          selectedDate: _endDate!,
                                          onDateSelected: (date) {
                                            setState(() => _endDate = date);
                                          },
                                        ),
                                ),
                              ),
                              isGray: false,
                              inheritBackground: true,
                            ),
                            _row(
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppTheme.space20,
                                  0,
                                  AppTheme.space20,
                                  AppTheme.space8,
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width:
                                          164 + _recurringExpenseChildStartGap,
                                    ),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: _buildNeverExpiresToggle(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isGray: false,
                              inheritBackground: true,
                            ),
                            _row(
                              _RecurringExpenseFormRow(
                                label: 'Expense Account',
                                required: true,
                                child: _w(
                                  ExpenseAccountDropdownWidget(
                                    value: _selectedExpenseAccount,
                                    nodes: expenseAccountsList,
                                    hint: 'Select an account',
                                    onChanged: (val) {
                                      setState(
                                        () => _selectedExpenseAccount = val,
                                      );
                                    },
                                    onAddAccount: () async {
                                      final createdAccountName =
                                          await AddAccountDialog.show(context);
                                      if (createdAccountName != null &&
                                          context.mounted) {
                                        ref.invalidate(
                                          recurringExpenseAccountsProvider,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                              isGray: false,
                              inheritBackground: true,
                            ),
                          ],
                        ),
                      ),

                      // Amount
                      _row(
                        _RecurringExpenseFormRow(
                          label: 'Amount',
                          required: true,
                          child: _w(
                            AmountInputWidget(
                              controller: _amountCtrl,
                              selectedCurrency: _selectedCurrency,
                              currencies: currencyOptions,
                              isLoadingCurrencies: currenciesAsync.isLoading,
                              onCurrencyChanged: (val) {
                                setState(() => _selectedCurrency = val);
                              },
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Amount is required';
                                }
                                if (double.tryParse(val) == null) {
                                  return 'Please enter a valid amount';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        isGray: false,
                      ),

                      // Paid Through
                      _row(
                        _RecurringExpenseFormRow(
                          label: 'Paid Through',
                          required: true,
                          child: _w(
                            AccountTreeDropdownWithAddButton(
                              value: _selectedPaidThrough,
                              nodes: paidThroughAccountsList,
                              height: _recurringExpenseFieldHeight,
                              hint: 'Select an account',
                              highlightSearchMatches: false,
                              onChanged: (val) {
                                setState(() => _selectedPaidThrough = val);
                              },
                            ),
                          ),
                        ),
                        isGray: false,
                      ),

                      // Expense Type
                      _row(
                        _RecurringExpenseFormRow(
                          label: 'Expense Type',
                          required: true,
                          verticalPadding:
                              _recurringExpenseDenseSectionRowVerticalPadding,
                          child: _w(
                            _selectionField(
                              ZerpaiRadioGroup<String>(
                                options: const ['Goods', 'Services'],
                                current: _expenseType,
                                onChanged: (val) {
                                  setState(() => _expenseType = val);
                                },
                              ),
                            ),
                          ),
                        ),
                        isGray: false,
                      ),

                      // HSN Code / SAC
                      _row(
                        _RecurringExpenseFormRow(
                          label: _expenseType == 'Goods' ? 'HSN Code' : 'SAC',
                          verticalPadding:
                              _recurringExpenseDenseSectionRowVerticalPadding,
                          child: _w(
                            CustomTextField(
                              controller: _hsnCodeCtrl,
                              forceUppercase: true,
                            ),
                          ),
                        ),
                        isGray: false,
                      ),

                      // Vendor
                      _row(
                        _RecurringExpenseFormRow(
                          label: 'Vendor',
                          verticalPadding:
                              _recurringExpenseDenseSectionRowVerticalPadding,
                          child: _wLookup(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: _recurringExpenseLookupInputWidth,
                                  child: VendorDropdownWidget(
                                    value: _selectedVendor,
                                    items: vendorsList,
                                    isLoading: vendorState.isLoading,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      bottomLeft: Radius.circular(4),
                                    ),
                                    hint: vendorState.isLoading
                                        ? 'Loading Vendors...'
                                        : vendorState.error != null
                                        ? 'Unable to load vendors'
                                        : vendorsList.isEmpty
                                        ? 'No Vendors Found'
                                        : 'Select a Vendor',
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedVendor = val;
                                        _vendorSelectionCleared = val == null;
                                        _applyVendorLinkedDropdownSelections(
                                          val,
                                          stateOptions: stateOptions,
                                          taxes: taxesList,
                                        );
                                      });
                                    },
                                    onAddVendor: _showNewVendorDialog,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _openAdvancedVendorSearch(vendorsList),
                                  child: Container(
                                    width: _recurringExpenseLookupActionWidth,
                                    height: _recurringExpenseFieldHeight,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.accentGreen,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(4),
                                        bottomRight: Radius.circular(4),
                                      ),
                                    ),
                                    child: const Icon(
                                      LucideIcons.search,
                                      color: AppTheme.backgroundColor,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        isGray: false,
                      ),

                      // GST Treatment
                      _row(
                        _RecurringExpenseFormRow(
                          label: 'GST Treatment',
                          required: true,
                          verticalPadding:
                              _recurringExpenseDenseSectionRowVerticalPadding,
                          child: _w(
                            FormDropdown<GstTreatmentLookupModel>(
                              height: _recurringExpenseFieldHeight,
                              value: selectedGstTreatmentOption(),
                              items: gstTreatmentOptions,
                              hint: gstTreatmentsAsync.isLoading
                                  ? 'Loading GST Treatments...'
                                  : gstTreatmentOptions.isEmpty
                                  ? 'No GST Treatments Found'
                                  : 'Select treatment',
                              menuMaxHeight: _recurringExpenseGstMenuMaxHeight,
                              itemHeight: _recurringExpenseGstOptionHeight,
                              isLoading: gstTreatmentsAsync.isLoading,
                              displayStringForValue: (item) => item.label,
                              textStyle: selectedGstTreatmentOption() == null
                                  ? null
                                  : AppTextStyles.input,
                              itemBuilder: (item, isSelected, isHovered) {
                                return buildRecurringExpenseGstOptionRow(
                                  item: item.label,
                                  isSelected: isSelected,
                                  isHovered: isHovered,
                                  height:
                                      _recurringExpenseGstOptionContentHeight,
                                  useStandardDropdownTypography: true,
                                );
                              },
                              onChanged: (val) {
                                setState(() {
                                  _applyGstTreatmentSelection(
                                    val,
                                    stateOptions: stateOptions,
                                    taxes: taxesList,
                                  );
                                });
                              },
                            ),
                          ),
                        ),
                        isGray: false,
                      ),

                      if (_showVendorGstin)
                        _row(
                          _RecurringExpenseFormRow(
                            label: 'Vendor GSTIN',
                            required: _vendorGstinRequired,
                            verticalPadding:
                                _recurringExpenseDenseSectionRowVerticalPadding,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width:
                                    _recurringExpenseCustomRepeatMaxWidth, // adjust if needed
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width:
                                          _recurringExpenseStandardFieldWidth,
                                      child: CustomTextField(
                                        height: _recurringExpenseFieldHeight,
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
                            ),
                          ),
                          isGray: false,
                        ),

                      // Source of Supply
                      if (_showSourceOfSupply)
                        _row(
                          _RecurringExpenseFormRow(
                            label: 'Source of Supply',
                            required: true,
                            verticalPadding:
                                _recurringExpenseDenseSectionRowVerticalPadding,
                            child: _w(
                              FormDropdown<StateLookupModel>(
                                height: _recurringExpenseFieldHeight,
                                value: selectedStateOption(
                                  _selectedSourceOfSupply,
                                ),
                                items: stateOptions,
                                hint: statesAsync.isLoading
                                    ? 'Loading States...'
                                    : stateOptions.isEmpty
                                    ? 'No States Found'
                                    : 'Select source state',
                                isLoading: statesAsync.isLoading,
                                displayStringForValue: (item) =>
                                    item.displayLabel,
                                onChanged: (val) {
                                  setState(() {
                                    _applySourceOfSupplySelection(
                                      val,
                                      stateOptions: stateOptions,
                                      taxes: taxesList,
                                    );
                                  });
                                },
                              ),
                            ),
                          ),
                          isGray: false,
                        ),

                      // Destination of Supply
                      if (_showDestinationOfSupply)
                        _row(
                          _RecurringExpenseFormRow(
                            label: 'Destination of Supply',
                            required: true,
                            verticalPadding:
                                _recurringExpenseDenseSectionRowVerticalPadding,
                            child: _w(
                              FormDropdown<StateLookupModel>(
                                height: _recurringExpenseFieldHeight,
                                value: selectedStateOption(
                                  _selectedDestinationOfSupply,
                                ),
                                items: stateOptions,
                                hint: statesAsync.isLoading
                                    ? 'Loading States...'
                                    : stateOptions.isEmpty
                                    ? 'No States Found'
                                    : 'State/Province',
                                isLoading: statesAsync.isLoading,
                                displayStringForValue: (item) =>
                                    item.displayLabel,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedDestinationOfSupply = val?.name;
                                    pruneHiddenTaxSelection(
                                      nextDestination:
                                          _selectedDestinationOfSupply,
                                    );
                                  });
                                },
                              ),
                            ),
                          ),
                          isGray: false,
                        ),

                      // Reverse Charge
                      if (_showReverseCharge)
                        _row(
                          _RecurringExpenseFormRow(
                            label: 'Reverse Charge',
                            verticalPadding:
                                _recurringExpenseDenseSectionRowVerticalPadding,
                            child: _w(
                              _selectionField(
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: const VisualDensity(
                                            horizontal: -4,
                                            vertical: -4,
                                          ),
                                        ),
                                        child: Checkbox(
                                          value: _reverseCharge,
                                          onChanged: (val) {
                                            setState(() {
                                              _reverseCharge = val ?? false;
                                              if (_reverseCharge) {
                                                _amountIs = 'Tax Exclusive';
                                              }
                                            });
                                          },
                                          activeColor: AppTheme.primaryBlueDark,
                                          side: const BorderSide(
                                            color: AppTheme.textSubtle,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'This transaction is applicable for reverse charge',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          isGray: false,
                        ),

                      // Tax
                      if (_showTax)
                        _row(
                          _RecurringExpenseFormRow(
                            label: 'Tax',
                            required: _taxRequired,
                            verticalPadding:
                                _recurringExpenseDenseSectionRowVerticalPadding,
                            child: _w(
                              MouseRegion(
                                cursor: _taxFieldReadOnly
                                    ? SystemMouseCursors.forbidden
                                    : MouseCursor.defer,
                                child: Focus(
                                  canRequestFocus: !_taxFieldReadOnly,
                                  descendantsAreFocusable: !_taxFieldReadOnly,
                                  child: AbsorbPointer(
                                    absorbing: _taxFieldReadOnly,
                                    child: FormDropdown<RecurringExpenseTaxOption>(
                                      height: _recurringExpenseFieldHeight,
                                      value: selectedTaxOption,
                                      items: visibleTaxesList,
                                      hint: 'Select a Tax',
                                      enabled: !_taxFieldReadOnly,
                                      fillColor: _taxFieldReadOnly
                                          ? AppTheme.bgDisabled
                                          : null,
                                      allowClear: true,
                                      showArrowOnSelection: true,
                                      showSearch: true,
                                      isItemEnabled: (item) =>
                                          item.isSelectable,
                                      displayStringForValue: (item) =>
                                          item.displayLabel,
                                      searchStringForValue: (item) =>
                                          item.searchLabel,
                                      textStyle: _taxFieldReadOnly
                                          ? AppTextStyles.input.copyWith(
                                              color: AppTheme.textMuted,
                                            )
                                          : null,
                                      itemHeight: 56.0,
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedTax = val?.id;
                                          if (val != null &&
                                              _isNonTaxableOption(val)) {
                                            _exemptionReasonErrorText = null;
                                            _hideItcEditor();
                                          } else {
                                            _clearExemptionReason();
                                          }
                                        });
                                      },
                                      itemBuilder:
                                          (item, isSelected, isHovered) {
                                            if (item.isHeader) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
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

                                            final Color backgroundColor =
                                                isHovered
                                                ? const Color(0xFF3B82F6)
                                                : (isSelected
                                                      ? const Color(0xFFF3F4F6)
                                                      : Colors.white);
                                            final Color primaryTextColor =
                                                isHovered
                                                ? Colors.white
                                                : AppTheme.textPrimary;
                                            final Color secondaryTextColor =
                                                isHovered
                                                ? Colors.white.withValues(
                                                    alpha: 0.85,
                                                  )
                                                : AppTheme.textSecondary;

                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: backgroundColor,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    item.displayLabel,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: primaryTextColor,
                                                    ),
                                                  ),
                                                  if (item.description !=
                                                          null &&
                                                      item
                                                          .description!
                                                          .isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item.description!,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color:
                                                            secondaryTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          isGray: false,
                        ),
                      if (_showRecurringTaxAmountRow(visibleTaxesList))
                        _row(
                          _buildRecurringTaxSummarySection(
                            taxAmountText: displayedTaxAmount,
                            showItc: _showEligibleForItc,
                          ),
                          isGray: false,
                        ),
                      if (_showExemptionReasonField(visibleTaxesList))
                        _row(
                          _RecurringExpenseFormRow(
                            label: 'Exemption Reason',
                            required: true,
                            verticalPadding:
                                _recurringExpenseDenseSectionRowVerticalPadding,
                            child: _w(
                              CustomTextField(
                                controller: _exemptionReasonCtrl,
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
                          ),
                          isGray: false,
                        ),
                      if (_showTax && _reverseCharge)
                        _row(
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space20,
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 164 + _recurringExpenseChildStartGap,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Reverse Charge',
                                      style: AppTextStyles.body.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          isGray: false,
                        ),

                      // Amount Is
                      if (_showAmountIs && !_reverseCharge)
                        _row(
                          _RecurringExpenseFormRow(
                            label: 'Amount Is',
                            verticalPadding:
                                _recurringExpenseDenseSectionRowVerticalPadding,
                            child: _w(
                              _selectionField(
                                ZerpaiRadioGroup<String>(
                                  options: const [
                                    'Tax Inclusive',
                                    'Tax Exclusive',
                                  ],
                                  current: _amountIs,
                                  onChanged: (val) {
                                    setState(() => _amountIs = val);
                                  },
                                ),
                              ),
                            ),
                          ),
                          isGray: false,
                        ),

                      // Notes
                      _row(
                        _RecurringExpenseFormRow(
                          label: 'Notes',
                          crossAxisAlignment: CrossAxisAlignment.start,
                          child: _w(
                            _RecurringExpenseResizableBox(
                              initialHeight: _notesFieldHeight,
                              minHeight:
                                  _recurringExpenseMultilineFieldMinHeight,
                              maxHeight: 220,
                              child: CustomTextField(
                                controller: _notesCtrl,
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
                              onResize: (height) {
                                setState(() {
                                  _notesFieldHeight = height;
                                });
                              },
                            ),
                          ),
                        ),
                        isGray: false,
                      ),

                      const Divider(height: 1, color: AppTheme.borderLight),

                      // Customer Name
                      _row(
                        _RecurringExpenseFormRow(
                          label: 'Customer Name',
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Customer dropdown + search button
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: _recurringExpenseLookupInputWidth,
                                    child: Container(
                                      height: _recurringExpenseFieldHeight,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          bottomLeft: Radius.circular(4),
                                        ),
                                      ),
                                      child: CustomerDropdownWidget(
                                        value: _selectedCustomer,
                                        items: customersList,
                                        isLoading: customersAsync.isLoading,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          bottomLeft: Radius.circular(4),
                                        ),
                                        hint: customersAsync.isLoading
                                            ? 'Loading Customers...'
                                            : customersAsync.hasError
                                            ? 'Unable to load customers'
                                            : customersList.isEmpty
                                            ? 'No Customers Found'
                                            : 'Select Customer',
                                        onChanged: (val) => setState(() {
                                          _selectedCustomer = val;
                                          _customerSelectionCleared =
                                              val == null;
                                          if (val == null) {
                                            _isCustomerBillable = false;
                                          }
                                        }),
                                        onAddCustomer: _openNewCustomer,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _openAdvancedCustomerSearch(
                                      customersList,
                                    ),
                                    child: Container(
                                      width: _recurringExpenseLookupActionWidth,
                                      height: _recurringExpenseFieldHeight,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.accentGreen,
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(4),
                                          bottomRight: Radius.circular(4),
                                        ),
                                      ),
                                      child: const Icon(
                                        LucideIcons.search,
                                        color: AppTheme.backgroundColor,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Billable checkbox — on same row as customer dropdown
                              if (_selectedCustomer != null) ...[
                                const SizedBox(width: 16),
                                SizedBox(
                                  height: _recurringExpenseFieldHeight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                            () => _isCustomerBillable =
                                                value ?? false,
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
                        ),
                        isGray: false,
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      ..._buildReportingTagRows(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
