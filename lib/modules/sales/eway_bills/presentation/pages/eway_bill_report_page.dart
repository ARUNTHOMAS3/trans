import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:web/web.dart' as web;
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/org_scope_resolver.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

class EWayBillReportPage extends StatefulWidget {
  const EWayBillReportPage({super.key});

  @override
  State<EWayBillReportPage> createState() => _EWayBillReportPageState();
}

class _EWayBillReportPageState extends State<EWayBillReportPage> {
  static const double _baseActionsColumnWidth = 120;
  static const double _baseTotalColumnWidth = 110;
  static const Color _tableRowTextColor = Color(0xFF0F172A);
  static const List<String> _rowActionOptions = <String>[
    'Add e-Way Bill Details',
    'Exclude',
  ];
  static const double _tableContentWidth =
      28 +
      190 +
      190 +
      190 +
      190 +
      180 +
      _baseTotalColumnWidth +
      _baseActionsColumnWidth;
  static const double _tableHorizontalPadding = 28;
  static const List<String> _locationOptions = <String>[
    'ZABNIX PRIVATE LIMITED',
    'SAHAKAR TIRUR',
  ];
  static const List<String> _transactionPeriodOptions = <String>[
    'Today',
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
    'Yesterday',
    'Previous Week',
    'Previous Month',
    'Previous Quarter',
    'Previous Year',
    'Custom',
  ];
  static const List<String> _transactionTypeOptions = <String>[
    'Invoices',
    'Credit Notes',
    'Delivery Challans',
  ];
  static const List<String> _statusOptions = <String>[
    'Not Generated (1)',
    'Generated (0)',
    'Part A Generated (0)',
    'Canceled (0)',
    'Expired (0)',
    'Excluded (0)',
  ];
  static const List<_EWayBillRowData> _sampleRows = <_EWayBillRowData>[
    _EWayBillRowData(
      date: '20-06-2026',
      transactionNo: 'INV-000090',
      customerName: 'althaf m',
      customerGstin: '',
      expiryDate: '17-12-2026',
      total: '₹238.00',
    ),
  ];
  late String _selectedLocation;
  late String _selectedTransactionPeriod;
  late String _selectedTransactionType;
  late String _selectedStatus;
  final Set<String> _selectedTransactionNumbers = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedLocation = _locationOptions.first;
    _selectedTransactionPeriod = 'This Month';
    _selectedTransactionType = 'Invoices';
    _selectedStatus = _statusOptions.first;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selectedTransactionNumbers.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          if (hasSelection)
            const SingleActivator(LogicalKeyboardKey.escape): _clearSelection,
        },
        child: Focus(
          autofocus: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!hasSelection) _buildPageHeader(),
                      hasSelection ? _buildSelectionBar() : _buildFilterBar(),
                      _buildTableShell(),
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

  void _clearSelection() {
    setState(_selectedTransactionNumbers.clear);
  }

  void _openCreatePage() {
    final String orgId = resolveOrgSystemId(context);
    context.go('/$orgId${AppRoutes.salesEWayBillsCreate}');
  }

  void _toggleRowSelection(String transactionNo, bool? isSelected) {
    setState(() {
      if (isSelected ?? false) {
        _selectedTransactionNumbers.add(transactionNo);
      } else {
        _selectedTransactionNumbers.remove(transactionNo);
      }
    });
  }

  void _toggleSelectAll(bool? isSelected) {
    setState(() {
      if (isSelected ?? false) {
        _selectedTransactionNumbers
          ..clear()
          ..addAll(
            _sampleRows.map((row) => row.transactionNo),
          );
      } else {
        _selectedTransactionNumbers.clear();
      }
    });
  }

  List<_EWayBillRowData> get _selectedRows =>
      _sampleRows
          .where(
            (row) => _selectedTransactionNumbers.contains(row.transactionNo),
          )
          .toList();

  void _exportSelectedAsJson() {
    if (_selectedRows.isEmpty) return;

    final jsonText = const JsonEncoder.withIndent(
      '  ',
    ).convert(_selectedRows.map((row) => row.toJson()).toList());

    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON export is available on web only.')),
      );
      return;
    }

    final anchor = web.HTMLAnchorElement()
      ..href =
          'data:application/json;charset=utf-8,${Uri.encodeComponent(jsonText)}'
      ..download =
          'e_way_bills_${DateTime.now().millisecondsSinceEpoch}.json'
      ..style.display = 'none';

    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported ${_selectedRows.length} e-Way Bill record(s).'),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Row(
        children: [
          Text(
            'e-Way Bills',
            style: AppTheme.pageTitle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.settings,
                    size: 15,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Change e-Way Bill Portal Settings',
                    style: AppTheme.linkText.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildPrimaryActionButton(),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildFilterItem(
              label: 'Location:',
              child: _buildLocationDropdown(),
            ),
            _buildFilterItem(
              label: 'Transaction Period:',
              child: _buildTransactionPeriodDropdown(),
            ),
            _buildFilterItem(
              label: 'Transaction Type:',
              child: _buildTransactionTypeDropdown(),
            ),
            _buildFilterItem(
              label: 'e-Way Bill Status:',
              child: _buildStatusDropdown(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: Color(0x050F172A),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSelectionActionButton(),
                const SizedBox(width: 10),
                _buildSelectionIconButton(),
              ],
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 16, color: const Color(0xFFE5E7EB)),
            const SizedBox(width: 16),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${_selectedTransactionNumbers.length}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Selected',
              style: AppTheme.bodyText.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: _clearSelection,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Esc',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.close,
                      size: 17,
                      color: AppTheme.errorRed,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionActionButton() {
    return SizedBox(
      width: 76,
      height: 32.22,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF3F4F6),
          foregroundColor: const Color(0xFF374151),
          side: const BorderSide(color: Color(0xFFD6DBE4), width: 1),
          elevation: 0,
          minimumSize: const Size(76, 32.22),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.5),
          ),
        ),
        child: const Text(
          'Exclude',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
            fontFamily: 'Inter',
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionIconButton() {
    return SizedBox(
      width: 42,
      height: 44,
      child: ZTooltip(
        message: 'Export as JSON',
        direction: ZTooltipDirection.top,
        child: OutlinedButton(
          onPressed: _exportSelectedAsJson,
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFF3F4F6),
            foregroundColor: const Color(0xFF374151),
            side: const BorderSide(color: Color(0xFFD6DBE4), width: 1),
            elevation: 0,
            padding: EdgeInsets.zero,
            minimumSize: const Size(42, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.5),
            ),
          ),
          child: const Icon(
            LucideIcons.upload,
            size: 16,
            color: Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterItem({
    required String label,
    required Widget child,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        child,
      ],
    );
  }

  Widget _buildLocationDropdown() {
    return SizedBox(
      width: 190,
      child: FormDropdown<String>(
        value: _selectedLocation,
        items: _locationOptions,
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedLocation = value);
        },
        height: 36,
        showSearch: false,
        showSettings: false,
        boldSelected: false,
        showArrowOnSelection: false,
        menuWidth: 190,
        menuMaxHeight: 80,
        maxVisibleItems: 2,
        itemHeight: 36,
        borderRadius: BorderRadius.circular(5),
        fillColor: const Color(0xFFF9FAFB),
        paintSelectionBackground: false,
        suffixWidget: const Icon(
          Icons.keyboard_arrow_down,
          size: 18,
          color: AppTheme.primaryBlueDark,
        ),
        textStyle: AppTheme.bodyText.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemBuilder: (location, isSelected, isHovered) {
          final bool isActive = isHovered;
          return Padding(
            padding: const EdgeInsets.fromLTRB(5, 3, 5, 3),
            child: Container(
              height: 31,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
                child: Text(
                  location,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppTheme.textBody,
                    fontFamily: 'Inter',
                  ),
                ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionPeriodDropdown() {
    return SizedBox(
      width: 116,
      child: FormDropdown<String>(
        value: _selectedTransactionPeriod,
        items: _transactionPeriodOptions,
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedTransactionPeriod = value);
        },
        height: 36,
        showSearch: false,
        showSettings: false,
        boldSelected: false,
        paintSelectionBackground: false,
        menuWidth: 154,
        menuMaxHeight: 392,
        maxVisibleItems: 8,
        itemHeight: 35,
        borderRadius: BorderRadius.circular(4),
        fillColor: const Color(0xFFF9FAFB),
        textStyle: AppTheme.bodyText.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        prefixWidget: const Icon(
          LucideIcons.calendar,
          size: 15,
          color: AppTheme.textPrimary,
        ),
        itemBuilder: (period, isSelected, isHovered) {
          final bool isActive = isHovered;
          return Padding(
            padding: const EdgeInsets.fromLTRB(5, 3, 5, 3),
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                period,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppTheme.textBody,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionTypeDropdown() {
    return SizedBox(
      width: 92,
      child: FormDropdown<String>(
        value: _selectedTransactionType,
        items: _transactionTypeOptions,
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedTransactionType = value);
        },
        height: 36,
        showSearch: false,
        showSettings: false,
        boldSelected: false,
        showArrowOnSelection: false,
        paintSelectionBackground: false,
        menuWidth: 188,
        menuMaxHeight: 116,
        maxVisibleItems: 3,
        itemHeight: 34,
        borderRadius: BorderRadius.circular(4),
        fillColor: const Color(0xFFF9FAFB),
        suffixWidget: const Icon(
          Icons.keyboard_arrow_down,
          size: 18,
          color: AppTheme.primaryBlueDark,
        ),
        textStyle: AppTheme.bodyText.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        itemBuilder: (type, isSelected, isHovered) {
          final bool isActive = isHovered;
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
            child: Container(
              height: 29,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                type,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppTheme.textBody,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return SizedBox(
      width: 148,
      child: FormDropdown<String>(
        value: _selectedStatus,
        items: _statusOptions,
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedStatus = value);
        },
        height: 36,
        showSearch: false,
        showSettings: false,
        boldSelected: false,
        showArrowOnSelection: false,
        paintSelectionBackground: false,
        menuWidth: 192,
        menuMaxHeight: 224,
        maxVisibleItems: 6,
        itemHeight: 35,
        borderRadius: BorderRadius.circular(4),
        fillColor: const Color(0xFFF9FAFB),
        suffixWidget: const Icon(
          Icons.keyboard_arrow_down,
          size: 18,
          color: AppTheme.primaryBlueDark,
        ),
        textStyle: AppTheme.bodyText.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        itemBuilder: (status, isSelected, isHovered) {
          final bool isActive = isHovered;
          return Padding(
            padding: const EdgeInsets.fromLTRB(5, 3, 5, 3),
            child: Container(
              height: 29,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                status,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppTheme.textBody,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableShell() {
    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double minTableWidth = _tableContentWidth + _tableHorizontalPadding;
          final double tableWidth = constraints.maxWidth > minTableWidth
              ? constraints.maxWidth
              : minTableWidth;
          final double totalColumnWidth = _baseTotalColumnWidth;
          final double actionsColumnWidth =
              _baseActionsColumnWidth + (tableWidth - minTableWidth);
          final bool allRowsSelected =
              _sampleRows.isNotEmpty &&
              _sampleRows.every(
                (row) => _selectedTransactionNumbers.contains(row.transactionNo),
              );

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  _buildTableHeader(
                    totalColumnWidth,
                    actionsColumnWidth,
                    allRowsSelected,
                  ),
                  Column(
                    children: [
                      for (var index = 0; index < _sampleRows.length; index++) ...[
                        _buildDataRow(
                          _sampleRows[index],
                          totalColumnWidth,
                          actionsColumnWidth,
                        ),
                        if (index != _sampleRows.length - 1)
                          const Divider(height: 1, color: AppTheme.borderLight),
                      ],
                      const SizedBox(height: 260),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDataRow(
    _EWayBillRowData row,
    double totalColumnWidth,
    double actionsColumnWidth,
  ) {
    final bool isSelected =
        _selectedTransactionNumbers.contains(row.transactionNo);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: isSelected ? const Color(0xFFF8FBFF) : Colors.white,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Checkbox(
              value: isSelected,
              onChanged: (value) =>
                  _toggleRowSelection(row.transactionNo, value),
              activeColor: AppTheme.primaryBlue,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              side: const BorderSide(color: AppTheme.borderMid),
            ),
          ),
          _buildDataCell(row.date, 190),
          _buildDataCell(
            row.transactionNo,
            190,
            isClickable: true,
            onTap: _openCreatePage,
          ),
          _buildDataCell(
            row.customerName,
            190,
            isClickable: true,
            onTap: _openCreatePage,
          ),
          _buildDataCell(row.customerGstin, 190),
          _buildDataCell(row.expiryDate, 180),
          _buildDataCell(
            row.total,
            totalColumnWidth,
            textAlign: TextAlign.left,
            fontWeight: FontWeight.w600,
          ),
          _buildActionsCell(actionsColumnWidth),
        ],
      ),
    );
  }

  Widget _buildDataCell(
    String value,
    double width, {
    TextAlign textAlign = TextAlign.left,
    FontWeight fontWeight = FontWeight.w500,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    final Widget text = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: AppTheme.bodyText.copyWith(
        fontSize: 12.5,
        fontWeight: fontWeight,
        color: isClickable ? AppTheme.primaryBlue : _tableRowTextColor,
      ),
    );

    return SizedBox(
      width: width,
      child: isClickable
          ? InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: text,
              ),
            )
          : text,
    );
  }

  Widget _buildTableHeader(
    double totalColumnWidth,
    double actionsColumnWidth,
    bool allRowsSelected,
  ) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: AppTheme.tableHeaderBg,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Checkbox(
              value: allRowsSelected,
              onChanged: _toggleSelectAll,
              activeColor: AppTheme.primaryBlue,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              side: const BorderSide(color: AppTheme.borderMid),
            ),
          ),
          _buildHeaderCell('DATE', 190, sortIcon: true),
          _buildHeaderCell('TRANSACTION#', 190),
          _buildHeaderCell('CUSTOMER NAME', 190),
          _buildHeaderCell('CUSTOMER GSTIN', 190),
          _buildHeaderCell('EXPIRY DATE', 180),
          _buildHeaderCell('TOTAL', totalColumnWidth),
          _buildHeaderCell(' ', actionsColumnWidth),
        ],
      ),
    );
  }

  Widget _buildActionsCell(double width) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: Alignment.centerLeft,
        child: PopupMenuButton<String>(
          tooltip: '',
          position: PopupMenuPosition.under,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 10,
          shadowColor: const Color(0x1F101828),
          offset: const Offset(0, 12),
          constraints: const BoxConstraints(minWidth: 152),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          itemBuilder: (context) => _rowActionOptions
              .map(
                (action) => PopupMenuItem<String>(
                  value: action,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: _EWayBillActionMenuItem(
                    label: action,
                  ),
                ),
              )
              .toList(),
          onSelected: (_) {},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Actions',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: _tableRowTextColor,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: _tableRowTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label, double width, {bool sortIcon = false}) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Text(
            label,
            style: AppTheme.tableHeader.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: AppTheme.textSecondary,
            ),
          ),
          if (sortIcon) ...[
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronsUpDown,
              size: 12,
              color: AppTheme.primaryBlue,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton() {
    return ElevatedButton(
      onPressed: _openCreatePage,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(LucideIcons.plus, size: 15, color: Colors.white),
          SizedBox(width: 5),
          Text(
            'New',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _EWayBillRowData {
  final String date;
  final String transactionNo;
  final String customerName;
  final String customerGstin;
  final String expiryDate;
  final String total;

  const _EWayBillRowData({
    required this.date,
    required this.transactionNo,
    required this.customerName,
    required this.customerGstin,
    required this.expiryDate,
    required this.total,
  });

  Map<String, String> toJson() => <String, String>{
    'date': date,
    'transactionNo': transactionNo,
    'customerName': customerName,
    'customerGstin': customerGstin,
    'expiryDate': expiryDate,
    'total': total,
  };
}

class _EWayBillActionMenuItem extends StatefulWidget {
  final String label;

  const _EWayBillActionMenuItem({
    required this.label,
  });

  @override
  State<_EWayBillActionMenuItem> createState() => _EWayBillActionMenuItemState();
}

class _EWayBillActionMenuItemState extends State<_EWayBillActionMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isActive = _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        height: 32,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF667085),
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
