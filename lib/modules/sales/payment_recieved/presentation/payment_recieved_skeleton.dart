import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';

/// Shimmer skeletons for the Payments Received module.
///
/// These reuse the shared [Skeleton] primitive (`lib/shared/widgets/skeleton.dart`)
/// and only compose the layouts that are specific to the payment-received pages,
/// so they are kept feature-local instead of polluting the shared catalog.
///
/// Wired into the pages that have a real loading boundary:
///  * [PaymentFormSkeleton]  -> createcustomeradvance.dart / createinvoicepayment.dart
///    (shown while `salesCustomersProvider` is loading).
///  * [PaymentReportSkeleton] -> report_page.dart (shown over the table while a
///    refresh is in flight).

/// Skeleton matching the create-payment form body:
/// a left-aligned column of `label (180px) + field` rows, followed by the
/// full-width notes and attachments blocks. Mirrors the `_fieldRow` layout used
/// by the Invoice Payment and Customer Advance create screens.
class PaymentFormSkeleton extends StatelessWidget {
  const PaymentFormSkeleton({
    super.key,
    this.fieldRows = 9,
    this.maxWidth = 900,
  });

  /// Number of label + field rows to render.
  final int fieldRows;

  /// Max content width — 900 for Customer Advance, 1200 for Invoice Payment.
  final double maxWidth;

  static const List<double> _labelWidths = [
    110,
    90,
    80,
    140,
    120,
    100,
    70,
    130,
    95,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...List.generate(
                  fieldRows,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 180,
                          child: Skeleton(
                            width: _labelWidths[i % _labelWidths.length],
                            height: 14,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: const Skeleton(height: 38, borderRadius: 6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Notes block
                const Skeleton(width: 120, height: 14),
                const SizedBox(height: 10),
                const Skeleton(
                  width: double.infinity,
                  height: 80,
                  borderRadius: 6,
                ),
                const SizedBox(height: 20),
                // Attachments block
                const Skeleton(width: 120, height: 14),
                const SizedBox(height: 10),
                const Skeleton(width: 220, height: 38, borderRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton matching the Payments Received report table:
/// a sticky-looking header row + data rows, each leading with a checkbox cell.
/// Rendered as an opaque overlay while the list refreshes.
class PaymentReportSkeleton extends StatelessWidget {
  const PaymentReportSkeleton({super.key, this.rows = 10});

  final int rows;

  static const List<double> _cellWidths = [80, 90, 90, 170, 70, 80, 80, 60];

  Widget _row({required double cellHeight}) {
    return Row(
      children: [
        const SizedBox(width: 16),
        const Skeleton(width: 16, height: 16, borderRadius: 2),
        const SizedBox(width: 22),
        ..._cellWidths.map(
          (w) => Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Skeleton(width: w, height: cellHeight),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            height: 44,
            color: AppTheme.bgLight,
            alignment: Alignment.centerLeft,
            child: _row(cellHeight: 13),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          // Rows
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.borderLight),
              itemBuilder: (_, __) => Container(
                height: 44,
                alignment: Alignment.centerLeft,
                child: _row(cellHeight: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
