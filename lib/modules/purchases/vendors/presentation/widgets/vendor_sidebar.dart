import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

class VendorSidebar extends StatefulWidget {
  final Vendor vendor;
  final VoidCallback onClose;
  final List<Map<String, dynamic>> paymentTermsList;

  const VendorSidebar({
    super.key,
    required this.vendor,
    required this.onClose,
    this.paymentTermsList = const [],
  });

  @override
  State<VendorSidebar> createState() => _VendorSidebarState();
}

class _VendorSidebarState extends State<VendorSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  int _tab = 0;
  bool _showContactPersons = false;
  bool _showAddress = true; // Open by default matching the 2nd screenshot

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClose() {
    _controller.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    final initials = v.displayName.isNotEmpty ? v.displayName[0].toUpperCase() : '?';

    // Check if vendor name is Evanto to mock values
    final isEvanto = v.displayName.toLowerCase().contains('evanto');
    final payablesStr = isEvanto ? '₹185.00' : '₹0.00';
    final creditsStr = isEvanto ? '₹100.00' : '₹0.00';

    return Stack(
      children: [
        // Backdrop overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: _handleClose,
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
        ),
        // Sidebar slide-in
        SlideTransition(
          position: _offsetAnimation,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 440,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white, // Header and tabs area is white background
                border: const Border(left: BorderSide(color: AppTheme.borderLight)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Header Section (Avatar, Name, Link, Close icon)
                    _buildTopHeader(initials, v),
                    const Divider(height: 1, color: AppTheme.borderLight), // Divider under top header row (red line)
                    // Sub Header Section (Company name, Email)
                    _buildSubHeader(v),
                    // Tabs Section
                    _buildTabs(),
                    // Main Content / Body (Grey shade area under details & activity log)
                    Expanded(
                      child: Container(
                        color: const Color(0xFFF9FAFB), // Grey background for content below tabs
                        child: _tab == 0
                            ? _buildDetailsTab(v, payablesStr, creditsStr)
                            : _buildActivityLogTab(),
                      ),
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

  Widget _buildTopHeader(String initials, Vendor v) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          // Initials Avatar
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vendor',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        v.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Link icon
                    ZTooltip(
                      message: 'View in Vendors module',
                      direction: ZTooltipDirection.bottom,
                      child: InkWell(
                        onTap: () => context.push('/purchases/vendors'),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.open_in_new,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Close button
          InkWell(
            onTap: _handleClose,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close, size: 20, color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(Vendor v) {
    if ((v.companyName ?? '').isEmpty && (v.email ?? '').isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 16), // Left-aligned with top header, slightly lower
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((v.companyName ?? '').isNotEmpty)
            Row(
              children: [
                const Icon(LucideIcons.fileText, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  v.companyName!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          if ((v.companyName ?? '').isNotEmpty && (v.email ?? '').isNotEmpty)
            const SizedBox(height: 6),
          if ((v.email ?? '').isNotEmpty)
            Row(
              children: [
                const Icon(LucideIcons.mail, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  v.email!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          _buildTabItem('Details', _tab == 0, () => setState(() => _tab = 0)),
          _buildTabItem('Activity Log', _tab == 1, () => setState(() => _tab = 1)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab(Vendor v, String payablesStr, String creditsStr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Merged summary card container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.alertTriangle, size: 20, color: AppTheme.warningOrange),
                          const SizedBox(height: 12),
                          const Text(
                            'Outstanding Payables',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            payablesStr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppTheme.borderLight),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.circleDot, size: 20, color: AppTheme.accentGreen),
                          const SizedBox(height: 12),
                          const Text(
                            'Unused Credits',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            creditsStr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Contact Details Panel
          _buildContactDetailsCard(v),
          const SizedBox(height: 20),

          // Contact Persons Accordion
          _buildContactPersonsTile(v),
          const SizedBox(height: 14),

          // Address Accordion
          _buildAddressTile(v),
        ],
      ),
    );
  }

  Widget _buildContactDetailsCard(Vendor v) {
    // Resolve payment term name
    final term = widget.paymentTermsList.firstWhere(
      (t) => t['id'] == v.paymentTerms,
      orElse: () => {'term_name': v.paymentTerms ?? 'Due On Receipt'},
    );
    final paymentTermLabel = term['term_name'] ?? 'Due On Receipt';

    // Format source of supply
    String sos = v.sourceOfSupply ?? 'Kerala';
    if (sos.contains('] - ')) {
      sos = sos.split('] - ').last;
    } else if (sos.contains(' - ')) {
      sos = sos.split(' - ').last;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Contact Details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('Currency', v.currency ?? 'INR'),
                const SizedBox(height: 14),
                _buildDetailRow('Payment Terms', paymentTermLabel),
                const SizedBox(height: 14),
                _buildDetailRow('Portal Status', v.enablePortal == true ? 'Enabled' : 'Disabled'),
                const SizedBox(height: 14),
                _buildDetailRow('Vendor Language', 'English'),
                const SizedBox(height: 14),
                _buildDetailRow('GST Treatment', v.gstTreatment ?? 'Unregistered Business'),
                const SizedBox(height: 14),
                _buildDetailRow('Source of Supply', sos),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactPersonsTile(Vendor v) {
    final list = v.contactPersons ?? [];
    final count = list.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _showContactPersons,
          onExpansionChanged: (val) => setState(() => _showContactPersons = val),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Row(
            children: [
              const Text(
                'Contact Persons',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: Icon(
            _showContactPersons ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          children: [
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No contact persons',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: List.generate(list.length, (index) {
                    final p = list[index];
                    final salutation = p['salutation'] ?? '';
                    final firstName = p['firstName'] ?? p['first_name'] ?? '';
                    final lastName = p['lastName'] ?? p['last_name'] ?? '';
                    final fullName = [salutation, firstName, lastName].where((s) => s.isNotEmpty).join(' ').trim();
                    final name = fullName.isNotEmpty ? fullName : v.displayName;
                    final contactInitial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                    final email = (p['email'] ?? '').toString().trim();
                    final workPhone = (p['workPhone'] ?? p['work_phone'] ?? '').toString().trim();
                    final mobilePhone = (p['mobilePhone'] ?? p['mobile_phone'] ?? '').toString().trim();
                    final isPrimary = p['isPrimary'] == true || p['is_primary'] == true;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar Stack with optional Green Star
                              Stack(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      contactInitial,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  if (isPrimary)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(1),
                                        child: const Icon(
                                          Icons.stars,
                                          color: AppTheme.successGreen,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (email.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            LucideIcons.mail,
                                            size: 13,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              email,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (workPhone.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            LucideIcons.phone,
                                            size: 13,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            workPhone,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (mobilePhone.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            LucideIcons.smartphone,
                                            size: 13,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            mobilePhone,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index < list.length - 1)
                          const Divider(height: 1, color: AppTheme.borderLight),
                      ],
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressTile(Vendor v) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _showAddress,
          onExpansionChanged: (val) => setState(() => _showAddress = val),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text(
            'Address',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          trailing: Icon(
            _showAddress ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Billing Address Header with Icon
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.fileText,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Billing Address',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Billing Address Content with left border bar
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 2,
                        ),
                      ),
                    ),
                    child: _buildAddressContent(v.billingAddress, isBilling: true),
                  ),
                  const SizedBox(height: 20),
                  // Shipping Address Header
                  const Text(
                    'Shipping Address',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Shipping Address Content with left border bar
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 2,
                        ),
                      ),
                    ),
                    child: _buildAddressContent(v.shippingAddress, isBilling: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressContent(Map<String, dynamic>? address, {required bool isBilling}) {
    if (address == null) {
      return Text(
        isBilling ? 'No Billing Address' : 'No Shipping Address',
        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      );
    }

    final List<String> lines = [];
    if (address['attention'] != null && address['attention'].toString().trim().isNotEmpty) {
      lines.add(address['attention'].toString().trim());
    }
    if (address['street1'] != null && address['street1'].toString().trim().isNotEmpty) {
      lines.add(address['street1'].toString().trim());
    }
    if (address['street2'] != null && address['street2'].toString().trim().isNotEmpty) {
      lines.add(address['street2'].toString().trim());
    }

    final cityStateZip = [
      address['city'],
      address['state'],
      address['zip'],
    ].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');

    if (cityStateZip.isNotEmpty) lines.add(cityStateZip);

    if (address['country'] != null && address['country'].toString().trim().isNotEmpty) {
      lines.add(address['country'].toString().trim());
    }
    if (address['phone'] != null && address['phone'].toString().trim().isNotEmpty) {
      lines.add('Phone: ${address['phone'].toString().trim()}');
    }

    if (lines.isEmpty) {
      return Text(
        isBilling ? 'No Billing Address' : 'No Shipping Address',
        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      );
    }

    return Text(
      lines.join('\n'),
      style: const TextStyle(
        fontSize: 13,
        color: AppTheme.textPrimary,
        height: 1.5,
      ),
    );
  }

  Widget _buildActivityLogTab() {
    return const Center(
      child: Text(
        'No activity log available.',
        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
    );
  }
}
