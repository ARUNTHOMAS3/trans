import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import '../controllers/sales_order_controller.dart';
import '../models/sales_payment_link_model.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class SalesPaymentLinkCreateScreen extends ConsumerStatefulWidget {
  /// Deep-link support: pre-select a customer by ID.
  final String? initialCustomerId;

  /// Deep-link support: associate with a specific invoice.
  final String? fromInvoiceId;

  const SalesPaymentLinkCreateScreen({
    super.key,
    this.initialCustomerId,
    this.fromInvoiceId,
  });

  @override
  ConsumerState<SalesPaymentLinkCreateScreen> createState() =>
      _SalesPaymentLinkCreateScreenState();
}

class _SalesPaymentLinkCreateScreenState
    extends ConsumerState<SalesPaymentLinkCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedCustomerId;
  final amountCtrl = TextEditingController();
  final reasonCtrl = TextEditingController();

  @override
  void dispose() {
    amountCtrl.dispose();
    reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);

    return ZerpaiLayout(
      pageTitle: 'New Payment Link',
      footer: _buildFooter(),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                customersAsync.when(
                  data: (customers) => _labeledField(
                    'Customer Name',
                    FormDropdown<String>(
                      value: selectedCustomerId,
                      items: customers.map((c) => c.id).toList(),
                      displayStringForValue: (id) =>
                          customers.firstWhere((c) => c.id == id).displayName,
                      onChanged: (v) => setState(() => selectedCustomerId = v),
                    ),
                  ),
                  loading: () => const Skeleton(height: 44),
                  error: (err, _) => Text('Error: $err'),
                ),
                const SizedBox(height: 24),
                _labeledField(
                  'Amount',
                  CustomTextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    prefixIcon: LucideIcons.indianRupee,
                  ),
                ),
                const SizedBox(height: 24),
                _labeledField(
                  'Payment For',
                  CustomTextField(
                    controller: reasonCtrl,
                    hintText: 'e.g. Subscription, Project Advance',
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'A secure payment link will be generated and can be shared with the customer.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _labeledField(String label, Widget child) =>
      SharedFieldLayout(label: label, child: child);

  Widget _buildFooter() => Container(
    padding: const EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _savePaymentLink,
          child: const Text('Generate Link'),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );

  void _savePaymentLink() async {
    if (selectedCustomerId == null) return;

    final link = SalesPaymentLink(
      customerId: selectedCustomerId!,
      amount: double.tryParse(amountCtrl.text) ?? 0,
      linkNumber: 'PL-${DateFormat('yyyyMMddHHmm').format(DateTime.now())}',
      paymentReason: reasonCtrl.text,
      expiryDate: DateTime.now().add(const Duration(days: 7)),
    );

    try {
      await ref.read(salesOrderApiServiceProvider).createPaymentLink(link);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error: $e');
      }
    }
  }
}
