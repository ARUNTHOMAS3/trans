import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_date_picker_field.dart';
import 'package:go_router/go_router.dart';
import '../controllers/sales_order_controller.dart';
import '../models/sales_customer_model.dart';
import '../models/sales_payment_model.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/unsaved_changes_dialog.dart';

class SalesPaymentCreateScreen extends ConsumerStatefulWidget {
  /// Deep-link support: pre-select a customer by ID.
  final String? initialCustomerId;

  /// Deep-link support: pre-associate with a specific invoice.
  final String? fromInvoiceId;

  /// Deep-link support: clone an existing payment by ID.
  final String? cloneId;

  const SalesPaymentCreateScreen({
    super.key,
    this.initialCustomerId,
    this.fromInvoiceId,
    this.cloneId,
  });

  @override
  ConsumerState<SalesPaymentCreateScreen> createState() =>
      _SalesPaymentCreateScreenState();
}

class _SalesPaymentCreateScreenState
    extends ConsumerState<SalesPaymentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;

  String? selectedCustomerId;
  late final TextEditingController amountCtrl;
  late final TextEditingController paymentNumberCtrl;
  late final TextEditingController referenceCtrl;
  late final TextEditingController notesCtrl;

  DateTime paymentDate = DateTime.now();
  String paymentMode = 'Cash';
  String? depositTo = 'Petty Cash';

  void _markDirty() {
    if (!_isDirty && mounted) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _handleCancel() async {
    if (_isDirty) {
      final shouldDiscard = await showUnsavedChangesDialog(
        context,
        message:
            'If you leave, your unsaved payment changes will be discarded.',
      );
      if (!mounted || !shouldDiscard) return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.salesPaymentsReceived);
    }
  }

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
      onCancel: _handleCancel,
      isDirty: _isDirty,
      footer: _buildFooter(),
      child: Form(
        key: _formKey,
        onChanged: _markDirty,
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
        side: const BorderSide(color: AppTheme.borderColor),
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
                    height: 32,
                    items: customers.map((c) => c.id).toList(),
                    hint: 'Select a customer',
                    displayStringForValue: (id) =>
                        customers.firstWhere((c) => c.id == id).displayName,
                    onChanged: (val) =>
                        setState(() => selectedCustomerId = val),
                  ),
                ),
              ]),
              loading: () => const Skeleton(height: 32),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: 24),
            _row([
              _labeledField(
                'Amount Received',
                CustomTextField(
                  controller: amountCtrl,
                  height: 32,
                  keyboardType: TextInputType.number,
                  prefixIcon: LucideIcons.indianRupee,
                ),
              ),
              _labeledField(
                'Payment Date',
                ZDatePickerField(
                  selectedDate: paymentDate,
                  onDateSelected: (d) => setState(() => paymentDate = d),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            _row([
              _labeledField(
                'Payment#',
                CustomTextField(
                  controller: paymentNumberCtrl,
                  height: 36,
                ),
              ),
              _labeledField(
                'Payment Mode',
                FormDropdown<String>(
                  value: paymentMode,
                  height: 32,
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
                  height: 32,
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
                CustomTextField(
                  controller: referenceCtrl,
                  height: 32,
                ),
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


  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(onPressed: _savePayment, child: const Text('Save')),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: _handleCancel, child: const Text('Cancel')),
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
      if (mounted) {
        setState(() => _isDirty = false);
        _handleCancel();
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error: $e');
      }
    }
  }
}
