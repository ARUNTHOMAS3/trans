import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';

class BusinessPerformanceRatiosScreen extends StatefulWidget {
  const BusinessPerformanceRatiosScreen({super.key});

  @override
  State<BusinessPerformanceRatiosScreen> createState() =>
      _BusinessPerformanceRatiosScreenState();
}

class _BusinessPerformanceRatiosScreenState
    extends State<BusinessPerformanceRatiosScreen> {
  static const String _dateLabel = 'As of 30-06-2026';

  bool _hasPendingFilterChanges = false;

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _runReport() {
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Business Overview',
      reportTitle: 'Business Performance Ratios',
      dateLabel: _dateLabel,
      contentTitle: 'Current Ratio \\u25BE',
      contentSubtitle: _dateLabel,
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'As of Month',
          value: 'Last 6 Months',
          onPressed: _markFiltersDirty,
        ),
      ],
      onRunReport: _runReport,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showInlineRunReportButton: true,
      showExport: false,
      showReload: false,
      showRefresh: false,
      showSettings: false,
      showSchedule: false,
      showPrint: false,
      showDownload: false,
      leadingToolbarActions: [
        ReportIconActionButton(
          icon: Icons.tune,
          onPressed: _runReport,
          tooltip: 'Customize report',
        ),
        ReportIconActionButton(
          icon: Icons.share_outlined,
          onPressed: () {},
          tooltip: 'Share report',
        ),
        ReportIconActionButton(
          icon: Icons.refresh,
          onPressed: _runReport,
          tooltip: 'Refresh',
        ),
      ],
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      settingsTooltip: 'Customize the Business Performance Ratios report.',
      isLoading: false,
      currentNavigationCategory: 'Business Overview',
      currentNavigationReport: 'Business Performance Ratios',
      onReportSelected: (reportName, category) {
        if (reportName == 'Business Performance Ratios') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: const _BusinessPerformanceRatiosBody(),
    );
  }
}

class _RatioSnapshot {
  final String label;
  final String value;
  final String? delta;
  final bool isPositive;
  final bool isActive;

  const _RatioSnapshot({
    required this.label,
    required this.value,
    this.delta,
    this.isPositive = false,
    this.isActive = false,
  });
}

class _RatioMonthRow {
  final String month;
  final String currentAssets;
  final String currentLiabilities;
  final String currentRatio;

  const _RatioMonthRow({
    required this.month,
    required this.currentAssets,
    required this.currentLiabilities,
    required this.currentRatio,
  });
}

class _BusinessPerformanceRatiosBody extends StatelessWidget {
  const _BusinessPerformanceRatiosBody();

  static const List<_RatioSnapshot> _snapshots = [
    _RatioSnapshot(label: 'AS OF JUN 2026', value: '1.08', isActive: true),
    _RatioSnapshot(
      label: 'LAST YEAR',
      value: '0.99',
      delta: '0.05',
      isPositive: true,
    ),
    _RatioSnapshot(label: 'LAST 12 MONTHS', value: '1.23', delta: '-0.38'),
    _RatioSnapshot(label: 'LAST 6 MONTHS', value: '2.88', delta: '-2.18'),
    _RatioSnapshot(label: 'LAST QUARTER', value: '3.96', delta: '-1.3'),
  ];

  static const List<double> _chartValues = [0.79, 0.79, 1.0, 1.08, 1.08, 1.08];

  static const List<_RatioMonthRow> _rows = [
    _RatioMonthRow(
      month: 'Jan 2026',
      currentAssets: '\u20B922,35,764.46',
      currentLiabilities: '\u20B928,23,722.08',
      currentRatio: '0.79',
    ),
    _RatioMonthRow(
      month: 'Feb 2026',
      currentAssets: '\u20B922,35,764.46',
      currentLiabilities: '\u20B928,23,722.08',
      currentRatio: '0.79',
    ),
    _RatioMonthRow(
      month: 'Mar 2026',
      currentAssets: '\u20B929,43,764.46',
      currentLiabilities: '\u20B929,31,722.08',
      currentRatio: '1',
    ),
    _RatioMonthRow(
      month: 'Apr 2026',
      currentAssets: '\u20B931,56,109.36',
      currentLiabilities: '\u20B929,33,250.58',
      currentRatio: '1.08',
    ),
    _RatioMonthRow(
      month: 'May 2026',
      currentAssets: '\u20B931,73,194.21',
      currentLiabilities: '\u20B929,38,721.73',
      currentRatio: '1.08',
    ),
    _RatioMonthRow(
      month: 'Jun 2026',
      currentAssets: '\u20B932,40,646.11',
      currentLiabilities: '\u20B930,06,768.79',
      currentRatio: '1.08',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space10,
        AppTheme.space24,
        AppTheme.space8,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            primary: false,
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                SizedBox(height: AppTheme.space8),
                _RatioSnapshotStrip(snapshots: _snapshots),
                SizedBox(height: AppTheme.space32),
                _CurrentRatioChart(values: _chartValues),
                SizedBox(height: AppTheme.space32),
                _RatioTable(rows: _rows),
                SizedBox(height: AppTheme.space8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RatioSnapshotStrip extends StatelessWidget {
  final List<_RatioSnapshot> snapshots;

  const _RatioSnapshotStrip({required this.snapshots});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.space4),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var index = 0; index < snapshots.length; index++) ...[
              Expanded(child: _RatioSnapshotTile(snapshot: snapshots[index])),
              if (index != snapshots.length - 1)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppTheme.borderLight,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatioSnapshotTile extends StatelessWidget {
  final _RatioSnapshot snapshot;

  const _RatioSnapshotTile({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final delta = snapshot.delta;
    final deltaColor = snapshot.isPositive
        ? AppTheme.successTextDark
        : AppTheme.errorRed;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space28,
        vertical: AppTheme.space24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            snapshot.label,
            style: AppTheme.metaHelper.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                snapshot.value,
                style: AppTheme.textPrimaryStyle(24, FontWeight.w500).copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: AppTheme.space8),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space4),
                  child: Row(
                    children: [
                      Text(
                        delta,
                        style: AppTheme.captionText.copyWith(
                          color: deltaColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space4),
                      Icon(
                        snapshot.isPositive
                            ? Icons.keyboard_double_arrow_up
                            : Icons.keyboard_double_arrow_down,
                        size: AppTheme.space14,
                        color: deltaColor,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentRatioChart extends StatelessWidget {
  final List<double> values;

  const _CurrentRatioChart({required this.values});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: CustomPaint(
        painter: _CurrentRatioChartPainter(values: values),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CurrentRatioChartPainter extends CustomPainter {
  final List<double> values;

  const _CurrentRatioChartPainter({required this.values});

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 70.0;
    const rightPadding = 44.0;
    const topPadding = 12.0;
    const bottomPadding = 48.0;
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final origin = Offset(leftPadding, topPadding + chartHeight);

    final axisPaint = Paint()
      ..color = AppTheme.borderLight
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: 0.65)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawLine(Offset(leftPadding, topPadding), origin, axisPaint);
    canvas.drawLine(
      origin,
      Offset(size.width - rightPadding, origin.dy),
      axisPaint,
    );

    final labelStyle = AppTheme.captionText.copyWith(color: AppTheme.textMuted);
    _drawText(
      canvas,
      '1',
      Offset(leftPadding - 18, topPadding + 2),
      labelStyle,
    );
    _drawText(canvas, '0', Offset(leftPadding - 18, origin.dy - 8), labelStyle);

    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = leftPadding + (chartWidth / (values.length - 1)) * index;
      final normalized = values[index].clamp(0, 1.2) / 1.2;
      final y = origin.dy - (chartHeight * normalized);
      points.add(Offset(x, y));
      _drawText(canvas, '01', Offset(x - 8, origin.dy + 12), labelStyle);
      _drawText(
        canvas,
        _months[index],
        Offset(x - 10, origin.dy + 27),
        labelStyle.copyWith(fontSize: 9),
      );
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);
    for (final point in points) {
      canvas.drawCircle(point, 3.2, pointPaint);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _CurrentRatioChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _RatioTable extends StatelessWidget {
  final List<_RatioMonthRow> rows;

  const _RatioTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1030,
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.1),
            1: FlexColumnWidth(1.6),
            2: FlexColumnWidth(1.8),
            3: FlexColumnWidth(1.1),
          },
          border: const TableBorder(
            horizontalInside: BorderSide(color: AppTheme.borderLight),
            bottom: BorderSide(color: AppTheme.borderLight),
          ),
          children: [
            _buildHeaderRow(),
            for (final row in rows) _buildDataRow(row),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(color: AppTheme.bgLight),
      children: [
        _TableCellText('MONTH', isHeader: true),
        _TableCellText('CURRENT ASSETS', isHeader: true),
        _TableCellText('CURRENT LIABILITIES', isHeader: true),
        _TableCellText('CURRENT RATIO', isHeader: true, alignRight: true),
      ],
    );
  }

  TableRow _buildDataRow(_RatioMonthRow row) {
    return TableRow(
      children: [
        _TableCellText(row.month),
        _TableCellText(row.currentAssets),
        _TableCellText(row.currentLiabilities),
        _TableCellText(row.currentRatio, alignRight: true),
      ],
    );
  }
}

class _TableCellText extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool alignRight;

  const _TableCellText(
    this.text, {
    this.isHeader = false,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isHeader ? 38 : 42,
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space10,
        vertical: AppTheme.space8,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.visible,
        style: (isHeader ? ReportTableTypography.header : AppTheme.bodyText)
            .copyWith(
              color: isHeader ? AppTheme.textSecondary : AppTheme.textPrimary,
              fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
            ),
      ),
    );
  }
}
