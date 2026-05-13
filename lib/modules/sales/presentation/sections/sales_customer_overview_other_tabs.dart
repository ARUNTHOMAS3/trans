part of '../sales_customer_overview.dart';

extension _OverviewOtherTabs on _SalesCustomerOverviewScreenState {
  Widget _buildComments(
    SalesCustomer customer,
    SalesCustomerDetailContext? detailContext,
  ) {
    final comments = detailContext?.comments ?? const <CustomerCommentEntry>[];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: comments.isEmpty
          ? _buildCenteredEmptyState(
              title: 'No comments available',
              message:
                  'No schema-backed customer comments are available for this customer yet.',
            )
          : ListView.separated(
              itemCount: comments.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final comment = comments[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFE5E7EB),
                        child: Text(
                          comment.author.isNotEmpty
                              ? comment.author.substring(0, 1).toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.author,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              comment.body,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF374151),
                              ),
                            ),
                            if (comment.createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd-MM-yyyy hh:mm a')
                                    .format(comment.createdAt!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTransactions(
    SalesCustomer customer,
    SalesCustomerDetailContext? detailContext,
  ) {
    final groups =
        detailContext?.transactions ?? const <CustomerTransactionGroup>[];

    return groups.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(24),
            child: _buildCenteredEmptyState(
              title: 'No transaction data available',
              message:
                  'No customer transaction sources are available for this record yet.',
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: groups.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final group = groups[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Text(
                      group.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    subtitle: Text(
                      '${group.count} record${group.count == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    leading: const Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                    children: [
                      if (group.items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No ${group.label.toLowerCase()} found for this customer.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        )
                      else
                        ...group.items.map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.number,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    item.status,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    _formatAmount(item.amount),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    item.date != null
                                        ? DateFormat('dd-MM-yyyy hh:mm a')
                                            .format(item.date!)
                                        : '-',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildMails(
    SalesCustomer customer,
    SalesCustomerDetailContext? detailContext,
  ) {
    final mails = detailContext?.mails ?? const <CustomerMailEntry>[];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: mails.isEmpty
          ? _buildCenteredEmptyState(
              title: 'No mail activity available',
              message:
                  'No schema-backed customer mail activity is available for this customer yet.',
            )
          : ListView.separated(
              itemCount: mails.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final mail = mails[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFFF3F4F6),
                        child: Icon(
                          LucideIcons.mail,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To: ${mail.to}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mail.subject,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            mail.status,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          if (mail.sentAt != null)
                            Text(
                              DateFormat('dd-MM-yyyy hh:mm a')
                                  .format(mail.sentAt!),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatement(
    SalesCustomer customer,
    SalesCustomerDetailContext? detailContext,
  ) {
    final statementEntries =
        detailContext?.statementEntries ?? const <CustomerStatementEntry>[];
    final totalDebit = statementEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.debit,
    );
    final totalCredit = statementEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.credit,
    );
    final double closingBalance =
        statementEntries.isNotEmpty ? statementEntries.last.balance : 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Text(
                'Statement for ${customer.displayName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: statementEntries.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildCenteredEmptyState(
                    title: 'No statement activity available',
                    message:
                        'No invoice, credit note, payment, or opening-balance entries are available for this customer yet.',
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _statementSummaryCard(
                              'Total Debits',
                              _formatAmount(totalDebit),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statementSummaryCard(
                              'Total Credits',
                              _formatAmount(totalCredit),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statementSummaryCard(
                              'Closing Balance',
                              _formatAmount(closingBalance),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: FixedColumnWidth(110),
                            1: FlexColumnWidth(1.1),
                            2: FlexColumnWidth(1.5),
                            3: FixedColumnWidth(110),
                            4: FixedColumnWidth(110),
                            5: FixedColumnWidth(120),
                          },
                          border: const TableBorder(
                            horizontalInside: BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(
                                color: Color(0xFFF9FAFB),
                              ),
                              children: [
                                TableCellWidget('Date', isHeader: true),
                                TableCellWidget('Type', isHeader: true),
                                TableCellWidget('Details', isHeader: true),
                                TableCellWidget(
                                  'Debit',
                                  isHeader: true,
                                  align: TextAlign.right,
                                ),
                                TableCellWidget(
                                  'Credit',
                                  isHeader: true,
                                  align: TextAlign.right,
                                ),
                                TableCellWidget(
                                  'Balance',
                                  isHeader: true,
                                  align: TextAlign.right,
                                ),
                              ],
                            ),
                            ...statementEntries.map(
                              (entry) => TableRow(
                                children: [
                                  TableCellWidget(
                                    entry.date != null
                                        ? DateFormat('dd-MM-yyyy')
                                            .format(entry.date!)
                                        : '-',
                                  ),
                                  TableCellWidget(entry.type),
                                  TableCellWidget(
                                    entry.reference?.isNotEmpty == true
                                        ? '${entry.number}\n${entry.reference}'
                                        : entry.number,
                                  ),
                                  TableCellWidget(
                                    entry.debit == 0
                                        ? '-'
                                        : _formatAmount(entry.debit),
                                    align: TextAlign.right,
                                  ),
                                  TableCellWidget(
                                    entry.credit == 0
                                        ? '-'
                                        : _formatAmount(entry.credit),
                                    align: TextAlign.right,
                                  ),
                                  TableCellWidget(
                                    _formatAmount(entry.balance),
                                    align: TextAlign.right,
                                  ),
                                ],
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

  Widget _buildCenteredEmptyState({
    required String title,
    required String message,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.inbox,
              size: 28,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statementSummaryCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }
}
