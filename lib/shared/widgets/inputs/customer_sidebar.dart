import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';

class CustomerDetailsSidebar extends StatefulWidget {
  final SalesCustomer customer;
  final String? currencyLabel;
  final VoidCallback onClose;

  const CustomerDetailsSidebar({
    super.key,
    required this.customer,
    this.currencyLabel,
    required this.onClose,
  });

  @override
  State<CustomerDetailsSidebar> createState() => _CustomerDetailsSidebarState();
}

class _CustomerDetailsSidebarState extends State<CustomerDetailsSidebar> {
  int _activeTabIndex = 0;
  bool _isContactPersonsExpanded = false;
  bool _isAddressExpanded = false;

  String _inr(double? value) {
    final amount = value ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _getGstTreatmentLabel(String? value) {
    if (value == null) return '';
    const map = {
      'registered_business': 'Registered Business',
      'unregistered_business': 'Unregistered Business',
      'consumer': 'Consumer',
      'overseas': 'Overseas',
      'special_economic_zone': 'Special Economic Zone',
      'sez_developer': 'SEZ Developer',
      'deemed_export': 'Deemed Export',
    };
    return map[value] ?? value;
  }

  Widget _tabItem(String label, int index) {
    final isActive = _activeTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _detailRow({required String label, required Widget value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 165,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool showRightBorder = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          border: showRightBorder
              ? const Border(right: BorderSide(color: Color(0xFFE5E7EB)))
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF020617),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _contactDisplayName(CustomerContact contact) {
    final parts = <String>[];
    final values = [contact.salutation, contact.firstName, contact.lastName];
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) parts.add(text);
    }

    if (parts.isNotEmpty) return parts.join(' ');
    if ((contact.email ?? '').trim().isNotEmpty) return contact.email!.trim();
    return 'Unnamed Contact';
  }

  Widget _buildContactPersonsSection(List<CustomerContact> contacts) {
    final badge = contacts.isNotEmpty ? '${contacts.length}' : null;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isContactPersonsExpanded = !_isContactPersonsExpanded;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  const Text(
                    'Contact Persons',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _isContactPersonsExpanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 16,
                    color: const Color(0xFF475569),
                  ),
                ],
              ),
            ),
          ),
          if (_isContactPersonsExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: contacts.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No contact persons found for this customer.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  : Column(
                      children: contacts
                          .asMap()
                          .entries
                          .map(
                            (entry) => Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(
                                bottom: entry.key == contacts.length - 1
                                    ? 0
                                    : 10,
                              ),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _contactDisplayName(entry.value),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  if ((entry.value.email ?? '')
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      entry.value.email!.trim(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                  if ((entry.value.mobilePhone ?? '')
                                          .trim()
                                          .isNotEmpty ||
                                      (entry.value.workPhone ?? '')
                                          .trim()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      (entry.value.mobilePhone ?? '')
                                              .trim()
                                              .isNotEmpty
                                          ? entry.value.mobilePhone!.trim()
                                          : entry.value.workPhone!.trim(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressCard({
    required String title,
    required List<String> lines,
    String? phone,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          if (lines.isEmpty)
            const Text(
              'No address found.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            )
          else
            Text(
              lines.join('\n'),
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF0F172A),
              ),
            ),
          if ((phone ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              phone!.trim(),
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressSection(SalesCustomer customer) {
    final billingLines = <String>[
      if ((customer.billingAddressStreet1 ?? '').trim().isNotEmpty)
        customer.billingAddressStreet1!.trim(),
      if ((customer.billingAddressStreet2 ?? '').trim().isNotEmpty)
        customer.billingAddressStreet2!.trim(),
      if ((customer.billingAddressCity ?? '').trim().isNotEmpty)
        customer.billingAddressCity!.trim(),
      [
        customer.billingAddressStateId?.trim() ?? '',
        customer.billingAddressZip?.trim() ?? '',
      ].where((value) => value.isNotEmpty).join(', '),
      if ((customer.billingAddressCountryId ?? '').trim().isNotEmpty)
        customer.billingAddressCountryId!.trim(),
    ].where((value) => value.trim().isNotEmpty).toList();

    final shippingLines = <String>[
      if ((customer.shippingAddressStreet1 ?? '').trim().isNotEmpty)
        customer.shippingAddressStreet1!.trim(),
      if ((customer.shippingAddressStreet2 ?? '').trim().isNotEmpty)
        customer.shippingAddressStreet2!.trim(),
      if ((customer.shippingAddressCity ?? '').trim().isNotEmpty)
        customer.shippingAddressCity!.trim(),
      [
        customer.shippingAddressStateId?.trim() ?? '',
        customer.shippingAddressZip?.trim() ?? '',
      ].where((value) => value.isNotEmpty).join(', '),
      if ((customer.shippingAddressCountryId ?? '').trim().isNotEmpty)
        customer.shippingAddressCountryId!.trim(),
    ].where((value) => value.trim().isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isAddressExpanded = !_isAddressExpanded;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  const Text(
                    'Address',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isAddressExpanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 16,
                    color: const Color(0xFF475569),
                  ),
                ],
              ),
            ),
          ),
          if (_isAddressExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  _buildAddressCard(
                    title: 'Billing Address',
                    lines: billingLines,
                    phone: customer.billingAddressPhone,
                  ),
                  const SizedBox(height: 10),
                  _buildAddressCard(
                    title: 'Shipping Address',
                    lines: shippingLines,
                    phone: customer.shippingAddressPhone,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    final c = widget.customer;
    final hasFacebook = (c.facebookHandle ?? '').trim().isNotEmpty;
    final hasX = (c.twitterHandle ?? '').trim().isNotEmpty;
    final portalEnabled = c.enablePortal ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                _summaryTile(
                  icon: LucideIcons.alertTriangle,
                  iconColor: const Color(0xFFF59E0B),
                  label: 'Outstanding Receivables',
                  value: _inr(c.receivables),
                  showRightBorder: true,
                ),
                _summaryTile(
                  icon: LucideIcons.badgeCheck,
                  iconColor: const Color(0xFF10B981),
                  label: 'Unused Credits',
                  value: _inr(0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Text(
                    'Contact Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                  child: Column(
                    children: [
                      _detailRow(
                        label: 'Customer Type',
                        value: Text(
                          c.customerType ?? 'Business',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _detailRow(
                        label: 'Currency',
                        value: Text(
                          (widget.currencyLabel ?? '').isNotEmpty
                              ? widget.currencyLabel!
                              : (c.currencyId ?? 'INR'),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _detailRow(
                        label: 'Credit Limit',
                        value: Text(
                          _inr(c.creditLimit),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _detailRow(
                        label: 'Payment Terms',
                        value: Text(
                          c.paymentTerms ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _detailRow(
                        label: 'Portal Status',
                        value: Text(
                          portalEnabled ? 'Enabled' : 'Disabled',
                          style: TextStyle(
                            fontSize: 14,
                            color: portalEnabled
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      _detailRow(
                        label: 'Customer Language',
                        value: const Row(
                          children: [
                            Text('English', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 6),
                            Icon(
                              LucideIcons.info,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                          ],
                        ),
                      ),
                      _detailRow(
                        label: 'Social Networks',
                        value: Row(
                          children: [
                            if (hasFacebook)
                              const FaIcon(
                                FontAwesomeIcons.facebook,
                                size: 15,
                                color: Color(0xFF1877F2),
                              ),
                            if (hasFacebook && hasX) const SizedBox(width: 10),
                            if (hasX)
                              const FaIcon(
                                FontAwesomeIcons.xTwitter,
                                size: 15,
                                color: Color(0xFF020617),
                              ),
                            if (!hasFacebook && !hasX)
                              const Text('-', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      _detailRow(
                        label: 'Price List',
                        value: Text(
                          (c.priceList ?? '').isNotEmpty
                              ? c.priceList!
                              : 'Pricelist',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _detailRow(
                        label: 'GST Treatment',
                        value: Text(
                          _getGstTreatmentLabel(c.gstTreatment).isNotEmpty
                              ? _getGstTreatmentLabel(c.gstTreatment)
                              : 'Unregistered Business',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _detailRow(
                        label: 'Place of Supply',
                        value: Text(
                          (c.placeOfSupply ?? '').isNotEmpty
                              ? c.placeOfSupply!
                              : '-',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _detailRow(
                        label: 'Tax Preference',
                        value: Text(
                          c.taxPreference ?? 'Taxable',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildContactPersonsSection(c.contactPersons ?? const []),
          _buildAddressSection(c),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return const Center(
      child: Text(
        'No activity found.',
        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final customerCode = (c.customerNumber ?? '').isNotEmpty
        ? c.customerNumber!
        : c.displayName;
    final customerName = c.displayName.isNotEmpty
        ? c.displayName
        : customerCode;
    final initial = c.displayName.isNotEmpty
        ? c.displayName[0].toUpperCase()
        : 'C';

    return Container(
      width: 500,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: const Border(left: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(-6, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              customerName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF020617),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(
                              LucideIcons.externalLink,
                              size: 14,
                              color: Color(0xFF2563EB),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              String orgId = '0000000000';
                              try {
                                final location = GoRouter.of(context).routeInformationProvider.value.uri.toString();
                                final match = RegExp(r'^/(\d{10,20})(/|$)').firstMatch(location);
                                final parsed = match?.group(1)?.trim();
                                if (parsed != null && parsed.isNotEmpty) {
                                  orgId = parsed;
                                }
                              } catch (_) {}
                              
                              if (orgId == '0000000000') {
                                try {
                                  final box = Hive.box('config');
                                  final selected = box.get('selected_entity_id') as String?;
                                  if (selected != null && selected.isNotEmpty) {
                                    orgId = selected;
                                  }
                                } catch (_) {}
                              }
                              
                              Scaffold.maybeOf(context)?.closeEndDrawer();
                              context.go('/$orgId/sales/customers/${c.id}');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                  splashRadius: 18,
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.fileText,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      customerCode,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mail,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (c.email ?? '').isNotEmpty ? c.email! : 'No email',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                _tabItem('Details', 0),
                const SizedBox(width: 24),
                _tabItem('Activity Log', 1),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: _activeTabIndex == 0
                ? _buildDetailsTab()
                : _buildActivityTab(),
          ),
        ],
      ),
    );
  }
}
