import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/theme/app_text_styles.dart';

import '../../models/recurring_expense_audit_history_model.dart';
import '../../models/recurring_expense_details_model.dart';
import '../../models/recurring_expense_enums.dart';
import '../../models/recurring_expense_history_model.dart';
import '../../providers/recurring_expense_provider.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';

class RecurringExpenseDetailsWidget extends ConsumerStatefulWidget {
  final RecurringExpenseDetails details;
  final List<RecurringExpenseAuditHistoryEntry> history;
  final List<RecurringExpenseRun> runs;
  final VoidCallback onClose;
  final double availableWidth;

  const RecurringExpenseDetailsWidget({
    super.key,
    required this.details,
    this.history = const <RecurringExpenseAuditHistoryEntry>[],
    this.runs = const <RecurringExpenseRun>[],
    required this.onClose,
    required this.availableWidth,
  });

  @override
  ConsumerState<RecurringExpenseDetailsWidget> createState() =>
      _RecurringExpenseDetailsWidgetState();
}

class _RecurringExpenseDetailsWidgetState
    extends ConsumerState<RecurringExpenseDetailsWidget> {
  String _activeTab = 'overview';

  String _formatCurrency(double amount) {
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first;
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return '\u20B9${buffer.toString()}.${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColor,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 18),
              _buildTabButton(label: 'Overview', tabId: 'overview'),
              const SizedBox(width: 28),
              _buildTabButton(label: 'All Expenses', tabId: 'expenses'),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: AppTheme.backgroundColor,
            child: SingleChildScrollView(
              child: _activeTab == 'overview'
                  ? _buildOverviewTab(widget.availableWidth)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
                      child: _buildExpensesTab(),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({required String label, required String tabId}) {
    final isActive = _activeTab == tabId;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = tabId;
        });
      },
      hoverColor: AppTheme.bgHover,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primaryBlueDark : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(double availableWidth) {
    final isCompact = availableWidth < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricTile(
                      icon: Icons.account_balance_wallet,
                      iconColor: AppTheme.successDark,
                      bgColor: AppTheme.successBg,
                      value: _formatCurrency(widget.details.amount),
                      label: 'Expense Amount',
                    ),
                    const SizedBox(height: 22),
                    _buildMetricTile(
                      icon: Icons.autorenew,
                      iconColor: AppTheme.warningOrange,
                      bgColor: AppTheme.warningBg,
                      value: _displayValue(widget.details.frequency),
                      label: 'Repeats',
                    ),
                    const SizedBox(height: 22),
                    _buildMetricTile(
                      icon: Icons.calendar_month_outlined,
                      iconColor: AppTheme.infoBlue,
                      bgColor: AppTheme.infoBg,
                      value: _displayValue(widget.details.nextExpenseDate),
                      label: 'Next Expense Date',
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricTile(
                      icon: Icons.account_balance_wallet,
                      iconColor: AppTheme.successDark,
                      bgColor: AppTheme.successBg,
                      value: _formatCurrency(widget.details.amount),
                      label: 'Expense Amount',
                    ),
                    const SizedBox(width: 56),
                    _buildMetricTile(
                      icon: Icons.autorenew,
                      iconColor: AppTheme.warningOrange,
                      bgColor: AppTheme.warningBg,
                      value: _displayValue(widget.details.frequency),
                      label: 'Repeats',
                    ),
                    const SizedBox(width: 56),
                    _buildMetricTile(
                      icon: Icons.calendar_month_outlined,
                      iconColor: AppTheme.infoBlue,
                      bgColor: AppTheme.infoBg,
                      value: _displayValue(widget.details.nextExpenseDate),
                      label: 'Next Expense Date',
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailGroup(
                      label: 'Expense Account',
                      value: widget.details.expenseAccount,
                    ),
                    const SizedBox(height: 22),
                    _buildDetailGroup(
                      label: 'Paid Through',
                      value: widget.details.paidThrough,
                    ),
                    const SizedBox(height: 22),
                    Container(width: 2, color: AppTheme.warningOrange),
                    const SizedBox(height: 10),
                    _buildDetailGroup(
                      label: 'Start On',
                      value: widget.details.startDate,
                    ),
                    const SizedBox(height: 14),
                    _buildDetailGroup(label: 'Ends On', value: _endValue()),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 200,
                      child: _buildDetailGroup(
                        label: 'Expense Account',
                        value: widget.details.expenseAccount,
                      ),
                    ),
                    const SizedBox(width: 56),
                    SizedBox(
                      width: 140,
                      child: _buildDetailGroup(
                        label: 'Paid Through',
                        value: widget.details.paidThrough,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Container(width: 2, color: AppTheme.warningOrange),
                    ),
                    SizedBox(
                      width: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInlineDetailRow(
                            label: 'Start On',
                            value: widget.details.startDate,
                          ),
                          const SizedBox(height: 14),
                          _buildInlineDetailRow(
                            label: 'Ends On',
                            value: _endValue(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              const Divider(color: AppTheme.borderLight, height: 1),
              const SizedBox(height: 22),
              Text(
                'OTHER DETAILS',
                style: AppTextStyles.body.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 22),
              _buildOtherDetailRow(
                label: 'GST Treatment',
                value: _displayValue(widget.details.gstTreatment),
              ),
              const SizedBox(height: 18),
              _buildOtherDetailRow(
                label: 'Notes',
                value: _displayValue(widget.details.notes),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
        _buildHistorySection(),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
          child: Center(child: Icon(icon, color: iconColor, size: 26)),
        ),
        const SizedBox(width: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.body.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailGroup({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 10),
        Text(
          _displayValue(value),
          style: AppTextStyles.body.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInlineDetailRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            _displayValue(value),
            style: AppTextStyles.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherDetailRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    final historyEntries = _historyEntries();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
      color: AppTheme.bgLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HISTORY',
            style: AppTextStyles.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 28),
          if (historyEntries.isEmpty)
            Text(
              'No history available yet.',
              style: AppTextStyles.body.copyWith(color: AppTheme.textSecondary),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: historyEntries.length,
              itemBuilder: (context, index) {
                final entry = historyEntries[index];
                final isNotLast = index < historyEntries.length - 1;
                return _buildTimelineItem(entry: entry, isNotLast: isNotLast);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required _RecurringExpenseHistoryEntry entry,
    required bool isNotLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 185,
          child: Padding(
            padding: EdgeInsets.only(top: 4, bottom: isNotLast ? 26 : 0),
            child: Text(
              entry.timestampLabel,
              style: AppTextStyles.body.copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ),
        SizedBox(
          width: 52,
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.backgroundColor,
                  border: Border.all(color: AppTheme.borderLight, width: 1.5),
                ),
                child: Center(
                  child: Icon(
                    entry.icon,
                    size: 14,
                    color: AppTheme.warningOrange,
                  ),
                ),
              ),
              if (isNotLast)
                Container(width: 1.5, height: 52, color: AppTheme.borderLight),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2, bottom: isNotLast ? 26 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'by ',
                        style: AppTextStyles.body.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: entry.author,
                        style: AppTextStyles.body.copyWith(
                          color: AppTheme.primaryBlueDark,
                          fontWeight: FontWeight.w500,
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

  List<_RecurringExpenseHistoryEntry> _historyEntries() {
    final entries = <_RecurringExpenseHistoryEntry>[];

    final createdAt = _parseAuditTimestamp(widget.details.createdAt);
    if (createdAt != null) {
      entries.add(
        _RecurringExpenseHistoryEntry(
          timestampLabel: _formatAuditTimestamp(createdAt),
          title:
              'Recurring expense created for ${_formatCurrency(widget.details.amount)}',
          author: _resolvedAuditUser(
            widget.details.createdByName,
            widget.details.createdBy,
          ),
          icon: Icons.assignment_outlined,
          dateTime: createdAt,
        ),
      );
    }

    if (widget.history.isNotEmpty) {
      final remainingEntries = <_RecurringExpenseHistoryEntry>[];
      for (final history in widget.history) {
        if (history.action.toUpperCase() == 'CREATE' ||
            history.action.toUpperCase() == 'INSERT') {
          continue;
        }
        final parsedTime = _parseAuditTimestamp(history.createdAt);
        remainingEntries.add(
          _RecurringExpenseHistoryEntry(
            timestampLabel: parsedTime == null
                ? _displayValue(history.createdAt)
                : _formatAuditTimestamp(parsedTime),
            title: history.summary,
            author: history.actorName.trim().isEmpty ? '-' : history.actorName,
            icon: _resolveAuditHistoryIcon(history.action, history.summary),
            dateTime: parsedTime ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
      }
      remainingEntries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      entries.addAll(remainingEntries);
    } else {
      final updatedAt = _parseAuditTimestamp(widget.details.updatedAt);
      if (updatedAt != null &&
          widget.details.updatedAt != widget.details.createdAt) {
        entries.add(
          _RecurringExpenseHistoryEntry(
            timestampLabel: _formatAuditTimestamp(updatedAt),
            title: 'Recurring expense updated.',
            author: _resolvedAuditUser(
              widget.details.updatedByName,
              widget.details.updatedBy,
            ),
            icon: Icons.edit_outlined,
            dateTime: updatedAt,
          ),
        );
      }
    }

    if (widget.history.isEmpty) {
      for (final run in widget.runs) {
        final runTimeRaw = run.createdAt ?? run.runDate ?? run.timestamp;
        final parsedTime = _parseAuditTimestamp(runTimeRaw);
        final sortDateTime =
            parsedTime ?? DateTime.fromMillisecondsSinceEpoch(0);

        var title = run.title;
        var icon = _resolveHistoryIcon(run);

        final note = run.remarks?.trim();
        if (note != null && note.startsWith('{') && note.endsWith('}')) {
          try {
            final decoded = jsonDecode(note);
            if (decoded is Map && decoded['type'] == 'update') {
              continue;
            }
          } catch (_) {}
        }

        entries.add(
          _RecurringExpenseHistoryEntry(
            timestampLabel: parsedTime == null
                ? _displayValue(runTimeRaw)
                : _formatAuditTimestamp(parsedTime),
            title: title,
            author: run.author,
            icon: icon,
            dateTime: sortDateTime,
          ),
        );
      }
    }

    return entries;
  }

  DateTime? _parseAuditTimestamp(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return DateTime.tryParse(trimmed)?.toLocal();
  }

  String _formatAuditTimestamp(DateTime value) {
    return DateFormat('dd-MM-yyyy hh:mm a').format(value);
  }

  String _resolvedAuditUser(String? name, String? id) {
    final resolvedName = name?.trim();
    if (resolvedName != null && resolvedName.isNotEmpty) {
      return resolvedName;
    }
    final resolvedId = id?.trim();
    if (resolvedId != null && resolvedId.toUpperCase() == 'AUTO') {
      return 'AUTO';
    }
    return '-';
  }

  IconData _resolveHistoryIcon(RecurringExpenseRun history) {
    return switch (history.status) {
      RunStatus.success => Icons.assignment_outlined,
      RunStatus.failed => Icons.error_outline,
      RunStatus.skipped => Icons.skip_next_outlined,
    };
  }

  IconData _resolveAuditHistoryIcon(String action, String summary) {
    final normalizedSummary = summary.trim().toLowerCase();
    if (normalizedSummary.contains('started') ||
        normalizedSummary.contains('stopped')) {
      return Icons.edit_outlined;
    }
    switch (action.toUpperCase()) {
      case 'CREATE':
      case 'INSERT':
        return Icons.assignment_outlined;
      case 'DELETE':
        return Icons.delete_outline;
      default:
        return Icons.edit_outlined;
    }
  }

  Widget _buildExpensesTableHeader() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              'DATE',
              style: AppTextStyles.helper.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 200,
            child: Text(
              'EXPENSE ACCOUNT',
              style: AppTextStyles.helper.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text(
              'STATUS',
              style: AppTextStyles.helper.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 150,
            child: Text(
              'PAID THROUGH',
              style: AppTextStyles.helper.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'AMOUNT',
                style: AppTextStyles.helper.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildExpenseStatusChip(String status) {
    final cleanStatus = status.trim().toUpperCase();
    Color bgColor = AppTheme.bgLight;
    Color textColor = AppTheme.textSecondary;

    if (cleanStatus == 'RECORDED') {
      bgColor = AppTheme.successBg;
      textColor = AppTheme.successDark;
    } else if (cleanStatus == 'DRAFT') {
      bgColor = AppTheme.bgHover;
      textColor = AppTheme.textSecondary;
    } else if (cleanStatus == 'PAID') {
      bgColor = AppTheme.infoBg;
      textColor = AppTheme.infoBlue;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          cleanStatus,
          style: AppTextStyles.helper.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseRow(Map<String, dynamic> expense) {
    final rawDate = expense['expense_date']?.toString();
    final parsedDate = DateTime.tryParse(rawDate ?? '');
    final dateStr = parsedDate != null
        ? DateFormat('dd-MM-yyyy').format(parsedDate)
        : (rawDate ?? '-');

    final expenseAccount =
        expense['expense_account_name']?.toString() ??
        expense['expense_account']?.toString() ??
        '-';
    final status = expense['status']?.toString() ?? '-';
    final paidThrough =
        expense['paid_through_account_name']?.toString() ??
        expense['paid_through']?.toString() ??
        '-';

    final amountVal =
        double.tryParse(
          expense['total_amount']?.toString() ??
              expense['amount']?.toString() ??
              '0',
        ) ??
        0.0;
    final amountStr = _formatCurrency(amountVal);

    return Container(
      height: 40,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              dateStr,
              style: AppTextStyles.body.copyWith(color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 200,
            child: Text(
              expenseAccount,
              style: AppTextStyles.body.copyWith(color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(width: 100, child: _buildExpenseStatusChip(status)),
          const SizedBox(width: 16),
          SizedBox(
            width: 150,
            child: Text(
              paidThrough,
              style: AppTextStyles.body.copyWith(color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                amountStr,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    final relatedExpensesAsync = ref.watch(
      recurringExpenseRelatedExpensesProvider(widget.details.id),
    );

    return relatedExpensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExpensesTableHeader(),
              const SizedBox(height: 120),
              Center(
                child: Text(
                  'There are no expenses',
                  style: AppTextStyles.body.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 120),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExpensesTableHeader(),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return _buildExpenseRow(expense);
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.space24),
        child: ZTableSkeleton(rows: 4, columns: 3),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Failed to load expenses: $err',
            style: AppTextStyles.body.copyWith(color: AppTheme.warningOrange),
          ),
        ),
      ),
    );
  }

  String _endValue() {
    if (widget.details.neverExpires) {
      return 'Goes on forever';
    }
    return _displayValue(widget.details.endDate);
  }

  String _displayValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return '-';
    }
    return trimmed;
  }
}

class _RecurringExpenseHistoryEntry {
  final String timestampLabel;
  final String title;
  final String author;
  final IconData icon;
  final DateTime dateTime;

  const _RecurringExpenseHistoryEntry({
    required this.timestampLabel,
    required this.title,
    required this.author,
    required this.icon,
    required this.dateTime,
  });
}
