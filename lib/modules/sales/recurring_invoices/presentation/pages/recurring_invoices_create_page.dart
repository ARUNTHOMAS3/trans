import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/sales/recurring_invoices/models/recurring_invoices_model.dart';
import 'package:zerpai_erp/modules/sales/recurring_invoices/providers/recurring_invoices_provider.dart';
import 'package:zerpai_erp/modules/sales/models/hsn_sac_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_payment_terms_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/address_dialog.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/widgets/manage_tds_tcs_rates_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/add_contact_person_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/recurring_invoice_preferences_dialog.dart';
import 'package:zerpai_erp/shared/widgets/hsn_sac_search_modal.dart';
import 'package:zerpai_erp/shared/widgets/inputs/customer_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/inputs/warehouse_popover.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/customers/presentation/pages/sales_customer_create.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/bulk_items_dialog.dart';
import 'package:zerpai_erp/modules/sales/shared/widgets/sales_item_table_shell.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/repositories/pricelist_repository.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

const double _kRecurringTextSize = 13;

// ── Models & Constants ───────────────────────────────────────────────────────

class _CustomerItem {
  final String id;
  final String name;
  final String code;
  final String subtitle;
  final SalesCustomer? data;
  const _CustomerItem({
    required this.id,
    required this.name,
    required this.code,
    required this.subtitle,
    this.data,
  });
}

class _TaxOption {
  final String title;
  final String subtitle;
  final bool isHeader;

  const _TaxOption(this.title, {this.subtitle = '', this.isHeader = false});
}

class _TaxSummaryLine {
  final String label;
  final double amount;

  const _TaxSummaryLine({required this.label, required this.amount});
}

class _IncomeAccountOption {
  final String title;
  final String? accountId;
  final String searchText;
  final bool isHeader;
  final int level;

  const _IncomeAccountOption(
    this.title, {
    this.accountId,
    this.searchText = '',
    this.isHeader = false,
    this.level = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _IncomeAccountOption &&
        other.title == title &&
        other.accountId == accountId &&
        other.isHeader == isHeader &&
        other.level == level;
  }

  @override
  int get hashCode => Object.hash(title, accountId, isHeader, level);
}

class _DiscountAccountOption {
  final String title;
  final String? accountId;
  final String searchText;
  final bool isHeader;
  final int level;

  const _DiscountAccountOption(
    this.title, {
    this.accountId,
    this.searchText = '',
    this.isHeader = false,
    this.level = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _DiscountAccountOption &&
        other.title == title &&
        other.accountId == accountId &&
        other.isHeader == isHeader &&
        other.level == level;
  }

  @override
  int get hashCode => Object.hash(title, accountId, isHeader, level);
}

class _TransactionSeriesItem {
  final String id;
  final String name;

  const _TransactionSeriesItem({required this.id, required this.name});
}

class _SalespersonOption {
  final String id;
  final String name;
  final String email;
  final bool isActive;

  const _SalespersonOption({
    required this.id,
    required this.name,
    required this.email,
    this.isActive = true,
  });

  _SalespersonOption copyWith({
    String? id,
    String? name,
    String? email,
    bool? isActive,
  }) {
    return _SalespersonOption(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
    );
  }
}

class _PriceListPopupRow extends StatefulWidget {
  final String label;
  final bool isSelected;

  const _PriceListPopupRow({required this.label, required this.isSelected});

  @override
  State<_PriceListPopupRow> createState() => _PriceListPopupRowState();
}

class _PriceListPopupRowState extends State<_PriceListPopupRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isHovered
        ? AppTheme.primaryBlue
        : widget.isSelected
        ? const Color(0xFFF3F4F6)
        : Colors.white;
    final textColor = _isHovered ? Colors.white : AppTheme.textPrimary;
    final checkColor = _isHovered ? Colors.white : AppTheme.primaryBlue;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: backgroundColor,
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (widget.isSelected)
              Icon(Icons.check, size: 14, color: checkColor),
          ],
        ),
      ),
    );
  }
}

class _DiscountUnitPopupOption extends StatefulWidget {
  final String label;
  final bool isSelected;

  const _DiscountUnitPopupOption({
    required this.label,
    required this.isSelected,
  });

  @override
  State<_DiscountUnitPopupOption> createState() =>
      _DiscountUnitPopupOptionState();
}

class _DiscountUnitPopupOptionState extends State<_DiscountUnitPopupOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final fillColor = _isHovered ? AppTheme.primaryBlue : Colors.white;
    final textColor = _isHovered ? Colors.white : AppTheme.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _PopoverPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()..color = Colors.white;
    final strokePaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RecurringNumericHoverField extends StatefulWidget {
  final TextEditingController controller;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final double? width;

  const _RecurringNumericHoverField({
    required this.controller,
    this.textAlign = TextAlign.left,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
    this.width,
  });

  @override
  State<_RecurringNumericHoverField> createState() =>
      _RecurringNumericHoverFieldState();
}

class _RecurringNumericHoverFieldState
    extends State<_RecurringNumericHoverField> {
  late final FocusNode _focusNode;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBorder = _isHovered || _focusNode.hasFocus;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Align(
        alignment: widget.textAlign == TextAlign.right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: widget.width,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: showBorder ? const Color(0xFF4A88E8) : Colors.transparent,
              width: 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            textAlign: widget.textAlign,
            keyboardType: widget.keyboardType,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.15,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
          ),
        ),
      ),
    );
  }
}

class _RecurringDiscountHoverField extends StatefulWidget {
  final TextEditingController controller;
  final String unit;
  final ValueChanged<String> onUnitSelected;
  final ValueChanged<String>? onChanged;

  const _RecurringDiscountHoverField({
    required this.controller,
    required this.unit,
    required this.onUnitSelected,
    this.onChanged,
  });

  @override
  State<_RecurringDiscountHoverField> createState() =>
      _RecurringDiscountHoverFieldState();
}

class _RecurringDiscountHoverFieldState
    extends State<_RecurringDiscountHoverField> {
  late final FocusNode _focusNode;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBorder = _isHovered || _focusNode.hasFocus;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Align(
        alignment: Alignment.centerRight,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: 132,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: showBorder ? const Color(0xFF4A88E8) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    height: 1.15,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: widget.onChanged,
                ),
              ),
              const SizedBox(width: 10),
              Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  popupMenuTheme: PopupMenuThemeData(
                    color: Colors.white,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  tooltip: '',
                  offset: const Offset(-8, 30),
                  constraints: const BoxConstraints(minWidth: 60, maxWidth: 60),
                  onSelected: widget.onUnitSelected,
                  itemBuilder: (context) => ['%', '₹']
                      .map(
                        (unit) => PopupMenuItem<String>(
                          value: unit,
                          height: 40,
                          padding: const EdgeInsets.all(4),
                          child: _DiscountUnitPopupOption(
                            label: unit,
                            isSelected: widget.unit == unit,
                          ),
                        ),
                      )
                      .toList(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.unit,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const double _kRecurringInvoiceFieldHeight = 32;
const double _kRecurringInvoiceCustomerFieldWidth =
    _kRecurringInvoiceStandardFieldWidth - 32;
const double _kRecurringInvoiceCompactFieldWidth = 300;
const double _kRecurringInvoiceStandardFieldWidth = 523;
const _kRepeatFrequencies = [
  'Week',
  '2 Weeks',
  'Month',
  '2 Months',
  '3 Months',
  '6 Months',
  'Year',
  '2 Years',
  '3 Years',
  'Custom',
];
const _kPaymentTermsList = ['Net 15', 'Net 30', 'Net 45', 'Net 60', 'Net 360'];
const _kSelectAccountLabel = 'Select an account';
const _kSelectDiscountAccountLabel = 'Select Discount Account';
const _kDefaultIncomeAccountOption = _IncomeAccountOption(_kSelectAccountLabel);
const _kDefaultDiscountAccountOption = _DiscountAccountOption(
  _kSelectDiscountAccountLabel,
);

const _kBaseTaxOptions = [
  _TaxOption(
    'Out of Scope',
    subtitle:
        "Supplies on which you don't charge any GST or include them in the returns.",
  ),
  _TaxOption(
    'Non-GST Supply',
    subtitle:
        'Supplies which do not come under GST such as petroleum products and liquor.',
  ),
];
const _kFallbackGstTaxOptions = [
  _TaxOption('GST0 [0%]'),
  _TaxOption('GST5 [5%]'),
  _TaxOption('GST12 [12%]'),
  _TaxOption('GST18 [18%]'),
  _TaxOption('GST28 [28%]'),
];
const _kFallbackIgstTaxOptions = [
  _TaxOption('IGST0 [0%]'),
  _TaxOption('IGST5 [5%]'),
  _TaxOption('IGST12 [12%]'),
  _TaxOption('IGST18 [18%]'),
  _TaxOption('IGST28 [28%]'),
];
double _evaluateExpression(String input) {
  String clean = input
      .replaceAll(' ', '')
      .replaceAll('x', '*')
      .replaceAll('X', '*');
  if (clean.isEmpty) return 0.0;

  if (clean.contains('+')) {
    final parts = clean.split('+');
    double sum = 0.0;
    for (var p in parts) {
      sum += _evaluateExpression(p);
    }
    return sum;
  }

  if (clean.contains('-')) {
    final parts = clean.split('-');
    if (parts[0].isEmpty) {
      if (parts.length == 2) {
        return -(_evaluateExpression(parts[1]));
      } else {
        double val = -(_evaluateExpression(parts[1]));
        for (int i = 2; i < parts.length; i++) {
          val -= _evaluateExpression(parts[i]);
        }
        return val;
      }
    } else {
      double val = _evaluateExpression(parts[0]);
      for (int i = 1; i < parts.length; i++) {
        val -= _evaluateExpression(parts[i]);
      }
      return val;
    }
  }

  if (clean.contains('*')) {
    final parts = clean.split('*');
    double prod = 1.0;
    for (var p in parts) {
      prod *= _evaluateExpression(p);
    }
    return prod;
  }

  if (clean.contains('/')) {
    final parts = clean.split('/');
    if (parts.isEmpty) return 0.0;
    double val = _evaluateExpression(parts[0]);
    for (int i = 1; i < parts.length; i++) {
      double denominator = _evaluateExpression(parts[i]);
      if (denominator != 0) {
        val /= denominator;
      } else {
        return 0.0;
      }
    }
    return val;
  }

  return double.tryParse(clean) ?? 0.0;
}

String _formatPlaceOfSupplyOption(Map<String, String> state) {
  final code = (state['code'] ?? '').trim();
  final name = (state['name'] ?? '').trim();
  if (code.isNotEmpty && name.isNotEmpty) {
    return '[$code] - $name';
  }
  return name;
}

String _sourceOfSupplyLabel(String placeOfSupply) {
  final value = placeOfSupply.trim();
  final dashIndex = value.indexOf(' - ');
  if (dashIndex != -1 && dashIndex + 3 < value.length) {
    return value.substring(dashIndex + 3).trim();
  }
  return value;
}

bool _isKeralaPlaceOfSupply(String placeOfSupply) {
  final value = placeOfSupply.trim().toLowerCase();
  if (value.isEmpty) return true;
  return value.contains('[kl]') || value.contains('kerala');
}

String _formatTaxLabel(String name, dynamic rate) {
  final taxName = name.trim();
  if (taxName.isEmpty) return '';
  if (taxName.contains('%') || taxName.contains('[')) {
    return taxName;
  }

  final parsedRate = rate is num
      ? rate.toDouble()
      : double.tryParse(rate?.toString() ?? '');
  if (parsedRate == null) {
    return taxName;
  }

  final rateText = parsedRate % 1 == 0
      ? parsedRate.toStringAsFixed(0)
      : parsedRate.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return '$taxName [$rateText%]';
}

String _formatTaxRateText(double rate) {
  return rate % 1 == 0
      ? rate.toStringAsFixed(0)
      : rate.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

double _extractTaxPercent(String label) {
  final percentMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(label);
  if (percentMatch != null) {
    return double.tryParse(percentMatch.group(1) ?? '') ?? 0.0;
  }

  final codeMatch = RegExp(
    r'(?:^|[^A-Z])(IGST|GST|CGST|SGST)\s*(\d+(?:\.\d+)?)',
    caseSensitive: false,
  ).firstMatch(label);
  if (codeMatch != null) {
    return double.tryParse(codeMatch.group(2) ?? '') ?? 0.0;
  }

  return 0.0;
}

class _ItemRow {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController quantityCtrl;
  final TextEditingController rateCtrl;
  final TextEditingController discountCtrl;
  final TextEditingController hsnCtrl;
  final LayerLink itemPickerLink;
  final LayerLink hsnLink;
  String? priceListId;
  String? priceListName;
  bool blocksGlobalPriceListInheritance;
  String warehouseName;
  String discountUnit; // '%' or '₹'
  String tax; // e.g. 'GST5 [5%]'
  _IncomeAccountOption incomeAccount;
  _DiscountAccountOption discount; // e.g. 'Discount'
  String project; // e.g. 'Select a project'
  String reportingTag; // e.g. 'Reporting Tags'
  String adgfTag;
  String sheduleTag;
  String demoTag;
  bool hideAdditionalInfo;
  bool isHovered = false;
  bool isMenuOpen = false;

  _ItemRow({
    String name = '',
    String desc = '',
    String quantity = '1.00',
    String rate = '0.00',
    String discountVal = '0',
    String? priceListIdVal,
    String? priceListNameVal,
    bool blocksGlobalPriceListInheritanceVal = false,
    String warehouseNameVal = '',
    String discountUnitVal = '%',
    String taxVal = 'GST12 [12%]',
    _IncomeAccountOption? incomeAccountVal,
    _DiscountAccountOption? discountName,
    String projectName = 'Select a project',
    String reportingTagName = 'Reporting Tags',
    String adgfTagVal = 'None',
    String sheduleTagVal = 'None',
    String demoTagVal = 'None',
    bool hideAdditionalInfoVal = false,
  }) : nameCtrl = TextEditingController(text: name),
       descCtrl = TextEditingController(text: desc),
       quantityCtrl = TextEditingController(text: quantity),
       rateCtrl = TextEditingController(text: rate),
       discountCtrl = TextEditingController(text: discountVal),
       hsnCtrl = TextEditingController(text: ''),
       itemPickerLink = LayerLink(),
       hsnLink = LayerLink(),
       priceListId = priceListIdVal,
       priceListName = priceListNameVal,
       blocksGlobalPriceListInheritance = blocksGlobalPriceListInheritanceVal,
       warehouseName = warehouseNameVal,
       discountUnit = discountUnitVal,
       tax = taxVal,
       incomeAccount = incomeAccountVal ?? _kDefaultIncomeAccountOption,
       discount = discountName ?? _kDefaultDiscountAccountOption,
       project = projectName,
       reportingTag = reportingTagName,
       adgfTag = adgfTagVal,
       sheduleTag = sheduleTagVal,
       demoTag = demoTagVal,
       hideAdditionalInfo = hideAdditionalInfoVal;

  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    quantityCtrl.dispose();
    rateCtrl.dispose();
    discountCtrl.dispose();
    hsnCtrl.dispose();
  }

  double get quantity => double.tryParse(quantityCtrl.text) ?? 0.0;
  double get rate => _evaluateExpression(rateCtrl.text);
  double get discountVal => double.tryParse(discountCtrl.text) ?? 0.0;

  double get amountBeforeTax {
    final sub = quantity * rate;
    if (discountUnit == '%') {
      return sub - (sub * (discountVal / 100.0));
    } else {
      return sub - discountVal;
    }
  }

  double get taxRate {
    return _extractTaxPercent(tax) / 100.0;
  }

  double get taxAmount => amountBeforeTax * taxRate;
  double get totalAmount => amountBeforeTax + taxAmount;
}

// ─────────────────────────────────────────────────────────────────────────────

class RecurringInvoicesCreatePage extends ConsumerStatefulWidget {
  const RecurringInvoicesCreatePage({super.key});

  @override
  ConsumerState<RecurringInvoicesCreatePage> createState() =>
      _RecurringInvoicesCreatePageState();
}

class _RecurringInvoicesCreatePageState
    extends ConsumerState<RecurringInvoicesCreatePage> {
  final _formKey = GlobalKey<FormState>();

  final List<_CustomerItem> _localCustomers = <_CustomerItem>[];

  final List<_SalespersonOption> _localSalespersons = <_SalespersonOption>[];
  final List<PriceList> _localPriceLists = <PriceList>[];

  // Form Fields State
  _CustomerItem? _customer;
  String? _customersSyncKey;
  String _location = '';
  final List<_TransactionSeriesItem> _transactionSeriesOptions =
      <_TransactionSeriesItem>[];
  String? _transactionSeries;
  String _gstTreatment = 'Unregistered Business';
  String _placeOfSupply = '[KL] - Kerala';
  String _entityType = 'Invoice'; // 'Invoice' | 'Bill Of Supply'
  final _profileNameCtrl = TextEditingController();
  final _orderNoCtrl = TextEditingController();
  String _repeatEvery = 'Week';
  final TextEditingController _customRepeatIntervalCtrl = TextEditingController(
    text: '1',
  );
  String _customRepeatFrequencyUnit = 'Week(s)';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _neverExpires = true;
  String _paymentTerms = 'Net 360';
  String? _salesperson;
  String? _salespersonId;
  String? _priceList;
  String? _priceListId;
  String? _selectedTdsId;
  List<Map<String, dynamic>> _paymentTermsList = [];
  List<Map<String, dynamic>> _tdsList = [];
  String? _selectedWarehouseId;
  String _selectedWarehouseName = '';
  final _subjectCtrl = TextEditingController();

  // Address State
  List<Map<String, dynamic>> _billingAddresses = [];
  List<Map<String, dynamic>> _shippingAddresses = [];
  int _selectedBillingIndex = 0;
  int _selectedShippingIndex = 0;

  final LayerLink _billingAddressLayerLink = LayerLink();
  final LayerLink _shippingAddressLayerLink = LayerLink();
  final LayerLink _settingsLink = LayerLink();
  OverlayEntry? _billingAddressOverlayEntry;
  OverlayEntry? _shippingAddressOverlayEntry;
  OverlayEntry? _itemPickerOverlayEntry;
  OverlayEntry? _settingsOverlay;
  int? _itemPickerHoverIndex;
  final ScrollController _itemPickerScrollCtrl = ScrollController();
  bool _showSearchItemDetails = false;
  final TextEditingController _itemDetailsSearchCtrl = TextEditingController();
  String _itemDetailsSearchQuery = '';

  // Global Keys for DatePickers
  final GlobalKey _startDateKey = GlobalKey();
  final GlobalKey _endDateKey = GlobalKey();

  // Item List State
  final List<_ItemRow> _items = [_ItemRow()];
  final Set<_ItemRow> _headerRows = <_ItemRow>{};

  // Side panels
  bool _showCustomerDetails = false;
  bool _hideAllAdditionalInfo = false;
  bool _showItemDetails = false;
  bool _showAvailableStockForSale = true;
  bool _showRecentTransactionSetting = true;
  bool _showPriceListSetting = true;
  bool _showRowPriceListSetting = true;
  String _selectedSidebarItemName = 'BATCH TARCK ITEM';
  Item? _selectedSidebarItem;
  int _itemDetailsSidebarTabIndex = 2;

  // Other Fields
  final _shippingChargesCtrl = TextEditingController(text: '0.00');
  final _adjustmentCtrl = TextEditingController(text: '0.00');
  final _adjustmentLabelCtrl = TextEditingController(text: 'Adjustment');
  final _customerNotesCtrl = TextEditingController(
    text: 'Thanks for your business.',
  );
  final _termsAndConditionsCtrl = TextEditingController();

  // Preferences settings state
  String _invoicePreference = 'drafts';
  bool _sendPreferenceEmail = true;
  bool _isSaving = false;
  bool _isLoadingTransactionSeries = false;

  @override
  void initState() {
    super.initState();
    _shippingChargesCtrl.addListener(_updateState);
    _adjustmentCtrl.addListener(_updateState);
    if (_customer != null) {
      _billingAddresses = _getDefaultAddressesFor(_customer, 'Billing');
      _shippingAddresses = _getDefaultAddressesFor(_customer, 'Shipping');
    }
    _loadTransactionSeries();
    _loadPaymentTerms();
    _loadSalespersons();
    _loadPriceLists();
    _loadTdsList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemsNotifier = ref.read(itemsControllerProvider.notifier);
      itemsNotifier.loadLookupData();
      itemsNotifier.loadItems();
    });
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  void _syncSelectedWarehouse(List<Warehouse> warehouses) {
    if (warehouses.isEmpty) return;

    Warehouse? matchedWarehouse;
    if (_selectedWarehouseId?.trim().isNotEmpty == true) {
      for (final warehouse in warehouses) {
        if (warehouse.id == _selectedWarehouseId) {
          matchedWarehouse = warehouse;
          break;
        }
      }
    }

    if (matchedWarehouse == null && _selectedWarehouseName.trim().isNotEmpty) {
      for (final warehouse in warehouses) {
        if (warehouse.name.trim() == _selectedWarehouseName.trim()) {
          matchedWarehouse = warehouse;
          break;
        }
      }
    }

    matchedWarehouse ??= warehouses.cast<Warehouse?>().firstWhere(
      (warehouse) => warehouse?.isDefaultForBranch == true,
      orElse: () => warehouses.first,
    );

    if (matchedWarehouse == null) return;

    final nextId = matchedWarehouse.id;
    final nextName = matchedWarehouse.name.trim();
    if (_selectedWarehouseId == nextId &&
        _selectedWarehouseName == nextName &&
        _location == nextName) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedWarehouseId = nextId;
        _selectedWarehouseName = nextName;
        _location = nextName;
        for (final row in _items) {
          if (row.warehouseName.trim().isEmpty) {
            row.warehouseName = nextName;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _hideHsnEditor();
    _profileNameCtrl.dispose();
    _orderNoCtrl.dispose();
    _customRepeatIntervalCtrl.dispose();
    _subjectCtrl.dispose();
    _shippingChargesCtrl.dispose();
    _adjustmentCtrl.dispose();
    _adjustmentLabelCtrl.dispose();
    _customerNotesCtrl.dispose();
    _termsAndConditionsCtrl.dispose();
    _itemDetailsSearchCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    _hideBillingOverlay();
    _hideShippingOverlay();
    _hideItemPicker();
    _itemPickerScrollCtrl.dispose();
    super.dispose();
  }

  String _customerSyncFingerprint(List<SalesCustomer> customers) {
    return customers
        .map((customer) => '${customer.id}:${customer.displayName}')
        .join('|');
  }

  String _customerSearchText(_CustomerItem customer) {
    final parts = <String>[
      customer.name,
      customer.code,
      customer.subtitle,
      customer.data?.email ?? '',
      customer.data?.phone ?? '',
      customer.data?.mobilePhone ?? '',
    ];
    return parts
        .where((value) => value.trim().isNotEmpty)
        .join(' ')
        .toLowerCase();
  }

  String _customerAvatarText(_CustomerItem customer) {
    final name = customer.name.trim();
    if (name.isEmpty) return 'C';
    return name.substring(0, 1).toUpperCase();
  }

  _SalespersonOption? _findSalespersonByName(String? name) {
    final normalized = name?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    for (final option in _localSalespersons) {
      if (option.name.trim().toLowerCase() == normalized) {
        return option;
      }
    }
    return null;
  }

  List<_SalespersonOption> get _activeSalespersons {
    return _localSalespersons.where((option) => option.isActive).toList();
  }

  _SalespersonOption _salespersonOptionFromUserJson(Map<String, dynamic> row) {
    final dynamic rawIsActive = row['is_active'] ?? row['isActive'];
    return _SalespersonOption(
      id: (row['id'] ?? '').toString().trim(),
      name: (row['fullName'] ?? row['full_name'] ?? row['name'] ?? '')
          .toString()
          .trim(),
      email: (row['email'] ?? '').toString().trim(),
      isActive: rawIsActive is bool
          ? rawIsActive
          : row['status']?.toString().toLowerCase() == 'active',
    );
  }

  Map<String, dynamic>? _extractApiError(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final statusCode = payload['statusCode'];
      if (statusCode is int && statusCode >= 400) {
        return payload;
      }
    }
    return null;
  }

  void _replaceSalespersonOption(_SalespersonOption next) {
    final index = _localSalespersons.indexWhere((item) => item.id == next.id);
    if (index == -1) {
      _localSalespersons.add(next);
    } else {
      _localSalespersons[index] = next;
    }
    _localSalespersons.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  Future<_SalespersonOption> _updateSalespersonStatus(
    _SalespersonOption salesperson,
    bool isActive,
  ) async {
    final response = await ref
        .read(apiClientProvider)
        .patch(
          '/users/${salesperson.id}/status',
          data: {'is_active': isActive},
        );
    final payload = response.data;
    final error = _extractApiError(payload);
    if (error != null) {
      throw Exception(
        error['message']?.toString() ?? 'Failed to update salesperson status',
      );
    }
    final data =
        payload is Map<String, dynamic> &&
            payload['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(payload['data'] as Map<String, dynamic>)
        : <String, dynamic>{'id': salesperson.id, 'name': salesperson.name};
    final updated = _salespersonOptionFromUserJson({
      ...data,
      if (!data.containsKey('email')) 'email': salesperson.email,
      'is_active': isActive,
    });

    if (!mounted) return updated;
    setState(() {
      _replaceSalespersonOption(updated);
      if (!updated.isActive && _salespersonId == updated.id) {
        _salesperson = null;
        _salespersonId = null;
      }
    });
    await _loadSalespersons();
    return updated;
  }

  Future<void> _deleteSalespersonOption(_SalespersonOption salesperson) async {
    final response = await ref
        .read(apiClientProvider)
        .delete('/users/${salesperson.id}');
    final error = _extractApiError(response.data);
    if (error != null) {
      throw Exception(
        error['message']?.toString() ?? 'Failed to delete salesperson',
      );
    }
    if (!mounted) return;
    setState(() {
      _localSalespersons.removeWhere((item) => item.id == salesperson.id);
      if (_salespersonId == salesperson.id) {
        _salesperson = null;
        _salespersonId = null;
      }
    });
    await _loadSalespersons();
  }

  PriceList? _findPriceListById(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    for (final option in _localPriceLists) {
      if (option.id == id) {
        return option;
      }
    }
    return null;
  }

  PriceList? _findPriceListByName(String? name) {
    final normalized = name?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    for (final option in _localPriceLists) {
      if (option.name.trim().toLowerCase() == normalized) {
        return option;
      }
    }
    return null;
  }

  double _defaultRateForItem(Item? item) {
    final sellingPrice = (item?.sellingPrice ?? 0).toDouble();
    return sellingPrice;
  }

  String? _effectivePriceListIdForRow(_ItemRow row) {
    final rowPriceListId = row.priceListId?.trim();
    if (rowPriceListId != null && rowPriceListId.isNotEmpty) {
      return rowPriceListId;
    }
    if (row.blocksGlobalPriceListInheritance) {
      return null;
    }
    final globalPriceListId = _priceListId?.trim();
    if (globalPriceListId != null && globalPriceListId.isNotEmpty) {
      return globalPriceListId;
    }
    return null;
  }

  PriceList? _effectivePriceListForRow(_ItemRow row) {
    return _findPriceListById(_effectivePriceListIdForRow(row));
  }

  bool _priceListIncludesItem(PriceList priceList, String itemId) {
    if (itemId.trim().isEmpty) return false;
    if (priceList.priceListType != 'individual_items') {
      return true;
    }
    return priceList.itemRates?.any((rate) => rate.itemId == itemId) ?? false;
  }

  bool _isRowItemMissingFromSelectedPriceList(_ItemRow row) {
    final itemId = _resolveRecurringInvoiceProductId(row);
    if (itemId == null || itemId.isEmpty) return false;
    final priceList = _effectivePriceListForRow(row);
    if (priceList == null) return false;
    return !_priceListIncludesItem(priceList, itemId);
  }

  List<PriceList> _applicablePriceListsForRow(_ItemRow row) {
    return _localPriceLists.where((priceList) {
      return priceList.transactionType.trim().toLowerCase() == 'sales';
    }).toList();
  }

  void _updateRowRate(
    _ItemRow row, {
    String? appliedPriceListId,
    bool updateRowSelection = false,
  }) {
    final item = _resolveRecurringInvoiceItem(row);
    if (item == null) return;

    final normalizedPriceListId = appliedPriceListId?.trim();
    if (updateRowSelection) {
      row.priceListId = normalizedPriceListId?.isEmpty == true
          ? null
          : normalizedPriceListId;
      row.priceListName = _findPriceListById(row.priceListId)?.name;
    }

    final priceListId = updateRowSelection
        ? row.priceListId
        : _effectivePriceListIdForRow(row);
    final fallbackRate = _defaultRateForItem(item);

    if (priceListId == null || priceListId.isEmpty) {
      row.rateCtrl.text = fallbackRate.toStringAsFixed(2);
      return;
    }

    final priceList = _findPriceListById(priceListId);
    if (priceList == null) {
      row.rateCtrl.text = fallbackRate.toStringAsFixed(2);
      return;
    }

    final itemId = item.id?.trim() ?? '';
    if (itemId.isEmpty || !_priceListIncludesItem(priceList, itemId)) {
      row.rateCtrl.text = fallbackRate.toStringAsFixed(2);
      return;
    }

    final quantity = double.tryParse(row.quantityCtrl.text.trim()) ?? 1;
    final rate = priceList.calculatePrice(
      itemId,
      fallbackRate,
      quantity: quantity,
    );
    row.rateCtrl.text = rate.toStringAsFixed(2);
  }

  void _refreshAllRowRates() {
    for (final row in _items) {
      _updateRowRate(row);
    }
  }

  void _applyGlobalPriceListSelection(PriceList? selected) {
    _priceListId = selected?.id;
    _priceList = selected?.name;
    for (final row in _items) {
      row.priceListId = null;
      row.priceListName = null;
      row.blocksGlobalPriceListInheritance = false;
    }
    _refreshAllRowRates();
  }

  Future<void> _loadSalespersons() async {
    try {
      final response = await ref
          .read(apiClientProvider)
          .get(
            '/users',
            queryParameters: {'status': 'all', 'source': 'table'},
            useCache: false,
          );
      final payload = response.data;
      final rows = payload is List
          ? payload
          : (payload is Map<String, dynamic> && payload['data'] is List
                ? payload['data'] as List
                : const <dynamic>[]);
      final options =
          rows
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .map(_salespersonOptionFromUserJson)
              .where((option) => option.id.isNotEmpty && option.name.isNotEmpty)
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      if (!mounted) return;
      setState(() {
        _localSalespersons
          ..clear()
          ..addAll(options);

        final existing = _findSalespersonByName(_salesperson);
        if (existing != null && existing.isActive) {
          _salesperson = existing.name;
          _salespersonId = existing.id;
          return;
        }

        if (options.isEmpty) {
          _salesperson = null;
          _salespersonId = null;
          return;
        }

        final activeOptions = options
            .where((option) => option.isActive)
            .toList(growable: false);
        if (activeOptions.isEmpty) {
          _salesperson = null;
          _salespersonId = null;
          return;
        }

        final defaultOption = activeOptions.firstWhere(
          (option) => option.name.trim().toUpperCase() == 'ALTHAF',
          orElse: () => activeOptions.first,
        );
        _salesperson = defaultOption.name;
        _salespersonId = defaultOption.id;
      });
    } on DioException catch (e) {
      debugPrint('Error loading salespersons from users: ${e.message}');
    } catch (e) {
      debugPrint('Error loading salespersons from users: $e');
    }
  }

  Future<void> _loadTdsList() async {
    try {
      final rates = await LookupsApiService().getTdsRates();
      if (!mounted) return;
      setState(() {
        _tdsList = rates;
        if (_selectedTdsId != null &&
            !_tdsList.any((rate) => rate['id'] == _selectedTdsId)) {
          _selectedTdsId = null;
        }
      });
    } catch (e) {
      debugPrint('Error loading TDS rates: $e');
    }
  }

  Future<void> _loadPriceLists() async {
    try {
      final repository = PriceListRepositoryImpl(
        apiClient: ref.read(apiClientProvider),
      );
      final fetched = await repository.getPriceLists();
      final salesPriceLists =
          fetched
              .where((pl) => pl.transactionType.trim().toLowerCase() == 'sales')
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      if (!mounted) return;
      setState(() {
        _localPriceLists
          ..clear()
          ..addAll(salesPriceLists);

        final existingById = _findPriceListById(_priceListId);
        if (existingById != null) {
          _priceListId = existingById.id;
          _priceList = existingById.name;
          return;
        }

        final existingByName = _findPriceListByName(_priceList);
        if (existingByName != null) {
          _priceListId = existingByName.id;
          _priceList = existingByName.name;
          return;
        }

        _priceListId = null;
        _priceList = null;
      });
      _refreshAllRowRates();
    } on DioException catch (e) {
      debugPrint('Error loading sales price lists: ${e.message}');
      if (!mounted) return;
      setState(() {
        _localPriceLists.clear();
        _priceListId = null;
        _priceList = null;
      });
    } catch (e) {
      debugPrint('Error loading sales price lists: $e');
      if (!mounted) return;
      setState(() {
        _localPriceLists.clear();
        _priceListId = null;
        _priceList = null;
      });
    }
  }

  Future<void> _loadPaymentTerms() async {
    try {
      final fetchedTerms = await LookupsApiService().getPaymentTerms();
      if (!mounted) return;

      setState(() {
        _paymentTermsList = fetchedTerms;
        if (fetchedTerms.isEmpty) {
          return;
        }

        final matchedTerm = fetchedTerms
            .cast<Map<String, dynamic>?>()
            .firstWhere(
              (term) =>
                  term?['id']?.toString() == _paymentTerms ||
                  term?['term_name']?.toString() == _paymentTerms,
              orElse: () => null,
            );

        if (matchedTerm != null) {
          _paymentTerms = matchedTerm['id']?.toString() ?? _paymentTerms;
          return;
        }

        final net360 = fetchedTerms.cast<Map<String, dynamic>?>().firstWhere(
          (term) => term?['term_name']?.toString() == 'Net 360',
          orElse: () => null,
        );

        _paymentTerms =
            (net360 ?? fetchedTerms.first)['id']?.toString() ?? _paymentTerms;
      });
    } catch (e) {
      debugPrint('Error loading payment terms: $e');
    }
  }

  void _showConfigurePaymentTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => ManagePaymentTermsDialog(
        items: _paymentTermsList,
        selectedId: _paymentTerms,
        onSelect: (selected) {
          setState(() {
            _paymentTerms =
                selected['id']?.toString() ??
                selected['term_name']?.toString() ??
                _paymentTerms;
          });
        },
        onSave: (items) async {
          final newTermNames = items
              .where((item) => item['id'] == null)
              .map((item) => item['term_name']?.toString().trim() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
          final updated = await LookupsApiService().syncPaymentTerms(items);
          await _loadPaymentTerms();
          if (!mounted || newTermNames.isEmpty) {
            return updated;
          }

          final latestNewTermName = newTermNames.last.toLowerCase();
          final savedTerm = _paymentTermsList
              .cast<Map<String, dynamic>?>()
              .firstWhere(
                (term) =>
                    term?['term_name']?.toString().trim().toLowerCase() ==
                    latestNewTermName,
                orElse: () => null,
              );

          if (savedTerm != null) {
            setState(() {
              _paymentTerms =
                  savedTerm['id']?.toString() ??
                  savedTerm['term_name']?.toString() ??
                  _paymentTerms;
            });
          }
          return updated;
        },
        onDeleteCheck: (item) async {
          final usage = await LookupsApiService().checkLookupUsage(
            'payment-terms',
            item['id'].toString(),
          );
          if (usage['inUse'] == true) {
            return usage['message']?.toString() ?? 'This term is in use.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCustomerDropdownRow(
    _CustomerItem customer,
    bool isSelected,
    bool isHovered,
  ) {
    final hoverBlue = const Color(0xFF4A88E8);
    final hasCode = customer.code.trim().isNotEmpty;
    final hasEmail = (customer.data?.email ?? '').trim().isNotEmpty;
    final hasPhone =
        ((customer.data?.mobilePhone ?? customer.data?.phone) ?? '')
            .trim()
            .isNotEmpty;

    final subtitleParts = <String>[
      if (hasEmail) customer.data!.email!.trim(),
      if (hasPhone)
        (customer.data?.mobilePhone ?? customer.data?.phone)!.trim(),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isHovered ? hoverBlue : Colors.white,
        border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Text(
              _customerAvatarText(customer),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isHovered ? hoverBlue : AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isHovered
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (hasCode) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '| ${customer.code}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isHovered
                                ? Colors.white
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitleParts.join('  |  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isHovered ? Colors.white : AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 16,
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }

  _TransactionSeriesItem? _selectedTransactionSeriesItem() {
    final selectedId = _transactionSeries;
    if (selectedId == null || selectedId.isEmpty) return null;
    for (final option in _transactionSeriesOptions) {
      if (option.id == selectedId) return option;
    }
    return null;
  }

  String? _resolveDefaultTransactionSeriesId(
    List<_TransactionSeriesItem> options, {
    String? previousSelection,
  }) {
    if (options.isEmpty) return null;

    final trimmedPrevious = previousSelection?.trim();
    if (trimmedPrevious != null && trimmedPrevious.isNotEmpty) {
      for (final option in options) {
        if (option.id == trimmedPrevious) {
          return option.id;
        }
      }
    }

    for (final option in options) {
      if (option.name.trim().toLowerCase() == 'default transaction series') {
        return option.id;
      }
    }

    return options.first.id;
  }

  Future<void> _loadTransactionSeries() async {
    if (mounted) {
      setState(() => _isLoadingTransactionSeries = true);
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .get('/transaction-series');
      final rawData = response.data;
      final seriesList = rawData is List
          ? rawData
          : (rawData is Map<String, dynamic> && rawData['data'] is List
                ? rawData['data'] as List
                : const []);

      final options = seriesList
          .whereType<Map>()
          .map(
            (row) => _TransactionSeriesItem(
              id: (row['id'] ?? '').toString(),
              name: (row['name'] ?? row['series_name'] ?? '').toString().trim(),
            ),
          )
          .where((row) => row.id.isNotEmpty && row.name.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _transactionSeriesOptions
          ..clear()
          ..addAll(options);
        _transactionSeries = _resolveDefaultTransactionSeriesId(
          _transactionSeriesOptions,
          previousSelection: _transactionSeries,
        );
      });
    } on DioException catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(
        context,
        e.message?.isNotEmpty == true
            ? e.message!
            : 'Failed to load transaction series.',
      );
      setState(() {
        _transactionSeriesOptions.clear();
        _transactionSeries = null;
      });
    } catch (_) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to load transaction series.');
      setState(() {
        _transactionSeriesOptions.clear();
        _transactionSeries = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingTransactionSeries = false);
      }
    }
  }

  List<Map<String, dynamic>> _getDefaultAddressesFor(
    _CustomerItem? customer,
    String type,
  ) {
    final customerData = customer?.data;
    if (customerData == null) return [];

    final isBilling = type == 'Billing';
    final realAddresses = customerData.customerAddresses;
    if (realAddresses.isNotEmpty) {
      final typeKey = isBilling ? 'billing' : 'shipping';
      final filtered = realAddresses.where((address) {
        final rawType = (address['type'] ?? address['addressType'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        if (rawType == typeKey) {
          return true;
        }
        if (isBilling && address['isDefaultBilling'] == true) {
          return true;
        }
        if (!isBilling && address['isDefaultShipping'] == true) {
          return true;
        }
        return false;
      }).toList();

      final normalized = (filtered.isNotEmpty ? filtered : realAddresses)
          .map(
            (address) => {
              'companyName':
                  (customerData.companyName?.trim().isNotEmpty ?? false)
                  ? customerData.companyName!.trim()
                  : customerData.displayName,
              'attention':
                  (address['attention'] ?? '').toString().trim().isNotEmpty
                  ? address['attention'].toString().trim()
                  : customerData.displayName,
              'street1': (address['street1'] ?? address['address_street'] ?? '')
                  .toString(),
              'street2': (address['street2'] ?? address['address_place'] ?? '')
                  .toString(),
              'city': (address['city'] ?? '').toString(),
              'zip': (address['zip'] ?? address['pincode'] ?? '').toString(),
              'state': (address['state'] ?? address['stateId'] ?? '')
                  .toString(),
              'stateName': (address['stateName'] ?? address['state'] ?? '')
                  .toString(),
              'country': (address['country'] ?? address['countryId'] ?? '')
                  .toString(),
              'countryName':
                  (address['countryName'] ?? address['country'] ?? '')
                      .toString(),
              'phone':
                  ((address['phone'] ?? '').toString().trim().isNotEmpty
                      ? address['phone']
                      : null) ??
                  customerData.phone ??
                  customerData.mobilePhone ??
                  '',
            },
          )
          .where(
            (address) => [
              address['street1'],
              address['street2'],
              address['city'],
              address['stateName'],
              address['countryName'],
              address['zip'],
              address['phone'],
            ].any((value) => value.toString().trim().isNotEmpty),
          )
          .toList();

      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    final street1 = isBilling
        ? customerData.billingAddressStreet1
        : customerData.shippingAddressStreet1;
    final street2 = isBilling
        ? customerData.billingAddressStreet2
        : customerData.shippingAddressStreet2;
    final city = isBilling
        ? customerData.billingAddressCity
        : customerData.shippingAddressCity;
    final state = isBilling
        ? customerData.billingAddressStateId
        : customerData.shippingAddressStateId;
    final zip = isBilling
        ? customerData.billingAddressZip
        : customerData.shippingAddressZip;
    final country = isBilling
        ? customerData.billingAddressCountryId
        : customerData.shippingAddressCountryId;
    final phone = isBilling
        ? customerData.billingAddressPhone
        : customerData.shippingAddressPhone;

    final hasAddressData = [
      street1,
      street2,
      city,
      state,
      zip,
      country,
      phone,
    ].any((value) => value != null && value.toString().trim().isNotEmpty);

    if (!hasAddressData) return [];

    return [
      {
        'companyName': (customerData.companyName?.trim().isNotEmpty ?? false)
            ? customerData.companyName!.trim()
            : customerData.displayName,
        'attention': customerData.displayName,
        'street1': street1 ?? '',
        'street2': street2 ?? '',
        'city': city ?? '',
        'zip': zip ?? '',
        'state': state ?? '',
        'stateName': state ?? '',
        'country': country ?? '',
        'countryName': country ?? '',
        'phone': phone ?? customerData.phone ?? customerData.mobilePhone ?? '',
      },
    ];
  }

  List<String> _addressDisplayLines(Map<String, dynamic> address) {
    final lines = <String>[
      if ((address['street1'] ?? '').toString().trim().isNotEmpty)
        address['street1'].toString().trim(),
      if ((address['street2'] ?? '').toString().trim().isNotEmpty)
        address['street2'].toString().trim(),
      if ((address['city'] ?? '').toString().trim().isNotEmpty)
        address['city'].toString().trim(),
      [
        (address['stateName'] ?? address['state'] ?? '').toString().trim(),
        (address['zip'] ?? '').toString().trim(),
      ].where((value) => value.isNotEmpty).join(' '),
      if ((address['countryName'] ?? address['country'] ?? '')
          .toString()
          .trim()
          .isNotEmpty)
        (address['countryName'] ?? address['country']).toString().trim(),
      if ((address['phone'] ?? '').toString().trim().isNotEmpty)
        'Phone: ${address['phone'].toString().trim()}',
    ];
    return lines.where((line) => line.trim().isNotEmpty).toList();
  }

  // Address Overlays
  void _showBillingOverlay() {
    _hideBillingOverlay();
    _hideShippingOverlay();
    final overlay = Overlay.of(context);
    _billingAddressOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _hideBillingOverlay,
            child: const SizedBox.expand(),
          ),
          CompositedTransformFollower(
            link: _billingAddressLayerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 24),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                child: _buildAddressSelectionCard('Billing'),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_billingAddressOverlayEntry!);
    setState(() {});
  }

  void _hideBillingOverlay() {
    if (_billingAddressOverlayEntry != null) {
      _billingAddressOverlayEntry!.remove();
      _billingAddressOverlayEntry = null;
      if (mounted) setState(() {});
    }
  }

  void _showShippingOverlay() {
    _hideShippingOverlay();
    _hideBillingOverlay();
    final overlay = Overlay.of(context);
    _shippingAddressOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _hideShippingOverlay,
            child: const SizedBox.expand(),
          ),
          CompositedTransformFollower(
            link: _shippingAddressLayerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 24),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                child: _buildAddressSelectionCard('Shipping'),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_shippingAddressOverlayEntry!);
    setState(() {});
  }

  void _hideShippingOverlay() {
    if (_shippingAddressOverlayEntry != null) {
      _shippingAddressOverlayEntry!.remove();
      _shippingAddressOverlayEntry = null;
      if (mounted) setState(() {});
    }
  }

  Widget _buildAddressSelectionCard(String type) {
    final addresses = type == 'Billing'
        ? _billingAddresses
        : _shippingAddresses;
    final selectedIndex = type == 'Billing'
        ? _selectedBillingIndex
        : _selectedShippingIndex;
    final hideOverlay = type == 'Billing'
        ? _hideBillingOverlay
        : _hideShippingOverlay;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: List.generate(addresses.length, (i) {
                  final addr = addresses[i];
                  final isActive = i == selectedIndex;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (type == 'Billing') {
                          _selectedBillingIndex = i;
                        } else {
                          _selectedShippingIndex = i;
                        }
                      });
                      hideOverlay();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF3B82F6)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isActive
                              ? Colors.transparent
                              : AppTheme.borderLight,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addr['companyName'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...[
                                      if (addr['street1']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true)
                                        addr['street1'].toString(),
                                      if (addr['street2']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true)
                                        addr['street2'].toString(),
                                      '${addr['city'] ?? ''}${addr['city'] != null && addr['stateName'] != null ? ', ' : ''}${addr['stateName'] ?? addr['state'] ?? ''}'
                                          .trim(),
                                      '${addr['countryName'] ?? addr['country'] ?? ''}${addr['countryName'] != null && addr['zip'] != null ? ' , ' : ''}${addr['zip'] ?? ''}'
                                          .trim(),
                                      if (addr['phone']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true)
                                        addr['phone'].toString(),
                                    ]
                                    .where((line) => line.isNotEmpty)
                                    .expand((line) => line.split('\n'))
                                    .where((line) => line.trim().isNotEmpty)
                                    .map(
                                      (line) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 2,
                                        ),
                                        child: Text(
                                          line,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isActive
                                                ? Colors.white.withValues(
                                                    alpha: 0.9,
                                                  )
                                                : AppTheme.textSecondary,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () async {
                                hideOverlay();
                                await showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => AddressDialog(
                                    title: '${type.toUpperCase()} ADDRESS',
                                    initialAddress: addr,
                                    onSave: (updated) {
                                      setState(() {
                                        if (type == 'Billing') {
                                          _billingAddresses[i] = updated;
                                        } else {
                                          _shippingAddresses[i] = updated;
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  LucideIcons.pencil,
                                  size: 12,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          InkWell(
            onTap: () async {
              hideOverlay();
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AddressDialog(
                  title: '${type.toUpperCase()} ADDRESS',
                  initialAddress: {
                    'companyName': '',
                    'attention': '',
                    'street1': '',
                    'street2': '',
                    'city': '',
                    'zip': '',
                    'state': '',
                    'stateName': '',
                    'country': 'IN',
                    'countryName': 'India',
                    'phone': '',
                  },
                  onSave: (newAddress) {
                    setState(() {
                      if (type == 'Billing') {
                        _billingAddresses.add(newAddress);
                        _selectedBillingIndex = _billingAddresses.length - 1;
                      } else {
                        _shippingAddresses.add(newAddress);
                        _selectedShippingIndex = _shippingAddresses.length - 1;
                      }
                    });
                  },
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    size: 14,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'New address',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdvancedSearchDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _AdvancedCustomerSearchDialog(customers: _localCustomers),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        final existing = _localCustomers.cast<_CustomerItem?>().firstWhere(
          (c) => c?.id == result,
          orElse: () => null,
        );
        if (existing != null) {
          _customer = existing;
        } else {
          ZerpaiToast.error(
            context,
            'Customer not found in database. Please create it in Customers first.',
          );
          return;
        }
        _billingAddresses = _getDefaultAddressesFor(_customer, 'Billing');
        _shippingAddresses = _getDefaultAddressesFor(_customer, 'Shipping');
        _selectedBillingIndex = 0;
        _selectedShippingIndex = 0;
      });
    }
  }

  Future<void> _showGstTreatmentDialog() async {
    final List<String> treatments = [
      'Registered Business - Regular',
      'Registered Business - Composition',
      'Unregistered Business',
      'Consumer',
      'Overseas',
      'Special Economic Zone',
      'government, governmental agencies or local authorities',
      'SEZ Developer',
      'Input Service Distributor',
    ];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ConfigureTaxPreferencesDialog(
        initialTreatment: _gstTreatment,
        treatments: treatments,
      ),
    );
    if (result != null) {
      setState(() {
        _gstTreatment = result['gstTreatment'] as String;
      });
    }
  }

  Future<void> _showEditItemDialog(_ItemRow row) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _EditItemDialog(row: row),
    );
    if (result != null) {
      setState(() {
        row.nameCtrl.text = result['name'] ?? '';
        row.rateCtrl.text = result['rate'] ?? '';
        row.descCtrl.text = result['description'] ?? '';
        row.tax = result['tax'] ?? 'GST5 [5%]';
        row.adgfTag = result['adgf'] ?? 'None';
        row.sheduleTag = result['shedule'] ?? 'None';
        row.demoTag = result['demo'] ?? 'None';
        _updateRowRate(row);
      });
    }
  }

  // Calculations
  /// Item picker options sourced from the real `products` table (name, rate).
  List<(String, String)> get _itemPickerOptions {
    return ref
        .read(itemsControllerProvider)
        .items
        .where((i) => i.productName.trim().isNotEmpty)
        .map((i) => (i.productName, (i.sellingPrice ?? 0).toStringAsFixed(2)))
        .toList();
  }

  String? _resolveRecurringInvoiceProductId(_ItemRow row) {
    final itemName = row.nameCtrl.text.trim();
    if (itemName.isEmpty) return null;

    final items = ref.read(itemsControllerProvider).items;
    for (final item in items) {
      if (item.productName.trim() == itemName) {
        return item.id;
      }
    }
    return null;
  }

  Item? _resolveRecurringInvoiceItem(_ItemRow row) {
    final itemName = row.nameCtrl.text.trim();
    if (itemName.isEmpty) return null;

    final items = ref.read(itemsControllerProvider).items;
    for (final item in items) {
      if (item.productName.trim() == itemName) {
        return item;
      }
    }
    return null;
  }

  String? _resolveRecurringInvoiceItemCode(_ItemRow row) {
    final itemName = row.nameCtrl.text.trim();
    if (itemName.isEmpty) return null;

    final items = ref.read(itemsControllerProvider).items;
    for (final item in items) {
      if (item.productName.trim() == itemName) {
        return item.itemCode;
      }
    }
    return null;
  }

  _ItemRow _createRecurringItemRow({
    String quantity = '1',
    String rate = '0',
    String discount = '0',
    String tax = 'GST5 [5%]',
  }) {
    final row = _ItemRow(
      quantity: quantity,
      rate: rate,
      discountVal: discount,
      taxVal: tax,
      warehouseNameVal: _selectedWarehouseName.trim().isNotEmpty
          ? _selectedWarehouseName.trim()
          : _location.trim(),
    );
    row.quantityCtrl.addListener(() {
      if (!mounted) return;
      setState(() {
        _updateRowRate(row);
      });
    });
    return row;
  }

  void _hydrateRecurringRowFromItem(
    _ItemRow row,
    Item item, {
    int quantity = 1,
  }) {
    row.nameCtrl.text = item.productName;
    row.descCtrl.text = item.salesDescription ?? '';
    row.quantityCtrl.text = quantity.toString();
    row.rateCtrl.text = (item.sellingPrice ?? 0).toStringAsFixed(2);
    if ((item.hsnCode ?? '').trim().isNotEmpty) {
      row.hsnCtrl.text = item.hsnCode!.trim();
    }
    row.incomeAccount = _IncomeAccountOption(
      (item.salesAccountName ?? '').trim().isNotEmpty
          ? item.salesAccountName!.trim()
          : 'Sales',
      searchText: (item.salesAccountName ?? '').trim(),
    );
    _updateRowRate(row);
  }

  bool _isRecurringItemRowBlank(_ItemRow row) {
    if (_headerRows.contains(row)) {
      return false;
    }
    return row.nameCtrl.text.trim().isEmpty &&
        row.descCtrl.text.trim().isEmpty &&
        row.hsnCtrl.text.trim().isEmpty;
  }

  void _ensureTrailingRecurringItemRow() {
    final blankRows = _items.where(_isRecurringItemRowBlank).toList();
    if (blankRows.isEmpty) {
      _items.add(_createRecurringItemRow());
      return;
    }

    final trailingBlank = blankRows.last;
    for (final row in blankRows.take(blankRows.length - 1)) {
      _items.remove(row);
      row.dispose();
    }

    _items.remove(trailingBlank);
    _items.add(trailingBlank);
  }

  void _applyRecurringBulkItems(Map<Item, int> selectedItems) {
    setState(() {
      _items.removeWhere((row) => row.nameCtrl.text.trim().isEmpty);
      selectedItems.forEach((item, quantity) {
        final row = _createRecurringItemRow(
          quantity: quantity.toString(),
          rate: (item.sellingPrice ?? 0).toStringAsFixed(2),
        );
        _hydrateRecurringRowFromItem(row, item, quantity: quantity);
        _items.add(row);
      });
      _ensureTrailingRecurringItemRow();
    });
  }

  Future<void> _showRecurringBulkItemsDialog() async {
    final products = ref.read(itemsControllerProvider).items;
    if (products.isEmpty) {
      ZerpaiToast.error(context, 'No items available to add.');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => BulkItemsDialog(
        products: products,
        onItemsSelected: _applyRecurringBulkItems,
      ),
    );
  }

  double get _subTotal => _items.fold(0.0, (sum, i) => sum + i.amountBeforeTax);
  double get _taxTotal => _items.fold(0.0, (sum, i) => sum + i.taxAmount);
  double get _shippingCharges =>
      double.tryParse(_shippingChargesCtrl.text) ?? 0.0;
  double get _adjustment => double.tryParse(_adjustmentCtrl.text) ?? 0.0;

  List<_TaxSummaryLine> get _appliedTaxSummaryLines {
    final isKerala = _isKeralaPlaceOfSupply(_placeOfSupply);
    final aggregated = <String, double>{};

    void addLine(String label, double amount) {
      if (amount.abs() < 0.000001) {
        return;
      }
      aggregated.update(
        label,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }

    for (final row in _items) {
      final taxPercent = _extractTaxPercent(row.tax);
      final taxAmount = row.taxAmount;
      if (taxPercent <= 0 || taxAmount == 0) {
        continue;
      }

      final upperLabel = row.tax.trim().toUpperCase();
      final isIntegratedTax =
          upperLabel.startsWith('IGST') || upperLabel.contains('IGST');

      if (!isKerala || isIntegratedTax) {
        final rateText = _formatTaxRateText(taxPercent);
        addLine('IGST$rateText [$rateText%]', taxAmount);
        continue;
      }

      final splitPercent = taxPercent / 2;
      final splitAmount = taxAmount / 2;
      final splitRateText = _formatTaxRateText(splitPercent);
      addLine('CGST$splitRateText [$splitRateText%]', splitAmount);
      addLine('SGST$splitRateText [$splitRateText%]', splitAmount);
    }

    return aggregated.entries
        .map((entry) => _TaxSummaryLine(label: entry.key, amount: entry.value))
        .toList(growable: false);
  }

  double get _totalBeforeRoundOff =>
      _subTotal + _taxTotal + _shippingCharges + _adjustment;

  double get _roundOff {
    final rounded = _totalBeforeRoundOff.roundToDouble();
    return rounded - _totalBeforeRoundOff;
  }

  double get _grandTotal => _totalBeforeRoundOff + _roundOff;

  String _repeatEveryUnit() {
    if (_repeatEvery == 'Custom') {
      final lower = _customRepeatFrequencyUnit.toLowerCase();
      if (lower.contains('day')) return 'day';
      if (lower.contains('week')) return 'week';
      if (lower.contains('year')) return 'year';
      return 'month';
    }
    final lower = _repeatEvery.toLowerCase();
    if (lower.contains('week')) return 'week';
    if (lower.contains('year')) return 'year';
    return 'month';
  }

  int _repeatEveryInterval() {
    if (_repeatEvery == 'Custom') {
      final interval = int.tryParse(_customRepeatIntervalCtrl.text.trim());
      return interval != null && interval > 0 ? interval : 1;
    }
    final lower = _repeatEvery.toLowerCase();
    if (lower.contains('2')) return 2;
    if (lower.contains('3')) return 3;
    if (lower.contains('6')) return 6;
    return 1;
  }

  String? _matchingRepeatEveryPreset(String unitLabel, int count) {
    final lowerUnit = unitLabel.toLowerCase();
    if (lowerUnit.contains('week')) {
      if (count == 1) return 'Week';
      if (count == 2) return '2 Weeks';
    } else if (lowerUnit.contains('month')) {
      if (count == 1) return 'Month';
      if (count == 2) return '2 Months';
      if (count == 3) return '3 Months';
      if (count == 6) return '6 Months';
    } else if (lowerUnit.contains('year')) {
      if (count == 1) return 'Year';
      if (count == 2) return '2 Years';
      if (count == 3) return '3 Years';
    }
    return null;
  }

  void _normalizeCustomRepeatSelection() {
    if (_repeatEvery != 'Custom') return;
    final interval = int.tryParse(_customRepeatIntervalCtrl.text.trim());
    if (interval == null || interval <= 0) return;

    final preset = _matchingRepeatEveryPreset(
      _customRepeatFrequencyUnit,
      interval,
    );
    if (preset == null) return;

    _repeatEvery = preset;
    _syncCustomRepeatEveryState(preset);
  }

  void _syncCustomRepeatEveryState(String value) {
    final lower = value.toLowerCase();
    int interval = 1;
    String unit = 'Week(s)';

    if (lower.contains('day')) {
      unit = 'Day(s)';
    } else if (lower.contains('week')) {
      unit = 'Week(s)';
      if (lower.contains('2')) interval = 2;
    } else if (lower.contains('month')) {
      unit = 'Month(s)';
      if (lower.contains('2')) {
        interval = 2;
      } else if (lower.contains('3')) {
        interval = 3;
      } else if (lower.contains('6')) {
        interval = 6;
      }
    } else if (lower.contains('year')) {
      unit = 'Year(s)';
      if (lower.contains('2')) {
        interval = 2;
      } else if (lower.contains('3')) {
        interval = 3;
      }
    }

    _customRepeatIntervalCtrl.text = interval.toString();
    _customRepeatFrequencyUnit = unit;
  }

  DateTime _computeNextInvoiceDate() {
    final unit = _repeatEveryUnit();
    final interval = _repeatEveryInterval();
    switch (unit) {
      case 'day':
        return _startDate.add(Duration(days: interval));
      case 'week':
        return _startDate.add(Duration(days: interval * 7));
      case 'year':
        return DateTime(
          _startDate.year + interval,
          _startDate.month,
          _startDate.day,
        );
      case 'month':
      default:
        return DateTime(
          _startDate.year,
          _startDate.month + interval,
          _startDate.day,
        );
    }
  }

  Map<String, dynamic>? _selectedAddress(
    List<Map<String, dynamic>> addresses,
    int index,
  ) {
    if (addresses.isEmpty || index < 0 || index >= addresses.length) {
      return null;
    }
    return addresses[index];
  }

  List<Map<String, dynamic>> _buildRecurringInvoiceItemsPayload() {
    return _items
        .where((row) {
          final itemName = row.nameCtrl.text.trim();
          final itemCode = _resolveRecurringInvoiceItemCode(row);
          final productId = _resolveRecurringInvoiceProductId(row);
          return itemName.isNotEmpty ||
              (itemCode?.isNotEmpty ?? false) ||
              (productId?.isNotEmpty ?? false);
        })
        .map((row) {
          final productId = _resolveRecurringInvoiceProductId(row);
          final itemCode = _resolveRecurringInvoiceItemCode(row);
          return {
            'itemId': productId,
            'productId': productId,
            'itemCode': itemCode,
            'name': row.nameCtrl.text.trim(),
            'description': row.descCtrl.text.trim(),
            'quantity': row.quantity,
            'rate': row.rate,
            'discountValue': row.discountVal,
            'discountType': row.discountUnit == '%' ? '%' : 'value',
            'taxLabel': row.tax,
            'taxRate': row.taxRate,
            'amount': row.amountBeforeTax,
            'total': row.totalAmount,
            'hsnCode': row.hsnCtrl.text.trim(),
            'incomeAccountName': row.incomeAccount.title,
            'discountAccountName': row.discount.title,
            'project': row.project,
            'reportingTag': row.reportingTag,
            'adgfTag': row.adgfTag,
            'sheduleTag': row.sheduleTag,
            'demoTag': row.demoTag,
            'warehouseName': row.warehouseName.trim().isNotEmpty
                ? row.warehouseName.trim()
                : _selectedWarehouseName,
          };
        })
        .toList();
  }

  Future<void> _saveRecurringInvoice() async {
    if (_isSaving) return;
    if (_customer == null) {
      ZerpaiToast.error(context, 'Please select a customer.');
      return;
    }
    if (_profileNameCtrl.text.trim().isEmpty) {
      ZerpaiToast.error(context, 'Profile Name is required.');
      return;
    }
    if (_repeatEvery == 'Custom') {
      final interval = int.tryParse(_customRepeatIntervalCtrl.text.trim());
      if (interval == null || interval <= 0) {
        ZerpaiToast.error(context, 'Enter a valid custom repeat interval.');
        return;
      }
    }

    final itemsPayload = _buildRecurringInvoiceItemsPayload();
    if (itemsPayload.isEmpty) {
      ZerpaiToast.error(context, 'Add at least one line item before saving.');
      return;
    }

    final selectedTransactionSeries = _selectedTransactionSeriesItem();
    final nextInvoiceDate = _computeNextInvoiceDate();
    final payload = <String, dynamic>{
      'customerId': _customer!.id,
      'customerName': _customer!.name,
      'location': _location,
      'transactionSeries': selectedTransactionSeries?.name,
      'transactionSeriesId': selectedTransactionSeries?.id,
      'gstTreatment': _gstTreatment,
      'placeOfSupply': _placeOfSupply,
      'entityType': _entityType,
      'documentType': 'recurring_invoice',
      'profileName': _profileNameCtrl.text.trim(),
      'orderNumber': _orderNoCtrl.text.trim().isEmpty
          ? null
          : _orderNoCtrl.text.trim(),
      'reference': _subjectCtrl.text.trim().isEmpty
          ? null
          : _subjectCtrl.text.trim(),
      'subject': _subjectCtrl.text.trim(),
      'repeatEvery': _repeatEveryUnit(),
      'interval': _repeatEveryInterval(),
      'startDate': _startDate.toIso8601String(),
      'endDate': _neverExpires || _endDate == null
          ? null
          : _endDate!.toIso8601String(),
      'nextInvoiceDate': nextInvoiceDate.toIso8601String(),
      'neverExpires': _neverExpires,
      'paymentTerms': _paymentTerms,
      'salespersonId': _salespersonId,
      'salespersonName': _salesperson?.trim().isNotEmpty == true
          ? _salesperson
          : null,
      'priceListId': _priceListId,
      'priceListName': _priceList,
      'warehouseName': _selectedWarehouseName,
      'billingAddress': _selectedAddress(
        _billingAddresses,
        _selectedBillingIndex,
      ),
      'shippingAddress': _selectedAddress(
        _shippingAddresses,
        _selectedShippingIndex,
      ),
      'shippingCharges': _shippingCharges,
      'adjustmentLabel': _adjustmentLabelCtrl.text.trim(),
      'adjustment': _adjustment,
      'customerNotes': _customerNotesCtrl.text.trim(),
      'termsAndConditions': _termsAndConditionsCtrl.text.trim(),
      'invoicePreference': _invoicePreference,
      'sendPreferenceEmail': _sendPreferenceEmail,
      'subTotal': _subTotal,
      'taxTotal': _taxTotal,
      'discountTotal': _items.fold<double>(
        0,
        (sum, row) => sum + ((row.quantity * row.rate) - row.amountBeforeTax),
      ),
      'totalQuantity': _items.fold<double>(0, (sum, row) => sum + row.quantity),
      'total': _grandTotal,
      'currency': 'INR',
      'status': _invoicePreference == 'drafts' ? 'Draft' : 'Active',
      'items': itemsPayload,
    };

    setState(() => _isSaving = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .post('/sales/recurring-invoices', data: payload);
      final responseData = response.data;
      final created =
          responseData is Map<String, dynamic> &&
              responseData['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              responseData['data'] as Map<String, dynamic>,
            )
          : Map<String, dynamic>.from(responseData as Map);

      ref
          .read(recurringInvoicesProvider.notifier)
          .addInvoice(
            RecurringInvoice(
              id: (created['id'] ?? '').toString(),
              profileName: _profileNameCtrl.text.trim(),
              customerName: _customer!.name,
              billingFrequency: _repeatEvery,
              amount: _grandTotal,
              status: _invoicePreference == 'drafts'
                  ? RecurringStatus.draft
                  : RecurringStatus.active,
              nextInvoiceDate: nextInvoiceDate,
              location: _location,
              endDate: _neverExpires ? null : _endDate,
              salespersonName: _salesperson ?? '',
            ),
          );
      await ref.read(recurringInvoicesProvider.notifier).loadInvoices();

      if (!mounted) return;
      ZerpaiToast.success(context, 'Recurring invoice saved successfully.');
      Navigator.pop(context, created);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final dioError = e.error;
      final message = responseData is Map<String, dynamic>
          ? (responseData['message']?.toString() ??
                responseData['error']?.toString() ??
                (dioError is Map ? dioError['message']?.toString() : null) ??
                e.message)
          : ((dioError is Map ? dioError['message']?.toString() : null) ??
                e.message);
      if (!mounted) return;
      ZerpaiToast.error(
        context,
        message?.isNotEmpty == true
            ? message!
            : 'Failed to save recurring invoice.',
      );
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to save recurring invoice: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final liveWarehouses =
        ref.watch(warehousesProvider).valueOrNull ?? const <Warehouse>[];
    final theme = Theme.of(context);
    final recurringTextTheme = theme.textTheme.copyWith(
      bodySmall: theme.textTheme.bodySmall?.copyWith(
        fontSize: _kRecurringTextSize,
      ),
      bodyMedium: theme.textTheme.bodyMedium?.copyWith(
        fontSize: _kRecurringTextSize,
      ),
      bodyLarge: theme.textTheme.bodyLarge?.copyWith(
        fontSize: _kRecurringTextSize,
      ),
      titleSmall: theme.textTheme.titleSmall?.copyWith(
        fontSize: _kRecurringTextSize,
      ),
      titleMedium: theme.textTheme.titleMedium?.copyWith(
        fontSize: _kRecurringTextSize,
      ),
      titleLarge: theme.textTheme.titleLarge?.copyWith(
        fontSize: _kRecurringTextSize,
      ),
      labelSmall: theme.textTheme.labelSmall?.copyWith(
        fontSize: _kRecurringTextSize,
      ),
      labelMedium: theme.textTheme.labelMedium?.copyWith(
        fontSize: _kRecurringTextSize,
      ),
      labelLarge: theme.textTheme.labelLarge?.copyWith(
        fontSize: _kRecurringTextSize,
      ),
    );
    _syncSelectedWarehouse(liveWarehouses);

    // Kick off / keep the real products loaded so the item picker is populated.
    ref.watch(itemsControllerProvider);

    final realCustomers = ref.watch(salesCustomersProvider).valueOrNull;
    if (realCustomers != null) {
      final syncKey = _customerSyncFingerprint(realCustomers);
      if (_customersSyncKey != syncKey) {
        _customersSyncKey = syncKey;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _localCustomers
              ..clear()
              ..addAll(
                realCustomers.map(
                  (c) => _CustomerItem(
                    id: c.id,
                    name: c.displayName,
                    code: c.customerNumber ?? '',
                    subtitle: c.email ?? '',
                    data: c,
                  ),
                ),
              );
            final match = _localCustomers.cast<_CustomerItem?>().firstWhere(
              (x) => x?.id == _customer?.id,
              orElse: () => null,
            );
            _customer = match;
            if (_customer != null) {
              _selectedBillingIndex = 0;
              _selectedShippingIndex = 0;
              _billingAddresses = _getDefaultAddressesFor(_customer, 'Billing');
              _shippingAddresses = _getDefaultAddressesFor(
                _customer,
                'Shipping',
              );
            } else {
              _billingAddresses = [];
              _shippingAddresses = [];
            }
          });
        });
      }
    }

    return Theme(
      data: theme.copyWith(
        textTheme: recurringTextTheme,
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          hintStyle: theme.inputDecorationTheme.hintStyle?.copyWith(
            fontSize: _kRecurringTextSize,
          ),
          labelStyle: theme.inputDecorationTheme.labelStyle?.copyWith(
            fontSize: _kRecurringTextSize,
          ),
          helperStyle: theme.inputDecorationTheme.helperStyle?.copyWith(
            fontSize: _kRecurringTextSize,
          ),
          errorStyle: theme.inputDecorationTheme.errorStyle?.copyWith(
            fontSize: _kRecurringTextSize,
          ),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontSize: _kRecurringTextSize),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              Column(
                children: [
                  // Header
                  _buildHeader(),
                  // Form Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Customer Block
                            _buildCustomerSection(),
                            const Divider(
                              height: 1,
                              color: AppTheme.borderColor,
                            ),
                            // Core Form fields
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: _buildCoreFormFields(),
                            ),
                            // Item Table section
                            _buildItemTableSection(screenWidth),
                            const SizedBox(height: 24),
                            // Totals & Terms
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                              ),
                              child: _buildFooterDetailsSection(),
                            ),
                            const SizedBox(height: 36),
                            _buildTermsAndConditions(),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                              ),
                              child: _buildAdditionalSettings(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Footer Action Bar
                  _buildBottomActionBar(),
                ],
              ),
              if (_showCustomerDetails && _customer != null)
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildCustomerDetailsDrawer(),
                ),
              if (_showItemDetails)
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: _ItemDetailsSidebar(
                    item: _selectedSidebarItem,
                    itemName: _selectedSidebarItemName,
                    customerName: _customer?.name ?? 'customer',
                    initialTabIndex: _itemDetailsSidebarTabIndex,
                    onClose: () => setState(() => _showItemDetails = false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.repeat, size: 20, color: AppTheme.textPrimary),
          const SizedBox(width: 12),
          Text(
            'New Recurring Invoice',
            style: AppTheme.pageTitle.copyWith(
              fontSize: _kRecurringTextSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 20),
            onPressed: () => Navigator.pop(context),
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF9FAFB),
      // Right inset kept small so the customer-name tag (the only
      // right-aligned element, pushed by the Spacer) sits near the page edge.
      padding: const EdgeInsets.fromLTRB(48, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Customer Name field
          _FormRow(
            label: 'Customer Name*',
            child: Row(
              children: [
                SizedBox(
                  width: _kRecurringInvoiceCustomerFieldWidth,
                  child: FormDropdown<_CustomerItem>(
                    height: _kRecurringInvoiceFieldHeight,
                    value: _customer,
                    items: _localCustomers,
                    hint: 'Select or add a customer',
                    allowClear: true,
                    itemEstimatedHeight: 68,
                    menuMaxHeight: 335,
                    showSearchIcon: true,
                    searchIconColor: const Color(0xFF22B378),
                    showSettings: true,
                    settingsLabel: 'New Customer',
                    settingsIcon: LucideIcons.plus,
                    onSettingsTap: _showNewCustomerDialog,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                    displayStringForValue: (c) => c.name,
                    searchStringForValue: _customerSearchText,
                    itemBuilder: _buildCustomerDropdownRow,
                    onChanged: (v) {
                      setState(() {
                        _customer = v;
                        _selectedBillingIndex = 0;
                        _selectedShippingIndex = 0;
                        if (v != null) {
                          _billingAddresses = _getDefaultAddressesFor(
                            v,
                            'Billing',
                          );
                          _shippingAddresses = _getDefaultAddressesFor(
                            v,
                            'Shipping',
                          );
                        } else {
                          _billingAddresses = [];
                          _shippingAddresses = [];
                        }
                      });
                    },
                  ),
                ),
                InkWell(
                  onTap: _showAdvancedSearchDialog,
                  child: Container(
                    width: 32,
                    height: _kRecurringInvoiceFieldHeight,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22B378),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.search,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_customer != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    height: _kRecurringInvoiceFieldHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.borderLight),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.globe,
                          size: 13,
                          color: Color(0xFF22C55E),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'INR',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => setState(
                      () => _showCustomerDetails = !_showCustomerDetails,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF374151),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_customer!.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Row 2: Billing & Shipping Address lines
          if (_customer != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 160, top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Billing Address
                  SizedBox(
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CompositedTransformTarget(
                          link: _billingAddressLayerLink,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'BILLING ADDRESS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: _showBillingOverlay,
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    LucideIcons.pencil,
                                    size: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_billingAddresses.isNotEmpty) ...[
                          Text(
                            _billingAddresses[_selectedBillingIndex]['attention'] ??
                                '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ..._addressDisplayLines(
                                _billingAddresses[_selectedBillingIndex],
                              )
                              .where((line) => line.isNotEmpty)
                              .expand((line) => line.split('\n'))
                              .where((line) => line.trim().isNotEmpty)
                              .map(
                                (line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    line,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ),
                        ] else
                          InkWell(
                            onTap: _showBillingOverlay,
                            child: const Text(
                              'New Address',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Shipping Address
                  SizedBox(
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CompositedTransformTarget(
                          link: _shippingAddressLayerLink,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'SHIPPING ADDRESS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: _showShippingOverlay,
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    LucideIcons.pencil,
                                    size: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_shippingAddresses.isNotEmpty) ...[
                          Text(
                            _shippingAddresses[_selectedShippingIndex]['attention'] ??
                                '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ..._addressDisplayLines(
                                _shippingAddresses[_selectedShippingIndex],
                              )
                              .where((line) => line.isNotEmpty)
                              .expand((line) => line.split('\n'))
                              .where((line) => line.trim().isNotEmpty)
                              .map(
                                (line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    line,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ),
                        ] else
                          InkWell(
                            onTap: _showShippingOverlay,
                            child: const Text(
                              'New Address',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Row 3: GST Treatment
            Padding(
              padding: const EdgeInsets.only(left: 160, top: 16, bottom: 12),
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                      children: [
                        const TextSpan(
                          text: 'GST Treatment: ',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        TextSpan(
                          text: _gstTreatment,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _showGstTreatmentDialog,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        LucideIcons.pencil,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Row 4: Place of Supply*
            _FormRow(
              label: 'Place of Supply*',
              child: Builder(
                builder: (context) {
                  final statesAsync = ref.watch(statesProvider('IN'));
                  final placeOfSupplyOptions = (statesAsync.value ?? [])
                      .map(_formatPlaceOfSupplyOption)
                      .where((value) => value.isNotEmpty)
                      .toList();
                  final selectedValue =
                      placeOfSupplyOptions.contains(_placeOfSupply)
                      ? _placeOfSupply
                      : null;

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: _kRecurringInvoiceCompactFieldWidth,
                      child: FormDropdown<String>(
                        height: _kRecurringInvoiceFieldHeight,
                        value: selectedValue,
                        items: placeOfSupplyOptions,
                        hint: statesAsync.isLoading
                            ? 'Loading Place of Supply'
                            : 'Select Place of Supply',
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _placeOfSupply = v;
                              _syncRowTaxesForPlaceOfSupply(v);
                            });
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 160, bottom: 12),
              child: Text(
                'Source of Supply: ${_sourceOfSupplyLabel(_placeOfSupply)}',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Keep transaction series visible even before customer selection.
          _FormRow(
            label: 'Transaction Series',
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: _kRecurringInvoiceCompactFieldWidth,
                child: FormDropdown<_TransactionSeriesItem>(
                  height: _kRecurringInvoiceFieldHeight,
                  value: _selectedTransactionSeriesItem(),
                  items: _transactionSeriesOptions,
                  displayStringForValue: (series) => series.name,
                  searchStringForValue: (series) => series.name,
                  hint: _isLoadingTransactionSeries
                      ? 'Loading transaction series...'
                      : (_transactionSeriesOptions.isEmpty
                            ? 'No transaction series found'
                            : 'Select transaction series'),
                  isLoading: _isLoadingTransactionSeries,
                  enabled:
                      !_isLoadingTransactionSeries &&
                      _transactionSeriesOptions.isNotEmpty,
                  onChanged: (v) {
                    setState(() => _transactionSeries = v?.id);
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 160, bottom: 12),
            child: Text(
              _entityType == 'Invoice'
                  ? 'Invoice#: INV-000089'
                  : 'Invoice#: BOS-000001',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Entity Type
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: _FormRow(
            label: 'Entity type*',
            child: Row(
              children: [
                Radio<String>(
                  value: 'Invoice',
                  activeColor: const Color(0xFF2563EB),
                  // ignore: deprecated_member_use
                  groupValue: _entityType,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setState(() => _entityType = v!),
                ),
                const Text('Invoice', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 16),
                Radio<String>(
                  value: 'Bill Of Supply',
                  activeColor: const Color(0xFF2563EB),
                  // ignore: deprecated_member_use
                  groupValue: _entityType,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setState(() => _entityType = v!),
                ),
                const Text('Bill Of Supply', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Profile Name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: _FormRow(
            label: 'Profile Name*',
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: _kRecurringInvoiceCompactFieldWidth,
                child: CustomTextField(
                  controller: _profileNameCtrl,
                  height: _kRecurringInvoiceFieldHeight,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Order Number
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: _FormRow(
            label: 'Order Number',
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: _kRecurringInvoiceCompactFieldWidth,
                child: CustomTextField(
                  controller: _orderNoCtrl,
                  height: _kRecurringInvoiceFieldHeight,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Repeat Every
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: _FormRow(
            label: 'Repeat Every*',
            child: Row(
              children: [
                SizedBox(
                  width: _kRecurringInvoiceCompactFieldWidth,
                  child: FormDropdown<String>(
                    height: _kRecurringInvoiceFieldHeight,
                    value: _repeatEvery,
                    items: _kRepeatFrequencies,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _repeatEvery = v;
                        if (v != 'Custom') {
                          _syncCustomRepeatEveryState(v);
                        }
                      });
                    },
                  ),
                ),
                if (_repeatEvery == 'Custom') ...[
                  const SizedBox(width: 32),
                  SizedBox(
                    width: 60,
                    child: CustomTextField(
                      controller: _customRepeatIntervalCtrl,
                      height: _kRecurringInvoiceFieldHeight,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (_) {
                        setState(() => _normalizeCustomRepeatSelection());
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 160,
                    child: FormDropdown<String>(
                      height: _kRecurringInvoiceFieldHeight,
                      value: _customRepeatFrequencyUnit,
                      items: const ['Day(s)', 'Week(s)', 'Month(s)', 'Year(s)'],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _customRepeatFrequencyUnit = v;
                            _normalizeCustomRepeatSelection();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Start On / Ends On / Never Expires
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: _FormRow(
            label: 'Start On',
            child: Row(
              children: [
                // Start Date Picker Box
                GestureDetector(
                  key: _startDateKey,
                  onTap: () async {
                    final picked = await ZerpaiDatePicker.show(
                      context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      targetKey: _startDateKey,
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                  child: Container(
                    width: 220,
                    height: _kRecurringInvoiceFieldHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_startDate.day.toString().padLeft(2, '0')}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.year}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(
                          LucideIcons.calendar,
                          size: 15,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                const Text('Ends On', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 12),
                // Ends On Date Picker Box
                GestureDetector(
                  key: _endDateKey,
                  onTap: _neverExpires
                      ? null
                      : () async {
                          final picked = await ZerpaiDatePicker.show(
                            context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            targetKey: _endDateKey,
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                  child: Container(
                    width: 150,
                    height: _kRecurringInvoiceFieldHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _neverExpires
                          ? const Color(0xFFF3F4F6)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _neverExpires
                                ? 'dd-MM-yyyy'
                                : (_endDate != null
                                      ? '${_endDate!.day.toString().padLeft(2, '0')}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.year}'
                                      : 'dd-MM-yyyy'),
                            style: TextStyle(
                              fontSize: 13,
                              color: _neverExpires || _endDate == null
                                  ? AppTheme.textMuted
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          LucideIcons.calendar,
                          size: 15,
                          color: _neverExpires
                              ? AppTheme.textDisabled
                              : AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Checkbox(
                  value: _neverExpires,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (v) => setState(() {
                    _neverExpires = v ?? true;
                    if (_neverExpires) _endDate = null;
                  }),
                ),
                const Text('Never Expires', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Payment Terms
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: _FormRow(
            label: 'Payment Terms',
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: _kRecurringInvoiceCompactFieldWidth,
                child: Builder(
                  builder: (context) {
                    final selectedPaymentTermId =
                        _paymentTermsList.any(
                          (term) => term['id']?.toString() == _paymentTerms,
                        )
                        ? _paymentTerms
                        : null;

                    return FormDropdown<String>(
                      height: _kRecurringInvoiceFieldHeight,
                      value: selectedPaymentTermId,
                      showSettings: true,
                      settingsLabel: 'New Payment Term',
                      onSettingsTap: _showConfigurePaymentTermsDialog,
                      items: _paymentTermsList
                          .map((term) => term['id']?.toString() ?? '')
                          .where((id) => id.isNotEmpty)
                          .toList(),
                      hint: _paymentTermsList.isEmpty
                          ? 'Loading Payment Terms'
                          : 'Select Payment Terms',
                      displayStringForValue: (id) {
                        final term = _paymentTermsList.firstWhere(
                          (t) => t['id']?.toString() == id,
                          orElse: () => {'term_name': id},
                        );
                        return term['term_name']?.toString() ?? id;
                      },
                      itemBuilder: (id, isSelected, isHovered) {
                        final term = _paymentTermsList.firstWhere(
                          (t) => t['id']?.toString() == id,
                          orElse: () => {'term_name': id},
                        );
                        final label = term['term_name']?.toString() ?? id;
                        return Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: isHovered
                                ? AppTheme.primaryBlueDark
                                : isSelected
                                ? AppTheme.infoBg
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isHovered
                                        ? Colors.white
                                        : isSelected
                                        ? AppTheme.primaryBlueDark
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: isHovered
                                      ? Colors.white
                                      : AppTheme.primaryBlueDark,
                                ),
                            ],
                          ),
                        );
                      },
                      onChanged: (v) {
                        if (v != null) setState(() => _paymentTerms = v);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: AppTheme.borderColor.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        // Salesperson
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: _FormRow(
            label: 'Salesperson',
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: _kRecurringInvoiceCompactFieldWidth,
                child: FormDropdown<String>(
                  height: _kRecurringInvoiceFieldHeight,
                  value: _salesperson,
                  items: _activeSalespersons.map((s) => s.name).toList(),
                  allowClear: true,
                  showSettings: true,
                  settingsLabel: 'Manage Salespersons',
                  settingsIcon: LucideIcons.settings,
                  onSettingsTap: () async {
                    final result = await showDialog<String>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => _ManageSalespersonsDialog(
                        salespersons: _localSalespersons,
                        onToggleActive: _updateSalespersonStatus,
                        onDelete: _deleteSalespersonOption,
                      ),
                    );
                    if (result != null) {
                      final selected = _findSalespersonByName(result);
                      setState(() {
                        _salesperson = selected?.name ?? result;
                        _salespersonId = selected?.id;
                      });
                    }
                  },
                  onChanged: (v) {
                    final selected = _findSalespersonByName(v);
                    setState(() {
                      _salesperson = selected?.name;
                      _salespersonId = selected?.id;
                    });
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: _FormRow(
            label: 'Subject',
            labelSuffix: const ZTooltip(
              message:
                  'can enter up to 250 characters. If do not require this field, you can keep it as inactive under invoice references.',
              child: Icon(LucideIcons.info, size: 14, color: Color(0xFF94A3B8)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: _kRecurringInvoiceCompactFieldWidth,
                child: CustomTextField(
                  controller: _subjectCtrl,
                  hintText:
                      'Let your customer know what this Recurring Invoice is for',
                  maxLines: null,
                  height: 48,
                  minHeight: 48,
                  resizable: true,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ],
    );
  }

  Widget _buildItemTableSection(double screenWidth) {
    final warehousesAsync = ref.watch(warehousesProvider);
    final liveWarehouses = warehousesAsync.valueOrNull ?? const <Warehouse>[];
    final isWarehousesLoading = warehousesAsync.isLoading;
    final hasWarehousesError = warehousesAsync.hasError;
    final warehouseLabel = _selectedWarehouseName.isNotEmpty
        ? _selectedWarehouseName
        : (liveWarehouses.isNotEmpty
              ? liveWarehouses.first.name
              : (isWarehousesLoading
                    ? 'Loading warehouses'
                    : (hasWarehousesError
                          ? 'Failed to load warehouses'
                          : 'No warehouses for this entity')));

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 24, top: 16, bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Warehouse Location',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Theme(
                    data: Theme.of(context).copyWith(
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      popupMenuTheme: PopupMenuThemeData(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: AppTheme.borderLight),
                        ),
                        elevation: 4,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      offset: const Offset(0, 24),
                      onSelected: (val) {
                        setState(() {
                          _selectedWarehouseId = liveWarehouses
                              .cast<Warehouse?>()
                              .firstWhere(
                                (warehouse) => warehouse?.name == val,
                                orElse: () => null,
                              )
                              ?.id;
                          _selectedWarehouseName = val;
                          _location = val;
                          for (final row in _items) {
                            row.warehouseName = val;
                          }
                        });
                      },
                      itemBuilder: (context) => liveWarehouses.map((warehouse) {
                        final warehouseName = warehouse.name.trim();
                        bool isSelected = _selectedWarehouseId == warehouse.id;
                        return PopupMenuItem<String>(
                          value: warehouseName,
                          height: 32,
                          padding: EdgeInsets.zero,
                          child: _PriceListPopupRow(
                            label: warehouseName,
                            isSelected: isSelected,
                          ),
                        );
                      }).toList(),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                warehouseLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted,
                                  decorationColor: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(height: 16, width: 1, color: AppTheme.borderLight),
                  if (_showPriceListSetting) ...[
                    const SizedBox(width: 16),
                    Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        popupMenuTheme: PopupMenuThemeData(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: AppTheme.borderLight),
                          ),
                          elevation: 4,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.clipboardList,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            offset: const Offset(0, 24),
                            onSelected: (val) {
                              final selected = _findPriceListById(val);
                              setState(() {
                                _applyGlobalPriceListSelection(selected);
                              });
                            },
                            itemBuilder: (context) =>
                                _localPriceLists.map((pl) {
                                  bool isSelected = _priceListId == pl.id;
                                  return PopupMenuItem<String>(
                                    value: pl.id,
                                    height: 32,
                                    padding: EdgeInsets.zero,
                                    child: _PriceListPopupRow(
                                      label: pl.name,
                                      isSelected: isSelected,
                                    ),
                                  );
                                }).toList(),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  _priceList ??
                                      (_localPriceLists.isEmpty
                                          ? 'No Sales Price Lists'
                                          : 'Select Price List'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _priceList == null
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                    color: _priceList == null
                                        ? AppTheme.textSecondary
                                        : AppTheme.textPrimary,
                                    decoration: TextDecoration.underline,
                                    decorationStyle: TextDecorationStyle.dotted,
                                    decorationColor: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_priceList != null) ...[
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) {
                                    setState(() {
                                      _priceListId = null;
                                      _priceList = null;
                                      _refreshAllRowRates();
                                    });
                                  }
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 2),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          Container(
                            height: 12,
                            width: 1,
                            color: AppTheme.borderLight,
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            offset: const Offset(0, 24),
                            onSelected: (val) {
                              final selected = _findPriceListById(val);
                              setState(() {
                                _applyGlobalPriceListSelection(selected);
                              });
                            },
                            itemBuilder: (context) =>
                                _localPriceLists.map((pl) {
                                  bool isSelected = _priceListId == pl.id;
                                  return PopupMenuItem<String>(
                                    value: pl.id,
                                    height: 32,
                                    padding: EdgeInsets.zero,
                                    child: _PriceListPopupRow(
                                      label: pl.name,
                                      isSelected: isSelected,
                                    ),
                                  );
                                }).toList(),
                            child: const MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              SalesItemTableSectionBar(
                title: const Text(
                  'Item Table',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        popupMenuTheme: PopupMenuThemeData(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: AppTheme.borderLight),
                          ),
                          elevation: 4,
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        offset: const Offset(0, 28),
                        onSelected: (val) {
                          if (val == 'toggle_additional_info') {
                            setState(() {
                              _hideAllAdditionalInfo = !_hideAllAdditionalInfo;
                            });
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'toggle_additional_info',
                            height: 40,
                            padding: EdgeInsets.zero,
                            child: _PriceListPopupRow(
                              label: _hideAllAdditionalInfo
                                  ? 'Show All Additional Information'
                                  : 'Hide All Additional Information',
                              isSelected: false,
                            ),
                          ),
                        ],
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  LucideIcons.checkCircle,
                                  size: 16,
                                  color: AppTheme.primaryBlue,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Bulk Actions',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CompositedTransformTarget(
                      link: _settingsLink,
                      child: InkWell(
                        onTap: _toggleSettingsOverlay,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.settings,
                                size: 16,
                                color: Color(0xFF4B5563),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 16,
                                color: Color(0xFF4B5563),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SalesItemTableHeaderFrame(
                leadingWidth: 0,
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      flex: 14,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: _buildRecurringHeaderSearchField(),
                      ),
                    ),
                    _recurringTableDivider(),
                    const Expanded(
                      flex: 5,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: _RecurringTableHeaderCell(
                          'QUANTITY',
                          right: true,
                        ),
                      ),
                    ),
                    _recurringTableDivider(),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            _RecurringTableHeaderCell('RATE'),
                            SizedBox(width: 4),
                            ZTooltip(
                              message:
                                  'You can perform basic calculations directly in this field using parentheses and arithmetic operators.',
                              child: Icon(
                                LucideIcons.calculator,
                                size: 13,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _recurringTableDivider(),
                    const Expanded(
                      flex: 5,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: _RecurringTableHeaderCell(
                          'DISCOUNT',
                          right: true,
                        ),
                      ),
                    ),
                    _recurringTableDivider(),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _RecurringTableHeaderCell('TAX'),
                            SizedBox(width: 6),
                            ZTooltip(
                              message:
                                  'Tax can only be applied to an item after choosing a customer. Please select a customer from the Customer Name drop-down.',
                              direction: ZTooltipDirection.bottom,
                              child: Icon(
                                LucideIcons.helpCircle,
                                size: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _recurringTableDivider(),
                    const Expanded(
                      flex: 4,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: _RecurringTableHeaderCell('AMOUNT', right: true),
                      ),
                    ),
                  ],
                ),
              ),
              ReorderableListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                clipBehavior: Clip.none,
                itemCount: _items.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = _items.removeAt(oldIndex);
                    _items.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, idx) {
                  final row = _items[idx];
                  if (_headerRows.contains(row)) {
                    return _buildHeaderRow(idx);
                  }
                  if (_itemDetailsSearchQuery.isNotEmpty) {
                    final itemName = row.nameCtrl.text.trim().toLowerCase();
                    final description = row.descCtrl.text.trim().toLowerCase();
                    final query = _itemDetailsSearchQuery.toLowerCase();
                    if (!itemName.contains(query) &&
                        !description.contains(query)) {
                      return SizedBox(key: ValueKey(row));
                    }
                  }
                  return _buildItemRow(idx);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildRecurringAddRowButton(),
                  const SizedBox(width: 12),
                  _buildRecurringBulkAddButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecurringAddRowButton() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(_ensureTrailingRecurringItemRow),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 14,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Add New Row',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringBulkAddButton() {
    return InkWell(
      onTap: _showRecurringBulkItemsDialog,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, size: 14, color: Color(0xFF2563EB)),
            SizedBox(width: 6),
            Text(
              'Add Items in Bulk',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringHeaderSearchField() {
    if (!_showSearchItemDetails) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _RecurringTableHeaderCell('ITEMS DETAILS'),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              setState(() {
                _showSearchItemDetails = true;
              });
            },
            child: const Icon(
              LucideIcons.search,
              size: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      );
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 12, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _itemDetailsSearchCtrl,
              onChanged: (value) {
                setState(() {
                  _itemDetailsSearchQuery = value;
                });
              },
              autofocus: true,
              style: const TextStyle(fontSize: 11, color: Color(0xFF111827)),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                hintText: 'Search items...',
                hintStyle: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                border: InputBorder.none,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _showSearchItemDetails = false;
                _itemDetailsSearchCtrl.clear();
                _itemDetailsSearchQuery = '';
              });
            },
            child: const Icon(
              LucideIcons.x,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  void _showItemPicker(_ItemRow row) {
    _hideItemPicker();
    _itemPickerHoverIndex = 0;

    _itemPickerOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideItemPicker,
              ),
            ),
            CompositedTransformFollower(
              link: row.itemPickerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 48),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 620,
                  constraints: const BoxConstraints(maxHeight: 420),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Scrollbar(
                          controller: _itemPickerScrollCtrl,
                          thumbVisibility: true,
                          child: Builder(
                            builder: (context) {
                              final options = _itemPickerOptions;
                              return ListView.builder(
                                controller: _itemPickerScrollCtrl,
                                padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final item = options[index];
                                  final hovered =
                                      _itemPickerHoverIndex == index;
                                  return MouseRegion(
                                    onEnter: (_) {
                                      _itemPickerHoverIndex = index;
                                      _itemPickerOverlayEntry?.markNeedsBuild();
                                    },
                                    child: InkWell(
                                      onTap: () {
                                        final selectedItem = ref
                                            .read(itemsControllerProvider)
                                            .items
                                            .where(
                                              (product) =>
                                                  product.productName ==
                                                  item.$1,
                                            )
                                            .firstOrNull;
                                        setState(() {
                                          if (selectedItem != null) {
                                            _hydrateRecurringRowFromItem(
                                              row,
                                              selectedItem,
                                              quantity:
                                                  int.tryParse(
                                                    row.quantityCtrl.text,
                                                  ) ??
                                                  1,
                                            );
                                          } else {
                                            row.nameCtrl.text = item.$1;
                                            row.rateCtrl.text = item.$2;
                                          }
                                          _ensureTrailingRecurringItemRow();
                                        });
                                        _hideItemPicker();
                                      },
                                      hoverColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      child: Container(
                                        height: 68,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: hovered
                                              ? const Color(0xFF3B82F6)
                                              : Colors.white,
                                          borderRadius: hovered
                                              ? BorderRadius.circular(4)
                                              : null,
                                          border: hovered
                                              ? null
                                              : const Border(
                                                  bottom: BorderSide(
                                                    color: AppTheme.borderLight,
                                                  ),
                                                ),
                                        ),
                                        alignment: Alignment.centerLeft,
                                        child: RichText(
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: item.$1,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  height: 1.2,
                                                  fontWeight: FontWeight.w400,
                                                  color: hovered
                                                      ? Colors.white
                                                      : AppTheme.textPrimary,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    '\nRate: \u20B9${item.$2}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  height: 1.2,
                                                  fontWeight: FontWeight.w600,
                                                  color: hovered
                                                      ? Colors.white
                                                      : AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _hideItemPicker();
                          _showEditItemDialog(row);
                        },
                        hoverColor: AppTheme.bgDisabled,
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          child: const Row(
                            children: [
                              Icon(
                                LucideIcons.plusCircle,
                                size: 14,
                                color: AppTheme.primaryBlue,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Add New Item',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
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

    Overlay.of(context).insert(_itemPickerOverlayEntry!);
  }

  void _hideItemPicker() {
    _itemPickerOverlayEntry?.remove();
    _itemPickerOverlayEntry = null;
    _itemPickerHoverIndex = null;
  }

  // ── HSN Code inline editor ────────────────────────────────────────────────
  OverlayEntry? _hsnOverlay;
  TextEditingController? _hsnTempCtrl;

  void _hideHsnEditor() {
    _hsnOverlay?.remove();
    _hsnOverlay = null;
    _hsnTempCtrl?.dispose();
    _hsnTempCtrl = null;
  }

  void _showHsnCodeDialog(
    _ItemRow row, {
    required String codeLabel,
    String initialValue = '',
  }) {
    _hideHsnEditor();
    _hsnTempCtrl = TextEditingController(text: initialValue);
    _hsnOverlay = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideHsnEditor,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: row.hsnLink,
            showWhenUnlinked: false,
            offset: const Offset(-8, 24),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 58),
                    child: CustomPaint(
                      size: Size(18, 10),
                      painter: _PopoverPointerPainter(),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -1),
                    child: Container(
                      width: 320,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            codeLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _hsnTempCtrl!,
                            hintText: 'Enter $codeLabel',
                            autoFocus: true,
                            keyboardType: TextInputType.number,
                            suffixWidget: InkWell(
                              onTap: () async {
                                final result = await showDialog<HsnSacCode>(
                                  context: context,
                                  useSafeArea: false,
                                  builder: (context) => HsnSacSearchModal(
                                    type: codeLabel.startsWith('HSN')
                                        ? 'HSN'
                                        : 'SAC',
                                    initialQuery: _hsnTempCtrl?.text,
                                  ),
                                );
                                if (result != null) {
                                  _hsnTempCtrl?.text = result.code;
                                  setState(() {
                                    row.hsnCtrl.text = result.code;
                                  });
                                  _hideHsnEditor();
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(
                                  LucideIcons.search,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                            onSubmitted: (_) {
                              setState(() {
                                row.hsnCtrl.text =
                                    _hsnTempCtrl?.text.trim() ?? '';
                              });
                              _hideHsnEditor();
                            },
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      row.hsnCtrl.text =
                                          _hsnTempCtrl?.text.trim() ?? '';
                                    });
                                    _hideHsnEditor();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF22A95E),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
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
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 32,
                                child: OutlinedButton(
                                  onPressed: _hideHsnEditor,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF22A95E),
                                    side: const BorderSide(
                                      color: Color(0xFF22A95E),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
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
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_hsnOverlay!);
  }

  void _removeRowAt(int index) {
    setState(() {
      if (index < 0 || index >= _items.length) return;
      final removed = _items.removeAt(index);
      _headerRows.remove(removed);
      removed.dispose();
      _ensureTrailingRecurringItemRow();
    });
  }

  void _toggleSettingsOverlay() {
    if (_settingsOverlay != null) {
      _settingsOverlay?.remove();
      _settingsOverlay = null;
      setState(() {});
      return;
    }

    String? hovered;
    _settingsOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _settingsOverlay?.remove();
                _settingsOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _settingsLink,
            showWhenUnlinked: false,
            offset: const Offset(-200, 24),
            child: Material(
              elevation: 12,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Container(
                width: 250,
                padding: const EdgeInsets.all(8),
                child: StatefulBuilder(
                  builder: (context, setOverlayState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSettingsOverlayItem(
                          label: _showAvailableStockForSale
                              ? 'Hide Available stock for sale'
                              : 'Show Available stock for sale',
                          showHighlight: hovered == 'stock',
                          onHover: (v) => setOverlayState(
                            () => hovered = v ? 'stock' : null,
                          ),
                          onTap: () {
                            setState(() {
                              _showAvailableStockForSale =
                                  !_showAvailableStockForSale;
                            });
                            _settingsOverlay?.remove();
                            _settingsOverlay = null;
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 4),
                        _buildSettingsOverlayItem(
                          label: _showRecentTransactionSetting
                              ? 'Hide Recent Transaction'
                              : 'Show Recent Transaction',
                          showHighlight: hovered == 'history',
                          onHover: (v) => setOverlayState(
                            () => hovered = v ? 'history' : null,
                          ),
                          onTap: () {
                            setState(() {
                              _showRecentTransactionSetting =
                                  !_showRecentTransactionSetting;
                            });
                            _settingsOverlay?.remove();
                            _settingsOverlay = null;
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 4),
                        _buildSettingsOverlayItem(
                          label: _showRowPriceListSetting
                              ? 'Hide PriceList'
                              : 'Show PriceList',
                          showHighlight: hovered == 'pricelist',
                          onHover: (v) => setOverlayState(
                            () => hovered = v ? 'pricelist' : null,
                          ),
                          onTap: () {
                            setState(() {
                              _showRowPriceListSetting =
                                  !_showRowPriceListSetting;
                            });
                            _settingsOverlay?.remove();
                            _settingsOverlay = null;
                            setState(() {});
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_settingsOverlay!);
    setState(() {});
  }

  Widget _buildSettingsOverlayItem({
    required String label,
    required bool showHighlight,
    required ValueChanged<bool> onHover,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onHover: onHover,
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: showHighlight ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: showHighlight ? FontWeight.w600 : FontWeight.w500,
            color: showHighlight
                ? Colors.white
                : AppTheme.textPrimary.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineItemMeta(_ItemRow row) {
    if (_hideAllAdditionalInfo || row.hideAdditionalInfo) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Builder(
            builder: (context) {
              final accountsState = ref.watch(chartOfAccountsProvider);
              final incomeAccountOptions = _buildIncomeAccountOptions(
                accountsState.roots,
              );
              final selectedIncomeAccount = _selectedIncomeAccountOption(
                row,
                incomeAccountOptions,
              );
              final discountAccountOptions = _buildDiscountAccountOptions(
                accountsState.roots,
              );
              final selectedDiscountAccount = _selectedDiscountAccountOption(
                row,
                discountAccountOptions,
              );

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 138,
                    child: FormDropdown<_IncomeAccountOption>(
                      value: selectedIncomeAccount,
                      items: incomeAccountOptions,
                      hint: accountsState.isLoading
                          ? 'Loading accounts...'
                          : _kSelectAccountLabel,
                      onChanged: (option) {
                        setState(() {
                          row.incomeAccount =
                              option ?? _kDefaultIncomeAccountOption;
                        });
                      },
                      showSearch: true,
                      showSearchIcon: true,
                      showCustomValueAction: false,
                      placeholder: _kSelectAccountLabel,
                      menuWidth: 305,
                      menuMaxHeight: 360,
                      itemEstimatedHeight: 52,
                      hideBorderDefault: true,
                      fillColor: const Color(0xFFF7F8FB),
                      displayStringForValue: (option) => option.title,
                      searchStringForValue: (option) => option.searchText,
                      isItemEnabled: (option) => !option.isHeader,
                      itemBuilder: _buildIncomeAccountDropdownRow,
                      padding: EdgeInsets.zero,
                      prefixWidget: _buildArchiveIcon(
                        isSelected:
                            row.incomeAccount.title != _kSelectAccountLabel,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1,
                      ),
                      iconSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 14,
                    color: const Color(0xFFD1D5DB),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 102,
                    child: FormDropdown<_DiscountAccountOption>(
                      value: selectedDiscountAccount,
                      items: discountAccountOptions,
                      hint: accountsState.isLoading
                          ? 'Loading accounts...'
                          : _kSelectDiscountAccountLabel,
                      onChanged: (option) {
                        setState(() {
                          row.discount =
                              option ?? _kDefaultDiscountAccountOption;
                        });
                      },
                      showSearch: true,
                      showSearchIcon: true,
                      showCustomValueAction: false,
                      placeholder: _kSelectDiscountAccountLabel,
                      menuWidth: 290,
                      menuMaxHeight: 320,
                      itemEstimatedHeight: 44,
                      hideBorderDefault: true,
                      fillColor: const Color(0xFFF7F8FB),
                      displayStringForValue: (option) => option.title,
                      searchStringForValue: (option) => option.searchText,
                      isItemEnabled: (option) => !option.isHeader,
                      itemBuilder: _buildDiscountAccountDropdownRow,
                      padding: EdgeInsets.zero,
                      prefixWidget: SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M4.9 3.05a2.1 2.1 0 0 1 4.2 0h.85c1.02 0 1.85.83 1.85 1.85v5.1c0 1.02-.83 1.85-1.85 1.85H4.05A1.85 1.85 0 0 1 2.2 10V4.9c0-1.02.83-1.85 1.85-1.85z" stroke="#94A3B8" stroke-width="1.05" stroke-linejoin="round"/><path d="M4.9 4.25V3.1a2.1 2.1 0 1 1 4.2 0v1.15" stroke="#94A3B8" stroke-width="1.05" stroke-linecap="round"/><path d="M5.25 9.1 8.75 5.6" stroke="#94A3B8" stroke-width="1.05" stroke-linecap="round"/><circle cx="5.55" cy="5.75" r="0.62" stroke="#94A3B8" stroke-width="1.0"/><circle cx="8.45" cy="8.65" r="0.62" stroke="#94A3B8" stroke-width="1.0"/></svg>',
                        width: 14,
                        height: 14,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1,
                      ),
                      iconSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 14,
                    color: const Color(0xFFD1D5DB),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 150,
                    child: _buildRowReportingTagsDropdown(row),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveIcon({bool isSelected = true}) {
    final stroke = isSelected ? '#5B668F' : '#8FA0A0';
    final fill = isSelected ? '#9AA8A2' : '#DDE5EA';
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M4.35 2.2h5.3" stroke="$stroke" stroke-width="0.95" stroke-linecap="round"/><path d="M3.7 4.1h6.6" stroke="$stroke" stroke-width="0.95" stroke-linecap="round"/><path d="M2.7 5.15c0-.72.58-1.3 1.3-1.3h6c.72 0 1.3.58 1.3 1.3v4.45c0 .88-.72 1.6-1.6 1.6H4.3c-.88 0-1.6-.72-1.6-1.6z" fill="$fill" stroke="$stroke" stroke-width="0.95" stroke-linejoin="round"/><path d="M5.85 6.55h2.3" stroke="$stroke" stroke-width="0.95" stroke-linecap="round"/></svg>',
      width: 14,
      height: 14,
    );
  }

  Widget _buildRowReportingTagsDropdown(_ItemRow row) {
    return ReportingTagsPopover(
      row: row,
      onSaved: () {
        setState(() {});
      },
    );
  }

  String _incomeAccountSearchText(AccountNode account) {
    final parts = <String>[
      account.name,
      account.parentName ?? '',
      account.accountType,
      account.accountGroup,
      account.code ?? '',
    ];
    return parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  List<AccountNode> _flattenActiveIncomeAccounts(List<AccountNode> nodes) {
    final accounts = <AccountNode>[];

    void collect(List<AccountNode> currentNodes) {
      for (final node in currentNodes) {
        if (!node.isActive || node.isDeleted) {
          continue;
        }
        accounts.add(node);
        collect(node.children);
      }
    }

    collect(nodes);
    return accounts;
  }

  List<_IncomeAccountOption> _buildIncomeAccountOptions(
    List<AccountNode> roots,
  ) {
    final groupedAccounts = <String, List<AccountNode>>{};
    for (final account in _flattenActiveIncomeAccounts(roots)) {
      final type = account.accountType.trim().isEmpty
          ? 'Other Accounts'
          : account.accountType.trim();
      groupedAccounts.putIfAbsent(type, () => <AccountNode>[]).add(account);
    }

    final options = <_IncomeAccountOption>[];
    for (final entry in groupedAccounts.entries) {
      final accounts = entry.value;
      if (accounts.isEmpty) {
        continue;
      }

      final headerSearchText = <String>[
        entry.key,
        ...accounts.map(_incomeAccountSearchText),
      ].join(' ');

      options.add(
        _IncomeAccountOption(
          entry.key,
          isHeader: true,
          searchText: headerSearchText,
        ),
      );

      for (final account in accounts) {
        options.add(
          _IncomeAccountOption(
            account.name,
            accountId: account.id,
            searchText: _incomeAccountSearchText(account),
            level: 1,
          ),
        );
      }
    }

    return options;
  }

  List<_DiscountAccountOption> _buildDiscountAccountOptions(
    List<AccountNode> roots,
  ) {
    final groupedAccounts = <String, List<AccountNode>>{};
    for (final account in _flattenActiveIncomeAccounts(roots)) {
      final type = account.accountType.trim().isEmpty
          ? 'Other Accounts'
          : account.accountType.trim();
      groupedAccounts.putIfAbsent(type, () => <AccountNode>[]).add(account);
    }

    final options = <_DiscountAccountOption>[];
    for (final entry in groupedAccounts.entries) {
      final accounts = entry.value;
      if (accounts.isEmpty) {
        continue;
      }

      final headerSearchText = <String>[
        entry.key,
        ...accounts.map(_incomeAccountSearchText),
      ].join(' ');

      options.add(
        _DiscountAccountOption(
          entry.key,
          isHeader: true,
          searchText: headerSearchText,
        ),
      );

      for (final account in accounts) {
        options.add(
          _DiscountAccountOption(
            account.name,
            accountId: account.id,
            searchText: _incomeAccountSearchText(account),
            level: 1,
          ),
        );
      }
    }

    if (options.isEmpty) {
      options.add(_kDefaultDiscountAccountOption);
    }

    return options;
  }

  _IncomeAccountOption? _selectedIncomeAccountOption(
    _ItemRow row,
    List<_IncomeAccountOption> options,
  ) {
    if (row.incomeAccount.title == _kSelectAccountLabel) {
      return null;
    }

    for (final option in options) {
      if (option.isHeader) {
        continue;
      }
      if (row.incomeAccount.accountId != null &&
          option.accountId == row.incomeAccount.accountId) {
        return option;
      }
      if (option.title == row.incomeAccount.title) {
        return option;
      }
    }
    return row.incomeAccount.isHeader ? null : row.incomeAccount;
  }

  _DiscountAccountOption? _selectedDiscountAccountOption(
    _ItemRow row,
    List<_DiscountAccountOption> options,
  ) {
    if (row.discount.title == _kDefaultDiscountAccountOption.title &&
        row.discount.accountId == null) {
      return null;
    }

    for (final option in options) {
      if (option.isHeader) {
        continue;
      }
      if (row.discount.accountId != null &&
          option.accountId == row.discount.accountId) {
        return option;
      }
      if (option.title == row.discount.title) {
        return option;
      }
    }

    return row.discount.isHeader ? null : row.discount;
  }

  Widget _buildIncomeAccountDropdownRow(
    _IncomeAccountOption option,
    bool isSelected,
    bool isHovered,
  ) {
    if (option.isHeader) {
      return Container(
        height: 34,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.fromLTRB(14 + (option.level * 14), 10, 12, 6),
        color: Colors.white,
        child: Text(
          option.title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }

    final bgColor = isHovered
        ? AppTheme.infoBlue
        : (isSelected ? AppTheme.bgDisabled : Colors.white);
    final textColor = isHovered ? Colors.white : AppTheme.textPrimary;
    final tickColor = isHovered ? Colors.white : AppTheme.textSecondary;

    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: EdgeInsets.fromLTRB(14 + (option.level * 14), 9, 12, 9),
      color: bgColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              option.title,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: textColor,
                height: 1.25,
              ),
            ),
          ),
          if (isSelected) Icon(Icons.check, size: 14, color: tickColor),
        ],
      ),
    );
  }

  Widget _buildDiscountAccountDropdownRow(
    _DiscountAccountOption option,
    bool isSelected,
    bool isHovered,
  ) {
    if (option.isHeader) {
      return Container(
        height: 34,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.fromLTRB(14 + (option.level * 14), 10, 12, 6),
        color: Colors.white,
        child: Text(
          option.title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }

    final bgColor = isHovered
        ? AppTheme.infoBlue
        : (isSelected ? AppTheme.bgDisabled : Colors.white);
    final textColor = isHovered ? Colors.white : AppTheme.textPrimary;
    final tickColor = isHovered ? Colors.white : AppTheme.textSecondary;

    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: EdgeInsets.fromLTRB(14 + (option.level * 14), 9, 12, 9),
      color: bgColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              option.title,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: textColor,
                height: 1.2,
              ),
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 1),
              child: Icon(LucideIcons.check, size: 13, color: tickColor),
            ),
        ],
      ),
    );
  }

  List<_TaxOption> _taxOptionsForPlaceOfSupply(
    String placeOfSupply, {
    required List<TaxRate> taxGroups,
    required List<TaxRate> taxRates,
  }) {
    final isKerala = _isKeralaPlaceOfSupply(placeOfSupply);
    final dynamicOptions = (isKerala ? taxGroups : taxRates)
        .where((rate) {
          if (rate.taxName.trim().isEmpty) {
            return false;
          }
          if (isKerala) {
            return true;
          }

          final taxType = (rate.taxType ?? '').trim().toUpperCase();
          final taxName = rate.taxName.trim().toUpperCase();
          return taxType == 'IGST' || taxName.startsWith('IGST');
        })
        .map((rate) => _TaxOption(_formatTaxLabel(rate.taxName, rate.taxRate)))
        .toList();

    final rateOptions = dynamicOptions.isNotEmpty
        ? dynamicOptions
        : (isKerala ? _kFallbackGstTaxOptions : _kFallbackIgstTaxOptions);
    final headerTitle = isKerala ? 'Tax Group' : 'Tax';
    return [
      ..._kBaseTaxOptions,
      _TaxOption(headerTitle, isHeader: true),
      ...rateOptions,
    ];
  }

  _TaxOption _defaultTaxOptionFor(List<_TaxOption> options) {
    return options.firstWhere((option) => !option.isHeader);
  }

  _TaxOption _taxOptionFor(String value, List<_TaxOption> options) {
    return options.firstWhere(
      (option) => !option.isHeader && option.title == value,
      orElse: () => _defaultTaxOptionFor(options),
    );
  }

  String _normalizedTaxLabelForOptions(
    String currentValue,
    List<_TaxOption> options,
  ) {
    final exactMatch = options
        .where((option) => !option.isHeader)
        .firstWhere(
          (option) => option.title == currentValue,
          orElse: () => const _TaxOption(''),
        );
    if (exactMatch.title.isNotEmpty) {
      return exactMatch.title;
    }

    final targetRate = _extractTaxPercent(currentValue);
    if (targetRate > 0) {
      final rateMatch = options
          .where((option) => !option.isHeader)
          .firstWhere(
            (option) => _extractTaxPercent(option.title) == targetRate,
            orElse: () => const _TaxOption(''),
          );
      if (rateMatch.title.isNotEmpty) {
        return rateMatch.title;
      }
    }

    return _defaultTaxOptionFor(options).title;
  }

  void _syncRowTaxesForPlaceOfSupply(String placeOfSupply) {
    final itemsState = ref.read(itemsControllerProvider);
    final options = _taxOptionsForPlaceOfSupply(
      placeOfSupply,
      taxGroups: itemsState.taxGroups,
      taxRates: itemsState.taxRates,
    );

    for (final row in _items) {
      row.tax = _normalizedTaxLabelForOptions(row.tax, options);
    }
  }

  String _formatItemQuantity(double? value) {
    final number = value ?? 0;
    if (number % 1 == 0) {
      return number.toStringAsFixed(0);
    }
    return number.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _showNewCustomerDialog() {
    showDialog(
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
              final customerItem = _CustomerItem(
                id: newCustomer.id,
                name: newCustomer.displayName,
                code: newCustomer.customerNumber ?? '',
                subtitle: newCustomer.email ?? '',
                data: newCustomer,
              );
              setState(() {
                _customer = customerItem;
                _selectedBillingIndex = 0;
                _selectedShippingIndex = 0;
                _billingAddresses = _getDefaultAddressesFor(
                  customerItem,
                  'Billing',
                );
                _shippingAddresses = _getDefaultAddressesFor(
                  customerItem,
                  'Shipping',
                );
              });
              ref.refresh(salesCustomersProvider);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBorderlessItemField(
    TextEditingController controller, {
    TextAlign textAlign = TextAlign.left,
    TextInputType? keyboardType,
    void Function(String)? onSubmitted,
    double? width,
  }) {
    return _RecurringNumericHoverField(
      controller: controller,
      textAlign: textAlign,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      onSubmitted: onSubmitted,
      width: width,
    );
  }

  Future<void> _showNewTaxDialog() async {
    final taxTypes = <String>{
      'GST',
      'Tax Group',
      'Single Tax',
      'Compound Tax',
      ...ref
          .read(itemsControllerProvider)
          .taxRates
          .map((rate) => rate.taxType?.trim() ?? '')
          .where((value) => value.isNotEmpty),
    }.toList()..sort();

    final createdTax = await showDialog<TaxRate>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _RecurringNewTaxDialog(
        taxTypes: taxTypes,
        onSave: (taxName, taxRate, taxType) async {
          final service = LookupsApiService();
          final result = await service.createTaxGroup(
            taxName: taxName,
            taxRate: taxRate,
            taxType: taxType,
          );
          if (result == null) {
            throw Exception('Failed to create tax group');
          }
          return result;
        },
      ),
    );

    if (createdTax == null || !mounted) {
      return;
    }

    final itemsNotifier = ref.read(itemsControllerProvider.notifier);
    await itemsNotifier.loadLookupData(force: true);

    if (!mounted) {
      return;
    }

    ZerpaiToast.success(
      context,
      'Tax "${_formatTaxLabel(createdTax.taxName, createdTax.taxRate)}" saved successfully.',
    );
  }

  Widget _buildRecurringIconAction(
    IconData icon, {
    double size = 16,
    double diameter = 18,
    VoidCallback? onTap,
    Color? color,
  }) {
    final content = Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: color?.withValues(alpha: 0.3) ?? const Color(0xFFD3D3D3),
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size, color: color ?? const Color(0xFF808080)),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: content,
    );
  }

  Widget _buildSelectedItemInfo(_ItemRow row, Item? item) {
    final itemType = ((item?.type ?? '').trim()).toLowerCase();
    final isGoods = itemType != 'service';
    final codeLabel = isGoods ? 'HSN Code' : 'SAC Code';
    final codeValue = row.hsnCtrl.text.trim().isNotEmpty
        ? row.hsnCtrl.text.trim()
        : (item?.hsnCode?.trim() ?? '');
    final codeDisplay = codeValue.isEmpty ? 'Update' : codeValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _showItemPicker(row),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        row.nameCtrl.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(hoverColor: Colors.transparent),
                      child: PopupMenuButton<String>(
                        tooltip: 'Show more actions',
                        padding: EdgeInsets.zero,
                        offset: const Offset(0, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showEditItemDialog(row);
                          } else if (val == 'details') {
                            setState(() {
                              _selectedSidebarItem =
                                  _resolveRecurringInvoiceItem(row);
                              _selectedSidebarItemName = row.nameCtrl.text
                                  .trim();
                              _itemDetailsSidebarTabIndex = 0;
                              _showItemDetails = true;
                            });
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            padding: EdgeInsets.zero,
                            height: 40,
                            child: _RowThreeDotsMenuContent(
                              icon: LucideIcons.pencil,
                              label: 'Edit Item',
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'details',
                            padding: EdgeInsets.zero,
                            height: 40,
                            child: _RowThreeDotsMenuContent(
                              icon: LucideIcons.shoppingBag,
                              label: 'View Item Details',
                            ),
                          ),
                        ],
                        child: _buildRecurringIconAction(
                          LucideIcons.moreHorizontal,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                setState(() {
                  row.nameCtrl.clear();
                  row.descCtrl.clear();
                  row.quantityCtrl.text = '1.00';
                  row.rateCtrl.text = '0.00';
                  row.discountCtrl.text = '0';
                  row.hsnCtrl.text = '';
                  row.priceListId = null;
                  row.priceListName = null;
                  row.blocksGlobalPriceListInheritance = false;
                  row.tax = _defaultTaxOptionFor(
                    _taxOptionsForPlaceOfSupply(
                      _placeOfSupply,
                      taxGroups: ref.read(itemsControllerProvider).taxGroups,
                      taxRates: ref.read(itemsControllerProvider).taxRates,
                    ),
                  ).title;
                  row.incomeAccount = _kDefaultIncomeAccountOption;
                });
              },
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: const Icon(
                  LucideIcons.x,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: row.descCtrl,
            maxLines: 2,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: 'Add a description to your item',
              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isGoods
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF059669),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                isGoods ? 'GOODS' : 'SERVICE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              codeLabel,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(width: 6),
            Text(
              codeDisplay,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF2563EB),
                fontWeight: codeValue.isEmpty
                    ? FontWeight.w500
                    : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            CompositedTransformTarget(
              link: row.hsnLink,
              child: InkWell(
                onTap: () => _showHsnCodeDialog(
                  row,
                  codeLabel: codeLabel,
                  initialValue: codeValue,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    LucideIcons.pencil,
                    size: 12,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedQuantityInfo(_ItemRow row, Item? item) {
    if (!_showAvailableStockForSale) {
      return const SizedBox.shrink();
    }

    final availableForSale =
        (item?.stockOnHand ?? 0) - (item?.committedStock ?? 0);
    final rowWarehouseName = row.warehouseName.trim().isNotEmpty
        ? row.warehouseName.trim()
        : _selectedWarehouseName.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 10),
        Text(
          'Available for Sale: ${_formatItemQuantity(availableForSale)} pcs',
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 10, color: Color(0xFF4B5563)),
        ),
        const SizedBox(height: 10),
        WarehouseHoverPopover(
          warehouseName: rowWarehouseName,
          selectedView: 'Available for Sale',
          productId: item?.id,
          onViewChanged: (_) {},
          onWarehouseChanged: (newName) {
            final normalizedName = newName.trim();
            setState(() {
              row.warehouseName = normalizedName;
            });
          },
          child: Text(
            rowWarehouseName.toUpperCase(),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedRateInfo(_ItemRow row, Item? item) {
    final applicablePriceLists = _applicablePriceListsForRow(row);
    final notIncluded = _isRowItemMissingFromSelectedPriceList(row);
    final displayedPriceListLabel = row.priceListName?.trim().isNotEmpty == true
        ? row.priceListName!.trim()
        : row.blocksGlobalPriceListInheritance
        ? null
        : _priceList?.trim();
    final hasDisplayedPriceList =
        displayedPriceListLabel != null && displayedPriceListLabel.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_showRowPriceListSetting) ...[
          const SizedBox(height: 10),
          Theme(
            data: Theme.of(context).copyWith(
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              popupMenuTheme: PopupMenuThemeData(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: AppTheme.borderLight),
                ),
                elevation: 4,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (notIncluded) ...[
                  const ZTooltip(
                    message:
                        "This item has not been included in the selected price list. So, the item's default rate has been used.",
                    direction: ZTooltipDirection.bottom,
                    child: Icon(
                      LucideIcons.alertCircle,
                      size: 14,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        tooltip: '',
                        padding: EdgeInsets.zero,
                        offset: const Offset(0, 28),
                        onSelected: (val) {
                          final selected = _findPriceListById(val);
                          setState(() {
                            row.blocksGlobalPriceListInheritance = false;
                            _updateRowRate(
                              row,
                              appliedPriceListId: selected?.id,
                              updateRowSelection: true,
                            );
                          });
                        },
                        itemBuilder: (context) =>
                            applicablePriceLists.map((pl) {
                              final isSelected =
                                  _effectivePriceListIdForRow(row) == pl.id;
                              return PopupMenuItem<String>(
                                value: pl.id,
                                height: 32,
                                padding: EdgeInsets.zero,
                                child: _PriceListPopupRow(
                                  label: pl.name,
                                  isSelected: isSelected,
                                ),
                              );
                            }).toList(),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10, right: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ZTooltip(
                                message:
                                    displayedPriceListLabel ??
                                    'Apply Price List',
                                direction: ZTooltipDirection.bottom,
                                child: Text(
                                  displayedPriceListLabel ?? 'Apply Price List',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: !hasDisplayedPriceList
                                        ? const Color(0xFF9CA3AF)
                                        : AppTheme.textPrimary,
                                    fontWeight: !hasDisplayedPriceList
                                        ? FontWeight.w400
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (hasDisplayedPriceList) ...[
                        Container(
                          width: 1,
                          height: 20,
                          color: const Color(0xFFE5E7EB),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              row.blocksGlobalPriceListInheritance = true;
                              _updateRowRate(
                                row,
                                appliedPriceListId: null,
                                updateRowSelection: true,
                              );
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              LucideIcons.x,
                              size: 14,
                              color: Color(0xFFFF5A5F),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_showRecentTransactionSetting) ...[
          SizedBox(height: _showRowPriceListSetting ? 8 : 10),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedSidebarItem = item;
                _selectedSidebarItemName = row.nameCtrl.text.trim();
                _itemDetailsSidebarTabIndex = 2;
                _showItemDetails = true;
              });
            },
            child: const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeaderRow(int idx) {
    final row = _items[idx];
    return MouseRegion(
      key: ValueKey(row),
      onEnter: (_) => setState(() => row.isHovered = true),
      onExit: (_) => setState(() => row.isHovered = false),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: ReorderableDragStartListener(
                      index: idx,
                      child: const MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Icon(
                          LucideIcons.gripVertical,
                          size: 16,
                          color: Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: row.nameCtrl,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: 'Type a header...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Align(
                alignment: Alignment.topCenter,
                child: IgnorePointer(
                  ignoring: !row.isHovered,
                  child: AnimatedOpacity(
                    opacity: row.isHovered ? 1 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => _removeRowAt(idx),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int idx) {
    final row = _items[idx];
    final bool hasSelectedItem = row.nameCtrl.text.trim().isNotEmpty;
    final selectedItem = _resolveRecurringInvoiceItem(row);
    final itemsState = ref.watch(itemsControllerProvider);
    final taxOptions = _taxOptionsForPlaceOfSupply(
      _placeOfSupply,
      taxGroups: itemsState.taxGroups,
      taxRates: itemsState.taxRates,
    );

    return StatefulBuilder(
      key: ValueKey(row),
      builder: (context, setStateRow) {
        return MouseRegion(
          onEnter: (_) => setStateRow(() => row.isHovered = true),
          onExit: (_) => setStateRow(() => row.isHovered = false),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      left: const BorderSide(color: AppTheme.borderColor),
                      right: const BorderSide(color: AppTheme.borderColor),
                      bottom: const BorderSide(color: AppTheme.borderColor),
                    ),
                    borderRadius: idx == _items.length - 1
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          )
                        : BorderRadius.zero,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Main fields row with vertical grid lines
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 40,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: ReorderableDragStartListener(
                                    index: idx,
                                    child: const MouseRegion(
                                      cursor: SystemMouseCursors.grab,
                                      child: Icon(
                                        LucideIcons.gripVertical,
                                        size: 16,
                                        color: Color(0xFFD1D5DB),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // ITEM DETAILS (flex: 3)
                            Expanded(
                              flex: 14,
                              child: CompositedTransformTarget(
                                link: row.itemPickerLink,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Icon(
                                            LucideIcons.image,
                                            size: 20,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: hasSelectedItem
                                            ? _buildSelectedItemInfo(
                                                row,
                                                selectedItem,
                                              )
                                            : InkWell(
                                                onTap: () =>
                                                    _showItemPicker(row),
                                                child: SizedBox(
                                                  height: 34,
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          'Type or click to select an item.',
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                height: 1.15,
                                                                color: AppTheme
                                                                    .textMuted,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                              ),
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons
                                                            .keyboard_arrow_down,
                                                        size: 17,
                                                        color: Color(
                                                          0xFF6B7280,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(width: 1, color: const Color(0xFFE5E7EB)),

                            // QUANTITY (flex: 1)
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          height: 36,
                                          child: _buildBorderlessItemField(
                                            row.quantityCtrl,
                                            width: 132,
                                            textAlign: TextAlign.right,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                          ),
                                        ),
                                        if (hasSelectedItem)
                                          _buildSelectedQuantityInfo(
                                            row,
                                            selectedItem,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(width: 1, color: const Color(0xFFE5E7EB)),

                            // RATE (flex: 1)
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          height: 36,
                                          child: _buildBorderlessItemField(
                                            row.rateCtrl,
                                            width: 132,
                                            textAlign: TextAlign.right,
                                            keyboardType: TextInputType.text,
                                            onSubmitted: (val) {
                                              final evaluated =
                                                  _evaluateExpression(val);
                                              setState(() {
                                                row.rateCtrl.text = evaluated
                                                    .toStringAsFixed(2);
                                              });
                                            },
                                          ),
                                        ),
                                        if (hasSelectedItem)
                                          _buildSelectedRateInfo(
                                            row,
                                            selectedItem,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(width: 1, color: const Color(0xFFE5E7EB)),

                            // DISCOUNT (flex: 1)
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: SizedBox(
                                  height: 36,
                                  child: _RecurringDiscountHoverField(
                                    controller: row.discountCtrl,
                                    unit: row.discountUnit,
                                    onChanged: (_) => setState(() {}),
                                    onUnitSelected: (value) {
                                      setState(() => row.discountUnit = value);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Container(width: 1, color: const Color(0xFFE5E7EB)),

                            // TAX (flex: 1)
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: FormDropdown<_TaxOption>(
                                    height: 38,
                                    value: _taxOptionFor(row.tax, taxOptions),
                                    items: taxOptions,
                                    showSearch: true,
                                    showSettings: true,
                                    settingsLabel: 'New Tax',
                                    settingsIcon: LucideIcons.plusCircle,
                                    onSettingsTap: _showNewTaxDialog,
                                    menuWidth: 240,
                                    menuMaxHeight: 340,
                                    itemEstimatedHeight: 58,
                                    displayStringForValue: (option) =>
                                        option.title,
                                    searchStringForValue: (option) =>
                                        '${option.title} ${option.subtitle}',
                                    isItemEnabled: (option) => !option.isHeader,
                                    itemBuilder: (option, isSelected, isHovered) {
                                      if (option.isHeader) {
                                        return Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            10,
                                            8,
                                            10,
                                            4,
                                          ),
                                          child: Text(
                                            option.title,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        );
                                      }

                                      final active = isSelected || isHovered;
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 2,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: option.subtitle.isEmpty
                                              ? 9
                                              : 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: active
                                              ? (isHovered
                                                    ? const Color(0xFF3B82F6)
                                                    : const Color(0xFFF3F4F6))
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: RichText(
                                                maxLines:
                                                    option.subtitle.isEmpty
                                                    ? 1
                                                    : 4,
                                                overflow: TextOverflow.ellipsis,
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: option.title,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        height: 1.15,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: active
                                                            ? (isHovered
                                                                  ? Colors.white
                                                                  : AppTheme
                                                                        .textPrimary)
                                                            : AppTheme
                                                                  .textPrimary,
                                                      ),
                                                    ),
                                                    if (option
                                                        .subtitle
                                                        .isNotEmpty)
                                                      TextSpan(
                                                        text:
                                                            '\n${option.subtitle}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          height: 1.15,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: active
                                                              ? (isHovered
                                                                    ? Colors
                                                                          .white
                                                                    : AppTheme
                                                                          .textSecondary)
                                                              : AppTheme
                                                                    .textSecondary,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                LucideIcons.check,
                                                size: 13,
                                                color: isHovered
                                                    ? Colors.white
                                                    : const Color(0xFF6B7280),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                    onChanged: (v) {
                                      if (v != null && !v.isHeader) {
                                        setState(() => row.tax = v.title);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Container(width: 1, color: const Color(0xFFE5E7EB)),

                            // AMOUNT (flex: 1)
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: Text(
                                    '₹${row.amountBeforeTax.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_hideAllAdditionalInfo && !row.hideAdditionalInfo)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 5,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF7F8FB),
                            border: Border(
                              top: BorderSide(color: Color(0xFFEAECEF)),
                            ),
                          ),
                          child: _buildInlineItemMeta(row),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: 60,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: IgnorePointer(
                      ignoring: !(row.isHovered || row.isMenuOpen),
                      child: AnimatedOpacity(
                        opacity: row.isHovered || row.isMenuOpen ? 1 : 0,
                        duration: const Duration(milliseconds: 120),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(hoverColor: Colors.transparent),
                              child: PopupMenuButton<String>(
                                tooltip: 'Show more actions',
                                padding: EdgeInsets.zero,
                                offset: const Offset(0, 30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onOpened: () =>
                                    setStateRow(() => row.isMenuOpen = true),
                                onCanceled: () =>
                                    setStateRow(() => row.isMenuOpen = false),
                                onSelected: (val) {
                                  setStateRow(() => row.isMenuOpen = false);
                                  if (val == 'edit') {
                                    _showEditItemDialog(row);
                                  } else if (val == 'details') {
                                    setState(() {
                                      _selectedSidebarItem =
                                          _resolveRecurringInvoiceItem(row);
                                      _selectedSidebarItemName = row
                                          .nameCtrl
                                          .text
                                          .trim();
                                      _itemDetailsSidebarTabIndex = 0;
                                      _showItemDetails = true;
                                    });
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    padding: EdgeInsets.zero,
                                    height: 40,
                                    child: _RowThreeDotsMenuContent(
                                      icon: LucideIcons.pencil,
                                      label: 'Edit Item',
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'details',
                                    padding: EdgeInsets.zero,
                                    height: 40,
                                    child: _RowThreeDotsMenuContent(
                                      icon: LucideIcons.shoppingBag,
                                      label: 'View Item Details',
                                    ),
                                  ),
                                ],
                                child: _buildRecurringIconAction(
                                  LucideIcons.moreHorizontal,
                                  size: 14,
                                ),
                              ),
                            ),
                            if (_items.length > 1) ...[
                              const SizedBox(width: 4),
                              _buildRecurringIconAction(
                                LucideIcons.x,
                                size: 10,
                                color: const Color(0xFFEF4444),
                                onTap: () => _removeRowAt(idx),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterDetailsSection() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Customer Notes
                  const Text(
                    'Customer Notes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 400,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: TextField(
                      controller: _customerNotesCtrl,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText:
                            'Enter any notes to be displayed in your transaction',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFBBBBBB),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Totals Calculations Card
            Container(
              width: 440,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF9),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row 1: Sub Total
                  _buildSubTotalRow(
                    leftWidget: const Text(
                      'Sub Total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    rightWidget: Text(
                      _subTotal.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Row 2: Shipping Charges
                  _buildSubTotalRow(
                    leftWidget: const Text(
                      'Shipping Charges',
                      style: TextStyle(fontSize: 12, color: AppTheme.textBody),
                    ),
                    middleWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 120,
                          child: _buildSubTotalInputField(_shippingChargesCtrl),
                        ),
                        const SizedBox(width: 6),
                        const ZTooltip(
                          message: 'Amount spent on shipping the goods.',
                          direction: ZTooltipDirection.bottom,
                          child: Icon(
                            LucideIcons.helpCircle,
                            size: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    rightWidget: Text(
                      _shippingCharges.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 20),

                  if (_appliedTaxSummaryLines.isNotEmpty) ...[
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Color(0xFFD3D9E3),
                            width: 1.5,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        children: [
                          for (
                            int index = 0;
                            index < _appliedTaxSummaryLines.length;
                            index++
                          ) ...[
                            _buildSubTotalRow(
                              leftWidget: Text(
                                _appliedTaxSummaryLines[index].label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textBody,
                                ),
                              ),
                              rightWidget: Text(
                                _appliedTaxSummaryLines[index].amount
                                    .toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            if (index != _appliedTaxSummaryLines.length - 1)
                              const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Row 5: TDS
                  _buildSubTotalRow(
                    leftWidget: const Text(
                      'TDS',
                      style: TextStyle(fontSize: 12, color: AppTheme.textBody),
                    ),
                    middleWidget: SizedBox(
                      width: 140,
                      child: FormDropdown<String>(
                        height: 28,
                        menuWidth: 240,
                        value: _selectedTdsId,
                        hint: 'Select a Tax',
                        items: _tdsList
                            .map((tds) => (tds['id'] ?? '').toString())
                            .where((id) => id.isNotEmpty)
                            .toList(),
                        displayStringForValue: (id) {
                          final match = _tdsList
                              .cast<Map<String, dynamic>?>()
                              .firstWhere(
                                (tds) => tds?['id']?.toString() == id,
                                orElse: () => null,
                              );
                          return (match?['tax_name'] ??
                                  match?['tds_name'] ??
                                  id)
                              .toString();
                        },
                        itemBuilder: (id, isSelected, isHovered) {
                          final match = _tdsList
                              .cast<Map<String, dynamic>?>()
                              .firstWhere(
                                (tds) => tds?['id']?.toString() == id,
                                orElse: () => null,
                              );
                          final name =
                              (match?['tax_name'] ?? match?['tds_name'] ?? id)
                                  .toString();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            color: isHovered
                                ? const Color(0xFF3B82F6)
                                : (isSelected
                                      ? const Color(0xFFEFF6FF)
                                      : Colors.transparent),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isHovered
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    size: 14,
                                    color: isHovered
                                        ? Colors.white
                                        : AppTheme.primaryBlue,
                                  ),
                              ],
                            ),
                          );
                        },
                        showSearch: true,
                        showSettings: true,
                        settingsLabel: 'Manage TDS',
                        settingsIcon: LucideIcons.settings,
                        onSettingsTap: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => ManageTdsTcsRatesDialog(
                              title: 'Manage TDS Rates',
                              isTcs: false,
                              items: const [],
                              sections: const [],
                              onSelect: (_) {},
                            ),
                          );
                        },
                        onChanged: (v) => setState(() => _selectedTdsId = v),
                      ),
                    ),
                    rightWidget: const Text(
                      '- 0.00',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Row 6: Adjustment
                  _buildSubTotalRow(
                    leftWidget: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 100,
                        height: 28,
                        child: CustomPaint(
                          painter: _DottedBorderPainter(
                            color: const Color(0xFFD3D9E3),
                            strokeWidth: 1.0,
                            dashLength: 4.0,
                            gapLength: 2.5,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.only(left: 10, right: 6),
                            alignment: Alignment.centerLeft,
                            child: TextField(
                              controller: _adjustmentLabelCtrl,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    middleWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 100,
                          child: _buildSubTotalInputField(_adjustmentCtrl),
                        ),
                        const SizedBox(width: 6),
                        const ZTooltip(
                          message:
                              'Add any other +ve or -ve charges that need to be applied to adjust the total amount of the transaction Eg. +10 or -10.',
                          direction: ZTooltipDirection.bottom,
                          child: Icon(
                            LucideIcons.helpCircle,
                            size: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    rightWidget: Text(
                      _adjustment.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Row 7: Round Off
                  _buildSubTotalRow(
                    leftWidget: const Text(
                      'Round Off',
                      style: TextStyle(fontSize: 12, color: AppTheme.textBody),
                    ),
                    rightWidget: Text(
                      _roundOff.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          '(Round off the total to the nearest whole number)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.pencil,
                        size: 11,
                        color: Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 20),

                  // Row 8: Total ( ₹ )
                  _buildSubTotalRow(
                    leftWidget: const Text(
                      'Total ( ₹ )',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    rightWidget: Text(
                      _grandTotal.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 16, 40, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Terms and conditions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 750,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: TextField(
              controller: _termsAndConditionsCtrl,
              maxLines: 5,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText:
                    'Enter the terms and conditions of your business to be displayed in your transaction',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text(
              'Want to get paid faster? ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Stack(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Text(
              'VISA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1A1F71),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontFamily: 'Inter',
            ),
            children: [
              TextSpan(
                text:
                    'Configure payment gateways and receive payments online. ',
              ),
              TextSpan(
                text: 'Set up Payment Gateway',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Email Communications',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC2410C),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            InkWell(
              onTap: () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => const AddContactPersonDialog(),
                );
                if (result != null && context.mounted) {
                  final name =
                      '${result['firstName'] ?? ''} ${result['lastName'] ?? ''}'
                          .trim();
                  ZerpaiToast.show(
                    context,
                    name.isNotEmpty
                        ? 'Contact Person $name added!'
                        : 'Contact Person added!',
                  );
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: CustomPaint(
                painter: _DottedBorderPainter(
                  color: const Color(0xFFD1D5DB), // light gray border
                  strokeWidth: 1.0,
                  dashLength: 4.0,
                  gapLength: 3.0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6), // blue fill
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.add, size: 10, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Add New',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF3B82F6), // blue text
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: Color(0xFFD97706),
            ),
            const SizedBox(width: 4),
            const Text(
              'No contact persons found.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFD97706),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text(
              'Preferences :  ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            InkWell(
              onTap: _openRecurringInvoicePreferencesDialog,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      _invoicePreference == 'drafts'
                          ? 'Create Invoices as Drafts'
                          : (_invoicePreference == 'send'
                                ? 'Create, Push, and Send Invoices'
                                : 'Create, Charge and Send Invoices'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.settings_outlined,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openRecurringInvoicePreferencesDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => RecurringInvoicePreferencesDialog(
        initialPreference: _invoicePreference,
        initialSendEmail: _sendPreferenceEmail,
      ),
    );
    if (result != null) {
      setState(() {
        _invoicePreference = result['preference'] as String;
        _sendPreferenceEmail = result['sendEmail'] as bool;
      });
    }
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          ZButton.primary(
            label: 'Save',
            onPressed: _isSaving ? null : _saveRecurringInvoice,
          ),
          const SizedBox(width: 12),
          ZButton.secondary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Text(
            "PDF Template: 'Spreadsheet Template'",
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {},
            child: const Text(
              'Change',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsDrawer() {
    if (_customer == null) return const SizedBox.shrink();
    return CustomerDetailsSidebar(
      customer:
          _customer!.data ??
          SalesCustomer(
            id: _customer!.id,
            displayName: _customer!.name,
            customerNumber: _customer!.code,
            companyName: _customer!.name,
          ),
      onClose: () => setState(() => _showCustomerDetails = false),
    );
  }

  Widget _buildSubTotalRow({
    required Widget leftWidget,
    Widget? middleWidget,
    Widget? rightWidget,
  }) {
    return Row(
      children: [
        Expanded(child: leftWidget),
        if (middleWidget != null) ...[
          SizedBox(
            width: 150,
            child: Align(alignment: Alignment.centerLeft, child: middleWidget),
          ),
          const SizedBox(width: 12),
        ],
        if (rightWidget != null)
          SizedBox(
            width: 80,
            child: Align(alignment: Alignment.centerRight, child: rightWidget),
          ),
      ],
    );
  }

  Widget _buildSubTotalInputField(TextEditingController controller) {
    return Focus(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return Container(
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isFocused
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFD3D9E3),
                width: isFocused ? 1.5 : 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => setState(() {}),
            ),
          );
        },
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? labelSuffix;

  const _FormRow({required this.label, required this.child, this.labelSuffix});

  @override
  Widget build(BuildContext context) {
    final hasAsterisk = label.endsWith('*');
    final cleanLabel = hasAsterisk
        ? label.substring(0, label.length - 1)
        : label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: Row(
              children: [
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: _kRecurringTextSize,
                        fontWeight: FontWeight.w500,
                        color: hasAsterisk
                            ? const Color(0xFFEF4444)
                            : AppTheme.textPrimary,
                      ),
                      children: [
                        TextSpan(text: cleanLabel),
                        if (hasAsterisk)
                          const TextSpan(
                            text: '*',
                            style: TextStyle(color: Color(0xFFEF4444)),
                          ),
                      ],
                    ),
                  ),
                ),
                if (labelSuffix != null) ...[
                  const SizedBox(width: 6),
                  labelSuffix!,
                ],
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Advanced Customer Search Dialog ──────────────────────────────────────────

class _AdvancedCustomerSearchDialog extends StatefulWidget {
  final List<_CustomerItem> customers;

  const _AdvancedCustomerSearchDialog({required this.customers});

  @override
  State<_AdvancedCustomerSearchDialog> createState() =>
      _AdvancedCustomerSearchDialogState();
}

class _AdvancedCustomerSearchDialogState
    extends State<_AdvancedCustomerSearchDialog> {
  String _searchCriteria = 'Customer Number';
  final _searchCtrl = TextEditingController();
  List<_CustomerItem> _filteredResults = [];

  final List<String> _criteriaList = [
    'Customer Number',
    'Display Name',
    'Company Name',
    'First Name',
    'Last Name',
    'Email',
    'Phone',
    'GSTIN',
  ];

  @override
  void initState() {
    super.initState();
    _filteredResults = List<_CustomerItem>.from(widget.customers);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredResults = List<_CustomerItem>.from(widget.customers);
        return;
      }
      _filteredResults = widget.customers.where((cust) {
        final customer = cust.data;
        String matchField = '';
        switch (_searchCriteria) {
          case 'Customer Number':
            matchField = cust.code;
            break;
          case 'Display Name':
            matchField = cust.name;
            break;
          case 'Company Name':
            matchField = customer?.companyName ?? cust.name;
            break;
          case 'First Name':
            matchField = customer?.firstName ?? '';
            break;
          case 'Last Name':
            matchField = customer?.lastName ?? '';
            break;
          case 'Email':
            matchField = cust.subtitle;
            break;
          case 'Phone':
            matchField = customer?.phone ?? customer?.mobilePhone ?? '';
            break;
          case 'GSTIN':
            matchField = customer?.gstin ?? '';
            break;
          default:
            matchField = cust.name;
        }
        return matchField.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.symmetric(vertical: 0),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox(
        width: 520,
        height: double.infinity,
        child: Column(
          children: [
            // Title Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Advanced Customer Search',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),

            // Search inputs bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Combined criteria dropdown and search text field
                  SizedBox(
                    width: 380,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 160,
                          child: FormDropdown<String>(
                            height: 32,
                            padding: const EdgeInsets.only(left: 6, right: 0),
                            value: _searchCriteria,
                            items: _criteriaList,
                            hint: 'Criteria',
                            showSearch: false,
                            fillColor: const Color(0xFFF3F4F6),
                            showRightBorder: false,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _searchCriteria = v);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: CustomTextField(
                            height: 32,
                            controller: _searchCtrl,
                            hintText: '',
                            showLeftBorder: false,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                            onSubmitted: (_) => _performSearch(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E), // Green
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 32),
                      fixedSize: const Size.fromHeight(32),
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                border: Border(
                  top: BorderSide(color: AppTheme.borderLight),
                  bottom: BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'EMAIL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'COMPANY NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'PHONE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Table results list
            Expanded(
              child: _filteredResults.isEmpty
                  ? const Center(
                      child: Text(
                        'No customers found',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredResults.length,
                      itemBuilder: (context, index) {
                        final cust = _filteredResults[index];
                        final customer = cust.data;
                        return InkWell(
                          onTap: () => Navigator.pop(context, cust.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppTheme.borderLight),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cust.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        cust.code,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    cust.subtitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    customer?.companyName ?? cust.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    customer?.phone ??
                                        customer?.mobilePhone ??
                                        '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Manage Salespersons Dialog ──────────────────────────────────────────────

class _ManageSalespersonsDialog extends StatefulWidget {
  final List<_SalespersonOption> salespersons;
  final Future<_SalespersonOption> Function(
    _SalespersonOption salesperson,
    bool isActive,
  )
  onToggleActive;
  final Future<void> Function(_SalespersonOption salesperson) onDelete;

  const _ManageSalespersonsDialog({
    required this.salespersons,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  State<_ManageSalespersonsDialog> createState() =>
      _ManageSalespersonsDialogState();
}

class _ManageSalespersonsDialogState extends State<_ManageSalespersonsDialog> {
  final _searchCtrl = TextEditingController();
  late List<_SalespersonOption> _salespersons;
  List<_SalespersonOption> _filteredResults = [];
  final Set<String> _selectedSalespersonIds = <String>{};
  final Set<String> _busySalespersonIds = <String>{};
  final Set<String> _hoveredSalespersonIds = <String>{};

  bool _sameSalespersonSnapshot(
    List<_SalespersonOption> left,
    List<_SalespersonOption> right,
  ) {
    if (identical(left, right)) {
      return true;
    }
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      final leftItem = left[index];
      final rightItem = right[index];
      if (leftItem.id != rightItem.id ||
          leftItem.name != rightItem.name ||
          leftItem.email != rightItem.email ||
          leftItem.isActive != rightItem.isActive) {
        return false;
      }
    }
    return true;
  }

  void _upsertSalesperson(_SalespersonOption salesperson) {
    final index = _salespersons.indexWhere((item) => item.id == salesperson.id);
    if (index == -1) {
      _salespersons.add(salesperson);
    } else {
      _salespersons[index] = salesperson;
    }
  }

  Widget _buildInactiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFA3A3A3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _salespersons = List<_SalespersonOption>.from(widget.salespersons);
    _refreshFilteredResults();
    _searchCtrl.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ManageSalespersonsDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameSalespersonSnapshot(widget.salespersons, _salespersons)) {
      return;
    }
    _salespersons = List<_SalespersonOption>.from(widget.salespersons);
    _refreshFilteredResults();
  }

  void _performSearch() {
    setState(_refreshFilteredResults);
  }

  void _toggleSelection(String salespersonId, bool selected) {
    setState(() {
      if (selected) {
        _selectedSalespersonIds.add(salespersonId);
      } else {
        _selectedSalespersonIds.remove(salespersonId);
      }
    });
  }

  void _refreshFilteredResults() {
    final query = _searchCtrl.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredResults = List<_SalespersonOption>.from(_salespersons);
      return;
    }
    _filteredResults = _salespersons.where((s) {
      final name = s.name.toLowerCase();
      final email = s.email.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  _SalespersonOption _resolveSalesperson(String id) {
    return _salespersons.firstWhere(
      (item) => item.id == id,
      orElse: () => _filteredResults.firstWhere((item) => item.id == id),
    );
  }

  Future<void> _handleToggleActive(_SalespersonOption salesperson) async {
    final previous = salesperson;
    final optimistic = salesperson.copyWith(isActive: !salesperson.isActive);
    setState(() => _busySalespersonIds.add(salesperson.id));
    setState(() {
      _upsertSalesperson(optimistic);
      _refreshFilteredResults();
    });
    try {
      final updated = await widget.onToggleActive(
        salesperson,
        !salesperson.isActive,
      );
      if (!mounted) return;
      setState(() {
        _upsertSalesperson(updated);
        _refreshFilteredResults();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _upsertSalesperson(previous);
        _refreshFilteredResults();
      });
      ZerpaiToast.error(context, 'Failed to update salesperson status: $e');
    } finally {
      if (mounted) {
        setState(() => _busySalespersonIds.remove(salesperson.id));
      }
    }
  }

  Future<void> _handleDelete(_SalespersonOption salesperson) async {
    setState(() => _busySalespersonIds.add(salesperson.id));
    try {
      await widget.onDelete(salesperson);
      if (!mounted) return;
      setState(() {
        _salespersons.removeWhere((item) => item.id == salesperson.id);
        _selectedSalespersonIds.remove(salesperson.id);
        _refreshFilteredResults();
      });
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to delete salesperson: $e');
    } finally {
      if (mounted) {
        setState(() => _busySalespersonIds.remove(salesperson.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: SizedBox(
        width: 760,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manage Salespersons',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: AppTheme.errorRed, // Red 'X' as in screenshot
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: CustomTextField(
                height: 32,
                controller: _searchCtrl,
                hintText: 'Search Salesperson',
              ),
            ),

            if (_selectedSalespersonIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Text(
                      '${_selectedSalespersonIds.length} selected',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        if (_selectedSalespersonIds.length < 2) {
                          ZerpaiToast.error(
                            context,
                            'Select at least two salespersons to merge.',
                          );
                          return;
                        }
                        ZerpaiToast.info(
                          context,
                          'Merge action is ready for the selected salespersons.',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.borderColor),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('Merge'),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      onSelected: (value) {
                        if (value == 'clear') {
                          setState(() => _selectedSalespersonIds.clear());
                          return;
                        }
                        ZerpaiToast.info(
                          context,
                          'More options for selected salespersons will be available here.',
                        );
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'clear',
                          padding: EdgeInsets.zero,
                          child: _RowThreeDotsMenuContent(
                            icon: LucideIcons.xCircle,
                            label: 'Clear Selection',
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'bulk_actions',
                          padding: EdgeInsets.zero,
                          child: _RowThreeDotsMenuContent(
                            icon: LucideIcons.moreHorizontal,
                            label: 'More Options',
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'More Options',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              LucideIcons.chevronDown,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Table Columns Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                border: Border(
                  top: BorderSide(color: AppTheme.borderLight),
                  bottom: BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 24), // Space for checkbox
                  Expanded(
                    flex: 4,
                    child: Text(
                      'SALESPERSON NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'EMAIL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // List of Salespersons
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: _filteredResults.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No salespersons found',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredResults.length,
                      itemBuilder: (context, index) {
                        final rowItem = _filteredResults[index];
                        final s = _resolveSalesperson(rowItem.id);
                        final isInactive = !s.isActive;
                        final isBusy = _busySalespersonIds.contains(s.id);
                        final isHovered = _hoveredSalespersonIds.contains(s.id);

                        return MouseRegion(
                          onEnter: (_) => setState(() {
                            _hoveredSalespersonIds.add(s.id);
                          }),
                          onExit: (_) => setState(() {
                            _hoveredSalespersonIds.remove(s.id);
                          }),
                          child: InkWell(
                            key: ValueKey('${s.id}-${s.isActive}'),
                            onTap: isInactive
                                ? null
                                : () => Navigator.pop(context, s.name),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isInactive
                                    ? const Color(0xFFF5F7FA)
                                    : Colors.white,
                                border: const Border(
                                  bottom: BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Checkbox(
                                      value: _selectedSalespersonIds.contains(
                                        s.id,
                                      ),
                                      onChanged: isBusy
                                          ? null
                                          : (val) {
                                              _toggleSelection(
                                                s.id,
                                                val ?? false,
                                              );
                                            },
                                      activeColor: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 4,
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            s.name,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: isInactive
                                                  ? AppTheme.textSecondary
                                                  : AppTheme.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isInactive) ...[
                                          const SizedBox(width: 8),
                                          _buildInactiveBadge(),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            s.email,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isInactive
                                                  ? AppTheme.textSecondary
                                                  : AppTheme.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isHovered || isInactive) ...[
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: AppTheme.borderColor,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              splashRadius: 16,
                                              onPressed: isBusy
                                                  ? null
                                                  : () {
                                                      ZerpaiToast.info(
                                                        context,
                                                        'Edit salesperson action will be available here.',
                                                      );
                                                    },
                                              icon: const Icon(
                                                LucideIcons.pencil,
                                                size: 14,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Theme(
                                            data: Theme.of(context).copyWith(
                                              hoverColor: Colors.transparent,
                                            ),
                                            child: PopupMenuButton<String>(
                                              tooltip: 'More Actions',
                                              color: Colors.white,
                                              surfaceTintColor: Colors.white,
                                              padding: EdgeInsets.zero,
                                              offset: const Offset(0, 28),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              onSelected: (value) {
                                                if (value == 'toggle_active') {
                                                  _handleToggleActive(s);
                                                  return;
                                                }
                                                _handleDelete(s);
                                              },
                                              itemBuilder: (context) => [
                                                PopupMenuItem<String>(
                                                  value: 'toggle_active',
                                                  padding: EdgeInsets.zero,
                                                  height: 40,
                                                  child:
                                                      _RowThreeDotsMenuContent(
                                                        icon: isInactive
                                                            ? LucideIcons
                                                                  .checkCircle
                                                            : LucideIcons.ban,
                                                        label: isInactive
                                                            ? 'Mark as Active'
                                                            : 'Mark as Inactive',
                                                      ),
                                                ),
                                                const PopupMenuItem<String>(
                                                  value: 'delete',
                                                  padding: EdgeInsets.zero,
                                                  height: 40,
                                                  child:
                                                      _RowThreeDotsMenuContent(
                                                        icon:
                                                            LucideIcons.trash2,
                                                        label: 'Delete',
                                                      ),
                                                ),
                                              ],
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(
                                                    color: AppTheme.borderColor,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Icon(
                                                  LucideIcons.moreVertical,
                                                  size: 14,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (isBusy) ...[
                                          const SizedBox(width: 8),
                                          const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowThreeDotsMenuContent extends StatefulWidget {
  final IconData icon;
  final String label;

  const _RowThreeDotsMenuContent({required this.icon, required this.label});

  @override
  State<_RowThreeDotsMenuContent> createState() =>
      _RowThreeDotsMenuContentState();
}

class _RowThreeDotsMenuContentState extends State<_RowThreeDotsMenuContent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF0088FF) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 16,
              color: _isHovered ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                color: _isHovered ? Colors.white : const Color(0xFF1F2937),
                fontWeight: _isHovered ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportingTagsPopover extends StatefulWidget {
  final _ItemRow row;
  final VoidCallback onSaved;

  const ReportingTagsPopover({
    super.key,
    required this.row,
    required this.onSaved,
  });

  @override
  State<ReportingTagsPopover> createState() => _ReportingTagsPopoverState();
}

class _ReportingTagsPopoverState extends State<ReportingTagsPopover> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;

  late String _tempAdgf;
  late String _tempShedule;
  late String _tempDemo;

  @override
  void initState() {
    super.initState();
    _tempAdgf = widget.row.adgfTag;
    _tempShedule = widget.row.sheduleTag;
    _tempDemo = widget.row.demoTag;
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _tempAdgf = widget.row.adgfTag;
    _tempShedule = widget.row.sheduleTag;
    _tempDemo = widget.row.demoTag;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final spaceBelow = screenHeight - position.dy - renderBox.size.height;
    final spaceAbove = position.dy;

    final bool showBelow = spaceBelow >= 240 || spaceBelow > spaceAbove;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            return Stack(
              children: [
                CompositedTransformFollower(
                  link: _layerLink,
                  targetAnchor: showBelow
                      ? Alignment.bottomCenter
                      : Alignment.topCenter,
                  followerAnchor: showBelow
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  offset: Offset(0, showBelow ? 6 : -6),
                  child: Material(
                    color: Colors.transparent,
                    child: TapRegion(
                      groupId: 'reporting_tags_popover',
                      onTapOutside: (event) => _closeOverlay(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showBelow)
                            CustomPaint(
                              size: const Size(14, 7),
                              painter: _ReportingTagsArrowPainter(
                                color: Colors.white,
                                borderColor: const Color(0xFFE5E7EB),
                                isUp: true,
                              ),
                            ),
                          Container(
                            width: 380,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(5),
                                      topRight: Radius.circular(5),
                                    ),
                                  ),
                                  child: const Text(
                                    'Reporting Tags',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE5E7EB),
                                ),

                                // Content Form Fields
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          // ADGF field
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'ADGF',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF374151),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                FormDropdown<String>(
                                                  height: 32,
                                                  value: _tempAdgf,
                                                  items: const [
                                                    'None',
                                                    'Option 1',
                                                    'Option 2',
                                                  ],
                                                  showSearch: false,
                                                  menuWidth: 166,
                                                  onChanged: (v) {
                                                    if (v != null) {
                                                      setOverlayState(() {
                                                        _tempAdgf = v;
                                                      });
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // shedule field
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'shedule',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF374151),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                FormDropdown<String>(
                                                  height: 32,
                                                  value: _tempShedule,
                                                  items: const [
                                                    'None',
                                                    'Daily',
                                                    'Weekly',
                                                    'Monthly',
                                                  ],
                                                  showSearch: false,
                                                  menuWidth: 166,
                                                  onChanged: (v) {
                                                    if (v != null) {
                                                      setOverlayState(() {
                                                        _tempShedule = v;
                                                      });
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // demo adavced reporting tag field
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'demo adavced reporting tag',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF374151),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          FormDropdown<String>(
                                            height: 32,
                                            value: _tempDemo,
                                            items: const [
                                              'None',
                                              'Tag Alpha',
                                              'Tag Beta',
                                            ],
                                            showSearch: false,
                                            menuWidth: 348,
                                            onChanged: (v) {
                                              if (v != null) {
                                                setOverlayState(() {
                                                  _tempDemo = v;
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE5E7EB),
                                ),

                                // Footer
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          widget.row.adgfTag = _tempAdgf;
                                          widget.row.sheduleTag = _tempShedule;
                                          widget.row.demoTag = _tempDemo;

                                          // Update summary text
                                          final List<String> activeTags = [];
                                          if (_tempAdgf != 'None')
                                            activeTags.add('ADGF: $_tempAdgf');
                                          if (_tempShedule != 'None')
                                            activeTags.add(
                                              'shedule: $_tempShedule',
                                            );
                                          if (_tempDemo != 'None')
                                            activeTags.add('demo: $_tempDemo');

                                          if (activeTags.isEmpty) {
                                            widget.row.reportingTag =
                                                'Reporting Tags';
                                          } else {
                                            widget.row.reportingTag = activeTags
                                                .join(', ');
                                          }

                                          widget.onSaved();
                                          _closeOverlay();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF10B981,
                                          ), // Green button matching screenshot
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          minimumSize: const Size(64, 30),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Save',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: _closeOverlay,
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFF3F4F6,
                                          ), // Light grey matching Cancel button
                                          foregroundColor: const Color(
                                            0xFF374151,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFE5E7EB),
                                          ),
                                          minimumSize: const Size(64, 30),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: 12,
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
                          if (!showBelow)
                            CustomPaint(
                              size: const Size(14, 7),
                              painter: _ReportingTagsArrowPainter(
                                color: Colors.white,
                                borderColor: const Color(0xFFE5E7EB),
                                isUp: false,
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
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeOverlay({bool shouldSetState = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (shouldSetState && mounted) {
      setState(() => _isOpen = false);
    }
  }

  @override
  void deactivate() {
    _closeOverlay(shouldSetState: false);
    super.deactivate();
  }

  @override
  void dispose() {
    _closeOverlay(shouldSetState: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _showOverlay,
        hoverColor: Colors.transparent,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: Colors.transparent,
          child: Row(
            children: [
              const Icon(LucideIcons.tag, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.row.reportingTag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 16,
                color: _isOpen
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportingTagsArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool isUp;
  _ReportingTagsArrowPainter({
    required this.color,
    required this.borderColor,
    required this.isUp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    if (isUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width / 2, 0);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    final mergePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (isUp) {
      canvas.drawLine(
        Offset(1, size.height),
        Offset(size.width - 1, size.height),
        mergePaint,
      );
    } else {
      canvas.drawLine(
        const Offset(1, 0),
        Offset(size.width - 1, 0),
        mergePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReportingTagsArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isUp != isUp;
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DottedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashLength = 4.0,
    this.gapLength = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(4),
        ),
      );

    final dashedPath = _dashPath(path, dashLength, gapLength);
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path source, double dashLength, double gapLength) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashLength : gapLength;
        if (draw) {
          dest.addPath(
            metric.extractPath(
              distance,
              math.min(distance + len, metric.length),
            ),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}

class _ConfigureTaxPreferencesDialog extends StatefulWidget {
  final String initialTreatment;
  final List<String> treatments;

  const _ConfigureTaxPreferencesDialog({
    required this.initialTreatment,
    required this.treatments,
  });

  @override
  State<_ConfigureTaxPreferencesDialog> createState() =>
      _ConfigureTaxPreferencesDialogState();
}

class _RecurringNewTaxDialog extends StatefulWidget {
  final List<String> taxTypes;
  final Future<TaxRate> Function(
    String taxName,
    double taxRate,
    String? taxType,
  )
  onSave;

  const _RecurringNewTaxDialog({required this.taxTypes, required this.onSave});

  @override
  State<_RecurringNewTaxDialog> createState() => _RecurringNewTaxDialogState();
}

class _RecurringNewTaxDialogState extends State<_RecurringNewTaxDialog> {
  final TextEditingController _taxNameCtrl = TextEditingController();
  final TextEditingController _rateCtrl = TextEditingController();
  String? _selectedTaxType;
  bool _isSaving = false;

  @override
  void dispose() {
    _taxNameCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF4A88E8)),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF374151),
        ),
        children: [
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: '*',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
        ],
      ),
    );
  }

  Future<void> _saveTaxGroup() async {
    final taxName = _taxNameCtrl.text.trim();
    final rateText = _rateCtrl.text.trim();
    final parsedRate = double.tryParse(rateText);

    if (taxName.isEmpty) {
      ZerpaiToast.error(context, 'Tax Name is required.');
      return;
    }

    if (rateText.isEmpty) {
      ZerpaiToast.error(context, 'Rate (%) is required.');
      return;
    }

    if (parsedRate == null || parsedRate < 0) {
      ZerpaiToast.error(context, 'Enter a valid tax rate.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final taxGroup = await widget.onSave(
        taxName,
        parsedRate,
        _selectedTaxType,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(taxGroup);
    } on DioException catch (error) {
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response?.data['message']?.toString() ??
                'Failed to save tax.')
          : (error.message ?? 'Failed to save tax.');
      if (!mounted) {
        return;
      }
      ZerpaiToast.error(context, message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ZerpaiToast.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 740),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      const Text(
                        'New Tax',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 210,
                            child: _label('Tax Name', required: true),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _taxNameCtrl,
                              decoration: _inputDecoration(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 210,
                            child: _label('Rate (%)', required: true),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _rateCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _inputDecoration(
                                suffixIcon: Container(
                                  width: 32,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: Color(0xFFD1D5DB),
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    '%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: 210, child: _label('Tax Type')),
                          Expanded(
                            child: FormDropdown<String>(
                              value: _selectedTaxType,
                              items: widget.taxTypes,
                              hint: 'Select a Tax Type.',
                              onChanged: (value) {
                                setState(() => _selectedTaxType = value);
                              },
                              fillColor: Colors.white,
                              height: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveTaxGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          _isSaving ? 'Saving...' : 'Save',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4B5563),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
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
        ),
      ),
    );
  }
}

class _ConfigureTaxPreferencesDialogState
    extends State<_ConfigureTaxPreferencesDialog> {
  late String _selectedTreatment;
  bool _makePermanent = false;

  final Map<String, String> _descriptions = {
    'Registered Business - Regular': 'Business that is registered under GST',
    'Registered Business - Composition':
        'Business that is registered under the Composition Scheme in GST',
    'Unregistered Business': 'Business that has not been registered under GST',
    'Consumer': 'A customer who is a regular consumer',
    'Overseas':
        'Persons with whom you do import or export of supplies outside India',
    'Special Economic Zone':
        'Business (Unit) that is located in a Special Economic Zone (SEZ) or a SEZ Developer',
    'government, governmental agencies or local authorities': '',
    'SEZ Developer':
        'A person/organisation who owns at least 26% of the equity in creating business units in a Special Economic Zone (SEZ)',
    'Input Service Distributor':
        'Input Service Distributor (ISD) is an office that receives tax invoices for services used by the company in different states under the same PAN.',
  };

  @override
  void initState() {
    super.initState();
    _selectedTreatment = widget.initialTreatment;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Configure Tax Preferences',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GST Treatment',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FormDropdown<String>(
                      height: 36,
                      value: _selectedTreatment,
                      items: widget.treatments,
                      itemEstimatedHeight: 64,
                      itemBuilder: (item, isSelected, isHovered) {
                        final desc = _descriptions[item] ?? '';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: isHovered
                              ? const Color(0xFF3B82F6)
                              : (isSelected
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.transparent),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                        color: isHovered
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        desc,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isHovered
                                              ? Colors.white.withValues(
                                                  alpha: 0.8,
                                                )
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: isHovered
                                      ? Colors.white
                                      : const Color(0xFF3B82F6),
                                ),
                            ],
                          ),
                        );
                      },
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _selectedTreatment = v;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Make it permanent?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _makePermanent,
                          activeColor: AppTheme.primaryBlue,
                          onChanged: (v) {
                            setState(() {
                              _makePermanent = v ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Use these settings for all future transactions of this customer.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'gstTreatment': _selectedTreatment,
                        'makePermanent': _makePermanent,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFE5E7EB),
                      foregroundColor: AppTheme.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
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
  }
}

class _AccountOption {
  final String title;
  final bool isHeader;
  final bool isSubItem;
  const _AccountOption(
    this.title, {
    this.isHeader = false,
    this.isSubItem = false,
  });
}

const _kSalesAccountOptions = [
  _AccountOption('Output Payable', isHeader: true),
  _AccountOption('• Output CGST', isSubItem: true),
  _AccountOption('• Output IGST', isSubItem: true),
  _AccountOption('• Output SGST', isSubItem: true),
  _AccountOption('[ Payroll-022 ] Payroll Tax Payable'),
  _AccountOption('RCM Output CGST 9%'),
  _AccountOption('RCM Output SGST 9%'),
];

class _EditItemDialog extends StatefulWidget {
  final _ItemRow row;

  const _EditItemDialog({required this.row});

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  String _type = 'Goods';
  late TextEditingController _nameCtrl;
  final _skuCtrl = TextEditingController();
  String _unit = 'pcs';
  final _hsnCtrl = TextEditingController(text: '30049084');
  String _taxPreference = 'Taxable';

  bool _sellable = true;
  late TextEditingController _sellingPriceCtrl;
  late _AccountOption _salesAccount;
  late TextEditingController _salesDescCtrl;

  bool _purchasable = true;
  final _costPriceCtrl = TextEditingController(text: '100');
  String _purchaseAccount = 'Cost of Goods Sold';
  final _purchaseDescCtrl = TextEditingController(
    text: 'purchase description demo txt',
  );
  String _preferredVendor = 'None';

  late String _intraTax;
  late String _interTax;

  bool _trackInventory = true;
  String _invAccount = 'Inventory Asset';
  String _invValuation = 'FIFO (First In, First Out)';
  final _reorderPointCtrl = TextEditingController();

  late String _adgf;
  late String _shedule;
  late String _demo;

  @override
  void initState() {
    super.initState();
    _salesAccount = _kSalesAccountOptions.firstWhere(
      (o) => o.title == '[ Payroll-022 ] Payroll Tax Payable',
    );
    _nameCtrl = TextEditingController(text: widget.row.nameCtrl.text);
    _sellingPriceCtrl = TextEditingController(text: widget.row.rateCtrl.text);
    _salesDescCtrl = TextEditingController(text: widget.row.descCtrl.text);
    _intraTax = widget.row.tax;
    _interTax = widget.row.tax.replaceAll('GST', 'IGST');
    _adgf = widget.row.adgfTag;
    _shedule = widget.row.sheduleTag;
    _demo = widget.row.demoTag;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _hsnCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _salesDescCtrl.dispose();
    _costPriceCtrl.dispose();
    _purchaseDescCtrl.dispose();
    _reorderPointCtrl.dispose();
    super.dispose();
  }

  Widget _buildFieldRow(
    String label,
    Widget child, {
    bool required = false,
    bool hasHelp = false,
    String? helpTooltip,
    bool hasUnderline = false,
  }) {
    final textStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: required ? Colors.red : AppTheme.textPrimary,
      fontFamily: 'Inter',
      decoration: hasUnderline ? TextDecoration.underline : null,
      decorationColor: const Color(0xFF94A3B8),
      decorationStyle: TextDecorationStyle.dashed,
    );

    Widget labelWidget = RichText(
      text: TextSpan(
        text: label,
        style: textStyle,
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ]
            : null,
      ),
    );

    if (hasUnderline && helpTooltip != null) {
      labelWidget = ZTooltip(message: helpTooltip, child: labelWidget);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Flexible(child: labelWidget),
                if (hasHelp && helpTooltip != null) ...[
                  const SizedBox(width: 4),
                  ZTooltip(
                    message: helpTooltip,
                    child: const Icon(
                      LucideIcons.helpCircle,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ] else if (hasHelp) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    LucideIcons.helpCircle,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(width: 300, child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 40),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 1050,
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Item',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Main Info side-by-side with Upload Box
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Main Fields
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _buildFieldRow(
                                'Type',
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: 'Goods',
                                      // ignore: deprecated_member_use
                                      groupValue: _type,
                                      activeColor: AppTheme.primaryBlue,
                                      // ignore: deprecated_member_use
                                      onChanged: (v) =>
                                          setState(() => _type = v!),
                                    ),
                                    const Text(
                                      'Goods',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(width: 16),
                                    Radio<String>(
                                      value: 'Service',
                                      // ignore: deprecated_member_use
                                      groupValue: _type,
                                      activeColor: AppTheme.primaryBlue,
                                      // ignore: deprecated_member_use
                                      onChanged: (v) =>
                                          setState(() => _type = v!),
                                    ),
                                    const Text(
                                      'Service',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                                hasHelp: true,
                                helpTooltip:
                                    'Select if this item is a physical good or a service. Remember that you cannot change the type if this item is included in a transaction.',
                              ),
                              _buildFieldRow(
                                'Name',
                                CustomTextField(
                                  controller: _nameCtrl,
                                  height: 32,
                                ),
                                required: true,
                              ),
                              _buildFieldRow(
                                'SKU',
                                CustomTextField(
                                  controller: _skuCtrl,
                                  height: 32,
                                ),
                                hasHelp: true,
                                helpTooltip:
                                    'The Stock Keeping Unit of the item',
                              ),
                              _buildFieldRow(
                                'Unit',
                                SizedBox(
                                  height: 32,
                                  child: FormDropdown<String>(
                                    value: _unit,
                                    items: const ['pcs', 'box', 'kg', 'm'],
                                    onChanged: (v) {
                                      if (v != null) setState(() => _unit = v);
                                    },
                                    allowClear: true,
                                  ),
                                ),
                                hasHelp: true,
                                helpTooltip:
                                    'The item will be measured in terms of this unit (e.g.: kg, dozen)',
                              ),
                              _buildFieldRow(
                                _type == 'Service' ? 'SAC' : 'HSN Code',
                                CustomTextField(
                                  controller: _hsnCtrl,
                                  height: 32,
                                ),
                              ),
                              _buildFieldRow(
                                'Tax Preference',
                                SizedBox(
                                  height: 32,
                                  child: FormDropdown<String>(
                                    value: _taxPreference,
                                    items: const ['Taxable', 'Tax Exempt'],
                                    onChanged: (v) {
                                      if (v != null)
                                        setState(() => _taxPreference = v);
                                    },
                                  ),
                                ),
                                required: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Right Column: Image Drag Box
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.borderColor,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.image,
                                  size: 40,
                                  color: AppTheme.textSecondary,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Drag image(s) here or',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Browse images',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    const SizedBox(height: 24),

                    // Section 2: Sales & Purchase Info stacked
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sales Information
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Sales Information',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Checkbox(
                                  value: _sellable,
                                  activeColor: AppTheme.primaryBlue,
                                  onChanged: (v) =>
                                      setState(() => _sellable = v ?? false),
                                ),
                                const Text(
                                  'Sellable',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildFieldRow(
                              'Selling Price',
                              CustomTextField(
                                controller: _sellingPriceCtrl,
                                height: 32,
                                prefixWidget: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'INR',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              required: true,
                              hasUnderline: true,
                            ),
                            _buildFieldRow(
                              'Account',
                              SizedBox(
                                height: 32,
                                child: FormDropdown<_AccountOption>(
                                  value: _salesAccount,
                                  items: _kSalesAccountOptions,
                                  showSearch: true,
                                  displayStringForValue: (option) =>
                                      option.title,
                                  searchStringForValue: (option) =>
                                      option.title,
                                  isItemEnabled: (option) => !option.isHeader,
                                  itemBuilder: (option, isSelected, isHovered) {
                                    if (option.isHeader) {
                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          10,
                                          8,
                                          10,
                                          4,
                                        ),
                                        child: Text(
                                          option.title,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      );
                                    }

                                    final active = isSelected || isHovered;
                                    return Container(
                                      height: 30,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      padding: EdgeInsets.only(
                                        left: option.isSubItem ? 20 : 10,
                                        right: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? const Color(0xFF3B82F6)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              option.title,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: active
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: active
                                                    ? Colors.white
                                                    : AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              LucideIcons.check,
                                              size: 13,
                                              color: active
                                                  ? Colors.white
                                                  : AppTheme.primaryBlue,
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                  onChanged: (v) {
                                    if (v != null)
                                      setState(() => _salesAccount = v);
                                  },
                                ),
                              ),
                              required: true,
                              hasUnderline: true,
                            ),
                            _buildFieldRow(
                              'Description',
                              TextField(
                                controller: _salesDescCtrl,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Purchase Information
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Purchase Information',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Checkbox(
                                  value: _purchasable,
                                  activeColor: AppTheme.primaryBlue,
                                  onChanged: (v) =>
                                      setState(() => _purchasable = v ?? false),
                                ),
                                const Text(
                                  'Purchasable',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildFieldRow(
                              'Cost Price',
                              CustomTextField(
                                controller: _costPriceCtrl,
                                height: 32,
                                prefixWidget: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'INR',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              required: true,
                              hasUnderline: true,
                            ),
                            _buildFieldRow(
                              'Account',
                              SizedBox(
                                height: 32,
                                child: FormDropdown<String>(
                                  value: _purchaseAccount,
                                  items: const [
                                    'Cost of Goods Sold',
                                    'Advertising Expense',
                                  ],
                                  onChanged: (v) {
                                    if (v != null)
                                      setState(() => _purchaseAccount = v);
                                  },
                                ),
                              ),
                              required: true,
                              hasUnderline: true,
                            ),
                            _buildFieldRow(
                              'Description',
                              TextField(
                                controller: _purchaseDescCtrl,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(8),
                                ),
                              ),
                            ),
                            _buildFieldRow(
                              'Preferred Vendor',
                              SizedBox(
                                height: 32,
                                child: FormDropdown<String>(
                                  value: _preferredVendor,
                                  items: const ['None', 'Vendor A', 'Vendor B'],
                                  onChanged: (v) {
                                    if (v != null)
                                      setState(() => _preferredVendor = v);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    const SizedBox(height: 24),

                    // Section 3: Default Tax Rates & Inventory stacked
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Default Tax Rates
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Default Tax Rates',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFieldRow(
                              'Intra State Tax Rate',
                              SizedBox(
                                height: 32,
                                child: FormDropdown<String>(
                                  value: _intraTax,
                                  items: const [
                                    'GST0 [0%]',
                                    'GST5 [5%]',
                                    'GST12 [12%]',
                                    'GST18 [18%]',
                                  ],
                                  onChanged: (v) {
                                    if (v != null)
                                      setState(() => _intraTax = v);
                                  },
                                ),
                              ),
                            ),
                            _buildFieldRow(
                              'Inter State Tax Rate',
                              SizedBox(
                                height: 32,
                                child: FormDropdown<String>(
                                  value: _interTax,
                                  items: const [
                                    'IGST0 [0%]',
                                    'IGST5 [5%]',
                                    'IGST12 [12%]',
                                    'IGST18 [18%]',
                                  ],
                                  onChanged: (v) {
                                    if (v != null)
                                      setState(() => _interTax = v);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: const Text(
                                'NOTE: You have changed the tax rate manually. Any changes you make in your organisation\'s Default Tax Preferences will not be applied to this item.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF92400E),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Track Inventory
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _trackInventory,
                                  activeColor: AppTheme.primaryBlue,
                                  onChanged: (v) => setState(
                                    () => _trackInventory = v ?? false,
                                  ),
                                ),
                                const Text(
                                  'Track Inventory for this item',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  LucideIcons.helpCircle,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.only(left: 12),
                              child: Text(
                                'You cannot enable/disable inventory tracking once you\'ve created transactions for this item',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: const Text(
                                'Note: You can configure the opening stock and stock tracking for this item under the Items module',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF92400E),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFieldRow(
                              'Inventory Account',
                              SizedBox(
                                height: 32,
                                child: FormDropdown<String>(
                                  value: _invAccount,
                                  items: const ['Inventory Asset'],
                                  onChanged: (v) {
                                    if (v != null)
                                      setState(() => _invAccount = v);
                                  },
                                ),
                              ),
                              required: true,
                              hasUnderline: true,
                            ),
                            _buildFieldRow(
                              'Inventory Valuation Method',
                              SizedBox(
                                height: 32,
                                child: FormDropdown<String>(
                                  value: _invValuation,
                                  items: const ['FIFO (First In, First Out)'],
                                  onChanged: (v) {
                                    if (v != null)
                                      setState(() => _invValuation = v);
                                  },
                                ),
                              ),
                              required: true,
                              hasUnderline: true,
                              helpTooltip:
                                  'The method you select here will be used for inventory valuation',
                            ),
                            _buildFieldRow(
                              'Reorder Point',
                              CustomTextField(
                                controller: _reorderPointCtrl,
                                height: 32,
                              ),
                              hasUnderline: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    const SizedBox(height: 24),

                    // Section 4: Reporting Tags
                    const Text(
                      'Reporting Tags',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFieldRow(
                            'ADGF',
                            SizedBox(
                              height: 32,
                              child: FormDropdown<String>(
                                value: _adgf,
                                items: const ['None', 'Option 1', 'Option 2'],
                                onChanged: (v) {
                                  if (v != null) setState(() => _adgf = v);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: _buildFieldRow(
                            'shedule',
                            SizedBox(
                              height: 32,
                              child: FormDropdown<String>(
                                value: _shedule,
                                items: const ['None', 'Option 1', 'Option 2'],
                                onChanged: (v) {
                                  if (v != null) setState(() => _shedule = v);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFieldRow(
                            'demo adavced\nreporting tag',
                            SizedBox(
                              height: 32,
                              child: FormDropdown<String>(
                                value: _demo,
                                items: const ['None', 'Option 1', 'Option 2'],
                                onChanged: (v) {
                                  if (v != null) setState(() => _demo = v);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'name': _nameCtrl.text,
                        'rate': _sellingPriceCtrl.text,
                        'description': _salesDescCtrl.text,
                        'tax': _intraTax,
                        'adgf': _adgf,
                        'shedule': _shedule,
                        'demo': _demo,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Save & Update Line Item',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'name': _nameCtrl.text,
                        'rate': _sellingPriceCtrl.text,
                        'description': _salesDescCtrl.text,
                        'tax': _intraTax,
                        'adgf': _adgf,
                        'shedule': _shedule,
                        'demo': _demo,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFE5E7EB),
                      foregroundColor: AppTheme.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
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
  }
}

// ── Item Details Sidebar (local, screen-specific) ────────────────────────────
// Right-anchored drawer shown when an item row is inspected. Kept local because
// it is keyed by item name (not a full Item object) and is specific to this
// screen's flow. The shared items-module ItemDetailsSidebar is provider/Item
// driven and does not fit this usage.
class _ItemDetailsSidebar extends StatefulWidget {
  final Item? item;
  final String itemName;
  final String? customerName;
  final int initialTabIndex;
  final VoidCallback onClose;

  const _ItemDetailsSidebar({
    required this.item,
    required this.itemName,
    required this.onClose,
    this.customerName,
    this.initialTabIndex = 0,
  });

  @override
  State<_ItemDetailsSidebar> createState() => _ItemDetailsSidebarState();
}

Widget _recurringTableDivider() {
  return const VerticalDivider(
    width: 1,
    thickness: 1,
    color: AppTheme.borderColor,
  );
}

class _RecurringTableHeaderCell extends StatelessWidget {
  final String text;
  final bool right;

  const _RecurringTableHeaderCell(this.text, {this.right = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        letterSpacing: 0.4,
      ),
    );
  }
}

class _ItemDetailsSidebarState extends State<_ItemDetailsSidebar> {
  static const List<String> _tabs = [
    'ITEM DETAILS',
    'STOCK LOCATIONS',
    'TRANSACTIONS',
  ];
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex.clamp(0, _tabs.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(left: BorderSide(color: AppTheme.borderColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  const Text(
                    'Item Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFFEF4444),
                    ),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        color: Color(0xFF9CA3AF),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inventory Items',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.item?.productName ??
                                      (widget.itemName.trim().isEmpty
                                          ? 'Select Item'
                                          : widget.itemName),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.open_in_new,
                                size: 14,
                                color: Color(0xFF2563EB),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.item?.unitName ?? 'pcs'} • ${widget.item?.brandName ?? 'OTHER BRANDS'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (int i = 0; i < _tabs.length; i++) ...[
                    _buildTab(i),
                    if (i != _tabs.length - 1) const SizedBox(width: 24),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int i) {
    final bool isActive = i == _activeTab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = i),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: isActive
              ? const Border(
                  bottom: BorderSide(color: Color(0xFF2563EB), width: 2),
                )
              : null,
        ),
        child: Text(
          _tabs[i],
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_activeTab == 0) {
      return _buildItemDetailsTab();
    }
    if (_activeTab == 1) {
      return _buildStockLocationsTab();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Sales Orders',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
              const Spacer(),
              const Text(
                'Status: ',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const Text(
                'All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: true,
                  onChanged: (v) {},
                  activeColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Show only ${widget.customerName ?? 'customer'}\'s transactions',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
            ],
          ),
          const Expanded(
            child: Center(
              child: Text(
                'No Sales Orders recorded yet.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoBox(
                'Price',
                '₹${widget.item?.sellingPrice?.toStringAsFixed(2) ?? '0.00'}',
                Icons.sell_outlined,
              ),
              _infoBox(
                'Stock On Hand',
                _formatMetric(widget.item?.stockOnHand),
                Icons.inventory_2_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _detailRow('Item Name', widget.item?.productName ?? widget.itemName),
          _detailRow('Type', (widget.item?.type ?? 'goods').toUpperCase()),
          _detailRow('HSN / SAC', widget.item?.hsnCode ?? '-'),
          _detailRow('Unit', widget.item?.unitName ?? 'pcs'),
          _detailRow('Brand', widget.item?.brandName ?? 'OTHER BRANDS'),
          _detailRow(
            'Description',
            widget.item?.salesDescription?.trim().isNotEmpty == true
                ? widget.item!.salesDescription!.trim()
                : '-',
          ),
        ],
      ),
    );
  }

  Widget _buildStockLocationsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                flex: 3,
                child: Text(
                  'LOCATION NAME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'STOCK ON HAND',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'AVAILABLE FOR SALE',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB)),
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    widget.itemName.trim().isEmpty
                        ? 'Warehouse'
                        : 'ZABNIX PRIVATE LIMITED',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatMetric(widget.item?.stockOnHand),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatMetric(
                      (widget.item?.stockOnHand ?? 0) -
                          (widget.item?.committedStock ?? 0),
                    ),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String title, String value, IconData icon) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMetric(num? value) {
    final metric = (value ?? 0).toDouble();
    if (metric % 1 == 0) {
      return metric.toStringAsFixed(0);
    }
    return metric.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
