import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class SystemMailReportRow {
  final String date;
  final String subject;
  final String mailType;

  const SystemMailReportRow({
    required this.date,
    required this.subject,
    required this.mailType,
  });
}

class SystemMailsTable extends StatelessWidget {
  final List<SystemMailReportRow> rows;
  final int page;
  final int pageSize;
  final int totalCount;
  final ValueChanged<int>? onPageChanged;

  const SystemMailsTable({
    super.key,
    required this.rows,
    this.page = 1,
    this.pageSize = 24,
    int? totalCount,
    this.onPageChanged,
  }) : totalCount = totalCount ?? rows.length;

  @override
  Widget build(BuildContext context) {
    return ReportStickyHeaderScrollTable(
      header: const _SystemMailsHeader(),
      emptyBody: const SizedBox.shrink(),
      isEmpty: rows.isEmpty,
      children: [
        if (rows.isNotEmpty)
          SizedBox(
            height: 345,
            child: ListView.separated(
              primary: false,
              physics: const ClampingScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: AppTheme.borderLight,
              ),
              itemBuilder: (context, index) {
                return _SystemMailsDataRow(row: rows[index]);
              },
            ),
          ),
        ReportPaginationFooter(
          totalCount: totalCount,
          page: page,
          pageSize: pageSize,
          onPageChanged: onPageChanged,
        ),
      ],
    );
  }
}

class _SystemMailsHeader extends StatelessWidget {
  const _SystemMailsHeader();

  @override
  Widget build(BuildContext context) {
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
      child: _buildSystemMailsTableRow(
        date: Row(
          children: [
            Text('DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
        subject: Text('SUBJECT', style: ReportTableTypography.header),
        mailType: Text('MAIL TYPE', style: ReportTableTypography.header),
      ),
    );
  }
}

class _SystemMailsDataRow extends StatefulWidget {
  final SystemMailReportRow row;

  const _SystemMailsDataRow({required this.row});

  @override
  State<_SystemMailsDataRow> createState() => _SystemMailsDataRowState();
}

class _SystemMailsDataRowState extends State<_SystemMailsDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space20,
          vertical: AppTheme.space10,
        ),
        color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
        child: _buildSystemMailsTableRow(
          date: _bodyText(widget.row.date),
          subject: _bodyText(widget.row.subject),
          mailType: _bodyText(widget.row.mailType),
        ),
      ),
    );
  }

  Widget _bodyText(String value) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTheme.tableCell,
    );
  }
}

Widget _buildSystemMailsTableRow({
  required Widget date,
  required Widget subject,
  required Widget mailType,
}) {
  return Row(
    children: [
      Expanded(flex: 3, child: date),
      Expanded(flex: 5, child: subject),
      Expanded(flex: 3, child: mailType),
    ],
  );
}
