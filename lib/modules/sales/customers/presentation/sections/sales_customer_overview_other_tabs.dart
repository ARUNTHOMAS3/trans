part of '../pages/sales_customer_overview.dart';

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
                                DateFormat(
                                  'dd-MM-yyyy hh:mm a',
                                ).format(comment.createdAt!),
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

    return _CustomerTransactionsSectionWidget(
      customer: customer,
      orgSystemId: _orgSystemId,
      groups: groups,
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
                              DateFormat(
                                'dd-MM-yyyy hh:mm a',
                              ).format(mail.sentAt!),
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
    final double closingBalance = statementEntries.isNotEmpty
        ? statementEntries.last.balance
        : 0;

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
                                        ? DateFormat(
                                            'dd-MM-yyyy',
                                          ).format(entry.date!)
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
            const Icon(LucideIcons.inbox, size: 28, color: Color(0xFF9CA3AF)),
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

class _CustomerTransactionsSectionWidget extends StatefulWidget {
  final SalesCustomer customer;
  final String orgSystemId;
  final List<CustomerTransactionGroup> groups;

  const _CustomerTransactionsSectionWidget({
    required this.customer,
    required this.orgSystemId,
    required this.groups,
  });

  @override
  State<_CustomerTransactionsSectionWidget> createState() =>
      __CustomerTransactionsSectionWidgetState();
}

class __CustomerTransactionsSectionWidgetState
    extends State<_CustomerTransactionsSectionWidget> {
  final Map<String, bool> _expanded = {};
  final Map<String, String> _statusFilters = {};
  final Map<String, int> _pages = {};
  final Map<String, int?> _sortCol = {};
  final Map<String, bool> _sortAsc = {};

  String _formatCurrency(double amount) {
    return '₹${NumberFormat('#,##0.00', 'en_IN').format(amount)}';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd-MM-yyyy').format(dt);
  }

  Widget _buildStatusBadge(String status) {
    final lower = status.toLowerCase();
    Color textColor = const Color(0xFF374151);
    Color bgColor = const Color(0xFFF3F4F6);

    if (lower == 'paid' || lower == 'recorded' || lower == 'completed') {
      textColor = const Color(0xFF16A34A);
      bgColor = const Color(0xFFDCFCE7);
    } else if (lower == 'sent' || lower == 'open' || lower == 'issued') {
      textColor = const Color(0xFF2563EB);
      bgColor = const Color(0xFFDBEAFE);
    } else if (lower == 'draft') {
      textColor = const Color(0xFF4B5563);
      bgColor = const Color(0xFFF3F4F6);
    } else if (lower == 'void' || lower == 'cancelled' || lower == 'overdue') {
      textColor = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEE2E2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  void _onHeaderTap(String groupKey, int colIndex) {
    setState(() {
      if (_sortCol[groupKey] == colIndex) {
        _sortAsc[groupKey] = !(_sortAsc[groupKey] ?? true);
      } else {
        _sortCol[groupKey] = colIndex;
        _sortAsc[groupKey] = true;
      }
    });
  }

  dynamic _getColValue(String groupKey, CustomerTransactionItem item, int col) {
    if (groupKey == 'invoice') {
      switch (col) {
        case 0: return item.date;
        case 1: return item.location ?? 'Central Logistics Hub';
        case 2: return item.number;
        case 3: return item.orderNumber ?? '';
        case 4: return item.amount;
        case 5: return item.balanceDue ?? item.amount;
        case 6: return item.status;
      }
    } else if (groupKey == 'payment') {
      switch (col) {
        case 0: return item.date;
        case 1: return item.location ?? 'Central Logistics Hub';
        case 2: return item.number;
        case 3: return item.referenceNumber ?? '';
        case 4: return item.paymentMode ?? '';
        case 5: return item.amount;
        case 6: return item.unusedAmount ?? 0;
        case 7: return item.status;
      }
    } else if (groupKey == 'retainer_invoice') {
      switch (col) {
        case 0: return item.date;
        case 1: return item.location ?? 'Central Logistics Hub';
        case 2: return item.number;
        case 3: return item.referenceNumber ?? '';
        case 4: return item.amount;
        case 5: return item.balanceDue ?? item.amount;
        case 6: return item.status;
      }
    } else if (groupKey == 'order') {
      switch (col) {
        case 0: return item.number;
        case 1: return item.location ?? 'Central Logistics Hub';
        case 2: return item.referenceNumber ?? '';
        case 3: return item.date;
        case 4: return item.shipmentDate ?? item.date;
        case 5: return item.amount;
        case 6: return item.status;
      }
    } else if (groupKey == 'package') {
      switch (col) {
        case 0: return item.number;
        case 1: return item.orderNumber ?? '';
        case 2: return item.date;
        case 3: return item.trackingNumber ?? '';
        case 4: return item.status;
      }
    } else if (groupKey == 'shipment') {
      switch (col) {
        case 0: return item.number;
        case 1: return item.orderNumber ?? '';
        case 2: return item.date;
        case 3: return item.trackingNumber ?? '';
        case 4: return item.status;
      }
    } else if (groupKey == 'challan') {
      switch (col) {
        case 0: return item.number;
        case 1: return item.location ?? 'Central Logistics Hub';
        case 2: return item.referenceNumber ?? '';
        case 3: return item.date;
        case 4: return item.amount;
        case 5: return item.status;
      }
    } else if (groupKey == 'bill') {
      switch (col) {
        case 0: return item.date;
        case 1: return item.location ?? 'Central Logistics Hub';
        case 2: return item.number;
        case 3: return item.orderNumber ?? '';
        case 4: return item.vendorName ?? '';
        case 5: return item.amount;
        case 6: return item.lineItemsTotal ?? item.amount;
        case 7: return item.balanceDue ?? item.amount;
        case 8: return item.status;
      }
    } else if (groupKey == 'credit_note') {
      switch (col) {
        case 0: return item.date;
        case 1: return item.location ?? 'Central Logistics Hub';
        case 2: return item.number;
        case 3: return item.referenceNumber ?? '';
        case 4: return item.balanceDue ?? item.amount;
        case 5: return item.amount;
        case 6: return item.status;
      }
    }
    switch (col) {
      case 0: return item.date;
      case 1: return item.location ?? 'Central Logistics Hub';
      case 2: return item.number;
      case 3: return item.referenceNumber ?? '';
      case 4: return item.amount;
      case 5: return item.status;
      default: return item.number;
    }
  }

  List<CustomerTransactionItem> _sortItems(
      String groupKey, List<CustomerTransactionItem> items) {
    final col = _sortCol[groupKey];
    if (col == null) return items;
    final asc = _sortAsc[groupKey] ?? true;

    final sorted = List<CustomerTransactionItem>.from(items);
    sorted.sort((a, b) {
      dynamic valA = _getColValue(groupKey, a, col);
      dynamic valB = _getColValue(groupKey, b, col);
      if (valA == null && valB == null) return 0;
      if (valA == null) return asc ? -1 : 1;
      if (valB == null) return asc ? 1 : -1;
      int cmp = 0;
      if (valA is Comparable && valB is Comparable) {
        cmp = valA.compareTo(valB);
      } else {
        cmp = valA.toString().compareTo(valB.toString());
      }
      return asc ? cmp : -cmp;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No transaction data available for this customer.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: widget.groups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final group = widget.groups[index];
        final isExpanded = _expanded[group.key] ?? true;
        final selectedStatus = _statusFilters[group.key] ?? 'All';

        // Unique statuses for filter dropdown
        final allStatuses = ['All'];
        for (final item in group.items) {
          if (item.status.isNotEmpty && !allStatuses.contains(item.status)) {
            allStatuses.add(item.status);
          }
        }

        // Filtered items
        final filteredItems = selectedStatus == 'All'
            ? group.items
            : group.items.where((i) => i.status == selectedStatus).toList();

        // Sorted items
        final sortedItems = _sortItems(group.key, filteredItems);

        // 10 items per page
        const itemsPerPage = 10;
        final totalItems = sortedItems.length;
        final totalPages = math.max(1, (totalItems / itemsPerPage).ceil());
        final page = (_pages[group.key] ?? 1).clamp(1, totalPages);

        final startIndex = totalItems == 0 ? 0 : (page - 1) * itemsPerPage;
        final endIndex = math.min(startIndex + itemsPerPage, totalItems);
        final pageItems = totalItems == 0
            ? <CustomerTransactionItem>[]
            : sortedItems.sublist(startIndex, endIndex);

        final rangeText = totalItems == 0
            ? '0 - 0'
            : '${startIndex + 1} - $endIndex';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: isExpanded
                      ? const BorderRadius.vertical(top: Radius.circular(6))
                      : BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    // Expand/Collapse Toggle
                    InkWell(
                      onTap: () => setState(() {
                        _expanded[group.key] = !isExpanded;
                      }),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpanded
                                ? LucideIcons.chevronDown
                                : LucideIcons.chevronRight,
                            size: 16,
                            color: const Color(0xFF4B5563),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            group.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Status Filter Dropdown
                    PopupMenuButton<String>(
                      initialValue: selectedStatus,
                      onSelected: (val) {
                        setState(() {
                          _statusFilters[group.key] = val;
                          _pages[group.key] = 1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.filter,
                              size: 13,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Status: $selectedStatus',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              LucideIcons.chevronDown,
                              size: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => allStatuses
                          .map(
                            (s) => PopupMenuItem<String>(
                              value: s,
                              height: 32,
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: s == selectedStatus
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: s == selectedStatus
                                      ? AppTheme.primaryBlue
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(width: 12),
                    // New Button
                    InkWell(
                      onTap: () => _navigateToCreate(group.key),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.plus,
                              size: 13,
                              color: AppTheme.primaryBlue,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'New',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Table Body & Footer
              if (isExpanded) ...[
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _buildTableForGroup(group.key, pageItems, group.label),

                // Footer Pagination Bar
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Total Count: $totalItems',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const Spacer(),
                      // Pagination controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: page > 1
                                  ? () => setState(
                                        () => _pages[group.key] = page - 1,
                                      )
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Icon(
                                  LucideIcons.chevronLeft,
                                  size: 14,
                                  color: page > 1
                                      ? const Color(0xFF374151)
                                      : const Color(0xFFD1D5DB),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                rangeText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: page < totalPages
                                  ? () => setState(
                                        () => _pages[group.key] = page + 1,
                                      )
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Icon(
                                  LucideIcons.chevronRight,
                                  size: 14,
                                  color: page < totalPages
                                      ? const Color(0xFF374151)
                                      : const Color(0xFFD1D5DB),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _navigateToCreate(String groupKey) {
    final orgId = widget.orgSystemId;
    final customerId = widget.customer.id;

    if (groupKey == 'invoice') {
      context.go('/$orgId/sales/invoices/create?customerId=$customerId');
    } else if (groupKey == 'payment') {
      context.go('/$orgId/sales/payments-received/create?customerId=$customerId');
    } else if (groupKey == 'retainer_invoice') {
      context.go('/$orgId/sales/retainer-invoices/create?customerId=$customerId');
    } else if (groupKey == 'order') {
      context.go('/$orgId/sales/orders/create?customerId=$customerId');
    } else if (groupKey == 'challan') {
      context.go('/$orgId/sales/delivery-challans/create?customerId=$customerId');
    } else if (groupKey == 'credit_note') {
      context.go('/$orgId/sales/credit-notes/create?customerId=$customerId');
    } else {
      context.go('/$orgId/sales/invoices/create?customerId=$customerId');
    }
  }

  Widget _buildTableForGroup(
    String groupKey,
    List<CustomerTransactionItem> items,
    String groupLabel,
  ) {
    if (groupKey == 'invoice') {
      return _buildInvoicesTable(groupKey, items, groupLabel);
    } else if (groupKey == 'payment') {
      return _buildPaymentsTable(groupKey, items, groupLabel);
    } else if (groupKey == 'retainer_invoice') {
      return _buildRetainerInvoicesTable(groupKey, items, groupLabel);
    } else if (groupKey == 'order') {
      return _buildSalesOrdersTable(groupKey, items, groupLabel);
    } else if (groupKey == 'package') {
      return _buildPackagesTable(groupKey, items, groupLabel);
    } else if (groupKey == 'shipment') {
      return _buildShipmentsTable(groupKey, items, groupLabel);
    } else if (groupKey == 'challan') {
      return _buildChallansTable(groupKey, items, groupLabel);
    } else if (groupKey == 'bill') {
      return _buildBillsTable(groupKey, items, groupLabel);
    } else if (groupKey == 'credit_note') {
      return _buildCreditNotesTable(groupKey, items, groupLabel);
    } else {
      return _buildGenericTable(groupKey, items, groupLabel);
    }
  }

  Widget _buildTableHeader(String groupKey, List<String> titles, List<int> flexes) {
    final currentSortCol = _sortCol[groupKey];

    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(titles.length, (i) {
          final isSorted = currentSortCol == i;
          return Expanded(
            flex: flexes[i],
            child: InkWell(
              onTap: () => _onHeaderTap(groupKey, i),
              child: Center(
                child: Text(
                  titles[i],
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSorted
                        ? AppTheme.primaryBlue
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // 1. Invoices Table: DATE, WAREHOUSE, INVOICE NUMBER, ORDER NUMBER, AMOUNT, BALANCE DUE, STATUS
  Widget _buildInvoicesTable(String groupKey, List<CustomerTransactionItem> items, String groupLabel) {
    final titles = [
      'DATE',
      'WAREHOUSE',
      'INVOICE NUMBER',
      'ORDER NUMBER',
      'AMOUNT',
      'BALANCE DUE',
      'STATUS',
    ];
    final flexes = [2, 3, 3, 2, 2, 2, 2];

    return Column(
      children: [
        _buildTableHeader(groupKey, titles, flexes),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No ${groupLabel.toLowerCase()} found for this customer.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          )
        else
          ...items.map((item) {
            final warehouse = item.location?.isNotEmpty == true
                ? item.location!
                : 'Central Logistics Hub';
            final orderNum = item.orderNumber?.isNotEmpty == true
                ? item.orderNumber!
                : '-';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: flexes[0],
                    child: Center(
                      child: Text(
                        _formatDate(item.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[1],
                    child: Center(
                      child: Text(
                        warehouse,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[2],
                    child: Center(
                      child: InkWell(
                        onTap: () {
                          context.go('/${widget.orgSystemId}/sales/invoices/create');
                        },
                        child: Text(
                          item.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[3],
                    child: Center(
                      child: Text(
                        orderNum,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[4],
                    child: Center(
                      child: Text(
                        _formatCurrency(item.amount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[5],
                    child: Center(
                      child: Text(
                        _formatCurrency(item.balanceDue ?? item.amount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[6],
                    child: Center(
                      child: _buildStatusBadge(item.status),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // 2. Customer Payments Table: DATE, WAREHOUSE, PAYMENT NUMBER, REFERENCE NUMBER, PAYMENT MODE, AMOUNT, UNUSED AMOUNT, STATUS
  Widget _buildPaymentsTable(String groupKey, List<CustomerTransactionItem> items, String groupLabel) {
    final titles = [
      'DATE',
      'WAREHOUSE',
      'PAYMENT NUMBER',
      'REFERENCE NUMBER',
      'PAYMENT MODE',
      'AMOUNT',
      'UNUSED AMOUNT',
      'STATUS',
    ];
    final flexes = [2, 3, 3, 2, 2, 2, 2, 2];

    return Column(
      children: [
        _buildTableHeader(groupKey, titles, flexes),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No ${groupLabel.toLowerCase()} found for this customer.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          )
        else
          ...items.map((item) {
            final warehouse = item.location?.isNotEmpty == true
                ? item.location!
                : 'Central Logistics Hub';
            final refNum = item.referenceNumber?.isNotEmpty == true
                ? item.referenceNumber!
                : '-';
            final mode = item.paymentMode?.isNotEmpty == true
                ? item.paymentMode!
                : 'Cash';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: flexes[0],
                    child: Center(
                      child: Text(
                        _formatDate(item.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[1],
                    child: Center(
                      child: Text(
                        warehouse,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[2],
                    child: Center(
                      child: InkWell(
                        onTap: () {
                          context.go(
                            '/${widget.orgSystemId}/sales/payments-received/create',
                          );
                        },
                        child: Text(
                          item.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[3],
                    child: Center(
                      child: Text(
                        refNum,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[4],
                    child: Center(
                      child: Text(
                        mode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[5],
                    child: Center(
                      child: Text(
                        _formatCurrency(item.amount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[6],
                    child: Center(
                      child: Text(
                        _formatCurrency(item.unusedAmount ?? 0),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[7],
                    child: Center(
                      child: _buildStatusBadge(item.status),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // 3. Retainer Invoices Table: DATE, WAREHOUSE, RETAINER INVOICE NUMBER, REFERENCE NUMBER, AMOUNT, BALANCE DUE, STATUS
  Widget _buildRetainerInvoicesTable(String groupKey, List<CustomerTransactionItem> items, String groupLabel) {
    final titles = [
      'DATE',
      'WAREHOUSE',
      'RETAINER INVOICE NUMBER',
      'REFERENCE NUMBER',
      'AMOUNT',
      'BALANCE DUE',
      'STATUS',
    ];
    final flexes = [2, 3, 3, 2, 2, 2, 2];

    return Column(
      children: [
        _buildTableHeader(groupKey, titles, flexes),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No ${groupLabel.toLowerCase()} found for this customer.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          )
        else
          ...items.map((item) {
            final warehouse = item.location?.isNotEmpty == true
                ? item.location!
                : 'Central Logistics Hub';
            final refNum = item.referenceNumber?.isNotEmpty == true
                ? item.referenceNumber!
                : '-';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: flexes[0],
                    child: Center(
                      child: Text(
                        _formatDate(item.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[1],
                    child: Center(
                      child: Text(
                        warehouse,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[2],
                    child: Center(
                      child: InkWell(
                        onTap: () {
                          context.go(
                            '/${widget.orgSystemId}/sales/retainer-invoices/create',
                          );
                        },
                        child: Text(
                          item.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[3],
                    child: Center(
                      child: Text(
                        refNum,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[4],
                    child: Center(
                      child: Text(
                        _formatCurrency(item.amount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[5],
                    child: Center(
                      child: Text(
                        _formatCurrency(item.balanceDue ?? item.amount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[6],
                    child: Center(
                      child: _buildStatusBadge(item.status),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // 4. Sales Orders Table: SALES ORDER, WAREHOUSE, REFERENCE NUMBER, DATE, SHIPMENT DATE, AMOUNT, STATUS
  Widget _buildSalesOrdersTable(String groupKey, List<CustomerTransactionItem> items, String groupLabel) {
    final titles = [
      'SALES ORDER',
      'WAREHOUSE',
      'REFERENCE NUMBER',
      'DATE',
      'SHIPMENT DATE',
      'AMOUNT',
      'STATUS',
    ];
    final flexes = [3, 3, 2, 2, 2, 2, 2];

    return Column(
      children: [
        _buildTableHeader(groupKey, titles, flexes),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No ${groupLabel.toLowerCase()} found for this customer.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          )
        else
          ...items.map((item) {
            final warehouse = item.location?.isNotEmpty == true
                ? item.location!
                : 'Central Logistics Hub';
            final refNum = item.referenceNumber?.isNotEmpty == true
                ? item.referenceNumber!
                : '-';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: flexes[0],
                    child: Center(
                      child: Text(
                        item.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[1],
                    child: Center(
                      child: Text(
                        warehouse,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[2],
                    child: Center(
                      child: Text(
                        refNum,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[3],
                    child: Center(
                      child: Text(
                        _formatDate(item.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[4],
                    child: Center(
                      child: Text(
                        _formatDate(item.shipmentDate ?? item.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[5],
                    child: Center(
                      child: Text(
                        _formatCurrency(item.amount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[6],
                    child: Center(
                      child: _buildStatusBadge(item.status),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // 5. Packages Table: PACKAGE, SALES ORDER, DATE, TRACKING#, STATUS
  Widget _buildPackagesTable(String groupKey, List<CustomerTransactionItem> items, String groupLabel) {
    final titles = [
      'PACKAGE',
      'SALES ORDER',
      'DATE',
      'TRACKING#',
      'STATUS',
    ];
    final flexes = [3, 3, 2, 2, 2];

    return Column(
      children: [
        _buildTableHeader(groupKey, titles, flexes),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No ${groupLabel.toLowerCase()} found for this customer.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          )
        else
          ...items.map((item) {
            final orderNum = item.orderNumber?.isNotEmpty == true ? item.orderNumber! : '-';
            final tracking = item.trackingNumber?.isNotEmpty == true ? item.trackingNumber! : '-';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: flexes[0],
                    child: Center(
                      child: Text(
                        item.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[1],
                    child: Center(
                      child: Text(
                        orderNum,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[2],
                    child: Center(
                      child: Text(
                        _formatDate(item.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[3],
                    child: Center(
                      child: Text(
                        tracking,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[4],
                    child: Center(
                      child: _buildStatusBadge(item.status),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // 6. Shipments Table: SHIPMENT ORDER#, SALES ORDER#, DATE, TRACKING#, STATUS
  Widget _buildShipmentsTable(String groupKey, List<CustomerTransactionItem> items, String groupLabel) {
    final titles = [
      'SHIPMENT ORDER#',
      'SALES ORDER#',
      'DATE',
      'TRACKING#',
      'STATUS',
    ];
    final flexes = [3, 3, 2, 2, 2];

    return Column(
      children: [
        _buildTableHeader(groupKey, titles, flexes),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No ${groupLabel.toLowerCase()} found for this customer.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          )
        else
          ...items.map((item) {
            final orderNum = item.orderNumber?.isNotEmpty == true ? item.orderNumber! : '-';
            final tracking = item.trackingNumber?.isNotEmpty == true ? item.trackingNumber! : '-';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: flexes[0],
                    child: Center(
                      child: Text(
                        item.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[1],
                    child: Center(
                      child: Text(
                        orderNum,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[2],
                    child: Center(
                      child: Text(
                        _formatDate(item.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[3],
                    child: Center(
                      child: Text(
                        tracking,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[4],
                    child: Center(
                      child: _buildStatusBadge(item.status),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // 7. Delivery Challans Table: DELIVERY CHALLAN#, WAREHOUSE, REFERENCE NUMBER, DATE, AMOUNT, STATUS
  Widget _buildChallansTable(String groupKey, List<CustomerTransactionItem> items, String groupLabel) {
    final titles = [
      'DELIVERY CHALLAN#',
      'WAREHOUSE',
      'REFERENCE NUMBER',
      'DATE',
      'AMOUNT',
      'STATUS',
    ];
    final flexes = [3, 3, 2, 2, 2, 2];

    return Column(
      children: [
        _buildTableHeader(groupKey, titles, flexes),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No ${groupLabel.toLowerCase()} found for this customer.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          )
        else
          ...items.map((item) {
            final warehouse = item.location?.isNotEmpty == true
                ? item.location!
                : 'Central Logistics Hub';
            final refNum = item.referenceNumber?.isNotEmpty == true
                ? item.referenceNumber!
                : '-';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: flexes[0],
                    child: Center(
                      child: Text(
                        item.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[1],
                    child: Center(
                      child: Text(
                        warehouse,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[2],
                    child: Center(
                      child: Text(
                        refNum,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[3],
                    child: Center(
                      child: Text(
                        _formatDate(item.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[4],
                    child: Center(
                      child: Text(
                        _formatCurrency(item.amount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[5],
                    child: Center(
                      child: _buildStatusBadge(item.status),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // 8. Bills Table: DATE, WAREHOUSE, BILL#, ORDER NUMBER, VENDOR NAME, AMOUNT, Customer Associated Line Items Total, BALANCE DUE, STATUS
  Widget _buildBillsTable(String groupKey, List<CustomerTransactionItem> items, String groupLabel) {
    final titles = [
      'DATE',
      'WAREHOUSE',
      'BILL#',
      'ORDER NUMBER',
      'VENDOR NAME',
      'AMOUNT',
      'Customer Associated Line Items Total',
      'BALANCE DUE',
      'STATUS',
    ];
    final flexes = [2, 3, 2, 2, 3, 2, 3, 2, 2];

    return Column(
      children: [
        _buildTableHeader(groupKey, titles, flexes),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No ${groupLabel.toLowerCase()} found for this customer.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          )
        else
          ...items.map((item) {
            final warehouse = item.location?.isNotEmpty == true
                ? item.location!
                : 'Central Logistics Hub';
            final orderNum = item.orderNumber?.isNotEmpty == true ? item.orderNumber! : '-';
            final vendor = item.vendorName?.isNotEmpty == true ? item.vendorName! : '-';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: flexes[0],
                    child: Center(
                      child: Text(
                        _formatDate(item.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[1],
                    child: Center(
                      child: Text(
                        warehouse,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[2],
                    child: Center(
                      child: Text(
                        item.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[3],
                    child: Center(
                      child: Text(
                        orderNum,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[4],
                    child: Center(
                      child: Text(
                        vendor,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[5],
                    child: Center(
                      child: Text(
                        _formatCurrency(item.amount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[6],
                    child: Center(
                      child: Text(
                        _formatCurrency(item.lineItemsTotal ?? item.amount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[7],
                    child: Center(
                      child: Text(
                        _formatCurrency(item.balanceDue ?? item.amount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[8],
                    child: Center(
                      child: _buildStatusBadge(item.status),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // 9. Credit Notes Table: CREDIT DATE, WAREHOUSE, CREDIT NOTE NUMBER, REFERENCE NUMBER, BALANCE, AMOUNT, STATUS
  Widget _buildCreditNotesTable(String groupKey, List<CustomerTransactionItem> items, String groupLabel) {
    final titles = [
      'CREDIT DATE',
      'WAREHOUSE',
      'CREDIT NOTE NUMBER',
      'REFERENCE NUMBER',
      'BALANCE',
      'AMOUNT',
      'STATUS',
    ];
    final flexes = [2, 3, 3, 2, 2, 2, 2];

    return Column(
      children: [
        _buildTableHeader(groupKey, titles, flexes),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No ${groupLabel.toLowerCase()} found for this customer.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          )
        else
          ...items.map((item) {
            final warehouse = item.location?.isNotEmpty == true
                ? item.location!
                : 'Central Logistics Hub';
            final refNum = item.referenceNumber?.isNotEmpty == true
                ? item.referenceNumber!
                : '-';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: flexes[0],
                    child: Center(
                      child: Text(
                        _formatDate(item.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[1],
                    child: Center(
                      child: Text(
                        warehouse,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[2],
                    child: Center(
                      child: InkWell(
                        onTap: () {
                          context.go(
                            '/${widget.orgSystemId}/sales/credit-notes/create',
                          );
                        },
                        child: Text(
                          item.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[3],
                    child: Center(
                      child: Text(
                        refNum,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[4],
                    child: Center(
                      child: Text(
                        _formatCurrency(item.balanceDue ?? item.amount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[5],
                    child: Center(
                      child: Text(
                        _formatCurrency(item.amount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[6],
                    child: Center(
                      child: _buildStatusBadge(item.status),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // 10. Generic Table for other transaction types
  Widget _buildGenericTable(
    String groupKey,
    List<CustomerTransactionItem> items,
    String groupLabel,
  ) {
    final titles = [
      'DATE',
      'WAREHOUSE',
      'NUMBER',
      'REFERENCE NUMBER',
      'AMOUNT',
      'STATUS',
    ];
    final flexes = [2, 3, 3, 2, 2, 2];

    return Column(
      children: [
        _buildTableHeader(groupKey, titles, flexes),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No ${groupLabel.toLowerCase()} found for this customer.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          )
        else
          ...items.map((item) {
            final warehouse = item.location?.isNotEmpty == true
                ? item.location!
                : 'Central Logistics Hub';
            final refNum = item.referenceNumber?.isNotEmpty == true
                ? item.referenceNumber!
                : '-';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: flexes[0],
                    child: Center(
                      child: Text(
                        _formatDate(item.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[1],
                    child: Center(
                      child: Text(
                        warehouse,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[2],
                    child: Center(
                      child: Text(
                        item.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[3],
                    child: Center(
                      child: Text(
                        refNum,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[4],
                    child: Center(
                      child: Text(
                        _formatCurrency(item.amount),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: flexes[5],
                    child: Center(
                      child: _buildStatusBadge(item.status),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
