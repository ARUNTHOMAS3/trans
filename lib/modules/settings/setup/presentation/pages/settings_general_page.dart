import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/widgets/settings_page_header.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/models/account_node.dart';
import 'package:zerpai_erp/shared/widgets/inputs/account_tree_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/resizable_box.dart';
import 'package:zerpai_erp/shared/widgets/inputs/got_it_popover.dart';
import 'package:zerpai_erp/modules/settings/shared/data/repositories/settings_preferences_repository.dart';

class SettingsGeneralPage extends ConsumerStatefulWidget {
  const SettingsGeneralPage({super.key});

  @override
  ConsumerState<SettingsGeneralPage> createState() =>
      _SettingsGeneralPageState();
}

class _SettingsGeneralPageState extends ConsumerState<SettingsGeneralPage> {
  final SettingsPreferencesRepository _preferencesRepository =
      SettingsPreferencesRepository();
  // State variables for form controls
  String _stockTrackingMode = 'physical'; // 'physical' or 'accounting'
  String _stockReconcileMode = 'automatically'; // 'automatically' or 'manually'

  // Enabled Modules
  bool _moduleBillOfSupply = true;
  bool _moduleDeliveryChallans = true;
  bool _moduleRetainerInvoices = true;
  bool _modulePicklists = true;
  bool _moduleStockCounts = true;
  bool _moduleTasks = true;

  // PDF settings
  bool _pdfAttach = true;
  bool _pdfEncrypt = true;

  // Discounts
  String _discountType = 'line_item'; // 'none', 'line_item', 'transaction'
  String _discountTaxTreatment = 'exclusive'; // 'exclusive', 'inclusive'
  String _transactionDiscountTiming = 'before_tax'; // 'before_tax', 'after_tax'

  // Additional Charges
  bool _chargeAdjustments = true;
  bool _chargeShipping = true;
  final TextEditingController _shippingSacController = TextEditingController(
    text: '996511',
  );

  // Rates inclusivity
  String _taxInclusivity = 'exclusive'; // 'inclusive', 'exclusive', 'both'

  // Rounding off
  String _roundingType =
      'nearest_whole'; // 'none', 'nearest_whole', 'nearest_incremental'
  String _currentRoundingIncrement = '0.05';
  bool _addSalespersonField = true;

  // Profit Margin
  bool _enableProfitMargin = false;

  // Billable Bills
  final TextEditingController _defaultMarkupController = TextEditingController(
    text: '10.0',
  );

  // Document copy labels
  final TextEditingController _twoCopyOriginal = TextEditingController(
    text: 'ORIGINAL',
  );
  final TextEditingController _twoCopyDuplicate = TextEditingController(
    text: 'DUPLICATE',
  );

  final TextEditingController _threeCopyOriginal = TextEditingController(
    text: 'ORIGINAL',
  );
  final TextEditingController _threeCopyDuplicate = TextEditingController(
    text: 'DUPLICATE',
  );
  final TextEditingController _threeCopyTriplicate = TextEditingController(
    text: 'TRIPLICATE',
  );

  final TextEditingController _fourFiveCopyOriginal = TextEditingController(
    text: 'ORIGINAL',
  );
  final TextEditingController _fourFiveCopyDuplicate = TextEditingController(
    text: 'DUPLICATE',
  );
  final TextEditingController _fourFiveCopyTriplicate = TextEditingController(
    text: 'TRIPLICATE',
  );
  final TextEditingController _fourFiveCopyQuadruplicate =
      TextEditingController(text: 'QUADRUPLICATE');
  final TextEditingController _fourFiveCopyQuintuplicate =
      TextEditingController(text: 'QUINTUPLICATE');

  // Print Preferences
  String _printPreference =
      'choose_while_printing'; // 'choose_while_printing', 'always_original'

  // Payment Retention
  bool _paymentRetentionEnabled = false;
  final List<RetentionRowData> _retentions = [];

  // Address format
  final TextEditingController _addressFormatController = TextEditingController(
    text:
        '\${ORGANIZATION.STREET_ADDRESS_1}\n\${ORGANIZATION.STREET_ADDRESS_2}\n\${ORGANIZATION.CITY} \${ORGANIZATION.STATE} \${ORGANIZATION.POSTAL_CODE}\n\${ORGANIZATION.COUNTRY}\n\${ORGANIZATION.GSTNO_LABEL} \${ORGANIZATION.GSTNO_VALUE}\n\${ORGANIZATION.PHONE}\n\${ORGANIZATION.EMAIL}\n\${ORGANIZATION.WEBSITE}',
  );
  final TextEditingController
  _dispatchAddressFormatController = TextEditingController(
    text:
        '\${ORGANIZATION.COMPANY_NAME}\n\${ORGANIZATION.STREET_ADDRESS_1}\n\${ORGANIZATION.STREET_ADDRESS_2}\n\${ORGANIZATION.CITY}\n\${ORGANIZATION.POSTAL_CODE} \${ORGANIZATION.STATE}',
  );

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final data = await _preferencesRepository.load();
      if (!mounted || data.isEmpty) return;
      final modules = _map(data['enabled_modules']);
      final pdf = _map(data['pdf_preferences']);
      final discounts = _map(data['discount_preferences']);
      final charges = _map(data['charges_preferences']);
      final stock = _map(data['stock_preferences']);
      final rounding = _map(data['rounding_preferences']);
      final labels = _map(data['document_copy_labels']);
      final retention = _map(data['retention_preferences']);
      final addresses = _map(data['address_formats']);
      setState(() {
        _moduleBillOfSupply = _bool(
          modules['bill_of_supply'],
          _moduleBillOfSupply,
        );
        _moduleDeliveryChallans = _bool(
          modules['delivery_challans'],
          _moduleDeliveryChallans,
        );
        _moduleRetainerInvoices = _bool(
          modules['retainer_invoices'],
          _moduleRetainerInvoices,
        );
        _modulePicklists = _bool(modules['picklists'], _modulePicklists);
        _moduleStockCounts = _bool(modules['stock_counts'], _moduleStockCounts);
        _moduleTasks = _bool(modules['tasks'], _moduleTasks);
        _pdfAttach = _bool(pdf['attach'], _pdfAttach);
        _pdfEncrypt = _bool(pdf['encrypt'], _pdfEncrypt);
        _printPreference = _string(pdf['print_preference'], _printPreference);
        _discountType = _string(discounts['type'], _discountType);
        _discountTaxTreatment = _string(
          discounts['tax_treatment'],
          _discountTaxTreatment,
        );
        _transactionDiscountTiming = _string(
          discounts['transaction_timing'],
          _transactionDiscountTiming,
        );
        _chargeAdjustments = _bool(charges['adjustments'], _chargeAdjustments);
        _chargeShipping = _bool(charges['shipping'], _chargeShipping);
        _shippingSacController.text = _string(
          charges['shipping_sac'],
          _shippingSacController.text,
        );
        _taxInclusivity = _string(charges['tax_inclusivity'], _taxInclusivity);
        _addSalespersonField = _bool(
          charges['add_salesperson_field'],
          _addSalespersonField,
        );
        _enableProfitMargin = _bool(
          charges['enable_profit_margin'],
          _enableProfitMargin,
        );
        _defaultMarkupController.text = _string(
          charges['default_markup'],
          _defaultMarkupController.text,
        );
        _stockTrackingMode = _string(
          stock['tracking_mode'],
          _stockTrackingMode,
        );
        _stockReconcileMode = _string(
          stock['reconcile_mode'],
          _stockReconcileMode,
        );
        _roundingType = _string(rounding['type'], _roundingType);
        _currentRoundingIncrement = _string(
          rounding['increment'],
          _currentRoundingIncrement,
        );
        _applyLabels(labels);
        _paymentRetentionEnabled = _bool(
          retention['enabled'],
          _paymentRetentionEnabled,
        );
        _applyRetentions(retention['rows']);
        _addressFormatController.text = _string(
          addresses['organization'],
          _addressFormatController.text,
        );
        _dispatchAddressFormatController.text = _string(
          addresses['dispatch'],
          _dispatchAddressFormatController.text,
        );
      });
    } catch (_) {
      if (mounted)
        ZerpaiToast.error(context, 'Failed to load general settings');
    }
  }

  @override
  void dispose() {
    _shippingSacController.dispose();
    _defaultMarkupController.dispose();
    _twoCopyOriginal.dispose();
    _twoCopyDuplicate.dispose();
    _threeCopyOriginal.dispose();
    _threeCopyDuplicate.dispose();
    _threeCopyTriplicate.dispose();
    _fourFiveCopyOriginal.dispose();
    _fourFiveCopyDuplicate.dispose();
    _fourFiveCopyTriplicate.dispose();
    _fourFiveCopyQuadruplicate.dispose();
    _fourFiveCopyQuintuplicate.dispose();
    _addressFormatController.dispose();
    _dispatchAddressFormatController.dispose();
    for (final r in _retentions) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    try {
      await _preferencesRepository.save({
        'enabled_modules': {
          'bill_of_supply': _moduleBillOfSupply,
          'delivery_challans': _moduleDeliveryChallans,
          'retainer_invoices': _moduleRetainerInvoices,
          'picklists': _modulePicklists,
          'stock_counts': _moduleStockCounts,
          'tasks': _moduleTasks,
        },
        'pdf_preferences': {
          'attach': _pdfAttach,
          'encrypt': _pdfEncrypt,
          'print_preference': _printPreference,
        },
        'discount_preferences': {
          'type': _discountType,
          'tax_treatment': _discountTaxTreatment,
          'transaction_timing': _transactionDiscountTiming,
        },
        'charges_preferences': {
          'adjustments': _chargeAdjustments,
          'shipping': _chargeShipping,
          'shipping_sac': _shippingSacController.text.trim(),
          'tax_inclusivity': _taxInclusivity,
          'add_salesperson_field': _addSalespersonField,
          'enable_profit_margin': _enableProfitMargin,
          'default_markup': _defaultMarkupController.text.trim(),
        },
        'stock_preferences': {
          'tracking_mode': _stockTrackingMode,
          'reconcile_mode': _stockReconcileMode,
        },
        'rounding_preferences': {
          'type': _roundingType,
          'increment': _currentRoundingIncrement,
        },
        'document_copy_labels': _labelsPayload(),
        'retention_preferences': {
          'enabled': _paymentRetentionEnabled,
          'rows': _retentions
              .map(
                (row) => {
                  'name': row.nameController.text.trim(),
                  'rate': row.rateController.text.trim(),
                  'description': row.descriptionController.text.trim(),
                  'receivable_account': row.receivableAccount,
                  'payable_account': row.payableAccount,
                },
              )
              .toList(),
        },
        'address_formats': {
          'organization': _addressFormatController.text,
          'dispatch': _dispatchAddressFormatController.text,
        },
      });
      if (mounted)
        ZerpaiToast.success(context, 'General settings saved successfully.');
    } catch (_) {
      if (mounted)
        ZerpaiToast.error(context, 'Failed to save general settings');
    }
  }

  Map<String, dynamic> _labelsPayload() => {
    'two': [_twoCopyOriginal.text, _twoCopyDuplicate.text],
    'three': [
      _threeCopyOriginal.text,
      _threeCopyDuplicate.text,
      _threeCopyTriplicate.text,
    ],
    'five': [
      _fourFiveCopyOriginal.text,
      _fourFiveCopyDuplicate.text,
      _fourFiveCopyTriplicate.text,
      _fourFiveCopyQuadruplicate.text,
      _fourFiveCopyQuintuplicate.text,
    ],
  };

  void _applyLabels(Map<String, dynamic> labels) {
    void apply(dynamic values, List<TextEditingController> controllers) {
      if (values is! List) return;
      for (var i = 0; i < values.length && i < controllers.length; i++) {
        controllers[i].text = values[i]?.toString() ?? '';
      }
    }

    apply(labels['two'], [_twoCopyOriginal, _twoCopyDuplicate]);
    apply(labels['three'], [
      _threeCopyOriginal,
      _threeCopyDuplicate,
      _threeCopyTriplicate,
    ]);
    apply(labels['five'], [
      _fourFiveCopyOriginal,
      _fourFiveCopyDuplicate,
      _fourFiveCopyTriplicate,
      _fourFiveCopyQuadruplicate,
      _fourFiveCopyQuintuplicate,
    ]);
  }

  void _applyRetentions(dynamic rows) {
    if (rows is! List) return;
    for (final row in _retentions) row.dispose();
    _retentions
      ..clear()
      ..addAll(
        rows.whereType<Map>().map(
          (row) => RetentionRowData(
            name: row['name']?.toString() ?? '',
            rate: row['rate']?.toString() ?? '',
            description: row['description']?.toString() ?? '',
            receivableAccount: row['receivable_account']?.toString(),
            payableAccount: row['payable_account']?.toString(),
          ),
        ),
      );
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  static bool _bool(dynamic value, bool fallback) =>
      value is bool ? value : fallback;
  static String _string(dynamic value, String fallback) =>
      value?.toString() ?? fallback;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    final orgName =
        ref.watch(authUserProvider)?.orgName.trim() ?? 'Your Organization';

    final searchItems = [
      SettingsSearchItem(
        group: 'Organization',
        label: 'Profile',
        subtitle: 'Company details and contact info',
        onSelected: () =>
            context.go('/$orgSystemId${AppRoutes.settingsOrgProfile}'),
      ),
      SettingsSearchItem(
        group: 'Organization',
        label: 'Branding',
        subtitle: 'Company logos, colors and themes',
        onSelected: () =>
            context.go('/$orgSystemId${AppRoutes.settingsOrgBranding}'),
      ),
      SettingsSearchItem(
        group: 'Organization',
        label: 'Locations',
        subtitle: 'Manage branches and business locations',
        onSelected: () =>
            context.go('/$orgSystemId${AppRoutes.settingsLocations}'),
      ),
      SettingsSearchItem(
        group: 'Users & Roles',
        label: 'Users',
        subtitle: 'Invite and manage users',
        onSelected: () => context.go('/$orgSystemId${AppRoutes.settingsUsers}'),
      ),
      SettingsSearchItem(
        group: 'Users & Roles',
        label: 'Roles',
        subtitle: 'Configure user access permissions',
        onSelected: () => context.go('/$orgSystemId${AppRoutes.settingsRoles}'),
      ),
      SettingsSearchItem(
        group: 'Taxes & Compliance',
        label: 'Taxes',
        subtitle: 'GST, tax rates and exemptions',
        onSelected: () => context.go('/$orgSystemId${AppRoutes.settingsTaxes}'),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showSettingsSidebar = constraints.maxWidth >= 980;
          return Column(
            children: [
              SettingsPageHeader(orgName: orgName, searchItems: searchItems),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showSettingsSidebar)
                      SettingsNavigationSidebar(currentPath: currentPath),
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            // General settings heading bar pinned
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Text('General', style: AppTextStyles.title),
                                ],
                              ),
                            ),
                            // Scrollable settings body
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(32),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 820,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildModulesSection(),
                                        _buildDivider(),
                                        _buildPdfAttachmentSection(),
                                        _buildDivider(),
                                        _buildDiscountsSection(),
                                        _buildDivider(),
                                        _buildAdditionalChargesSection(),
                                        _buildDivider(),
                                        _buildTaxInclusivitySection(),
                                        _buildDivider(),
                                        _buildRoundingSection(),
                                        _buildDivider(),
                                        _buildProfitMarginSection(),
                                        _buildDivider(),
                                        _buildBillableMarkupSection(),
                                        _buildDivider(),
                                        _buildStockTrackingSection(),
                                        _buildDivider(),
                                        _buildDocumentCopyLabelsSection(),
                                        _buildDivider(),
                                        _buildPaymentRetentionSection(),
                                        _buildDivider(),
                                        _buildAddressFormatSection(),
                                        const SizedBox(height: 48),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Sticky Save/Cancel Button Bar
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  top: BorderSide(color: AppTheme.borderLight),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ZButton.primary(
                                    label: 'Save',
                                    onPressed: _handleSave,
                                  ),
                                  const SizedBox(width: 12),
                                  ZButton.secondary(
                                    label: 'Cancel',
                                    onPressed: () {
                                      context.go(
                                        '/$orgSystemId${AppRoutes.settings}',
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Divider(color: AppTheme.borderLight, height: 1),
    );
  }

  // Physical Stock Reconciliation Dialog
  void _showPhysicalStockReconciliationDialog() {
    String localMode = _stockReconcileMode;
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // Info text based on selection
            final String infoText1 = localMode == 'automatically'
                ? 'Whenever you raise a standalone invoice or bill, it will be marked as shipped or received automatically and the physical stock will be updated for the same.'
                : 'The physical stock will not be updated whenever you raise a standalone invoice or bill.';
            final String infoText2 = localMode == 'automatically'
                ? 'The transaction date will be applied for the shipment/receive date, and you can undo this status by clicking Undo Shipment or Undo Receive on the respective invoice or bill.'
                : 'If you wish to update the physical stock for that transaction, you can do so by clicking "Mark as Shipped" or "Mark as Received" in the respective invoice or bill.';

            const Color textColor = Color(0xFF374151);

            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                width: 500,
                height: 475,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                      child: Row(
                        children: [
                          const Text(
                            'Physical Stock Reconciliation',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          const Spacer(),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => Navigator.of(ctx).pop(),
                              child: const Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(height: 20, color: Color(0xFFE5E7EB)),
                    ),
                    // Body
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'How do you want to reconcile your physical stock for standalone invoices and bills?',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Color(0xFF374151),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Dropdown
                            SizedBox(
                              width: 260,
                              child: FormDropdown<String>(
                                value: localMode,
                                items: const ['automatically', 'manually'],
                                displayStringForValue: (val) =>
                                    val == 'automatically'
                                    ? 'Automatically'
                                    : 'Manually',
                                height: 36,
                                showSearch: false,
                                itemBuilder: (item, isSelected, isHovered) {
                                  return Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item == 'automatically'
                                              ? 'Automatically'
                                              : 'Manually',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            color: isHovered
                                                ? Colors.white
                                                : AppTheme.textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check,
                                            size: 16,
                                            color: isHovered
                                                ? Colors.white
                                                : AppTheme.primaryBlue,
                                          ),
                                      ],
                                    ),
                                  );
                                },
                                onChanged: (val) =>
                                    setDialogState(() => localMode = val!),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Notes container
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFFEDD5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '•',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          infoText1,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: textColor,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '•',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          infoText2,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: textColor,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Footer buttons
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _stockReconcileMode = localMode);
                              Navigator.of(ctx).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              side: BorderSide(color: AppTheme.borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 1. Stock Tracking Section
  Widget _buildStockTrackingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mode of Stock tracking', style: AppTheme.sectionHeader),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Radio<String>(
                  value: 'physical',
                  groupValue: _stockTrackingMode,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => _stockTrackingMode = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Physical Stock - The stock on hand will be calculated based on Receives & Shipments',
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Radio<String>(
                  value: 'accounting',
                  groupValue: _stockTrackingMode,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => _stockTrackingMode = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Accounting Stock - The stock on hand will be calculated based on Bills & Invoices',
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Note 1 (Mode conditional)
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Text(
                      _stockTrackingMode == 'physical'
                          ? 'Irrespective of your preferred mode of stock tracking in Zerpai Inventory, the integrated Zerpai Books organization will always track stock based on Bills and Invoices.'
                          : 'Please note that if you change the mode of stock tracking, the stock level in your marketplaces will update only when the next sync occurs.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF374151),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Note 2 (Always visible, without dot, styled according to spec)
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 750),
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF374151),
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text:
                                'The physical stock gets updated ${_stockReconcileMode == 'automatically' ? 'automatically' : 'manually'} when you raise ',
                          ),
                          const TextSpan(
                            text: 'standalone bills and invoices',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: '. '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () =>
                                    _showPhysicalStockReconciliationDialog(),
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Modules section
  Widget _buildModulesSection() {
    Widget checkRow(String label, bool value, ValueChanged<bool?> onChanged) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Checkbox(
                  value: value,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  onChanged: onChanged,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.body),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select the modules you would like to enable.',
          style: AppTheme.sectionHeader,
        ),
        const SizedBox(height: 10),
        checkRow(
          'Bill Of Supply',
          _moduleBillOfSupply,
          (val) => setState(() => _moduleBillOfSupply = val!),
        ),
        checkRow(
          'Delivery Challans',
          _moduleDeliveryChallans,
          (val) => setState(() => _moduleDeliveryChallans = val!),
        ),
        checkRow(
          'Retainer Invoices',
          _moduleRetainerInvoices,
          (val) => setState(() => _moduleRetainerInvoices = val!),
        ),
        checkRow(
          'Picklists',
          _modulePicklists,
          (val) => setState(() => _modulePicklists = val!),
        ),
        checkRow(
          'Stock Counts',
          _moduleStockCounts,
          (val) => setState(() => _moduleStockCounts = val!),
        ),
        checkRow(
          'Tasks',
          _moduleTasks,
          (val) => setState(() => _moduleTasks = val!),
        ),
      ],
    );
  }

  // 3. PDF Attachment
  Widget _buildPdfAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PDF Attachment', style: AppTheme.sectionHeader),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Checkbox(
                  value: _pdfAttach,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  onChanged: (val) => setState(() => _pdfAttach = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Attach an invoice PDF to email notifications which contain invoice payment links.',
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Checkbox(
                  value: _pdfEncrypt,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  onChanged: (val) => setState(() => _pdfEncrypt = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'I would like to encrypt the PDF files that I send.',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'This will ensure that the PDF files cannot be edited or converted into another file format',
                    style: AppTextStyles.helper,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 4. Discounts
  Widget _buildDiscountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Do you give discounts?', style: AppTheme.sectionHeader),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Radio<String>(
                  value: 'none',
                  groupValue: _discountType,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => _discountType = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text("I don't give discounts", style: AppTextStyles.body),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Radio<String>(
                  value: 'line_item',
                  groupValue: _discountType,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => _discountType = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('At Line Item Level', style: AppTextStyles.body),
          ],
        ),
        if (_discountType == 'line_item')
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: SizedBox(
              width: 256,
              child: FormDropdown<String>(
                value: _discountTaxTreatment,
                items: const ['exclusive', 'inclusive'],
                displayStringForValue: (val) => val == 'exclusive'
                    ? 'Discount exclusive of tax'
                    : 'Discount inclusive of tax',
                height: 28,
                showSearch: true,
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                itemBuilder: (item, isSelected, isHovered) {
                  return Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item == 'exclusive'
                              ? 'Discount exclusive of tax'
                              : 'Discount inclusive of tax',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: isHovered
                                ? Colors.white
                                : AppTheme.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            size: 16,
                            color: isHovered
                                ? Colors.white
                                : AppTheme.primaryBlue,
                          ),
                      ],
                    ),
                  );
                },
                onChanged: (val) =>
                    setState(() => _discountTaxTreatment = val!),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Radio<String>(
                  value: 'transaction',
                  groupValue: _discountType,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => _discountType = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('At Transaction Level', style: AppTextStyles.body),
          ],
        ),
        if (_discountType == 'transaction')
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: SizedBox(
              width: 256,
              child: FormDropdown<String>(
                value: _transactionDiscountTiming,
                items: const ['before_tax', 'after_tax'],
                displayStringForValue: (val) => val == 'before_tax'
                    ? 'Discount Before Tax'
                    : 'Discount After Tax',
                height: 28,
                showSearch: true,
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                itemBuilder: (item, isSelected, isHovered) {
                  return Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item == 'before_tax'
                              ? 'Discount Before Tax'
                              : 'Discount After Tax',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: isHovered
                                ? Colors.white
                                : AppTheme.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            size: 16,
                            color: isHovered
                                ? Colors.white
                                : AppTheme.primaryBlue,
                          ),
                      ],
                    ),
                  );
                },
                onChanged: (val) =>
                    setState(() => _transactionDiscountTiming = val!),
              ),
            ),
          ),
      ],
    );
  }

  // 5. Additional Charges
  Widget _buildAdditionalChargesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select any additional charges you'll like to add",
          style: AppTheme.sectionHeader,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Checkbox(
                  value: _chargeAdjustments,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  onChanged: (val) => setState(() => _chargeAdjustments = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Adjustments', style: AppTextStyles.body),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Checkbox(
                  value: _chargeShipping,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  onChanged: (val) => setState(() => _chargeShipping = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Shipping Charges', style: AppTextStyles.body),
          ],
        ),
        if (_chargeShipping)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Default Shipping Charge SAC',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(width: 4),
                    const ZTooltip(
                      message:
                          'When you apply tax on a shipping charge, the SAC (Services Accounting Code) you enter here will be auto-populated in the transaction.',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 220,
                  height: 34,
                  child: TextField(
                    controller: _shippingSacController,
                    style: AppTextStyles.input,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 6. Tax Inclusivity
  Widget _buildTaxInclusivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Do you sell your items at rates inclusive of Tax?',
          style: AppTheme.sectionHeader,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Radio<String>(
                  value: 'inclusive',
                  groupValue: _taxInclusivity,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => _taxInclusivity = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Tax Inclusive', style: AppTextStyles.body),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Radio<String>(
                  value: 'exclusive',
                  groupValue: _taxInclusivity,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => _taxInclusivity = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Tax Exclusive', style: AppTextStyles.body),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Radio<String>(
                  value: 'both',
                  groupValue: _taxInclusivity,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => _taxInclusivity = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Tax Inclusive or Tax Exclusive',
              style: AppTextStyles.body,
            ),
          ],
        ),
      ],
    );
  }

  // 7. Rounding off
  Widget _buildRoundingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rounding off in Sales Transactions',
          style: AppTheme.sectionHeader,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Radio<String>(
                  value: 'none',
                  groupValue: _roundingType,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => _roundingType = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('No Rounding', style: AppTextStyles.body),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Radio<String>(
                  value: 'nearest_whole',
                  groupValue: _roundingType,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => _roundingType = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Round off the total to the nearest whole number',
              style: AppTextStyles.body,
            ),
            const SizedBox(width: 6),
            const _RoundingExamplesTooltip(),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Radio<String>(
                  value: 'nearest_incremental',
                  groupValue: _roundingType,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => _roundingType = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Round off the total to the nearest incremental value',
              style: AppTextStyles.body,
            ),
          ],
        ),
        if (_roundingType == 'nearest_incremental')
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 4, bottom: 4),
            child: Row(
              children: [
                const Text(
                  'The current rounding increment is set to: ',
                  style: AppTextStyles.helper,
                ),
                Text(
                  _currentRoundingIncrement,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                _ConfigureRoundingIncrementWidget(
                  currentValue: _currentRoundingIncrement,
                  onApply: (newVal) {
                    setState(() {
                      _currentRoundingIncrement = newVal;
                    });
                  },
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Checkbox(
                  value: _addSalespersonField,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  onChanged: (val) =>
                      setState(() => _addSalespersonField = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'I want to add a field for salesperson',
              style: AppTextStyles.body,
            ),
          ],
        ),
      ],
    );
  }

  // 8. Profit Margin
  Widget _buildProfitMarginSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profit Margin', style: AppTheme.sectionHeader),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Checkbox(
                  value: _enableProfitMargin,
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  onChanged: (val) =>
                      setState(() => _enableProfitMargin = val!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enable Profit Margin estimation at line item and transaction level.',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Once enabled, a profit margin estimate will be shown for each line item in the items table, as well as for the overall transaction.',
                    style: AppTextStyles.helper,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 9. Billable bills markup
  Widget _buildBillableMarkupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Billable Bills and Expenses', style: AppTheme.sectionHeader),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Default Markup Percentage', style: AppTextStyles.body),
            const SizedBox(width: 6),
            const ZTooltip(
              message:
                  'Enter a default markup percentage to mark up the bills and expenses while invoicing',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 114,
          height: 34,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _defaultMarkupController,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: AppTextStyles.input,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Container(
                width: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  border: Border(left: BorderSide(color: AppTheme.borderColor)),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '%',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 10. Document Copy Labels
  Widget _buildDocumentCopyLabelsSection() {
    Widget cell(String text, {bool isHeader = false}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: isHeader
                ? AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B7280),
                    fontSize: 11,
                  )
                : AppTextStyles.bodySmall,
          ),
        ),
      );
    }

    Widget inputCell(TextEditingController controller) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: SizedBox(
            height: 34,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.left,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryBlue,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget emptyCell() {
      return const Expanded(child: SizedBox.shrink());
    }

    Widget rowHeader(String text) {
      String tooltipMessage = '';
      if (text == 'Two Copies') {
        tooltipMessage =
            'A supplier copy and a recipient copy will be printed.';
      } else if (text == 'Three Copies') {
        tooltipMessage =
            'A supplier copy, a transporter copy, and a recipient copy will be printed.';
      } else if (text == 'Four/Five Copies') {
        tooltipMessage =
            'One/Two additional copies will be printed along with original, duplicate, and triplicate.';
      }

      return SizedBox(
        width: 140,
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ZTooltip(
              message: tooltipMessage,
              direction: ZTooltipDirection.top,
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textBody,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dashed,
                  decorationColor: Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Document copy label', style: AppTheme.sectionHeader),
            const SizedBox(width: 6),
            const ZTooltip(
              message: 'Specify labels for additional copies of the document.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 290,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      const SizedBox(width: 140),
                      cell('ORIGINAL', isHeader: true),
                      cell('DUPLICATE', isHeader: true),
                      cell('TRIPLICATE', isHeader: true),
                      cell('QUADRUPLICATE', isHeader: true),
                      cell('QUINTUPLICATE', isHeader: true),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.borderLight, height: 1),
                // Copy rows centered in remaining space
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Two Copies Row
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            rowHeader('Two Copies'),
                            inputCell(_twoCopyOriginal),
                            inputCell(_twoCopyDuplicate),
                            emptyCell(),
                            emptyCell(),
                            emptyCell(),
                          ],
                        ),
                      ),
                      // Three Copies Row
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            rowHeader('Three Copies'),
                            inputCell(_threeCopyOriginal),
                            inputCell(_threeCopyDuplicate),
                            inputCell(_threeCopyTriplicate),
                            emptyCell(),
                            emptyCell(),
                          ],
                        ),
                      ),
                      // Four/Five Copies Row
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            rowHeader('Four/Five Copies'),
                            inputCell(_fourFiveCopyOriginal),
                            inputCell(_fourFiveCopyDuplicate),
                            inputCell(_fourFiveCopyTriplicate),
                            inputCell(_fourFiveCopyQuadruplicate),
                            inputCell(_fourFiveCopyQuintuplicate),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.borderLight, height: 1),
                // Default print preferences section
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Default print preferences',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 220,
                        child: FormDropdown<String>(
                          value: _printPreference,
                          items: const [
                            'one_copy',
                            'two_copies',
                            'three_copies',
                            'four_copies',
                            'five_copies',
                            'choose_while_printing',
                          ],
                          displayStringForValue: (val) {
                            if (val == 'one_copy') return 'One Copy';
                            if (val == 'two_copies') return 'Two Copies';
                            if (val == 'three_copies') return 'Three Copies';
                            if (val == 'four_copies') return 'Four Copies';
                            if (val == 'five_copies') return 'Five Copies';
                            if (val == 'choose_while_printing') {
                              return 'I will choose while printing';
                            }
                            return '';
                          },
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _printPreference = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 12. Payment Retention
  Widget _buildPaymentRetentionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Retention', style: AppTheme.sectionHeader),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: AppTextStyles.label,
                      children: [
                        const TextSpan(
                          text:
                              'Enable this option to allow your customers to retain a part of their total invoice amount. ',
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GotItPopover(
                            title: 'How does Retention Payment work in Zerpai?',
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Retention Payment allows your customers to retain a percentage of the total invoice amount and pay it later on a specified date.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'When you enable it, you can add retention and they can be used when you create invoices.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Once you apply a retention to the invoice total amount, based on the rate percentage, an amount will be set aside as retention amount. So, your customer will pay you only the balance amount, that is, the invoice total amount minus the retention amount.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Later, when you receive payment for the retention amount on a mutually-agreed date, you can record it in two ways:',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  '1. Create an invoice for that payment',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'In the invoice, add Retention Payment as a line item and select an account to track the payment. You can send this invoice to your customer and record a payment for it.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  '2. Create a manual journal for that payment',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Go to Accountant on the left sidebar and create a manual journal with the tracked account as credit and your bank/cash account as debit.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            child: const MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Text(
                                'How does it work?',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              _paymentRetentionEnabled ? 'Enabled' : 'Disabled',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _paymentRetentionEnabled
                    ? AppTheme.accentGreen
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: _paymentRetentionEnabled,
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.primaryBlue,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFE5E7EB),
                trackOutlineColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
                onChanged: (val) {
                  if (val) {
                    _showEnableRetentionDialog();
                  } else {
                    setState(() => _paymentRetentionEnabled = false);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Enable Retention Dialog
  void _showEnableRetentionDialog() {
    // If empty, initialize with one row
    if (_retentions.isEmpty) {
      _retentions.add(RetentionRowData());
    }

    final List<AccountNode> receivableNodes = [
      AccountNode(
        id: 'other_current_asset',
        name: 'Other Current Asset',
        selectable: false,
        children: [
          AccountNode(id: 'advance_tax', name: 'Advance Tax'),
          AccountNode(id: 'cgst_tds_receivable', name: 'CGST TDS Receivable'),
          AccountNode(id: 'employee_advance', name: 'Employee Advance'),
          AccountNode(id: 'goods_in_transit', name: 'Goods In Transit'),
          AccountNode(id: 'igst_tds_receivable', name: 'IGST TDS Receivable'),
          AccountNode(
            id: 'input_tax_credits',
            name: 'Input Tax Credits',
            selectable: false,
            children: [
              AccountNode(id: 'input_cgst', name: 'Input CGST'),
              AccountNode(id: 'input_igst', name: 'Input IGST'),
              AccountNode(id: 'input_sgst', name: 'Input SGST'),
            ],
          ),
          AccountNode(id: 'prepaid_expenses', name: 'Prepaid Expenses'),
          AccountNode(id: 'rcm_input_cgst_9', name: 'RCM Input CGST 9%'),
          AccountNode(id: 'rcm_input_sgst_9', name: 'RCM Input SGST 9%'),
          AccountNode(
            id: 'reverse_charge_tax_input_not_due',
            name: 'Reverse Charge Tax Input but not due',
          ),
          AccountNode(id: 'sgst_tds_receivable', name: 'SGST TDS Receivable'),
          AccountNode(id: 'tcs_receivable', name: 'TCS Receivable'),
          AccountNode(id: 'tds_receivable', name: 'TDS Receivable'),
          AccountNode(
            id: 'zoho_payroll_loan_account',
            name: 'Zoho Payroll - Loan Account',
          ),
        ],
      ),
    ];

    final List<AccountNode> payableNodes = [
      AccountNode(
        id: 'other_current_liability',
        name: 'Other Current Liability',
        selectable: false,
        children: [
          AccountNode(id: 'cgst_tds_payable', name: 'CGST TDS Payable'),
          AccountNode(
            id: 'deductions_payable_004',
            name: '[ Payroll-04 ] Deductions Payable',
          ),
          AccountNode(
            id: 'director_salary_payables',
            name: 'Director salary payables',
            selectable: false,
            children: [
              AccountNode(id: 'dr_irfan_salary', name: 'Dr.Irfan-Salary'),
              AccountNode(id: 'mr_favas_salary', name: 'Mr.Favas-Salary'),
              AccountNode(id: 'mr_sameer_salary', name: 'Mr.Sameer-Salary'),
              AccountNode(
                id: 'rahul_muraleedaran_salary',
                name: 'RAHUL MURALEEDARAN - SALARY',
              ),
              AccountNode(id: 'reshama_salary', name: 'Reshama -Salary'),
            ],
          ),
          AccountNode(
            id: 'statutory_deductions_payable_003',
            name: '[ Payroll-003 ] Statutory Deductions Payable',
          ),
          AccountNode(id: 'tax_payable', name: 'Tax Payable'),
          AccountNode(id: 'tcs_payable', name: 'TCS Payable'),
          AccountNode(id: 'tds_payable', name: 'TDS Payable'),
          AccountNode(
            id: 'staff_salary_payable',
            name: 'Staff Salary Payable',
            selectable: false,
            children: [
              AccountNode(id: 'althaf_salary', name: 'Althaf -Salary'),
              AccountNode(id: 'bijisha_salary', name: 'Bijisha -Salary'),
              AccountNode(id: 'deepthi_salary', name: 'Deepthi -Salary'),
              AccountNode(id: 'fathima_salary', name: 'Fathima -Salary'),
              AccountNode(id: 'nandana_salary', name: 'Nandana -Salary'),
            ],
          ),
          AccountNode(
            id: 'payroll_tax_payable_002',
            name: '[ Payroll-002 ] Payroll Tax Payable',
          ),
          AccountNode(id: 'rcm_output_cgst_9', name: 'RCM Output CGST 9%'),
          AccountNode(id: 'rcm_output_sgst_9', name: 'RCM Output SGST 9%'),
          AccountNode(
            id: 'reimbursements_payable_001',
            name: '[ Payroll-001 ] Reimbursements Payable',
          ),
          AccountNode(id: 'rent_payable_ac', name: 'Rent Payable A/C'),
          AccountNode(id: 'sgst_tds_payable', name: 'SGST TDS Payable'),
          AccountNode(
            id: 'net_salary_payable_005',
            name: '[ Payroll-005 ] Net Salary Payable',
          ),
          AccountNode(
            id: 'opening_balance_adjustments',
            name: 'Opening Balance Adjustments',
          ),
          AccountNode(
            id: 'output_payable',
            name: 'Output Payable',
            selectable: false,
            children: [
              AccountNode(id: 'output_cgst', name: 'Output CGST'),
              AccountNode(id: 'output_igst', name: 'Output IGST'),
              AccountNode(id: 'output_sgst', name: 'Output SGST'),
            ],
          ),
        ],
      ),
    ];

    int? hoveredRowIndex;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (dialogCtx) {
        List<String> validationErrors = [];
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            const headerStyle = TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
            );

            Widget gridCell({
              required int flex,
              required Widget child,
              bool hasRightBorder = true,
              EdgeInsets padding = const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              Alignment alignment = Alignment.centerLeft,
            }) {
              return Expanded(
                flex: flex,
                child: Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    border: hasRightBorder
                        ? const Border(
                            right: BorderSide(color: AppTheme.borderLight),
                          )
                        : null,
                  ),
                  alignment: alignment,
                  child: child,
                ),
              );
            }

            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 680),
                child: SizedBox(
                  width: 840,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Enable Retention',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(dialogCtx).pop();
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),

                      // Body (Scrollable)
                      Flexible(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (validationErrors.isNotEmpty) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      border: Border.all(
                                        color: const Color(0xFFFFEDD5),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: validationErrors.map((
                                              error,
                                            ) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 2,
                                                    ),
                                                child: Text(
                                                  '•  $error',
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 13,
                                                    color: Color(0xFF374151),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () {
                                              setDialogState(() {
                                                validationErrors.clear();
                                              });
                                            },
                                            child: const Icon(
                                              LucideIcons.x,
                                              size: 16,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const Text(
                                  'Payment Retention will be enabled once you add a retention and click Save and Enable.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Table
                                // Table (no outer Container border, borders are drawn per-row/header to keep cancel button outside)
                                Column(
                                  children: [
                                    // Table Header
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF9FAFB),
                                              border: Border(
                                                top: BorderSide(
                                                  color: AppTheme.borderLight,
                                                ),
                                                left: BorderSide(
                                                  color: AppTheme.borderLight,
                                                ),
                                                right: BorderSide(
                                                  color: AppTheme.borderLight,
                                                ),
                                              ),
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(6),
                                                topRight: Radius.circular(6),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                gridCell(
                                                  flex: 4,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8,
                                                      ),
                                                  child: const Text(
                                                    'RETENTION NAME',
                                                    style: headerStyle,
                                                  ),
                                                ),
                                                gridCell(
                                                  flex: 3,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8,
                                                      ),
                                                  child: const Text(
                                                    'RATE (%)',
                                                    style: headerStyle,
                                                  ),
                                                ),
                                                gridCell(
                                                  flex: 5,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8,
                                                      ),
                                                  child: const Text(
                                                    'DESCRIPTION',
                                                    style: headerStyle,
                                                  ),
                                                ),
                                                gridCell(
                                                  flex: 5,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8,
                                                      ),
                                                  child: const Text(
                                                    'RECEIVABLE ACCOUNT',
                                                    style: headerStyle,
                                                  ),
                                                ),
                                                gridCell(
                                                  flex: 5,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8,
                                                      ),
                                                  child: const Text(
                                                    'PAYABLE ACCOUNT',
                                                    style: headerStyle,
                                                  ),
                                                  hasRightBorder: false,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 32,
                                        ), // spacer for cancel button column
                                      ],
                                    ),
                                    // Divider below header aligning with cells
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            color: AppTheme.borderLight,
                                          ),
                                        ),
                                        const SizedBox(width: 32),
                                      ],
                                    ),

                                    // Table Rows
                                    ...List.generate(_retentions.length, (
                                      index,
                                    ) {
                                      final row = _retentions[index];
                                      final isLast =
                                          index == _retentions.length - 1;
                                      return MouseRegion(
                                        onEnter: (_) => setDialogState(
                                          () => hoveredRowIndex = index,
                                        ),
                                        onExit: (_) => setDialogState(
                                          () => hoveredRowIndex = null,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    left: const BorderSide(
                                                      color:
                                                          AppTheme.borderLight,
                                                    ),
                                                    right: const BorderSide(
                                                      color:
                                                          AppTheme.borderLight,
                                                    ),
                                                    bottom: const BorderSide(
                                                      color:
                                                          AppTheme.borderLight,
                                                    ),
                                                  ),
                                                  borderRadius: isLast
                                                      ? const BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                6,
                                                              ),
                                                          bottomRight:
                                                              Radius.circular(
                                                                6,
                                                              ),
                                                        )
                                                      : null,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    // Name
                                                    gridCell(
                                                      flex: 4,
                                                      padding: EdgeInsets.zero,
                                                      alignment:
                                                          Alignment.topLeft,
                                                      child: SizedBox(
                                                        height: 38,
                                                        child: TextField(
                                                          controller: row
                                                              .nameController,
                                                          style: AppTextStyles
                                                              .body,
                                                          decoration: const InputDecoration(
                                                            hintText:
                                                                'Enter a name',
                                                            hintStyle: TextStyle(
                                                              fontSize: 13,
                                                              color: AppTheme
                                                                  .textMuted,
                                                            ),
                                                            contentPadding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 10,
                                                                ),
                                                            border: InputBorder
                                                                .none,
                                                            enabledBorder:
                                                                InputBorder
                                                                    .none,
                                                            focusedBorder:
                                                                InputBorder
                                                                    .none,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Rate
                                                    gridCell(
                                                      flex: 3,
                                                      padding: EdgeInsets.zero,
                                                      alignment:
                                                          Alignment.topLeft,
                                                      child: SizedBox(
                                                        height: 38,
                                                        child: TextField(
                                                          controller: row
                                                              .rateController,
                                                          textAlign:
                                                              TextAlign.right,
                                                          keyboardType:
                                                              const TextInputType.numberWithOptions(
                                                                decimal: true,
                                                              ),
                                                          inputFormatters: [
                                                            FilteringTextInputFormatter.allow(
                                                              RegExp(
                                                                r'^\d*\.?\d*',
                                                              ),
                                                            ),
                                                          ],
                                                          style: AppTextStyles
                                                              .body,
                                                          decoration: const InputDecoration(
                                                            hintText:
                                                                'Enter a rate',
                                                            hintStyle: TextStyle(
                                                              fontSize: 13,
                                                              color: AppTheme
                                                                  .textMuted,
                                                            ),
                                                            contentPadding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 10,
                                                                ),
                                                            border: InputBorder
                                                                .none,
                                                            enabledBorder:
                                                                InputBorder
                                                                    .none,
                                                            focusedBorder:
                                                                InputBorder
                                                                    .none,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Description
                                                    gridCell(
                                                      flex: 5,
                                                      padding: EdgeInsets.zero,
                                                      alignment:
                                                          Alignment.topLeft,
                                                      child: ResizableBox(
                                                        initialHeight: 38,
                                                        minHeight: 38,
                                                        maxHeight: 160,
                                                        onResize: (newHeight) {
                                                          setDialogState(() {});
                                                        },
                                                        child: TextField(
                                                          controller: row
                                                              .descriptionController,
                                                          maxLines: null,
                                                          keyboardType:
                                                              TextInputType
                                                                  .multiline,
                                                          style: AppTextStyles
                                                              .body,
                                                          decoration: const InputDecoration(
                                                            hintText:
                                                                'Enter the description',
                                                            hintStyle: TextStyle(
                                                              fontSize: 13,
                                                              color: AppTheme
                                                                  .textMuted,
                                                            ),
                                                            contentPadding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 10,
                                                                ),
                                                            border: InputBorder
                                                                .none,
                                                            enabledBorder:
                                                                InputBorder
                                                                    .none,
                                                            focusedBorder:
                                                                InputBorder
                                                                    .none,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Receivable Account
                                                    gridCell(
                                                      flex: 5,
                                                      padding: EdgeInsets.zero,
                                                      alignment:
                                                          Alignment.topLeft,
                                                      child: AccountTreeDropdown(
                                                        value: row
                                                            .receivableAccount,
                                                        nodes: receivableNodes,
                                                        hint:
                                                            'Select an account',
                                                        border: Border.all(
                                                          color: Colors
                                                              .transparent,
                                                        ),
                                                        height: 38,
                                                        showHierarchyBullets:
                                                            false,
                                                        dropdownWidth: 240,
                                                        onChanged: (val) {
                                                          setDialogState(() {
                                                            row.receivableAccount =
                                                                val;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    // Payable Account
                                                    gridCell(
                                                      flex: 5,
                                                      padding: EdgeInsets.zero,
                                                      hasRightBorder: false,
                                                      alignment:
                                                          Alignment.topLeft,
                                                      child: AccountTreeDropdown(
                                                        value:
                                                            row.payableAccount,
                                                        nodes: payableNodes,
                                                        hint:
                                                            'Select an account',
                                                        border: Border.all(
                                                          color: Colors
                                                              .transparent,
                                                        ),
                                                        height: 38,
                                                        showHierarchyBullets:
                                                            false,
                                                        dropdownWidth: 240,
                                                        onChanged: (val) {
                                                          setDialogState(() {
                                                            row.payableAccount =
                                                                val;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Cancel Button outside the table border
                                            SizedBox(
                                              width: 32,
                                              child: Opacity(
                                                opacity:
                                                    (hoveredRowIndex == index)
                                                    ? 1.0
                                                    : 0.0,
                                                child: IgnorePointer(
                                                  ignoring:
                                                      hoveredRowIndex != index,
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setDialogState(() {
                                                          _retentions
                                                              .removeAt(index)
                                                              .dispose();
                                                          if (_retentions
                                                              .isEmpty) {
                                                            _retentions.add(
                                                              RetentionRowData(),
                                                            );
                                                          }
                                                        });
                                                      },
                                                      child: const Icon(
                                                        LucideIcons.xCircle,
                                                        color: Color(
                                                          0xFFEF4444,
                                                        ),
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // New Retention Link/Button
                                GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      _retentions.add(RetentionRowData());
                                    });
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        LucideIcons.plusCircle,
                                        color: AppTheme.primaryBlue,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'New Retention',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Points to Note Card
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.borderLight,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const ZohoLightbulbIcon(size: 18),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Points to Note',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Text(
                                          '•  If you haven\'t selected Receivable Account, the Retention will be tracked under Retention Receivables account.\n'
                                          '•  If you haven\'t selected Payable Account, the Retention will be tracked under Retention Payables account.',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                            height: 1.6,
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

                      const Divider(height: 1, color: AppTheme.borderLight),
                      // Footer Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 122,
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () {
                                  final List<String> errors = [];
                                  bool hasEmptyName = false;
                                  bool hasEmptyRate = false;
                                  for (final ret in _retentions) {
                                    if (ret.nameController.text
                                        .trim()
                                        .isEmpty) {
                                      hasEmptyName = true;
                                    }
                                    if (ret.rateController.text
                                        .trim()
                                        .isEmpty) {
                                      hasEmptyRate = true;
                                    }
                                  }
                                  if (hasEmptyName) {
                                    errors.add(
                                      'Enter a name for the retention to continue.',
                                    );
                                  }
                                  if (hasEmptyRate) {
                                    errors.add('Enter a rate to continue.');
                                  }

                                  if (errors.isNotEmpty) {
                                    setDialogState(() {
                                      validationErrors = errors;
                                    });
                                    return;
                                  }

                                  setState(() {
                                    _paymentRetentionEnabled = true;
                                  });
                                  Navigator.of(dialogCtx).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary, // Emerald 500
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Save and Enable',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 32,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(dialogCtx).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  side: const BorderSide(
                                    color: AppTheme.borderColor,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
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
            );
          },
        );
      },
    );
  }

  // 13. Address Format Placeholders Data
  static const List<PlaceholderItem> orgPlaceholders = [
    PlaceholderItem('ORGANIZATION', '', isHeader: true),
    PlaceholderItem('Street Address1', '\${ORGANIZATION.STREET_ADDRESS_1}'),
    PlaceholderItem('Street Address2', '\${ORGANIZATION.STREET_ADDRESS_2}'),
    PlaceholderItem('Organization Name', '\${ORGANIZATION.NAME}'),
    PlaceholderItem('City', '\${ORGANIZATION.CITY}'),
    PlaceholderItem('State/Province', '\${ORGANIZATION.STATE}'),
    PlaceholderItem('Country', '\${ORGANIZATION.COUNTRY}'),
    PlaceholderItem('ZIP/Postal Code', '\${ORGANIZATION.POSTAL_CODE}'),
    PlaceholderItem('Fax Label', '\${ORGANIZATION.FAX_LABEL}'),
    PlaceholderItem('Fax', '\${ORGANIZATION.FAX}'),
    PlaceholderItem('Phone Label', '\${ORGANIZATION.PHONE_LABEL}'),
    PlaceholderItem('Phone', '\${ORGANIZATION.PHONE}'),
    PlaceholderItem('Email', '\${ORGANIZATION.EMAIL}'),
    PlaceholderItem('Website', '\${ORGANIZATION.WEBSITE}'),
    PlaceholderItem('Company ID :', '\${ORGANIZATION.COMPANY_ID_LABEL}'),
    PlaceholderItem('32AACCZ4912F1ZL', '\${ORGANIZATION.GSTIN_VALUE}'),
    PlaceholderItem('GSTIN', '\${ORGANIZATION.GSTIN_LABEL}'),
    PlaceholderItem('Attention', '\${ORGANIZATION.ATTENTION}'),
    PlaceholderItem('Location Name', '\${ORGANIZATION.LOCATION_NAME}'),
    PlaceholderItem('MSME/Udyam No Label', '\${ORGANIZATION.MSME_LABEL}'),
    PlaceholderItem('MSME/Udyam No', '\${ORGANIZATION.MSME_VALUE}'),
  ];

  static const List<PlaceholderItem> dispatchPlaceholders = [
    PlaceholderItem('Attention', '\${ORGANIZATION.ATTENTION}'),
    PlaceholderItem('Country', '\${ORGANIZATION.COUNTRY}'),
    PlaceholderItem('Street Address1', '\${ORGANIZATION.STREET_ADDRESS_1}'),
    PlaceholderItem('ZIP/Postal Code', '\${ORGANIZATION.POSTAL_CODE}'),
    PlaceholderItem('Street Address2', '\${ORGANIZATION.STREET_ADDRESS_2}'),
    PlaceholderItem('Phone', '\${ORGANIZATION.PHONE}'),
    PlaceholderItem('City', '\${ORGANIZATION.CITY}'),
    PlaceholderItem('Fax', '\${ORGANIZATION.FAX}'),
    PlaceholderItem('State/Province', '\${ORGANIZATION.STATE}'),
    PlaceholderItem('Company Name', '\${ORGANIZATION.COMPANY_NAME}'),
  ];

  Widget _buildAddressFormatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Organization Address Format
        Row(
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Inter'),
                children: [
                  TextSpan(
                    text: 'Organization Address Format',
                    style: AppTheme.sectionHeader.copyWith(fontSize: 14),
                  ),
                  const TextSpan(
                    text: ' (Displayed in PDF only) ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const ZTooltip(
              message:
                  'Placeholders and characters like comma, space, -, ., : are allowed.',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 410,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      PlaceholdersDropdownLauncher(
                        items: orgPlaceholders,
                        textController: _addressFormatController,
                        onChanged: () => setState(() {}),
                      ),
                      const Spacer(),
                      AddressPreviewLauncher(
                        textController: _addressFormatController,
                      ),
                    ],
                  ),
                ),
                // Text Area
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _addressFormatController,
                    maxLines: 6,
                    style: AppTextStyles.body.copyWith(fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hoverColor: Colors.transparent,
                      hintText: 'Enter address template...',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 2. Dispatch From Address Format
        Row(
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Inter'),
                children: [
                  TextSpan(
                    text: 'Dispatch From Address Format',
                    style: AppTheme.sectionHeader.copyWith(fontSize: 14),
                  ),
                  const TextSpan(
                    text: ' (Displayed in PDF only) ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const ZTooltip(
              message:
                  'Placeholders and characters like comma, space, -, ., : are allowed.',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 410,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      PlaceholdersDropdownLauncher(
                        items: dispatchPlaceholders,
                        textController: _dispatchAddressFormatController,
                        isGrid: true,
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                ),
                // Text Area
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _dispatchAddressFormatController,
                    maxLines: 6,
                    style: AppTextStyles.body.copyWith(fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hoverColor: Colors.transparent,
                      hintText: 'Enter address template...',
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
}

class _RoundingExamplesTooltip extends StatefulWidget {
  const _RoundingExamplesTooltip();

  @override
  State<_RoundingExamplesTooltip> createState() =>
      _RoundingExamplesTooltipState();
}

class _RoundingExamplesTooltipState extends State<_RoundingExamplesTooltip> {
  OverlayEntry? _entry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay() {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _hideOverlay,
            child: const SizedBox.expand(),
          ),
          Positioned(
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.centerRight,
              followerAnchor: Alignment.centerLeft,
              offset: const Offset(12, 0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 418.4,
                  height: 279,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Rounding Examples',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: _hideOverlay,
                                      child: const Icon(
                                        LucideIcons.x,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                            // Content
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Here are a few examples of how the amount is rounded off based on the decimal value.',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Table
                                    Column(
                                      children: [
                                        // Table Header
                                        Container(
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF3F4F6),
                                            border: Border(
                                              top: BorderSide(
                                                color: AppTheme.borderLight,
                                              ),
                                              bottom: BorderSide(
                                                color: AppTheme.borderLight,
                                              ),
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12,
                                          ),
                                          child: const Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'BEFORE ROUNDING',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF4B5563),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'AFTER ROUNDING',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF4B5563),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildRow('5336.49', '5336.00'),
                                        const Divider(
                                          height: 1,
                                          color: AppTheme.borderLight,
                                        ),
                                        _buildRow('5336.50', '5337.00'),
                                        const Divider(
                                          height: 1,
                                          color: AppTheme.borderLight,
                                        ),
                                        _buildRow(
                                          '5336.78',
                                          '5337.00',
                                          isLast: true,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Left triangular pointer arrow pointing to the icon
                      Positioned(
                        left: -6,
                        top: 133.5, // 279 / 2 - 6 (centered vertically)
                        child: CustomPaint(
                          size: const Size(6, 12),
                          painter: _TooltipArrowPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  void _hideOverlay() {
    _entry?.remove();
    _entry = null;
  }

  Widget _buildRow(String before, String after, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              before,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              after,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _showOverlay,
          child: const Icon(
            LucideIcons.info,
            size: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConfigureRoundingIncrementWidget extends StatefulWidget {
  final String currentValue;
  final ValueChanged<String> onApply;

  const _ConfigureRoundingIncrementWidget({
    required this.currentValue,
    required this.onApply,
  });

  @override
  State<_ConfigureRoundingIncrementWidget> createState() =>
      _ConfigureRoundingIncrementWidgetState();
}

class _ConfigureRoundingIncrementWidgetState
    extends State<_ConfigureRoundingIncrementWidget> {
  OverlayEntry? _entry;
  final LayerLink _layerLink = LayerLink();

  late String _selectedDecimalPlaces;
  late String _selectedIncrement;

  @override
  void initState() {
    super.initState();
    _selectedIncrement = widget.currentValue;
    _updateDecimalPlaces();
  }

  void _updateDecimalPlaces() {
    if (_selectedIncrement == '0.005' || _selectedIncrement == '0.125') {
      _selectedDecimalPlaces = '3';
    } else {
      _selectedDecimalPlaces = '2';
    }
  }

  void _showOverlay() {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            return Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _hideOverlay,
                  child: const SizedBox.expand(),
                ),
                Positioned(
                  child: CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    targetAnchor: Alignment.centerRight,
                    followerAnchor: Alignment.centerLeft,
                    offset: const Offset(12, 0),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 418.4,
                        height: 424.95,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Configure Rounding Increment',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: _hideOverlay,
                                            child: const Icon(
                                              LucideIcons.x,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    color: AppTheme.borderLight,
                                  ),
                                  // Content
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Select the nearest rounding increment based on the decimal places configured for your currency. View examples of how the increment is applied in the table below.',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Dropdown Rows
                                          // 1. Decimal Places (Read-only container with grey shade)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                const SizedBox(
                                                  width: 140,
                                                  child: Text(
                                                    'Decimal Places',
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 12,
                                                      color:
                                                          AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                const Text(
                                                  ' :   ',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    height: 32,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFF3F4F6,
                                                      ), // grey shade
                                                      border: Border.all(
                                                        color: AppTheme
                                                            .borderColor,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _selectedDecimalPlaces,
                                                      style: const TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 12,
                                                        color: AppTheme
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // 2. Rounding Increment (FormDropdown)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                const SizedBox(
                                                  width: 140,
                                                  child: Text(
                                                    'Rounding Increment',
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 12,
                                                      color:
                                                          AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                const Text(
                                                  ' :   ',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: FormDropdown<String>(
                                                    value: _selectedIncrement,
                                                    items: const [
                                                      '0.005',
                                                      '0.05',
                                                      '0.125',
                                                      '0.25',
                                                      '0.5',
                                                      '2',
                                                      '5',
                                                      '10',
                                                    ],
                                                    height: 28,
                                                    showSearch: true,
                                                    textStyle: const TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 13,
                                                      color:
                                                          AppTheme.textPrimary,
                                                    ),
                                                    itemBuilder: (item, isSelected, isHovered) {
                                                      return Container(
                                                        height: 28,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                            ),
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              item,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Inter',
                                                                fontSize: 13,
                                                                color: isHovered
                                                                    ? Colors
                                                                          .white
                                                                    : AppTheme
                                                                          .textPrimary,
                                                                fontWeight:
                                                                    isSelected
                                                                    ? FontWeight
                                                                          .w500
                                                                    : FontWeight
                                                                          .normal,
                                                              ),
                                                            ),
                                                            if (isSelected)
                                                              Icon(
                                                                Icons.check,
                                                                size: 16,
                                                                color: isHovered
                                                                    ? Colors
                                                                          .white
                                                                    : AppTheme
                                                                          .primaryBlue,
                                                              ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                    onChanged: (val) {
                                                      setOverlayState(() {
                                                        _selectedIncrement =
                                                            val!;
                                                        _updateDecimalPlaces();
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // Table
                                          Column(
                                            children: [
                                              // Table Header
                                              Container(
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFF3F4F6),
                                                  border: Border(
                                                    top: BorderSide(
                                                      color:
                                                          AppTheme.borderLight,
                                                    ),
                                                    bottom: BorderSide(
                                                      color:
                                                          AppTheme.borderLight,
                                                    ),
                                                  ),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 12,
                                                    ),
                                                child: const Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'BEFORE ROUNDING',
                                                        style: TextStyle(
                                                          fontFamily: 'Inter',
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Color(
                                                            0xFF4B5563,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        'AFTER ROUNDING',
                                                        style: TextStyle(
                                                          fontFamily: 'Inter',
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Color(
                                                            0xFF4B5563,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              _buildRow(
                                                '5867.34',
                                                _calculateRounded(
                                                  '5867.34',
                                                  _selectedIncrement,
                                                  _selectedDecimalPlaces,
                                                ),
                                              ),
                                              const Divider(
                                                height: 1,
                                                color: AppTheme.borderLight,
                                              ),
                                              _buildRow(
                                                '5336.5',
                                                _calculateRounded(
                                                  '5336.5',
                                                  _selectedIncrement,
                                                  _selectedDecimalPlaces,
                                                ),
                                              ),
                                              const Divider(
                                                height: 1,
                                                color: AppTheme.borderLight,
                                              ),
                                              _buildRow(
                                                '5336.782',
                                                _calculateRounded(
                                                  '5336.782',
                                                  _selectedIncrement,
                                                  _selectedDecimalPlaces,
                                                ),
                                                isLast: true,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          // Apply Button
                                          SizedBox(
                                            width: 56,
                                            height: 32,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                widget.onApply(
                                                  _selectedIncrement,
                                                );
                                                _hideOverlay();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .primary, // Emerald 500
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: const Text(
                                                'Apply',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Left triangular pointer arrow pointing to the Configure icon/button
                            Positioned(
                              left: -6,
                              top:
                                  206.5, // 424.95 / 2 - 6 (centered vertically)
                              child: CustomPaint(
                                size: const Size(6, 12),
                                painter: _TooltipArrowPainter(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    Overlay.of(context).insert(_entry!);
  }

  void _hideOverlay() {
    _entry?.remove();
    _entry = null;
  }

  String _calculateRounded(
    String valueStr,
    String incrementStr,
    String decimalPlacesStr,
  ) {
    double val = double.tryParse(valueStr) ?? 0.0;
    double increment = double.tryParse(incrementStr) ?? 0.05;
    int decimals = int.tryParse(decimalPlacesStr) ?? 2;
    if (increment == 0.0) return val.toStringAsFixed(decimals);
    double rounded = (val / increment).floor() * increment;
    return rounded.toStringAsFixed(decimals);
  }

  Widget _buildRow(String before, String after, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              before,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              after,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _showOverlay,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.settings,
                size: 14,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 4),
              Text(
                'Configure',
                style: AppTextStyles.body.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RetentionRowData {
  final TextEditingController nameController;
  final TextEditingController rateController;
  final TextEditingController descriptionController;
  String? receivableAccount;
  String? payableAccount;

  RetentionRowData({
    String name = '',
    String rate = '',
    String description = '',
    this.receivableAccount,
    this.payableAccount,
  }) : nameController = TextEditingController(text: name),
       rateController = TextEditingController(text: rate),
       descriptionController = TextEditingController(text: description);

  void dispose() {
    nameController.dispose();
    rateController.dispose();
    descriptionController.dispose();
  }
}

class PlaceholderItem {
  final String label;
  final String value;
  final bool isHeader;

  const PlaceholderItem(this.label, this.value, {this.isHeader = false});
}

class PlaceholdersDropdownLauncher extends StatefulWidget {
  final List<PlaceholderItem> items;
  final TextEditingController textController;
  final bool isGrid;
  final VoidCallback onChanged;

  const PlaceholdersDropdownLauncher({
    super.key,
    required this.items,
    required this.textController,
    required this.onChanged,
    this.isGrid = false,
  });

  @override
  State<PlaceholdersDropdownLauncher> createState() =>
      _PlaceholdersDropdownLauncherState();
}

class _PlaceholdersDropdownLauncherState
    extends State<PlaceholdersDropdownLauncher> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;
  bool _isOpen = false;
  String _searchQuery = '';
  int? _hoveredIndex;

  void _toggleOverlay() {
    if (_isOpen) {
      _closeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_entry != null) return;
    _searchQuery = '';
    _hoveredIndex = null;

    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    _entry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            final filtered = widget.items.where((item) {
              if (item.isHeader) return true;
              return item.label.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
            }).toList();

            // If there's only a header in the filtered list, clear the header too so it shows empty
            if (filtered.length == 1 && filtered.first.isHeader) {
              filtered.clear();
            }

            return Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _closeOverlay,
                  child: const SizedBox.expand(),
                ),
                Positioned(
                  width: 340,
                  height: 260,
                  child: CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    targetAnchor: Alignment.bottomLeft,
                    followerAnchor: Alignment.topLeft,
                    offset: const Offset(0, 4),
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            // Search bar
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                height: 32,
                                child: TextField(
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    hintText: 'Search',
                                    hintStyle: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                    prefixIcon: const Icon(
                                      LucideIcons.search,
                                      size: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: AppTheme.borderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: AppTheme.borderColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryBlue,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    setOverlayState(() {
                                      _searchQuery = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                            // Scrollable list/grid
                            Expanded(
                              child: filtered.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No placeholders found',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    )
                                  : RawScrollbar(
                                      thumbColor: Colors.black26,
                                      thickness: 4,
                                      radius: const Radius.circular(2),
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: widget.isGrid
                                            ? Wrap(
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: List.generate(filtered.length, (
                                                  idx,
                                                ) {
                                                  final item = filtered[idx];
                                                  final isHovered =
                                                      _hoveredIndex == idx;
                                                  return MouseRegion(
                                                    onEnter: (_) =>
                                                        setOverlayState(
                                                          () => _hoveredIndex =
                                                              idx,
                                                        ),
                                                    onExit: (_) =>
                                                        setOverlayState(
                                                          () => _hoveredIndex =
                                                              null,
                                                        ),
                                                    cursor: SystemMouseCursors
                                                        .click,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        _insertPlaceholder(
                                                          item.value,
                                                        );
                                                        _closeOverlay();
                                                      },
                                                      child: Container(
                                                        width: 154,
                                                        height: 28,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: isHovered
                                                              ? AppTheme
                                                                    .primaryBlue
                                                              : Colors
                                                                    .transparent,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          item.label,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isHovered
                                                                ? Colors.white
                                                                : AppTheme
                                                                      .textPrimary,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: List.generate(filtered.length, (
                                                  idx,
                                                ) {
                                                  final item = filtered[idx];
                                                  if (item.isHeader) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.fromLTRB(
                                                            12,
                                                            6,
                                                            12,
                                                            4,
                                                          ),
                                                      child: Text(
                                                        item.label,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppTheme
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    );
                                                  }

                                                  final isHovered =
                                                      _hoveredIndex == idx;
                                                  return MouseRegion(
                                                    onEnter: (_) =>
                                                        setOverlayState(
                                                          () => _hoveredIndex =
                                                              idx,
                                                        ),
                                                    onExit: (_) =>
                                                        setOverlayState(
                                                          () => _hoveredIndex =
                                                              null,
                                                        ),
                                                    cursor: SystemMouseCursors
                                                        .click,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        _insertPlaceholder(
                                                          item.value,
                                                        );
                                                        _closeOverlay();
                                                      },
                                                      child: Container(
                                                        width: double.infinity,
                                                        height: 28,
                                                        margin:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 4,
                                                              vertical: 1,
                                                            ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: isHovered
                                                              ? AppTheme
                                                                    .primaryBlue
                                                              : Colors
                                                                    .transparent,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          item.label,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isHovered
                                                                ? Colors.white
                                                                : AppTheme
                                                                      .textPrimary,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    overlay.insert(_entry!);
    setState(() => _isOpen = true);
  }

  void _closeOverlay() {
    _entry?.remove();
    _entry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _insertPlaceholder(String placeholder) {
    final controller = widget.textController;
    final currentText = controller.text;
    final selection = controller.selection;
    final start = selection.start.clamp(0, currentText.length);
    final end = selection.end.clamp(0, currentText.length);
    final newText = currentText.replaceRange(start, end, placeholder);
    controller.text = newText;
    controller.selection = TextSelection.collapsed(
      offset: start + placeholder.length,
    );
    widget.onChanged();
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggleOverlay,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Insert Placeholders',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textBody,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 16,
                color: AppTheme.textBody,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddressPreviewLauncher extends StatefulWidget {
  final TextEditingController textController;

  const AddressPreviewLauncher({super.key, required this.textController});

  @override
  State<AddressPreviewLauncher> createState() => _AddressPreviewLauncherState();
}

class _AddressPreviewLauncherState extends State<AddressPreviewLauncher> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;

  String _resolveAddressPreview(String template) {
    return template
        .replaceAll('\${ORGANIZATION.NAME}', 'Zabnix Private Limited')
        .replaceAll('\${ORGANIZATION.COMPANY_NAME}', 'Zabnix Private Limited')
        .replaceAll('\${ORGANIZATION.STREET_ADDRESS_1}', 'PERINTHALMANNA')
        .replaceAll('\${ORGANIZATION.STREET_ADDRESS_2}', 'MALAPPURAM')
        .replaceAll('\${ORGANIZATION.CITY}', 'MALAPPURAM')
        .replaceAll('\${ORGANIZATION.STATE}', 'Kerala')
        .replaceAll('\${ORGANIZATION.POSTAL_CODE}', '679322')
        .replaceAll('\${ORGANIZATION.COUNTRY}', 'India')
        .replaceAll('\${ORGANIZATION.GSTIN_LABEL}', 'GSTIN')
        .replaceAll('\${ORGANIZATION.GSTIN_VALUE}', '32AACCZ4912F1ZL')
        .replaceAll('\${ORGANIZATION.GSTNO_LABEL}', 'GSTIN')
        .replaceAll('\${ORGANIZATION.GSTNO_VALUE}', '32AACCZ4912F1ZL')
        .replaceAll('\${ORGANIZATION.PHONE}', '8086355500')
        .replaceAll('\${ORGANIZATION.EMAIL}', 'zabnixprivatelimited@gmail.com')
        .replaceAll('\${ORGANIZATION.WEBSITE}', 'www.zabnix.com')
        .replaceAll('\${ORGANIZATION.ATTENTION}', 'Manager')
        .replaceAll('\${ORGANIZATION.FAX}', '04933-222333')
        .replaceAll('\${ORGANIZATION.FAX_LABEL}', 'Fax');
  }

  void _showOverlay() {
    if (_entry != null) return;
    final resolvedText = _resolveAddressPreview(widget.textController.text);

    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _hideOverlay,
            child: const SizedBox.expand(),
          ),
          Positioned(
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(12, -16),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 360,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Arrow Pointer on the left pointing left
                      Positioned(
                        left: -6,
                        top: 8,
                        child: CustomPaint(
                          size: const Size(6, 12),
                          painter: _TooltipArrowPainter(),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 36, 16),
                        child: Text(
                          resolvedText,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      // Close button
                      Positioned(
                        right: 8,
                        top: 8,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _hideOverlay,
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                LucideIcons.x,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  void _hideOverlay() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _showOverlay,
          child: Text(
            'Preview',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }
}

class ZohoLightbulbIcon extends StatelessWidget {
  final double size;
  const ZohoLightbulbIcon({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _BulbIconPainter(),
    );
  }
}

class _BulbIconPainter extends CustomPainter {
  const _BulbIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..isAntiAlias = true;

    // 1. Draw the yellow/orange bulb body
    final Path bulbPath = Path();
    bulbPath.moveTo(size.width * 0.5, size.height * 0.15);
    bulbPath.cubicTo(
      size.width * 0.85,
      size.height * 0.15,
      size.width * 0.95,
      size.height * 0.48,
      size.width * 0.76,
      size.height * 0.68,
    );
    bulbPath.lineTo(size.width * 0.65, size.height * 0.80);
    bulbPath.lineTo(size.width * 0.35, size.height * 0.80);
    bulbPath.lineTo(size.width * 0.24, size.height * 0.68);
    bulbPath.cubicTo(
      size.width * 0.05,
      size.height * 0.48,
      size.width * 0.15,
      size.height * 0.15,
      size.width * 0.5,
      size.height * 0.15,
    );
    bulbPath.close();

    final Rect bulbRect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = const LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFFFFD13B), // Bright yellow
        Color(0xFFF59E0B), // Warm orange
      ],
    ).createShader(bulbRect);
    canvas.drawPath(bulbPath, paint);

    // 2. Draw the socket (base)
    paint.shader = null;
    paint.color = const Color(0xFF475569); // Dark blue-gray socket

    final Path socketPath = Path();
    socketPath.moveTo(size.width * 0.35, size.height * 0.80);
    socketPath.lineTo(size.width * 0.65, size.height * 0.80);
    socketPath.lineTo(size.width * 0.60, size.height * 0.92);
    socketPath.lineTo(size.width * 0.40, size.height * 0.92);
    socketPath.close();
    canvas.drawPath(socketPath, paint);

    // Draw base contact point
    paint.color = const Color(0xFF1E293B); // Darker base tip
    final Rect tipRect = Rect.fromLTWH(
      size.width * 0.45,
      size.height * 0.92,
      size.width * 0.10,
      size.height * 0.06,
    );
    canvas.drawRect(tipRect, paint);

    // 3. Draw the white lightning bolt/spark inside the bulb
    paint.color = Colors.white;
    final Path boltPath = Path();
    boltPath.moveTo(size.width * 0.53, size.height * 0.26); // Top tip
    boltPath.lineTo(size.width * 0.38, size.height * 0.50); // Down to left bend
    boltPath.lineTo(
      size.width * 0.48,
      size.height * 0.50,
    ); // Right inside corner
    boltPath.lineTo(size.width * 0.44, size.height * 0.68); // Bottom tip
    boltPath.lineTo(size.width * 0.60, size.height * 0.44); // Up to right bend
    boltPath.lineTo(
      size.width * 0.50,
      size.height * 0.44,
    ); // Left inside corner
    boltPath.close();
    canvas.drawPath(boltPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
