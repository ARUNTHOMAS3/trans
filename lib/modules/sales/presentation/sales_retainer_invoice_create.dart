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
import '../models/sales_order_model.dart';
import '../models/sales_order_item_model.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class SalesRetainerInvoiceCreateScreen extends ConsumerStatefulWidget {
  const SalesRetainerInvoiceCreateScreen({super.key});

  @override
  ConsumerState<SalesRetainerInvoiceCreateScreen> createState() =>
      _SalesRetainerInvoiceCreateScreenState();
}

class _SalesRetainerInvoiceCreateScreenState
    extends ConsumerState<SalesRetainerInvoiceCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedCustomerId;
  late final TextEditingController invoiceNumberCtrl;
  late final TextEditingController referenceCtrl;
  late final TextEditingController descriptionCtrl;
  late final TextEditingController amountCtrl;
  late final TextEditingController notesCtrl;

  DateTime invoiceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    invoiceNumberCtrl = TextEditingController(
      text: 'RET-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}',
    );
    referenceCtrl = TextEditingController();
    descriptionCtrl = TextEditingController();
    amountCtrl = TextEditingController(text: '0.00');
    notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    invoiceNumberCtrl.dispose();
    referenceCtrl.dispose();
    descriptionCtrl.dispose();
    amountCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);

    return ZerpaiLayout(
      pageTitle: 'New Retainer Invoice',
      enableBodyScroll: true,
      footer: _buildFooter(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildHeader(customersAsync),
            const SizedBox(height: 24),
            _buildLineItem(),
            const SizedBox(height: 24),
            CustomTextField(
              controller: notesCtrl,
              label: 'Customer Notes',
              maxLines: 3,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<SalesCustomer>> customersAsync) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            customersAsync.when(
              data: (customers) => _row([
                _labeledField(
                  'Customer Name',
                  FormDropdown<String>(
                    value: selectedCustomerId,
                    items: customers.map((c) => c.id).toList(),
                    displayStringForValue: (id) =>
                        customers.firstWhere((c) => c.id == id).displayName,
                    onChanged: (v) => setState(() => selectedCustomerId = v),
                  ),
                ),
              ]),
              loading: () => const Skeleton(height: 44),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: 24),
            _row([
              _labeledField(
                'Retainer Invoice#',
                CustomTextField(controller: invoiceNumberCtrl),
              ),
              _labeledField(
                'Invoice Date',
                _datePicker(
                  invoiceDate,
                  (d) => setState(() => invoiceDate = d),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _row([
              _labeledField(
                'Reference#',
                CustomTextField(controller: referenceCtrl),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Line Items',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _row([
              _labeledField(
                'Description',
                CustomTextField(
                  controller: descriptionCtrl,
                  hintText: 'e.g. Advance payment for project',
                ),
              ),
              SizedBox(
                width: 150,
                child: _labeledField(
                  'Amount',
                  CustomTextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) => Row(
    children: children
        .map(
          (c) => Expanded(
            child: Padding(padding: const EdgeInsets.only(right: 20), child: c),
          ),
        )
        .toList(),
  );
  Widget _labeledField(String label, Widget child, {bool required = false}) =>
      SharedFieldLayout(label: label, required: required, child: child);

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
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd/MM/yyyy').format(value)),
            const Icon(LucideIcons.calendar, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() => Container(
    padding: const EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _saveRetainerInvoice,
          child: const Text('Save'),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );

  void _saveRetainerInvoice() async {
    if (selectedCustomerId == null) return;
    final amount = double.tryParse(amountCtrl.text) ?? 0;

    final order = SalesOrder(
      id: '',
      customerId: selectedCustomerId!,
      saleNumber: invoiceNumberCtrl.text,
      reference: referenceCtrl.text,
      saleDate: invoiceDate,
      status: 'confirmed',
      documentType: 'retainer_invoice',
      subTotal: amount,
      total: amount,
      customerNotes: notesCtrl.text,
      items: [
        SalesOrderItem(
          itemId: '',
          description: descriptionCtrl.text,
          quantity: 1,
          rate: amount,
        ),
      ],
    );

    try {
      await ref
          .read(salesOrderControllerProvider.notifier)
          .createSalesOrder(order);
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
