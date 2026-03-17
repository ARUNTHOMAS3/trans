import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/accountant_chart_of_accounts_account_model.dart';
import '../../providers/accountant_chart_of_accounts_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/utils/zerpai_toast.dart';
import '../../models/account_transaction_model.dart';
import 'package:fl_chart/fl_chart.dart';

class AccountOverviewPanel extends ConsumerStatefulWidget {
  final AccountNode account;
  final VoidCallback? onClose;

  const AccountOverviewPanel({super.key, required this.account, this.onClose});

  @override
  ConsumerState<AccountOverviewPanel> createState() =>
      _AccountOverviewPanelState();
}

class _AccountOverviewPanelState extends ConsumerState<AccountOverviewPanel> {
  List<PlatformFile> _attachments = [];
  bool _showBcy = true;

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(result.files);
        });

        if (mounted) {
          ZerpaiToast.success(context, 'Added ${result.files.length} file(s)');
        }
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error picking files: $e');
      }
    }
  }

  void _removeAttachment(PlatformFile file) {
    setState(() {
      _attachments.remove(file);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chartOfAccountsProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd-MM-yyyy');

    void handleClose() {
      widget.onClose?.call();
      ref.read(chartOfAccountsProvider.notifier).clearSelection();
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space8,
              AppTheme.space8,
              AppTheme.space8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.account.accountGroup,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        widget.account.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Ink(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(4),
                    color: AppTheme.bgLight,
                  ),
                  child: InkWell(
                    onTap: _pickFiles,
                    borderRadius: BorderRadius.circular(4),
                    child: const Icon(
                      LucideIcons.paperclip,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                IconButton(
                  onPressed: handleClose,
                  icon: const Icon(
                    LucideIcons.x,
                    color: AppTheme.errorRed,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),

          // Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space4,
            ),
            child: Row(
              children: [
                // Edit Button
                TextButton.icon(
                  onPressed: () {
                    context.push(
                      AppRoutes.accountsChartOfAccountsCreate,
                      extra: {'account': widget.account},
                    );
                  },
                  icon: const Icon(LucideIcons.pencil, size: 14),
                  label: const Text(
                    'Edit',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                if (widget.account.isDeletable) ...[
                  const SizedBox(width: 4),
                  const SizedBox(
                    height: 20,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
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
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            surfaceTintColor: Colors.white,
                            title: const Text('Delete Account'),
                            content: Text(
                              'Are you sure you want to delete "${widget.account.name}"? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.errorRed,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          try {
                            await ref
                                .read(chartOfAccountsProvider.notifier)
                                .deleteAccount(widget.account.id);
                            if (context.mounted) {
                              ZerpaiToast.success(
                                context,
                                'Account deleted successfully',
                              );
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
                        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),

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

          // Attachments Section
          if (_attachments.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attachments',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _attachments.map((file) {
                      return Chip(
                        label: Text(
                          file.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(LucideIcons.x, size: 14),
                        onDeleted: () => _removeAttachment(file),
                        backgroundColor: AppTheme.bgLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: AppTheme.borderColor),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppTheme.space24),
                ],
              ),
            ),
          ],

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
                      currencyFormat,
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

    // Mock trend based on recent transactions (reverse them for chronological order)
    double currentBal = state.closingBalance;
    final List<FlSpot> spots = [];
    final txs = state.recentTransactions.take(12).toList();
    
    // Last spot is the current balance
    spots.add(FlSpot(txs.length.toDouble(), currentBal));
    
    for (int i = 0; i < txs.length; i++) {
      final tx = txs[i];
      final amount = tx.debit - tx.credit;
      currentBal -= amount;
      spots.add(FlSpot((txs.length - 1 - i).toDouble(), currentBal));
    }

    final sortedSpots = spots..sort((a, b) => a.x.compareTo(b.x));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: 8),
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
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: sortedSpots,
                    isCurved: true,
                    color: AppTheme.primaryBlue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryBlue.withAlpha(20),
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
    DateFormat df,
    NumberFormat nf, {
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
              
              // Determine which currency symbol to show
              String symbol = '₹';
              if (!showBcy && tx.currencyCode != null) {
                // In a real app, we'd map currencyCode to symbols, 
                // for now we'll use the code itself if not BCY
                symbol = tx.currencyCode! == 'INR' ? '₹' : '${tx.currencyCode} ';
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
                        tx.transactionType ?? '--',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        debit > 0 ? (showBcy ? nf.format(debit) : '$symbol${debit.toStringAsFixed(2)}') : '',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        credit > 0 ? (showBcy ? nf.format(credit) : '$symbol${credit.toStringAsFixed(2)}') : '',
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
