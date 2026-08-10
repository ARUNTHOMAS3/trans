import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class ApAgingDetailsRow {
  final String label;
  final String date;
  final String dueDate;
  final String transactionNumber;
  final String type;
  final String status;
  final String vendorName;
  final String age;
  final String billAmount;
  final String balanceDue;
  final bool isGroup;

  const ApAgingDetailsRow._({
    required this.label,
    required this.date,
    required this.dueDate,
    required this.transactionNumber,
    required this.type,
    required this.status,
    required this.vendorName,
    required this.age,
    required this.billAmount,
    required this.balanceDue,
    required this.isGroup,
  });

  const ApAgingDetailsRow.group({
    required String label,
    required String billAmount,
    required String balanceDue,
  }) : this._(
         label: label,
         date: '',
         dueDate: '',
         transactionNumber: '',
         type: '',
         status: '',
         vendorName: '',
         age: '',
         billAmount: billAmount,
         balanceDue: balanceDue,
         isGroup: true,
       );

  const ApAgingDetailsRow.bill({
    required String date,
    required String dueDate,
    required String transactionNumber,
    required String type,
    required String status,
    required String vendorName,
    required String age,
    required String billAmount,
    required String balanceDue,
  }) : this._(
         label: '',
         date: date,
         dueDate: dueDate,
         transactionNumber: transactionNumber,
         type: type,
         status: status,
         vendorName: vendorName,
         age: age,
         billAmount: billAmount,
         balanceDue: balanceDue,
         isGroup: false,
       );
}

class ApAgingDetailsTable extends StatefulWidget {
  final List<ApAgingDetailsRow> rows;
  final int page;
  final int pageSize;
  final int totalCount;
  final ValueChanged<int> onPageChanged;
  final String groupBy;

  const ApAgingDetailsTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChanged,
    required this.groupBy,
  });

  @override
  State<ApAgingDetailsTable> createState() => _ApAgingDetailsTableState();
}

class _ApAgingDetailsTableState extends State<ApAgingDetailsTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  static const String _totalBillAmount = '\u20B974,931.05';
  static const String _totalBalanceDue = '\u20B974,931.05';

  bool get _isGrouped => widget.groupBy != 'None';

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1370
            ? 1370.0
            : constraints.maxWidth;

        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: tableWidth > constraints.maxWidth,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: ReportStickyHeaderScrollTable(
                header: _buildHeader(),
                emptyBody: const SizedBox.shrink(),
                children: [
                  SizedBox(
                    height: 405,
                    child: Scrollbar(
                      controller: _verticalController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: _verticalController,
                        itemCount: widget.rows.length + (_isGrouped ? 2 : 0) + 1,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: AppTheme.borderLight,
                        ),
                        itemBuilder: (context, index) {
                          if (_isGrouped && index == 0) {
                            return _buildAppliedGroupRow();
                          }
                          final currentIndex = _isGrouped ? 1 : 0;
                          if (_isGrouped && index == currentIndex) {
                            return _buildCurrentGroupRow();
                          }
                          final totalIndex = widget.rows.length + (_isGrouped ? 2 : 0);
                          if (index == totalIndex) {
                            return _buildTotalRow();
                          }

                          final rowIndex = index - (_isGrouped ? 2 : 0);
                          final row = widget.rows[rowIndex];
                          if (row.isGroup) return _buildGroupRow(row);
                          return _ApAgingDetailsDataRow(row: row);
                        },
                      ),
                    ),
                  ),
                  ReportPaginationFooter(
                    totalCount: widget.totalCount,
                    page: widget.page,
                    pageSize: widget.pageSize,
                    onPageChanged: widget.onPageChanged,
                  ),
                  const SizedBox(height: AppTheme.space28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space10,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.tableHeaderBg,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: _buildTableRow(
        date: Row(
          children: [
            Text('DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        dueDate: _headerText('DUE DATE'),
        transactionNumber: _headerText('TRANSACTION#'),
        type: _headerText('TYPE'),
        status: _headerText('STATUS'),
        vendorName: _headerText('VENDOR NAME'),
        age: _headerText('AGE'),
        billAmount: _headerText('BILL AMOUNT', alignRight: true),
        balanceDue: _headerText('BALANCE DUE', alignRight: true),
      ),
    );
  }

  Widget _headerText(String value, {bool alignRight = false}) {
    return Text(
      value,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: ReportTableTypography.header,
    );
  }

  Widget _buildGroupRow(ApAgingDetailsRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        date: Text(row.label, style: _groupStyle),
        dueDate: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
        type: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        age: const SizedBox.shrink(),
        billAmount: _totalText(row.billAmount),
        balanceDue: _totalText(row.balanceDue),
      ),
    );
  }

  Widget _buildTotalRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        date: Text('Total', style: _totalStyle),
        dueDate: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
        type: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        age: const SizedBox.shrink(),
        billAmount: _totalText(_totalBillAmount),
        balanceDue: _totalText(_totalBalanceDue),
      ),
    );
  }

  Widget _totalText(String value) {
    return Text(value, textAlign: TextAlign.right, style: _totalStyle);
  }

  TextStyle get _groupStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w700,
  );

  TextStyle get _totalStyle => AppTheme.bodyText.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 15,
  );

  String _groupDisplayValue() {
    switch (widget.groupBy) {
      case 'Vendor Name':
        return 'Vendor Name - Not mentioned';
      case 'Currency':
        return 'INR';
      default:
        return widget.groupBy;
    }
  }

  Widget _buildAppliedGroupRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        date: Text(_groupDisplayValue(), style: _groupStyle),
        dueDate: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
        type: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        age: const SizedBox.shrink(),
        billAmount: _totalText(_totalBillAmount),
        balanceDue: _totalText(_totalBalanceDue),
      ),
    );
  }

  Widget _buildCurrentGroupRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      color: AppTheme.backgroundColor,
      child: _buildTableRow(
        date: Text('Current', style: _groupStyle),
        dueDate: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
        type: const SizedBox.shrink(),
        status: const SizedBox.shrink(),
        vendorName: const SizedBox.shrink(),
        age: const SizedBox.shrink(),
        billAmount: _totalText(_totalBillAmount),
        balanceDue: _totalText(_totalBalanceDue),
      ),
    );
  }
}

class _ApAgingDetailsDataRow extends StatefulWidget {
  final ApAgingDetailsRow row;

  const _ApAgingDetailsDataRow({required this.row});

  @override
  State<_ApAgingDetailsDataRow> createState() => _ApAgingDetailsDataRowState();
}

class _ApAgingDetailsDataRowState extends State<_ApAgingDetailsDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space20,
          vertical: AppTheme.space12,
        ),
        color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
        child: _buildTableRow(
          date: Text(row.date, style: AppTheme.tableCell),
          dueDate: Text(row.dueDate, style: AppTheme.tableCell),
          transactionNumber: _linkText(row.transactionNumber),
          type: Text(row.type, style: AppTheme.tableCell),
          status: Text(
            row.status,
            style: AppTheme.tableCell.copyWith(color: _statusColor(row.status)),
          ),
          vendorName: _linkText(row.vendorName),
          age: Text(row.age, style: AppTheme.tableCell),
          billAmount: _amountText(row.billAmount),
          balanceDue: _amountText(row.balanceDue),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    if (status == 'Overdue') return AppTheme.warningOrange;
    return AppTheme.primaryBlue;
  }

  Widget _linkText(String value) {
    return Text(
      value,
      style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
    );
  }

  Widget _amountText(String value) {
    return Text(
      value,
      textAlign: TextAlign.right,
      style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
    );
  }
}

Widget _buildTableRow({
  required Widget date,
  required Widget dueDate,
  required Widget transactionNumber,
  required Widget type,
  required Widget status,
  required Widget vendorName,
  required Widget age,
  required Widget billAmount,
  required Widget balanceDue,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 2, child: date),
      Expanded(flex: 2, child: dueDate),
      Expanded(flex: 2, child: transactionNumber),
      Expanded(flex: 2, child: type),
      Expanded(flex: 2, child: status),
      Expanded(flex: 4, child: vendorName),
      Expanded(flex: 2, child: age),
      Expanded(flex: 2, child: billAmount),
      Expanded(flex: 2, child: balanceDue),
    ],
  );
}
