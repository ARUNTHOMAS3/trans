import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/app/routing/app_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/accountant/models/account_transaction_model.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/core/auth/capability_service.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

class AccountOverviewPanel extends ConsumerStatefulWidget {
  final AccountNode account;
  final VoidCallback? onClose;

  const AccountOverviewPanel({super.key, required this.account, this.onClose});

  @override
  ConsumerState<AccountOverviewPanel> createState() =>
      _AccountOverviewPanelState();
}

class _AccountOverviewPanelState extends ConsumerState<AccountOverviewPanel> {
  bool _showBcy = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chartOfAccountsProvider);
    final user = ref.watch(authUserProvider);
    final canEdit =
        user != null &&
        CapabilityService.canUserAction(
          user,
          'chart_of_accounts',
          action: 'edit',
        );
    final canDelete =
        user != null &&
        CapabilityService.canUserAction(
          user,
          'chart_of_accounts',
          action: 'delete',
        );
    final currencyFormat = NumberFormat.currency(
      symbol: '${widget.account.currency} ',
      decimalDigits: 2,
    );
    final orgDatePattern = ref.watch(orgDateFormatProvider);
    final dateFormat = DateFormat(orgDatePattern);

    void handleClose() {
      widget.onClose?.call();
      ref.read(chartOfAccountsProvider.notifier).clearSelection();
    }

    return Container(
      color: AppTheme.bgLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 92,
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chart of Accounts',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.account.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                ZTooltip(
                  message: 'Close account',
                  direction: ZTooltipDirection.bottom,
                  child: InkWell(
                    onTap: handleClose,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        color: AppTheme.errorRed,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space8,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                // Edit Button
                if (canEdit)
                  TextButton.icon(
                    onPressed: () {
                      final orgSystemId = GoRouterState.of(
                        context,
                      ).pathParameters['orgSystemId'];
                      final editPath =
                          (orgSystemId != null && orgSystemId.isNotEmpty)
                          ? '/$orgSystemId/accounts/chart-of-accounts/edit/${widget.account.id}'
                          : AppRoutes.accountsChartOfAccountsEdit.replaceAll(
                              ':id',
                              widget.account.id,
                            );
                      context.push(
                        editPath,
                        extra: {'account': widget.account},
                      );
                    },
                    icon: const Icon(LucideIcons.pencil, size: 14),
                    label: const Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                if (widget.account.isDeletable && (canEdit || canDelete)) ...[
                  const SizedBox(width: 4),
                  const SizedBox(
                    height: 20,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppTheme.borderLight,
                    ),
                  ),
                  const SizedBox(width: 4),

                  // More Button
                  PopupMenuButton<String>(
                    tooltip: 'More actions',
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    offset: const Offset(0, 32),
                    elevation: 6,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 190),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppTheme.borderLight),
                    ),
                    onSelected: (value) async {
                      if (value == 'inactive') {
                        try {
                          await ref
                              .read(chartOfAccountsProvider.notifier)
                              .updateAccountStatus(
                                widget.account.id,
                                !widget.account.isActive,
                              );
                          if (context.mounted) {
                            ZerpaiToast.success(
                              context,
                              'Account marked as ${widget.account.isActive ? 'Inactive' : 'Active'}',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ZerpaiToast.error(context, 'Error: $e');
                          }
                        }
                      } else if (value == 'delete') {
                        final confirmed = await showZerpaiConfirmationDialog(
                          context,
                          title: 'Delete Account',
                          message:
                              'Are you sure you want to delete "${widget.account.name}"? This action cannot be undone.',
                          confirmLabel: 'Delete',
                          cancelLabel: 'Cancel',
                          variant: ZerpaiConfirmationVariant.danger,
                        );

                        if (confirmed == true) {
                          try {
                            await ref
                                .read(chartOfAccountsProvider.notifier)
                                .deleteAccount(widget.account.id);
                            if (context.mounted) {
                              ZerpaiToast.deleted(context, 'Account');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ZerpaiToast.error(context, 'Error: $e');
                            }
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      if (canEdit)
                        PopupMenuItem<String>(
                          value: 'inactive',
                          padding: EdgeInsets.zero,
                          height: 48,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  widget.account.isActive
                                      ? LucideIcons.minusCircle
                                      : LucideIcons.checkCircle,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  widget.account.isActive
                                      ? 'Mark as Inactive'
                                      : 'Mark as Active',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (canDelete)
                        PopupMenuItem<String>(
                          value: 'delete',
                          padding: EdgeInsets.zero,
                          height: 48,
                          enabled: widget.account.isDeletable,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            height: 48,
                            color: Colors.white,
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.trash2,
                                  color: widget.account.isDeletable
                                      ? AppTheme.primaryBlue
                                      : Colors.grey.withAlpha(128),
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: widget.account.isDeletable
                                        ? AppTheme.textPrimary
                                        : Colors.grey.withAlpha(128),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        LucideIcons.moreHorizontal,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),
                  const SizedBox(
                    height: 20,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppTheme.borderLight,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Closing Balance Section
          Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Closing Balance',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      currencyFormat.format(state.closingBalance),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space4),
                    Text(
                      '(${state.closingBalanceType})',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description : ',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.account.description?.isNotEmpty == true
                            ? widget.account.description!
                            : '--',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            child: DottedBorder(
              color: AppTheme.primaryBlue.withAlpha(76),
              strokeWidth: 1,
              dashPattern: const [4, 2],
              padding: EdgeInsets.zero,
              child: const SizedBox(width: double.infinity, height: 0),
            ),
          ),

          _buildBalanceTrend(state),
          const SizedBox(height: AppTheme.space8),

          // Recent Transactions Section
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: AppTheme.primaryBlue.withAlpha(128),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _showBcy = false),
                        child: _CurrencyToggleItem('FCY', !_showBcy),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showBcy = true),
                        child: _CurrencyToggleItem('BCY', _showBcy),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Transactions Table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              child: state.recentTransactions.isEmpty
                  ? _buildEmptyState()
                  : _buildTransactionsTable(
                      state.recentTransactions,
                      dateFormat,
                      showBcy: _showBcy,
                    ),
            ),
          ),

          // Footer Link
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: InkWell(
              onTap: () {
                final uri = Uri.parse(AppRoutes.accountantTransactionsReport)
                    .replace(
                      queryParameters: {
                        'accountId': widget.account.id,
                        'accountName': widget.account.name,
                      },
                    );
                context.push(uri.toString());
              },
              child: const Text(
                'Show more details',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceTrend(ChartOfAccountsState state) {
    if (state.recentTransactions.isEmpty) return const SizedBox.shrink();

    double currentBal = state.closingBalance;
    final txs = state.recentTransactions.take(12).toList();
    final List<double> points = <double>[currentBal];

    for (int i = 0; i < txs.length; i++) {
      final tx = txs[i];
      final amount = tx.debit - tx.credit;
      currentBal -= amount;
      points.add(currentBal);
    }

    final normalized = points.reversed.toList();
    final minY = normalized.reduce((a, b) => a < b ? a : b);
    final maxY = normalized.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs() < 0.0001 ? 1.0 : (maxY - minY);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance Trend',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
            child: CustomPaint(
              painter: _MiniTrendPainter(
                values: normalized,
                minY: minY,
                rangeY: range,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTransactionType(String? rawType) {
    final value = (rawType ?? '').trim();
    if (value.isEmpty) return '--';
    final normalized = value.replaceAll(RegExp(r'[_-]+'), ' ');
    return normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(LucideIcons.receipt, size: 48, color: AppTheme.bgDisabled),
          SizedBox(height: 16),
          Text(
            'There are no transactions available',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTable(
    List<AccountTransaction> txs,
    DateFormat df, {
    required bool showBcy,
  }) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: const [
              Expanded(flex: 2, child: _TableHeaderCell('DATE')),
              Expanded(flex: 3, child: _TableHeaderCell('TRANSACTION DETAILS')),
              Expanded(flex: 2, child: _TableHeaderCell('TYPE')),
              Expanded(
                flex: 2,
                child: _TableHeaderCell('DEBIT', align: TextAlign.right),
              ),
              Expanded(
                flex: 2,
                child: _TableHeaderCell('CREDIT', align: TextAlign.right),
              ),
            ],
          ),
        ),
        // Rows
        Expanded(
          child: ListView.separated(
            itemCount: txs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tx = txs[index];
              final debit = showBcy ? tx.bcyDebit : tx.debit;
              final credit = showBcy ? tx.bcyCredit : tx.credit;
              final currencyCode = showBcy
                  ? tx.bcyCurrencyCode
                  : tx.currencyCode;
              String formatAmount(double? value) {
                if (value == null || currencyCode == null) return '--';
                return '$currencyCode ${value.toStringAsFixed(2)}';
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        df.format(tx.transactionDate),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        tx.description?.isNotEmpty == true
                            ? tx.description!
                            : '--',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatTransactionType(tx.transactionType),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatAmount(debit),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatAmount(credit),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniTrendPainter extends CustomPainter {
  final List<double> values;
  final double minY;
  final double rangeY;

  _MiniTrendPainter({
    required this.values,
    required this.minY,
    required this.rangeY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final linePaint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppTheme.primaryBlue.withAlpha(20)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalizedY = (values[i] - minY) / rangeY;
      final y = (1 - normalizedY) * (size.height - 8) + 4;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      if (i == values.length - 1) {
        fillPath.lineTo(x, size.height);
      }
    }

    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.minY != minY ||
        oldDelegate.rangeY != rangeY;
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String label;
  final TextAlign align;

  const _TableHeaderCell(this.label, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: align,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _CurrencyToggleItem extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _CurrencyToggleItem(this.label, this.isSelected);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(isSelected ? 3 : 0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : AppTheme.primaryBlue,
        ),
      ),
    );
  }
}
