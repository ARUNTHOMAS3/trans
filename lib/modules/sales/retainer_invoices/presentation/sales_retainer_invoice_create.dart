import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_date_picker_field.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/notifiers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/customers/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/models/sales_order_item_model.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/unsaved_changes_dialog.dart';

class SalesRetainerInvoiceCreateScreen extends ConsumerStatefulWidget {
  const SalesRetainerInvoiceCreateScreen({super.key});

  @override
  ConsumerState<SalesRetainerInvoiceCreateScreen> createState() =>
      _SalesRetainerInvoiceCreateScreenState();
}

class _SalesRetainerInvoiceCreateScreenState
    extends ConsumerState<SalesRetainerInvoiceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;

  String? selectedCustomerId;
  late final TextEditingController invoiceNumberCtrl;
  late final TextEditingController referenceCtrl;
  late final TextEditingController descriptionCtrl;
  late final TextEditingController amountCtrl;
  late final TextEditingController notesCtrl;

  DateTime invoiceDate = DateTime.now();

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
            'If you leave, your unsaved retainer invoice changes will be discarded.',
      );
      if (!mounted || !shouldDiscard) return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.salesRetainerInvoices);
    }
  }

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
      onCancel: _handleCancel,
      isDirty: _isDirty,
      footer: _buildFooter(),
      child: Form(
        key: _formKey,
        onChanged: _markDirty,
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
                    height: 32,
                    items: customers.map((c) => c.id).toList(),
                    displayStringForValue: (id) =>
                        customers.firstWhere((c) => c.id == id).displayName,
                    onChanged: (v) => setState(() => selectedCustomerId = v),
                  ),
                ),
              ]),
              loading: () => const Skeleton(height: 32),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: 24),
            _row([
              _labeledField(
                'Retainer Invoice#',
                CustomTextField(
                  controller: invoiceNumberCtrl,
                  height: 32,
                ),
              ),
               _labeledField(
                'Invoice Date',
                ZDatePickerField(
                  selectedDate: invoiceDate,
                  onDateSelected: (d) => setState(() => invoiceDate = d),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _row([
              _labeledField(
                'Reference#',
                CustomTextField(
                  controller: referenceCtrl,
                  height: 32,
                ),
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
                  height: 32,
                  hintText: 'e.g. Advance payment for project',
                ),
              ),
              SizedBox(
                width: 150,
                child: _labeledField(
                  'Amount',
                  CustomTextField(
                    controller: amountCtrl,
                    height: 32,
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
        OutlinedButton(onPressed: _handleCancel, child: const Text('Cancel')),
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

