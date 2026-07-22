import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

/// "Link <vendor> to Customer" dialog. Lets the user pick a customer to link
/// this vendor to. Customers load from [salesCustomersProvider].
class LinkVendorToCustomerDialog extends ConsumerStatefulWidget {
  final String vendorName;

  const LinkVendorToCustomerDialog({super.key, required this.vendorName});

  @override
  ConsumerState<LinkVendorToCustomerDialog> createState() =>
      _LinkVendorToCustomerDialogState();
}

class _LinkVendorToCustomerDialogState
    extends ConsumerState<LinkVendorToCustomerDialog> {
  SalesCustomer? _selected;

  Widget _dropdown(
    List<SalesCustomer> customers,
    ValueChanged<SalesCustomer?>? onChanged, {
    String hint = 'Choose a customer to link',
    bool isLoading = false,
  }) {
    return FormDropdown<SalesCustomer>(
      value: _selected,
      items: customers,
      hint: hint,
      isLoading: isLoading,
      onChanged: onChanged ?? (_) {},
      displayStringForValue: (c) => c.displayName,
      height: 42,
    );
  }

  void _onLink() {
    if (_selected == null) {
      ZerpaiToast.error(context, 'Please choose a customer to link');
      return;
    }
    ZerpaiToast.success(context, 'Linked to ${_selected!.displayName}');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Material(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 24,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 680,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 12, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF1F2937),
                            ),
                            children: [
                              const TextSpan(text: 'Link '),
                              TextSpan(
                                text: widget.vendorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(text: ' to Customer'),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Body ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "You're about to link this vendor to a customer. As a result "
                        'the vendor profile of the contact will be linked to the '
                        'customer profile of the other contact. This process will '
                        'allow you to view receivables and payables for the contact '
                        "from the contact's overview section.",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF667085),
                        ),
                      ),
                      const SizedBox(height: 20),
                      customersAsync.when(
                        loading: () => _dropdown(
                          const [],
                          null,
                          hint: 'Loading customers…',
                          isLoading: true,
                        ),
                        error: (_, __) => _dropdown(
                          const [],
                          null,
                          hint: 'Failed to load customers',
                        ),
                        data: (customers) => _dropdown(
                          customers,
                          (c) => setState(() => _selected = c),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Footer ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: _onLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Link',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.borderColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
