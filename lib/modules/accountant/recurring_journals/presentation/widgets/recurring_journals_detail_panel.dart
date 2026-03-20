import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import '../../providers/recurring_journal_provider.dart';
import '../../models/recurring_journal_model.dart';

import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';

class RecurringJournalDetailPanel extends ConsumerWidget {
  final RecurringJournal? journal;
  final VoidCallback onEdit;
  final VoidCallback onClose;

  const RecurringJournalDetailPanel({
    super.key,
    required this.journal,
    required this.onEdit,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recurringJournalProvider);
    if (journal == null) {
      return const Center(
        child: Text('Select a recurring journal to view details'),
      );
    }

    final j = journal!;

    return Container(
      color: Colors.white,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            _buildHeader(j, context, ref, state),
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: const TabBar(
                isScrollable: true,
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryBlue,
                labelStyle: TextStyle(fontWeight: FontWeight.w600),
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Child Journal'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Overview Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection(j),
                        const SizedBox(height: 24),
                        _buildItemsTable(j),
                        const SizedBox(height: 24),
                        _buildTotals(j),
                        const SizedBox(height: 32),
                        _buildHistoryTimeline(context, ref, j),
                      ],
                    ),
                  ),
                  // Child Journal Tab
                  _buildChildJournalsTab(context, ref, j),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    RecurringJournal j,
    BuildContext context,
    WidgetRef ref,
    RecurringJournalState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Text(
                j.profileName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(j.status),
            ],
          ),
          const Spacer(),
          // Edit Button
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              onPressed: onEdit,
              icon: const Icon(LucideIcons.edit2, size: 16),
              tooltip: 'Edit',
              padding: EdgeInsets.zero,
              color: AppTheme.textPrimary,
              hoverColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(width: 8),

          if (j.status == RecurringJournalStatus.active)
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    await ref
                        .read(recurringJournalProvider.notifier)
                        .generateChildJournal(j.id);
                    if (!context.mounted) return;
                    ZerpaiToast.success(
                      context,
                      'Journal generated successfully.',
                    );
                    // Refresh child journals
                    ref.invalidate(recurringJournalChildJournalsProvider(j.id));
                  } catch (e) {
                    if (!context.mounted) return;
                    ZerpaiToast.error(context, 'Error: $e');
                  }
                },
                style:
                    OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.borderColor),
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ).copyWith(
                      side: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return const BorderSide(color: AppTheme.primaryBlue);
                        }
                        return const BorderSide(color: AppTheme.borderColor);
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.hovered)) {
                          return AppTheme.primaryBlue;
                        }
                        return AppTheme.textPrimary;
                      }),
                    ),
                child: state.isMutating
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryBlue,
                        ),
                      )
                    : const Text('Create Manual Journal'),
              ),
            ),
          const SizedBox(width: 8),

          // More Dropdown
          SizedBox(
            height: 36,
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
              ),
              child: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirm = await showZerpaiConfirmationDialog(
                      context,
                      title: 'Delete Recurring Journal',
                      message:
                          'Are you sure you want to delete "${j.profileName}"?',
                      confirmLabel: 'Delete',
                      cancelLabel: 'Cancel',
                      variant: ZerpaiConfirmationVariant.danger,
                    );

                    if (confirm == true) {
                      try {
                        await ref
                            .read(recurringJournalProvider.notifier)
                            .deleteJournal(j.id);
                        if (!context.mounted) return;
                        onClose();
                        ZerpaiToast.deleted(context, 'Recurring journal');
                      } catch (e) {
                        if (!context.mounted) return;
                        ZerpaiToast.error(
                          context,
                          'Failed to delete journal: $e',
                        );
                      }
                    }
                  } else if (value == 'stop' || value == 'resume') {
                    final newStatus = value == 'stop'
                        ? RecurringJournalStatus.inactive
                        : RecurringJournalStatus.active;
                    try {
                      await ref
                          .read(recurringJournalProvider.notifier)
                          .updateJournal(j.copyWith(status: newStatus));
                      if (!context.mounted) return;
                      ZerpaiToast.success(
                        context,
                        'Journal ${value == 'stop' ? 'stopped' : 'resumed'}.',
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ZerpaiToast.error(context, 'Error: $e');
                    }
                  } else if (value == 'clone') {
                    try {
                      final cloned = await ref
                          .read(recurringJournalProvider.notifier)
                          .cloneJournal(j.id);
                      if (!context.mounted) return;
                      ZerpaiToast.success(
                        context,
                        'Journal cloned successfully.',
                      );
                      context.push(
                        AppRoutes.accountantRecurringJournalsCreate,
                        extra: cloned,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ZerpaiToast.error(context, 'Error: $e');
                    }
                  }
                },
                tooltip: 'More actions',
                itemBuilder: (context) => [
                  if (j.status == RecurringJournalStatus.active)
                    const PopupMenuItem(
                      value: 'stop',
                      child: Text(
                        'Stop',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                    ),
                  if (j.status == RecurringJournalStatus.inactive)
                    const PopupMenuItem(
                      value: 'resume',
                      child: Text(
                        'Resume',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'clone',
                    child: Text(
                      'Clone',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppTheme.errorRed),
                    ),
                  ),
                ],
                offset: const Offset(0, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
                child: OutlinedButton(
                  onPressed: null,
                  style:
                      OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.borderColor),
                        foregroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ).copyWith(
                        side: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.hovered)) {
                            return const BorderSide(
                              color: AppTheme.primaryBlue,
                            );
                          }
                          return const BorderSide(color: AppTheme.borderColor);
                        }),
                      ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'More',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(LucideIcons.x, size: 18),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(RecurringJournal j) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopDashboardStats(j),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (j.notes ?? '').trim().isEmpty ? '-' : j.notes!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48),
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _infoRow(
                    'Repeat Every',
                    'Every ${j.interval} ${j.repeatEvery}',
                  ),
                  _infoRow(
                    'Start Date',
                    DateFormat('dd MMM yyyy').format(j.startDate),
                  ),
                  if (j.endDate != null)
                    _infoRow(
                      'End Date',
                      DateFormat('dd MMM yyyy').format(j.endDate!),
                    ),
                  if (j.neverExpires) _infoRow('Ends', 'Never'),
                  _infoRow('Currency', j.currency),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopDashboardStats(RecurringJournal j) {
    final totalAmount = j.totalDebit;
    final amtFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    final unit = j.repeatEvery.toLowerCase();
    final cleanUnit = unit.endsWith('s')
        ? unit.substring(0, unit.length - 1)
        : unit;
    final displayUnit = cleanUnit.isNotEmpty
        ? '${cleanUnit[0].toUpperCase()}${cleanUnit.substring(1)}'
        : '';
    final frequency = j.interval > 1
        ? 'Every ${j.interval} ${displayUnit}s'
        : displayUnit;

    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatBlock(
            LucideIcons.wallet,
            amtFormatter.format(totalAmount),
            'Journal Amount',
            AppTheme.accentGreen,
            const Color(0xFFD1FAE5),
          ),
          Container(height: 48, width: 1, color: AppTheme.borderColor),
          _buildStatBlock(
            LucideIcons.refreshCw,
            frequency,
            'Recurring Interval',
            AppTheme.warningOrange,
            const Color(0xFFFEF3C7),
          ),
          Container(height: 48, width: 1, color: AppTheme.borderColor),
          _buildStatBlock(
            LucideIcons.calendar,
            _calculateNextRun(j),
            'Next Journal Entry',
            AppTheme.primaryBlue,
            AppTheme.infoBgBorder,
          ),
        ],
      ),
    );
  }

  String _calculateNextRun(RecurringJournal journal) {
    DateTime base = journal.startDate;
    final unit = journal.repeatEvery.toLowerCase();
    final n = journal.interval > 0 ? journal.interval : 1;

    DateTime next = base;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (journal.lastGeneratedDate != null) {
      DateTime lastRun = DateTime(
        journal.lastGeneratedDate!.year,
        journal.lastGeneratedDate!.month,
        journal.lastGeneratedDate!.day,
      );
      while (next.compareTo(lastRun) <= 0) {
        if (unit.contains('week')) {
          next = next.add(Duration(days: 7 * n));
        } else if (unit.contains('month')) {
          next = DateTime(next.year, next.month + n, next.day);
        } else if (unit.contains('year')) {
          next = DateTime(next.year + n, next.month, next.day);
        } else {
          next = next.add(Duration(days: n));
        }
      }
    } else {
      while (next.isBefore(today)) {
        if (unit.contains('week')) {
          next = next.add(Duration(days: 7 * n));
        } else if (unit.contains('month')) {
          next = DateTime(next.year, next.month + n, next.day);
        } else if (unit.contains('year')) {
          next = DateTime(next.year + n, next.month, next.day);
        } else {
          next = next.add(Duration(days: n));
        }
      }
    }

    return DateFormat('dd/MM/yyyy').format(next);
  }

  Widget _buildStatBlock(
    IconData icon,
    String value,
    String label,
    Color iconColor,
    Color bgColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(RecurringJournalStatus status) {
    Color color;
    Color bgColor;

    switch (status) {
      case RecurringJournalStatus.active:
        color = AppTheme.successTextDark;
        bgColor = AppTheme.successBg;
        break;
      case RecurringJournalStatus.inactive:
        color = AppTheme.warningTextDark;
        bgColor = const Color(0xFFFEF3C7);
        break;
      case RecurringJournalStatus.draft:
        color = AppTheme.infoTextDark;
        bgColor = AppTheme.infoBgBorder;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildItemsTable(RecurringJournal j) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Items',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Header
              Container(
                color: const Color(0xFF3F3F3C),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 40,
                      child: Text(
                        'ACCOUNT',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 30,
                      child: Text(
                        'DEBIT',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 30,
                      child: Text(
                        'CREDIT',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Data Rows
              ...j.items.map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 40,
                        child: Text(
                          item.accountName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 30,
                        child: Text(
                          item.debit > 0 ? item.debit.toStringAsFixed(2) : '',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 30,
                        child: Text(
                          item.credit > 0 ? item.credit.toStringAsFixed(2) : '',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13),
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
  }

  Widget _buildTotals(RecurringJournal j) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 380,
        child: Column(
          children: [
            _totalRow('Total Debit', j.totalDebit.toStringAsFixed(2)),
            _totalRow('Total Credit', j.totalCredit.toStringAsFixed(2)),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              color: AppTheme.bgDisabled,
              child: _totalRow(
                'Total',
                j.totalDebit.toStringAsFixed(2),
                isBold: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 80,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 80),
      ],
    );
  }

  Widget _buildChildJournalsTab(
    BuildContext context,
    WidgetRef ref,
    RecurringJournal j,
  ) {
    final childJournalsAsync = ref.watch(
      recurringJournalChildJournalsProvider(j.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              _headerCell('DATE', flex: 2),
              _headerCell('JOURNAL#', flex: 1),
              _headerCell('STATUS', flex: 2),
              _headerCell('AMOUNT', flex: 2, textAlign: TextAlign.right),
              _headerCell('NOTES', flex: 2, textAlign: TextAlign.center),
            ],
          ),
        ),
        // Rows
        Expanded(
          child: childJournalsAsync.when(
            data: (journals) {
              if (journals.isEmpty) {
                return const Center(
                  child: Text(
                    'No manual journals generated yet.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                itemCount: journals.length,
                itemBuilder: (context, index) {
                  final mj = journals[index];
                  return _childJournalRow(
                    context,
                    ref,
                    date: DateFormat('dd/MM/yyyy').format(mj.journalDate),
                    number: mj.journalNumber,
                    status: mj.status.name,
                    amount:
                        '${j.currency == 'INR' ? '₹' : ''}${mj.totalAmount.toStringAsFixed(2)}',
                    hasNotes: mj.notes != null && mj.notes!.isNotEmpty,
                    onTap: () {
                      context.go(
                        AppRoutes.accountantManualJournalsDetail.replaceAll(
                          ':id',
                          mj.id,
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _headerCell(
    String label, {
    int flex = 1,
    TextAlign textAlign = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: textAlign,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _childJournalRow(
    BuildContext context,
    WidgetRef ref, {
    required String date,
    required String number,
    required String status,
    required String amount,
    required bool hasNotes,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                date,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(flex: 2, child: _statusBadgeInTable(status)),
            Expanded(
              flex: 2,
              child: Text(
                amount,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Icon(
                  hasNotes ? LucideIcons.fileText : null,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadgeInTable(String status) {
    Color color;
    Color bgColor;

    switch (status.toLowerCase()) {
      case 'published':
      case 'posted':
        color = AppTheme.successTextDark;
        bgColor = AppTheme.successBg;
        break;
      case 'draft':
        color = AppTheme.warningTextDark;
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 'cancelled':
        color = AppTheme.errorTextDark;
        bgColor = AppTheme.errorBgBorder;
        break;
      default:
        color = AppTheme.textSecondary;
        bgColor = AppTheme.bgLight;
    }

    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTimeline(
    BuildContext context,
    WidgetRef ref,
    RecurringJournal j,
  ) {
    final childJournalsAsync = ref.watch(
      recurringJournalChildJournalsProvider(j.id),
    );
    final children = childJournalsAsync.asData?.value ?? [];

    if (children.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'HISTORY',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        ...children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4, right: 16),
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Journal created - ${child.journalNumber}. Saved as ${child.status.name}. By System.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'dd/MM/yyyy hh:mm a',
                            ).format(child.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }
}
