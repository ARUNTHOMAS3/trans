import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class SerialNumberDetailsRow {
  final String itemName;
  final String serialNumber;
  final String status;
  final String inwardTransactionDate;
  final String inwardTransaction;
  final String inwardTransactionNumber;
  final String outwardTransactionDate;
  final String outwardTransaction;
  final String outwardTransactionNumber;
  final String location;

  const SerialNumberDetailsRow({
    required this.itemName,
    required this.serialNumber,
    required this.status,
    required this.inwardTransactionDate,
    required this.inwardTransaction,
    required this.inwardTransactionNumber,
    required this.outwardTransactionDate,
    required this.outwardTransaction,
    required this.outwardTransactionNumber,
    required this.location,
  });

  factory SerialNumberDetailsRow.fromJson(Map<String, dynamic> json) {
    return SerialNumberDetailsRow(
      itemName: _stringValue(json['itemName']),
      serialNumber: _stringValue(json['serialNumber']),
      status: _stringValue(json['status']),
      inwardTransactionDate: _stringValue(json['inwardTransactionDate']),
      inwardTransaction: _stringValue(json['inwardTransaction']),
      inwardTransactionNumber: _stringValue(json['inwardTransactionNumber']),
      outwardTransactionDate: _stringValue(json['outwardTransactionDate']),
      outwardTransaction: _stringValue(json['outwardTransaction']),
      outwardTransactionNumber: _stringValue(json['outwardTransactionNumber']),
      location: _stringValue(json['location']),
    );
  }

  static String _stringValue(Object? value) {
    return value?.toString().trim() ?? '';
  }
}

class SerialNumberDetailsTable extends StatefulWidget {
  final List<SerialNumberDetailsRow> rows;
  final int page;
  final int pageSize;
  final int totalCount;
  final ValueChanged<int> onPageChanged;

  const SerialNumberDetailsTable({
    super.key,
    required this.rows,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChanged,
  });

  @override
  State<SerialNumberDetailsTable> createState() =>
      _SerialNumberDetailsTableState();
}

class _SerialNumberDetailsTableState extends State<SerialNumberDetailsTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1540,
          child: SizedBox(
            height: widget.rows.isEmpty ? 435 : 470,
            child: ReportStickyHeaderScrollTable(
              header: _buildHeader(),
              isEmpty: widget.rows.isEmpty,
              emptyBody: const ReportTableEmptyBody(
                minHeight: 345,
                message: 'There are no transactions during the selected date range.',
              ),
              children: [
                ...widget.rows.map((row) => _SerialNumberDetailsDataRow(row: row)),
                if (widget.rows.isNotEmpty) ...[
                  ReportPaginationFooter(
                    totalCount: widget.totalCount,
                    page: widget.page,
                    pageSize: widget.pageSize,
                    onPageChanged: widget.onPageChanged,
                  ),
                  const SizedBox(height: AppTheme.space28),
                ],
              ],
            ),
          ),
        ),
      ),
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
        itemName: Row(
          children: [
            Text('ITEM NAME', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
        serialNumber: _headerText('SERIAL NUMBER'),
        status: _headerText('STATUS'),
        inwardTransactionDate: _headerText('INWARD TRANSACTION DATE'),
        inwardTransaction: _headerText('INWARD TRANSACTION'),
        inwardTransactionNumber: _headerText('INWARD TRANSACTION#'),
        outwardTransactionDate: _headerText('OUTWARD TRANSACTION DATE'),
        outwardTransaction: _headerText('OUTWARD TRANSACTION'),
        outwardTransactionNumber: _headerText('OUTWARD TRANSACTION#'),
        location: _headerText('LOCATION'),
      ),
    );
  }

  Widget _headerText(String value) {
    return Text(
      value,
      overflow: TextOverflow.ellipsis,
      style: ReportTableTypography.header,
    );
  }
}

class _SerialNumberDetailsDataRow extends StatefulWidget {
  final SerialNumberDetailsRow row;

  const _SerialNumberDetailsDataRow({required this.row});

  @override
  State<_SerialNumberDetailsDataRow> createState() =>
      _SerialNumberDetailsDataRowState();
}

class _SerialNumberDetailsDataRowState
    extends State<_SerialNumberDetailsDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space20,
          vertical: AppTheme.space12,
        ),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
          border: const Border(
            bottom: BorderSide(color: AppTheme.borderLight),
          ),
        ),
        child: _buildTableRow(
          itemName: _linkText(widget.row.itemName),
          serialNumber: _linkText(widget.row.serialNumber),
          status: _bodyText(widget.row.status),
          inwardTransactionDate: _bodyText(widget.row.inwardTransactionDate),
          inwardTransaction: _bodyText(widget.row.inwardTransaction),
          inwardTransactionNumber: _linkText(widget.row.inwardTransactionNumber),
          outwardTransactionDate: _bodyText(widget.row.outwardTransactionDate),
          outwardTransaction: _bodyText(widget.row.outwardTransaction),
          outwardTransactionNumber: _linkText(widget.row.outwardTransactionNumber),
          location: _bodyText(widget.row.location),
        ),
      ),
    );
  }

  Widget _linkText(String value) {
    return Text(
      value,
      overflow: TextOverflow.ellipsis,
      style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
    );
  }

  Widget _bodyText(String value) {
    return Text(
      value,
      overflow: TextOverflow.ellipsis,
      style: AppTheme.tableCell,
    );
  }
}

Widget _buildTableRow({
  required Widget itemName,
  required Widget serialNumber,
  required Widget status,
  required Widget inwardTransactionDate,
  required Widget inwardTransaction,
  required Widget inwardTransactionNumber,
  required Widget outwardTransactionDate,
  required Widget outwardTransaction,
  required Widget outwardTransactionNumber,
  required Widget location,
}) {
  return Row(
    children: [
      Expanded(flex: 4, child: itemName),
      Expanded(flex: 4, child: serialNumber),
      Expanded(flex: 3, child: status),
      Expanded(flex: 5, child: inwardTransactionDate),
      Expanded(flex: 5, child: inwardTransaction),
      Expanded(flex: 5, child: inwardTransactionNumber),
      Expanded(flex: 5, child: outwardTransactionDate),
      Expanded(flex: 5, child: outwardTransaction),
      Expanded(flex: 5, child: outwardTransactionNumber),
      Expanded(flex: 4, child: location),
    ],
  );
}
