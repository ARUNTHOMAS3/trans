import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class AdvancedCustomerSearchModal extends StatefulWidget {
  final List<SalesCustomer> customers;
  const AdvancedCustomerSearchModal({super.key, required this.customers});

  static Future<String?> show(BuildContext context, {List<SalesCustomer> customers = const []}) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.1),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter,
          child: AdvancedCustomerSearchModal(customers: customers),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.1),
              end: Offset.zero,
            ).animate(anim1),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AdvancedCustomerSearchModal> createState() =>
      _AdvancedCustomerSearchModalState();
}

class _AdvancedCustomerSearchModalState
    extends State<AdvancedCustomerSearchModal> {
  String _selectedFilter = 'Customer Number';
  static const List<String> _filters = [
    'Customer Number',
    'Customer Name',
    'Email',
    'Phone',
  ];
  final TextEditingController _searchController = TextEditingController();

  // Dummy data replaced with real customer data getter
  List<Map<String, String>> get _customers => widget.customers.map((c) => {
    'name': c.displayName,
    'id': c.customerNumber ?? '',
    'email': c.email ?? '',
    'company': c.companyName ?? '',
    'phone': c.phone ?? c.mobilePhone ?? '',
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Advanced Customer Search',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primaryBlue,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Area
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          hoverColor: const Color(0x1A2563EB),
                          splashColor: const Color(0x1A2563EB),
                          highlightColor: const Color(0x1A2563EB),
                        ),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          position: PopupMenuPosition.under,
                          offset: const Offset(0, 4),
                          onSelected: (val) =>
                              setState(() => _selectedFilter = val),
                          itemBuilder: (ctx) => _filters
                              .map(
                                (c) => PopupMenuItem<String>(
                                  value: c,
                                  padding: EdgeInsets.zero,
                                  height: 38,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      c,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFD1D5DB)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedFilter,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textBody,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomTextField(
                        controller: _searchController,
                        hintText: 'Search...',
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ZButton.primary(label: 'Search', onPressed: () {}),
                  ],
                ),
              ),

              // Table Header - Density matched to Pricelist
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(
                    top: BorderSide(color: AppTheme.borderLight),
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 14,
                ),
                child: Row(
                  children: [
                    _buildHeaderCell('CUSTOMER NAME', flex: 18),
                    _buildHeaderCell('EMAIL', flex: 14),
                    _buildHeaderCell('COMPANY NAME', flex: 18),
                    _buildHeaderCell('PHONE', flex: 12),
                  ],
                ),
              ),

              // Table Body - Density matched to Pricelist
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _customers.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: AppTheme.borderLight),
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    return InkWell(
                      onTap: () => Navigator.pop(context, customer['name']),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 18,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer['name']!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    customer['id']!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 14,
                              child: Text(
                                customer['email']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 18,
                              child: Text(
                                customer['company']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 12,
                              child: Text(
                                customer['phone']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
