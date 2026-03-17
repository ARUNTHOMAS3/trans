import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import '../../models/manual_journal_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/manual_journal_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';
import 'dart:math' as math;

class ManualJournalDetailPanel extends ConsumerWidget {
  final ManualJournal journal;
  final VoidCallback onClose;
  final VoidCallback? onEdit;
  final VoidCallback? onPost;
  final VoidCallback? onCancelJournal;
  final VoidCallback? onDelete;
  final bool isBusy;

  const ManualJournalDetailPanel({
    super.key,
    required this.journal,
    required this.onClose,
    this.onEdit,
    this.onPost,
    this.onCancelJournal,
    this.onDelete,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopHeader(context, ref),
          _buildActionsBar(context, ref),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildJournalDocument(context),
                          const SizedBox(height: 48),
                          _buildMoreInformation(context),
                          const SizedBox(height: 60),
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
  }

  Widget _buildTopHeader(BuildContext context, WidgetRef ref) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            journal.journalNumber,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          if (isBusy) ...[
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
          ],
          // Action Buttons
          _headerAction(
            icon: LucideIcons.pencil,
            label: 'Edit',
            tooltip: 'Edit Journal',
            onTap: !isBusy ? onEdit : null,
          ),
          _headerDivider(),
          _buildPrintMenu(context),
          _headerDivider(),
          _headerAction(
            icon: LucideIcons.repeat,
            label: 'Make Recurring',
            tooltip: 'Convert to Recurring Journal',
            onTap: () {
              context.push(
                AppRoutes.accountantRecurringJournalsCreate,
                extra: journal,
              );
            },
          ),
          _headerDivider(),
          _buildMoreMenu(context, ref),
          _headerDivider(),
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                onClose();
              } else {
                context.go(AppRoutes.accountantManualJournals);
              }
            },
            tooltip: 'Close Panel',
            icon: const Icon(
              LucideIcons.x,
              size: 20,
              color: AppTheme.textSecondary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String label,
    String? tooltip,
    VoidCallback? onTap,
    bool hasSubMenu = false,
  }) {
    final body = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
            if (hasSubMenu) ...[
              const SizedBox(width: 4),
              const Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: AppTheme.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: body);
    }
    return body;
  }

  Widget _headerDivider() => const VerticalDivider(
    width: 24,
    indent: 14,
    endIndent: 14,
    color: AppTheme.borderColor,
  );

  Widget _buildPrintMenu(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'PDF/Print Options',
      offset: const Offset(0, 32),
      onSelected: (value) {
        ZerpaiToast.info(
          context,
          'Printing/PDF generation feature is coming soon!',
        );
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'pdf', child: Text('Save as PDF')),
        const PopupMenuItem(value: 'print', child: Text('Print Journal')),
      ],
      child: _headerAction(
        icon: LucideIcons.fileText,
        label: 'PDF/Print',
        onTap: null, // Tap handled by PopupMenuButton
        hasSubMenu: true,
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      offset: const Offset(0, 32),
      icon: const Icon(
        LucideIcons.moreHorizontal,
        size: 20,
        color: AppTheme.textSecondary,
      ),
      onSelected: (value) async {
        switch (value) {
          case 'clone':
            _handleClone(context, ref, journal);
            break;
          case 'reverse':
            _handleCloneReverse(context, ref, journal);
            break;
          case 'template':
            _handleCreateTemplate(context, ref, journal);
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'clone', child: Text('Clone')),
        const PopupMenuItem(
          value: 'reverse',
          child: Text('Clone Reverse Entry'),
        ),
        const PopupMenuItem(value: 'template', child: Text('Create Template')),
        if (journal.status == ManualJournalStatus.draft)
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  Widget _buildActionsBar(BuildContext context, WidgetRef ref) {
    if (journal.status != ManualJournalStatus.draft)
      return const SizedBox.shrink();
    return _buildBanner();
  }

  Widget _buildBanner() {
    if (journal.status != ManualJournalStatus.draft)
      return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.sparkles, size: 16, color: Colors.deepPurple),
          const SizedBox(width: 12),
          const Expanded(
            child: Wrap(
              children: [
                Text(
                  'WHAT\'S NEXT? ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'This journal is in draft status. Review and Proceed to publish. ',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 28,
            child: ElevatedButton(
              onPressed: !isBusy ? onPost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('Publish', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalDocument(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');
    final statusColor = _statusColor(journal.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 60, 40, 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Journal Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notes',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            journal.notes ?? 'No notes available',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'JOURNAL',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#${journal.journalNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _docInfoRow(
                            'Date:',
                            DateFormat(
                              'dd/MM/yyyy',
                            ).format(journal.journalDate),
                          ),
                          _docInfoRow(
                            'Amount:',
                            '₹${currencyFormat.format(journal.totalDebit)}',
                          ),
                          _docInfoRow(
                            'Reference Number:',
                            journal.referenceNumber ?? '-',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Items Table
                _buildItemsTable(context, currencyFormat),
                const SizedBox(height: 40),
                // Totals
                Column(
                  children: [
                    _summaryRow(
                      'Sub Total',
                      currencyFormat.format(journal.totalDebit),
                      currencyFormat.format(journal.totalCredit),
                    ),
                    const Divider(),
                    _summaryRow(
                      'Total',
                      '₹${currencyFormat.format(journal.totalDebit)}',
                      '₹${currencyFormat.format(journal.totalCredit)}',
                      isBold: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status Ribbon
          Positioned(
            top: 0,
            left: 0,
            child: _statusRibbon(_statusLabel(journal.status), statusColor),
          ),
        ],
      ),
    );
  }

  Widget _docInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRibbon(String label, Color color) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Fold behind card (left side)
          Positioned(
            left: 0,
            top: 48,
            child: _RibbonFold(color: color, isLeft: true),
          ),
          // Fold behind card (top side)
          Positioned(
            left: 48,
            top: 0,
            child: _RibbonFold(color: color, isLeft: false),
          ),
          // Main Ribbon Bar
          Positioned(
            top: 14,
            left: -24,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 110,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(BuildContext context, NumberFormat currencyFormat) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF3F3F3C),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: const Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Contact',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Debits',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Credits',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...journal.items.map((item) => _itemRow(context, item, currencyFormat)),
      ],
    );
  }

  Widget _itemRow(
    BuildContext context,
    ManualJournalItem item,
    NumberFormat currencyFormat,
  ) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.accountName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if ((item.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.contactName ?? '--',
                    style: TextStyle(
                      fontSize: 13,
                      color: (item.contactName ?? '').isNotEmpty
                          ? const Color(0xFF111827)
                          : const Color(0xFF111827).withValues(alpha: 0.4),
                      fontWeight: (item.contactName ?? '').isNotEmpty
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if ((item.contactName ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: () {
                        // Deep-link to Account Transactions Report filtered by contact
                        final startDateStr = DateFormat('yyyy-MM-dd').format(
                          journal.journalDate.subtract(
                            const Duration(days: 30),
                          ),
                        );
                        final endDateStr = DateFormat('yyyy-MM-dd').format(
                          journal.journalDate.add(const Duration(days: 30)),
                        );

                        final uri = Uri(
                          path: AppRoutes.accountantTransactionsReport,
                          queryParameters: {
                            'contactId': item.contactId,
                            'contactType': item.contactType?.toLowerCase(),
                            'accountName': item.contactName,
                            'startDate': startDateStr,
                            'endDate': endDateStr,
                          },
                        );
                        context.push(uri.toString());
                      },
                      child: Icon(
                        LucideIcons.history,
                        size: 14,
                        color: AppTheme.primaryBlue.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.debit > 0 ? currencyFormat.format(item.debit) : '',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.credit > 0 ? currencyFormat.format(item.credit) : '',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String debit,
    String credit, {
    bool isBold = false,
  }) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
      color: const Color(0xFF111827),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 7, // Matches Account(4) + Contact(3) from table
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: style.copyWith(
                  color: isBold
                      ? const Color(0xFF111827)
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(debit, textAlign: TextAlign.right, style: style),
          ),
          Expanded(
            flex: 2,
            child: Text(credit, textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }

  String _statusLabel(ManualJournalStatus status) {
    switch (status) {
      case ManualJournalStatus.posted:
        return 'Published';
      case ManualJournalStatus.cancelled:
        return 'Cancelled';
      case ManualJournalStatus.draft:
        return 'Draft';
    }
  }

  Color _statusColor(ManualJournalStatus status) {
    switch (status) {
      case ManualJournalStatus.posted:
        return const Color(0xFF1FB96D);
      case ManualJournalStatus.cancelled:
        return AppTheme.errorRed;
      case ManualJournalStatus.draft:
        return const Color(0xFFFF9900); // Standard Orange as seen in target
    }
  }

  void _handleClone(
    BuildContext context,
    WidgetRef ref,
    ManualJournal journal,
  ) async {
    try {
      final clonedJournal = await ref
          .read(manualJournalProvider.notifier)
          .cloneJournal(journal.id);
      if (!context.mounted) return;
      ZerpaiToast.success(context, 'Journal cloned successfully as Draft.');
      context.push(
        AppRoutes.accountantManualJournalsCreate,
        extra: clonedJournal,
      );
    } catch (e) {
      if (!context.mounted) return;
      final message = ErrorHandler.getFriendlyMessage(e);
      ZerpaiToast.error(context, message);
    }
  }

  void _handleCloneReverse(
    BuildContext context,
    WidgetRef ref,
    ManualJournal journal,
  ) async {
    try {
      final reversed = await ref
          .read(manualJournalProvider.notifier)
          .reverseJournal(journal.id);
      if (!context.mounted) return;
      ZerpaiToast.success(
        context,
        'Reversed journal created successfully as Draft.',
      );
      // Navigate to the newly created reversed journal
      context.go(
        AppRoutes.accountantManualJournalsDetail.replaceAll(':id', reversed.id),
      );
    } catch (e) {
      if (!context.mounted) return;
      final message = ErrorHandler.getFriendlyMessage(e);
      ZerpaiToast.error(context, message);
    }
  }

  void _handleCreateTemplate(
    BuildContext context,
    WidgetRef ref,
    ManualJournal journal,
  ) async {
    try {
      await ref
          .read(manualJournalProvider.notifier)
          .createTemplateFromJournal(journal.id);
      if (!context.mounted) return;
      ZerpaiToast.success(context, 'Template created successfully.');
    } catch (e) {
      if (!context.mounted) return;
      final message = ErrorHandler.getFriendlyMessage(e);
      ZerpaiToast.error(context, message);
    }
  }

  Widget _buildMoreInformation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'More Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 24),
        _moreInfoRow(
          'Journal Date',
          DateFormat('dd/MM/yyyy').format(journal.journalDate),
        ),
        const SizedBox(height: 12),
        _moreInfoRow(
          'Reporting Method',
          journal.reportingMethod
              .replaceAll('_', ' ')
              .split(' ')
              .map((s) => s[0].toUpperCase() + s.substring(1))
              .join(' ')
              .replaceAll('And', 'and'),
        ),
      ],
    );
  }

  Widget _moreInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ),
        Text(
          ': $value',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RibbonFold extends StatelessWidget {
  final Color color;
  final bool isLeft;

  const _RibbonFold({required this.color, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    final darkColor = Color.lerp(color, Colors.black, 0.3)!;
    return CustomPaint(
      size: const Size(8, 8),
      painter: _TrianglePainter(darkColor, isLeft: isLeft),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool isLeft;

  _TrianglePainter(this.color, {required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
