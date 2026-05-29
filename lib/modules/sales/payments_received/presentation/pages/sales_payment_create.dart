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
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/payments_received/data/models/sales_payment_model.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/app/routing/app_router.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/unsaved_changes_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';

class SalesPaymentCreateScreen extends ConsumerStatefulWidget {
  /// Deep-link support: pre-select a customer by ID.
  final String? initialCustomerId;

  /// Deep-link support: pre-associate with a specific invoice.
  final String? fromInvoiceId;

  /// Deep-link support: clone an existing payment by ID.
  final String? cloneId;
  final bool showLayout;
  final VoidCallback? onCancel;
  final Function(SalesPayment)? onSaveSuccess;

  const SalesPaymentCreateScreen({
    super.key,
    this.initialCustomerId,
    this.fromInvoiceId,
    this.cloneId,
    this.showLayout = true,
    this.onCancel,
    this.onSaveSuccess,
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
  String? _invoiceNumberForTitle;
  late final TextEditingController amountCtrl;
  late final TextEditingController paymentNumberCtrl;
  late final TextEditingController referenceCtrl;
  late final TextEditingController notesCtrl;

  DateTime paymentDate = DateTime.now();
  String paymentMode = 'Cash';
  String? depositTo = 'Petty Cash';
  bool _isTaxDeducted = false;

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

    if (widget.onCancel != null) {
      widget.onCancel!();
      return;
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

    if (widget.fromInvoiceId != null) {
      _loadInvoice(widget.fromInvoiceId!);
    } else if (widget.initialCustomerId != null) {
      selectedCustomerId = widget.initialCustomerId;
    }
  }

  Future<void> _loadInvoice(String invoiceId) async {
    try {
      final api = ref.read(salesOrderApiServiceProvider);
      final rawInv = await api.getInvoiceById(invoiceId);
      if (!mounted) return;
      setState(() {
        selectedCustomerId = rawInv['customer_id']?.toString();
        _invoiceNumberForTitle = rawInv['invoice_number']?.toString();
        final total = rawInv['total'];
        if (total != null) {
          amountCtrl.text = double.parse(total.toString()).toStringAsFixed(2);
        }
      });
    } catch (_) {}
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

    final formWidget = Form(
      key: _formKey,
      onChanged: _markDirty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainForm(customersAsync),
          const SizedBox(height: 48),
        ],
      ),
    );

    final titleText = _invoiceNumberForTitle != null 
       ? 'Payment for $_invoiceNumberForTitle' 
       : 'Record Payment';

    if (!widget.showLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
            child: Text(
              titleText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ),
          Expanded(child: SingleChildScrollView(child: formWidget)),
          _buildFooter(),
        ],
      );
    }

    return ZerpaiLayout(
      pageTitle: titleText,
      enableBodyScroll: true,
      onCancel: _handleCancel,
      isDirty: _isDirty,
      footer: _buildFooter(),
      child: formWidget,
    );
  }

  Widget _buildMainForm(AsyncValue<List<SalesCustomer>> customersAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grey Top Section
        Container(
          color: AppTheme.bgLight,
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    customersAsync.when(
                      data: (customers) => _labeledField(
                        'Customer Name',
                        FormDropdown<String>(
                          value: selectedCustomerId,
                          height: 36,
                          items: customers.map((c) => c.id).toList(),
                          hint: 'Select a customer',
                          displayStringForValue: (id) =>
                              customers.firstWhere((c) => c.id == id).displayName,
                          onChanged: (val) =>
                              setState(() => selectedCustomerId = val),
                        ),
                        required: true,
                      ),
                      loading: () => const Skeleton(height: 36, width: 320),
                      error: (err, _) => Text('Error: $err'),
                    ),
                    _labeledField(
                      'Payment #',
                      CustomTextField(
                        controller: paymentNumberCtrl,
                        height: 36,
                      ),
                      required: true,
                    ),
                    _labeledField(
                      'Transaction Series',
                      FormDropdown<String>(
                        value: 'Default Transaction Series',
                        height: 36,
                        items: const ['Default Transaction Series'],
                        onChanged: (_) {},
                      ),
                      required: true,
                    ),
                    _labeledField(
                      'Location',
                      FormDropdown<String>(
                        value: 'ZABNIX PRIVATE LIMITED',
                        height: 36,
                        items: const ['ZABNIX PRIVATE LIMITED'],
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.topRight,
                  child: selectedCustomerId != null
                      ? _buildCustomerDetailsCard(customersAsync)
                      : const SizedBox.shrink(),
                ),
              )
            ],
          ),
        ),
        
        // White Bottom Section
        Container(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dualFieldRow(
                _labeledField(
                  'Amount Received (INR)',
                  CustomTextField(
                    controller: amountCtrl,
                    height: 36,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                  ),
                  required: true,
                  subLabel: 'PAN: ABACS3075R',
                ),
                _labeledField(
                  'Bank Charges (if any)',
                  const CustomTextField(height: 36),
                ),
              ),
              const SizedBox(height: 8),
              _labeledField(
                'Tax deducted?',
                ZerpaiRadioGroup<bool>(
                  options: const [false, true],
                  current: _isTaxDeducted,
                  onChanged: (val) => setState(() => _isTaxDeducted = val),
                  labelBuilder: (val) => val ? 'Yes, TDS (Income Tax)' : 'No Tax deducted',
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: AppTheme.borderLight),
              const SizedBox(height: 24),
              _dualFieldRow(
                _labeledField(
                  'Payment Date',
                  ZDatePickerField(
                    selectedDate: paymentDate,
                    onDateSelected: (d) => setState(() => paymentDate = d),
                  ),
                  required: true,
                ),
                _labeledField(
                  'Payment Mode',
                  FormDropdown<String>(
                    value: paymentMode,
                    height: 36,
                    items: const ['Cash', 'Check', 'Credit Card', 'Bank Transfer', 'Other'],
                    onChanged: (v) => setState(() => paymentMode = v!),
                  ),
                ),
              ),
              _dualFieldRow(
                _labeledField(
                  'Payment Received On',
                  const CustomTextField(height: 36, hintText: 'dd-MM-yyyy'),
                ),
                _labeledField(
                  'Deposit To',
                  FormDropdown<String>(
                    value: depositTo,
                    height: 36,
                    items: const ['Petty Cash', 'Undeposited Funds', 'Bank Account'],
                    onChanged: (v) => setState(() => depositTo = v),
                  ),
                  required: true,
                ),
              ),
              _dualFieldRow(
                _labeledField(
                  'Reference#',
                  CustomTextField(
                    controller: referenceCtrl,
                    height: 36,
                  ),
                ),
                _labeledField(
                  'Notes',
                  CustomTextField(controller: notesCtrl, maxLines: 3),
                ),
              ),
              
              const SizedBox(height: 32),
              const Divider(color: AppTheme.borderLight),
              const SizedBox(height: 24),
              
              const Text('Attachments', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                 icon: const Icon(LucideIcons.upload, size: 14),
                 label: const Text('Upload File'),
                 style: OutlinedButton.styleFrom(
                   foregroundColor: AppTheme.textSecondary,
                   side: const BorderSide(color: AppTheme.borderColor),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                 ),
                 onPressed: () {},
              ),
              const SizedBox(height: 8),
              const Text('You can upload a maximum of 5 files, 5MB each', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 24),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(value: false, onChanged: (_) {}),
                  ),
                  const SizedBox(width: 8),
                  const Text('Send a "Thank you" note for this payment', style: TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDetailsCard(AsyncValue<List<SalesCustomer>> customersAsync) {
    return customersAsync.when(
      data: (customers) {
        final matched = customers.where((c) => c.id == selectedCustomerId).toList();
        final name = matched.isNotEmpty ? matched.first.displayName : 'Customer';
        return Container(
          margin: const EdgeInsets.only(right: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF4C556D),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$name's Details",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(width: 24),
              const Icon(LucideIcons.chevronRight, color: Colors.white, size: 16),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _dualFieldRow(Widget leftField, Widget rightField) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: leftField),
        const SizedBox(width: 32),
        Expanded(flex: 5, child: rightField),
      ],
    );
  }

  Widget _labeledField(String label, Widget child, {bool required = false, String? subLabel}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SharedFieldLayout(
        label: label,
        required: required,
        labelColor: required ? AppTheme.errorRed : AppTheme.textSecondary,
        labelWidth: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            if (subLabel != null) ...[
              const SizedBox(height: 6),
              Text(subLabel, style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          OutlinedButton(
            onPressed: () {}, 
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Save as Draft'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _savePayment, 
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF28A745),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Save as Paid'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: _handleCancel, 
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: Colors.transparent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
      if (mounted) {
        setState(() => _isDirty = false);
        if (widget.onSaveSuccess != null) {
          widget.onSaveSuccess!(payment);
        } else {
          _handleCancel();
        }
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error: $e');
      }
    }
  }
}

