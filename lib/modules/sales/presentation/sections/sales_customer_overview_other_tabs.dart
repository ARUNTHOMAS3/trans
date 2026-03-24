part of '../sales_customer_overview.dart';

extension _OverviewOtherTabs on _SalesCustomerOverviewScreenState {
  Widget _buildComments(SalesCustomer customer) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: 2,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFE5E7EB),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'System User',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          index == 0 ? 'Customer created.' : 'Address updated.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Just now',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactions(SalesCustomer customer) {
    final types = [
      'Invoices',
      'Customer Payments',
      'Retainer Invoices',
      'Sales Orders',
      'Packages',
      'Delivery Challans',
      'Bills',
      'Credit Notes',
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: types.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              types[index],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            leading: const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: Color(0xFF6B7280),
            ),
            trailing: InkWell(
              onTap: () {},
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.plusCircle,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'New',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No ${types[index]} found for this customer.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMails(SalesCustomer customer) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'System Mails',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.mail, size: 16),
                label: const Row(
                  children: [
                    Text('Link Email account', style: TextStyle(fontSize: 13)),
                    Icon(LucideIcons.chevronDown, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 5,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFF3F4F6),
                    child: Text(
                      'Z',
                      style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'To: zabnixprivatelimited@gmail.com',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Draft Notification - New auto-generated invoice for the recurring profile: check',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '30-05-2025 11:20 AM',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatement(SalesCustomer customer) {
    return Column(
      children: [
        // Statement Headers
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _simpleDialogDropdown('This Month', [
                'This Month',
                'Last Month',
              ], (v) {}),
              const SizedBox(width: 12),
              _simpleDialogDropdown('Filter By: All', [
                'Filter By: All',
              ], (v) {}),
              const Spacer(),
              _headerButton('', LucideIcons.printer, isIconOnly: true),
              const SizedBox(width: 8),
              _headerButton('', LucideIcons.download, isIconOnly: true),
              const SizedBox(width: 8),
              _headerButton('', LucideIcons.fileText, isIconOnly: true),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.send, size: 16),
                label: const Text('Send Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Statement Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                width: 800,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    const Text(
                      'ZABNIX PRIVATE LIMITED',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'PERINTHALMANNA, MALAPPURAM Kerala 679322\nIndia',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Customer Statement for ${customer.displayName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'From 01-01-2026 To 31-01-2026',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 48),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'To',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              customer.displayName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 250,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Account Summary',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(height: 16),
                              _summaryItem(
                                'Opening Balance',
                                customer.receivables ?? 0,
                              ),
                              _summaryItem('Invoiced Amount', 0),
                              _summaryItem('Amount Received', 0),
                              const Divider(height: 16),
                              _summaryItem(
                                'Balance Due',
                                customer.receivables ?? 0,
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    // Statement Table
                    Table(
                      border: const TableBorder(
                        horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Color(0xFF374151)),
                          children: [
                            TableCellWidget('Date', isHeader: true),
                            TableCellWidget('Transactions', isHeader: true),
                            TableCellWidget('Details', isHeader: true),
                            TableCellWidget(
                              'Amount',
                              isHeader: true,
                              align: TextAlign.right,
                            ),
                            TableCellWidget(
                              'Payments',
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
                        TableRow(
                          children: [
                            const TableCellWidget('01-01-2026'),
                            const TableCellWidget('*** Opening Balance ***'),
                            const TableCellWidget(''),
                            const TableCellWidget(
                              '34.00',
                              align: TextAlign.right,
                            ),
                            const TableCellWidget(''),
                            TableCellWidget(
                              NumberFormat.currency(
                                symbol: '',
                              ).format(customer.receivables),
                              align: TextAlign.right,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(String label, double val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            NumberFormat.currency(symbol: 'rs').format(val),
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
