import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';

class ReconciliationStatusContent extends StatelessWidget {
  const ReconciliationStatusContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: false,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        0,
        AppTheme.space24,
        AppTheme.space24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _AccountSummaryCard(),
          SizedBox(height: AppTheme.space48),
          _ReconciliationTabs(),
          _ReconciliationTotals(),
          _ReconciliationTable(),
        ],
      ),
    );
  }
}

class ReconciliationStatusHeading extends StatelessWidget {
  const ReconciliationStatusHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ZABNIX PRIVATE LIMITED',
          textAlign: TextAlign.center,
          style: AppTheme.metaHelper.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          'Reconciliation Status',
          textAlign: TextAlign.center,
          style: AppTheme.pageTitle.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.space6),
        Text(
          'Zoho Payroll - Bank Account',
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.space6),
        Text(
          'From 01-07-2026 To 31-07-2026',
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  const _AccountSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1168),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(AppTheme.space8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.space20,
                  vertical: AppTheme.space10,
                ),
                child: Text('Account Summary:', style: AppTheme.bodyText),
              ),
              Divider(height: 1, color: AppTheme.borderLight),
              const _AccountSummaryBody(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountSummaryBody extends StatelessWidget {
  const _AccountSummaryBody();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: const [
          Expanded(
            flex: 5,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.space20,
                AppTheme.space48,
                AppTheme.space20,
                AppTheme.space48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BalanceMetric(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Opening Balance',
                    value: '\u20B90.00',
                  ),
                  SizedBox(height: AppTheme.space12),
                  _BalanceMetric(
                    icon: Icons.account_balance_outlined,
                    label: 'Closing Balance',
                    value: '\u20B9-1,00,000.00',
                  ),
                ],
              ),
            ),
          ),
          VerticalDivider(width: 1, color: AppTheme.borderLight),
          Expanded(
            flex: 7,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.space20,
                AppTheme.space28,
                AppTheme.space20,
                AppTheme.space28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SummaryAmount(
                    label: 'Total value of matched transactions for the period',
                    value: '\u20B90.00',
                  ),
                  SizedBox(height: AppTheme.space16),
                  _SummaryAmount(
                    label: 'Total value of unmatched statements as on 31-07-2026',
                    value: '\u20B90.00',
                  ),
                  SizedBox(height: AppTheme.space16),
                  _SummaryAmount(
                    label: 'Total value of unmatched transactions in Zoho Books as on 31-07-2026',
                    value: '\u20B9-1,00,000.00',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BalanceMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(AppTheme.space8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: AppTheme.space18, color: AppTheme.textMuted),
        ),
        const SizedBox(width: AppTheme.space10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.metaHelper),
            const SizedBox(height: AppTheme.space4),
            Text(
              value,
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryAmount extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryAmount({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.space6),
        Text(
          value,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReconciliationTabs extends StatelessWidget {
  const _ReconciliationTabs();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _StatusTab(
          count: '0',
          countColor: AppTheme.errorRed,
          label: 'Matched/Categorized Transactions',
        ),
        const SizedBox(width: AppTheme.space8),
        const _StatusTab(
          count: '1',
          countColor: AppTheme.successGreen,
          label: 'Unmatched Books Transactions',
        ),
        const SizedBox(width: AppTheme.space8),
        const _StatusTab(
          count: '0',
          countColor: AppTheme.warningOrange,
          label: 'Unmatched Statement Lines',
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: AppTheme.space10),
            child: Align(
              alignment: Alignment.centerRight,
              child: _ViewTransactionsLink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String count;
  final Color countColor;
  final String label;

  const _StatusTab({
    required this.count,
    required this.countColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space12,
        AppTheme.space16,
        AppTheme.space10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.space8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: AppTheme.pageTitle.copyWith(
              color: countColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.space6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ViewTransactionsLink extends StatelessWidget {
  const _ViewTransactionsLink();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'View Reconciled and Unreconciled Transactions',
          style: AppTheme.bodyText.copyWith(color: AppTheme.primaryBlue),
        ),
        const SizedBox(width: AppTheme.space4),
        const Icon(
          Icons.chevron_right,
          size: AppTheme.space16,
          color: AppTheme.primaryBlue,
        ),
      ],
    );
  }
}

class _ReconciliationTotals extends StatelessWidget {
  const _ReconciliationTotals();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space12,
        AppTheme.space28,
        AppTheme.space12,
        AppTheme.space20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
          children: [
            const TextSpan(text: 'Total Deposit(0): '),
            TextSpan(
              text: '\u20B90.00',
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(text: ' | Total Withdrawal(0): '),
            TextSpan(
              text: '\u20B90.00',
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReconciliationTable extends StatelessWidget {
  const _ReconciliationTable();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ReconciliationTableHeader(),
        SizedBox(
          height: 210,
          child: Center(
            child: Text(
              'No data to display',
              style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReconciliationTableHeader extends StatelessWidget {
  const _ReconciliationTableHeader();

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
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('STATEMENT DETAILS', style: ReportTableTypography.header)),
          Expanded(flex: 3, child: Text('DATE', style: ReportTableTypography.header)),
          Expanded(flex: 4, child: Text('REFERENCE#', style: ReportTableTypography.header)),
          Expanded(flex: 3, child: Text('TYPE', style: ReportTableTypography.header)),
          Expanded(flex: 5, child: Text('RECONCILIATION STATUS', style: ReportTableTypography.header)),
          Expanded(flex: 3, child: Text('DEPOSITS', textAlign: TextAlign.right, style: ReportTableTypography.header)),
          Expanded(flex: 3, child: Text('WITHDRAWALS', textAlign: TextAlign.right, style: ReportTableTypography.header)),
        ],
      ),
    );
  }
}
