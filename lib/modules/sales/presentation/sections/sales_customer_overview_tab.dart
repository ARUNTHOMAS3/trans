part of '../sales_customer_overview.dart';

extension _OverviewTab on _SalesCustomerOverviewScreenState {
  Widget _buildOverview(SalesCustomer customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.user,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mr. Sameer',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.phone,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '7561005789',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.smartphone,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '9446196641',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Invite to Portal',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildProfileSettingsMenu(),
                  ],
                ),
                const SizedBox(height: 32),

                // Collapsible Sections
                _collapsibleSection(
                  'ADDRESS',
                  Row(
                    children: [
                      Expanded(
                        child: _addressBlock(
                          'Billing Address',
                          customer.fullBillingAddress,
                        ),
                      ),
                      Expanded(
                        child: _addressBlock(
                          'Shipping Address',
                          customer.fullShippingAddress,
                        ),
                      ),
                    ],
                  ),
                ),
                _collapsibleSection(
                  'OTHER DETAILS',
                  Column(
                    children: [
                      _detailRow(
                        'Customer Type',
                        customer.customerType ?? 'Individual',
                      ),
                      _detailRow(
                        'Customer Number',
                        customer.customerNumber ?? 'N/A',
                      ),
                      _detailRow(
                        'Default Currency',
                        customer.currencyId ?? 'INR',
                      ),
                      _detailRow(
                        'GST Treatment',
                        customer.gstTreatment ?? 'N/A',
                      ),
                      _detailRow(
                        'Place of Supply',
                        customer.placeOfSupply ?? 'N/A',
                      ),
                      _detailRow(
                        'Tax Preference',
                        customer.taxPreference ?? 'N/A',
                      ),
                      _detailRow('Portal Status', 'Disabled', isStatus: true),
                      _detailRow('Customer Language', 'English'),
                      _detailRow(
                        'Opening Balance',
                        NumberFormat.currency(
                          symbol: '₹',
                          locale: 'en_IN',
                        ).format(customer.openingBalance ?? 0),
                        onEditOverride: () =>
                            context.go(AppRoutes.accountantOpeningBalances),
                      ),
                    ],
                  ),
                ),
                _collapsibleSection(
                  'TAX INFORMATION',
                  const Text(
                    'No Tax Information found.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  showAdd: true,
                ),
                _collapsibleSection(
                  'CONTACT PERSONS (1)',
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          LucideIcons.user,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'info@starlex.in',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        LucideIcons.settings,
                        size: 16,
                        color: Color(0xFFE5E7EB),
                      ),
                    ],
                  ),
                  showAdd: true,
                ),
                _collapsibleSection(
                  'ASSOCIATE TAGS',
                  const Text(
                    'No tags associated.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  showAdd: true,
                ),

                const SizedBox(height: 24),
                // Portal Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.userCircle,
                        color: Color(0xFF166534),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF166534),
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        'Customer Portal allows your customers to keep track of all the transactions between them and your business. ',
                                  ),
                                  TextSpan(
                                    text: 'Learn More',
                                    style: TextStyle(color: Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF374151),
                                elevation: 0,
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text(
                                'Enable Portal',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _collapsibleSection(
                  'RECORD INFO',
                  const Text(
                    'Created on: 2026-01-18',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
          // Right Column
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You can request your contact to directly update the GSTIN by sending an email. Send email',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricBlock('Payment due period', 'Net 360'),
                    _metricBlock('Credit Limit', 'Unlimited'),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Receivables',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 16),
                _receivablesTable(customer),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _countBadge('Items to be packed', 17, Colors.red),
                    const SizedBox(width: 16),
                    _countBadge('Items to be shipped', 1, Colors.red),
                  ],
                ),
                const SizedBox(height: 48),
                _timelineSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _collapsibleSection(
    String title,
    Widget content, {
    bool showAdd = false,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            if (showAdd) ...[
              const SizedBox(width: 8),
              const Icon(
                LucideIcons.plusCircle,
                size: 16,
                color: Color(0xFF2563EB),
              ),
            ],
          ],
        ),
        trailing: const Icon(
          LucideIcons.chevronDown,
          size: 20,
          color: Color(0xFF2563EB),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 8),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _addressBlock(String title, String? address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                _state(() {
                  _editingField = title;
                  _tempValue = address ?? '';
                });
              },
              child: const Icon(
                LucideIcons.edit2,
                size: 14,
                color: Color(0xFFD1D5DB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_editingField == title)
          _buildZerpaiInlineEditor(title, address ?? '')
        else if (address == null || address.isEmpty)
          const Text(
            'No Address - New Address',
            style: TextStyle(fontSize: 13, color: Color(0xFF2563EB)),
          )
        else
          Text(
            address,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
      ],
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool isStatus = false,
    VoidCallback? onEditOverride,
  }) {
    final isEditing = _editingField == label;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: isEditing
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Padding(
              padding: EdgeInsets.only(top: isEditing ? 0 : 2),
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ),
          ),
          Expanded(
            child: isEditing
                ? _buildZerpaiInlineEditor(label, value)
                : MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(
                      children: [
                        if (isStatus)
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            value,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF111827),
                            ),
                          ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            if (onEditOverride != null) {
                              onEditOverride();
                            } else if (label == 'Tax Preference') {
                              _showTaxPreferencePopup(context, value);
                            } else {
                              _state(() {
                                _editingField = label;
                                _tempValue = value;
                              });
                            }
                          },
                          child: const Icon(
                            LucideIcons.edit2,
                            size: 14,
                            color: Color(0xFFD1D5DB),
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

  Widget _buildZerpaiInlineEditor(String label, String initialValue) {
    final List<String>? options = _getOptionsForField(label);
    final isAddress = label.toLowerCase().contains('address');

    return Row(
      children: [
        Expanded(
          child: Container(
            constraints: BoxConstraints(minHeight: isAddress ? 60 : 36),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF2563EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: options != null
                ? FormDropdown<String>(
                    height: 36,
                    value: options.contains(_tempValue)
                        ? _tempValue
                        : options.first,
                    items: options,
                    onChanged: (v) => _state(() => _tempValue = v),
                  )
                : TextField(
                    autofocus: true,
                    controller: TextEditingController(text: _tempValue),
                    onChanged: (v) => _tempValue = v,
                    minLines: isAddress ? 2 : 1,
                    maxLines: isAddress ? 4 : 1,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        _actionSquare(LucideIcons.check, const Color(0xFF22C55E), () {
          _state(() {
            _editingField = null;
            // logic to save would go here
          });
        }),
        const SizedBox(width: 4),
        _actionSquare(LucideIcons.x, const Color(0xFFF87171), () {
          _state(() => _editingField = null);
        }),
      ],
    );
  }

  Widget _actionSquare(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  List<String>? _getOptionsForField(String label) {
    if (label == 'Customer Language') {
      return ['English', 'Deutsch', 'Español', 'Filipino', 'Arabic'];
    }
    if (label == 'GST Treatment') {
      return [
        'Registered Business - Regular',
        'Registered Business - Composition',
        'Unregistered Business',
        'Consumer',
        'Overseas',
      ];
    }
    if (label == 'Place of Supply') {
      return ['Kerala', 'Tamil Nadu', 'Karnataka', 'Maharashtra', 'Delhi'];
    }
    return null;
  }

  void _showTaxPreferencePopup(BuildContext context, String initialValue) {
    _tempValue = initialValue;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          titlePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Configure Tax Preferences',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  LucideIcons.x,
                  size: 18,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 1),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              const Text(
                'Tax Preference*',
                style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _tempValue,
                onChanged: (v) => setDialogState(() => _tempValue = v ?? ''),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => setDialogState(() => _tempValue = 'Taxable'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: 'Taxable',
                            activeColor: const Color(0xFF2563EB),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 4),
                          const Text('Taxable', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () =>
                          setDialogState(() => _tempValue = 'Tax Exempt'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: 'Tax Exempt',
                            activeColor: const Color(0xFF2563EB),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Tax Exempt',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Update',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _receivablesTable(SalesCustomer customer) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'CURRENCY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                Text(
                  'OUTSTANDING RECEIVABLES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
                SizedBox(width: 48),
                Text(
                  'UNUSED CREDITS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'INR- Indian Rupee',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    symbol: 'rs',
                  ).format(customer.receivables),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 48),
                const Text('rs0.00', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _countBadge(String label, int count, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
        ),
        const Text(': ', style: TextStyle(fontSize: 13)),
        Text(
          count.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _timelineSection() {
    return Column(children: List.generate(3, (index) => _timelineItem()));
  }

  Widget _timelineItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const Text(
                '30-05-2023',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const Text(
                '03:56 PM',
                style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(width: 16),
          const Icon(LucideIcons.fileText, size: 16, color: Color(0xFF2563EB)),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales Order updated',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Package shipped for Sales Order SO-00019\nby zabnixprivatelimited - View Details',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleDialogDropdown(
    String label,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return FormDropdown<String>(
      height: 32,
      value: options.contains(label) ? label : options.first,
      items: options,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
