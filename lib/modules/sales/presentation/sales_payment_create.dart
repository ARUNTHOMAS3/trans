import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import '../controllers/sales_order_controller.dart';
import '../models/sales_customer_model.dart';
import '../models/sales_payment_model.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';

class SalesPaymentCreateScreen extends ConsumerStatefulWidget {
  const SalesPaymentCreateScreen({super.key});

  @override
  ConsumerState<SalesPaymentCreateScreen> createState() =>
      _SalesPaymentCreateScreenState();
}

class _SalesPaymentCreateScreenState
    extends ConsumerState<SalesPaymentCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedCustomerId;
  late final TextEditingController amountCtrl;
  late final TextEditingController paymentNumberCtrl;
  late final TextEditingController referenceCtrl;
  late final TextEditingController notesCtrl;

  DateTime paymentDate = DateTime.now();
  String paymentMode = 'Cash';
  String? depositTo = 'Petty Cash';

  @override
  void initState() {
    super.initState();
    amountCtrl = TextEditingController(text: '0.00');
    paymentNumberCtrl = TextEditingController(
      text: 'PAY-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}',
    );
    referenceCtrl = TextEditingController();
    notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    paymentNumberCtrl.dispose();
    referenceCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);

    return ZerpaiLayout(
      pageTitle: 'Record Payment',
      enableBodyScroll: true,
      footer: _buildFooter(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainForm(customersAsync),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildMainForm(AsyncValue<List<SalesCustomer>> customersAsync) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            customersAsync.when(
              data: (customers) => _row([
                _labeledField(
                  'Customer Name',
                  FormDropdown<String>(
                    value: selectedCustomerId,
                    items: customers.map((c) => c.id).toList(),
                    hint: 'Select a customer',
                    displayStringForValue: (id) =>
                        customers.firstWhere((c) => c.id == id).displayName,
                    onChanged: (val) =>
                        setState(() => selectedCustomerId = val),
                  ),
                ),
              ]),
              loading: () => const Skeleton(height: 44),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: 24),
            _row([
              _labeledField(
                'Amount Received',
                CustomTextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: LucideIcons.indianRupee,
                ),
              ),
              _labeledField(
                'Payment Date',
                _datePicker(
                  paymentDate,
                  (d) => setState(() => paymentDate = d),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            _row([
              _labeledField(
                'Payment#',
                CustomTextField(controller: paymentNumberCtrl),
              ),
              _labeledField(
                'Payment Mode',
                FormDropdown<String>(
                  value: paymentMode,
                  items: const [
                    'Cash',
                    'Check',
                    'Credit Card',
                    'Bank Transfer',
                    'Other',
                  ],
                  onChanged: (v) => setState(() => paymentMode = v!),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            _row([
              _labeledField(
                'Deposit To',
                FormDropdown<String>(
                  value: depositTo,
                  items: const [
                    'Petty Cash',
                    'Undeposited Funds',
                    'Bank Account',
                  ],
                  onChanged: (v) => setState(() => depositTo = v),
                ),
              ),
              _labeledField(
                'Reference#',
                CustomTextField(controller: referenceCtrl),
              ),
            ]),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),
            _labeledField(
              'Notes',
              CustomTextField(controller: notesCtrl, maxLines: 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map(
            (c) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: c,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _labeledField(String label, Widget child, {bool required = false}) {
    return SharedFieldLayout(label: label, required: required, child: child);
  }

  Widget _datePicker(DateTime value, ValueChanged<DateTime> onPicked) {
    final fieldKey = GlobalKey();
    return InkWell(
      key: fieldKey,
      onTap: () async {
        final picked = await ZerpaiDatePicker.show(
          context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          targetKey: fieldKey,
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(value),
              style: const TextStyle(fontSize: 13),
            ),
            const Icon(
              LucideIcons.calendar,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(onPressed: _savePayment, child: const Text('Save')),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _savePayment() async {
    if (selectedCustomerId == null) return;

    final payment = SalesPayment(
      customerId: selectedCustomerId!,
      paymentNumber: paymentNumberCtrl.text,
      paymentDate: paymentDate,
      paymentMode: paymentMode,
      amount: double.tryParse(amountCtrl.text) ?? 0,
      reference: referenceCtrl.text,
      depositTo: depositTo,
      notes: notesCtrl.text,
    );

    try {
      await ref.read(salesOrderApiServiceProvider).createPayment(payment);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
