import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import '../controllers/sales_order_controller.dart';
import '../models/sales_customer_model.dart';
import '../models/sales_order_model.dart';
import '../models/sales_order_item_model.dart';
import 'widgets/sales_order_item_row.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';

class SalesRecurringInvoiceCreateScreen extends ConsumerStatefulWidget {
  const SalesRecurringInvoiceCreateScreen({super.key});

  @override
  ConsumerState<SalesRecurringInvoiceCreateScreen> createState() =>
      _SalesRecurringInvoiceCreateScreenState();
}

class _SalesRecurringInvoiceCreateScreenState
    extends ConsumerState<SalesRecurringInvoiceCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedCustomerId;
  late final TextEditingController profileNameCtrl;
  late final TextEditingController notesCtrl;

  String frequency = 'Monthly';
  DateTime startDate = DateTime.now();
  DateTime? endDate;

  List<SalesOrderItemRow> rows = [];

  @override
  void initState() {
    super.initState();
    profileNameCtrl = TextEditingController();
    notesCtrl = TextEditingController();
    _addItemRow();
  }

  @override
  void dispose() {
    profileNameCtrl.dispose();
    notesCtrl.dispose();
    for (var row in rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addItemRow() {
    setState(() {
      rows.add(
        SalesOrderItemRow(
          quantityCtrl: TextEditingController(text: '1'),
          rateCtrl: TextEditingController(text: '0'),
          discountCtrl: TextEditingController(text: '0'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);
    final itemsState = ref.watch(itemsControllerProvider);

    return ZerpaiLayout(
      pageTitle: 'New Recurring Invoice',
      enableBodyScroll: true,
      footer: _buildFooter(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProfileInfo(customersAsync),
            const SizedBox(height: 24),
            _buildItemsTable(itemsState.items),
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

  Widget _buildProfileInfo(AsyncValue<List<SalesCustomer>> customersAsync) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _row([
              _labeledField(
                'Profile Name',
                CustomTextField(controller: profileNameCtrl),
              ),
            ]),
            const SizedBox(height: 16),
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
                'Repeat Every',
                FormDropdown<String>(
                  value: frequency,
                  items: const ['Weekly', 'Monthly', 'Yearly'],
                  onChanged: (v) => setState(() => frequency = v!),
                ),
              ),
              _labeledField(
                'Start Date',
                _datePicker(startDate, (d) => setState(() => startDate = d)),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable(List<Item> productList) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF9FAFB),
            child: Row(
              children: const [
                Expanded(
                  flex: 4,
                  child: Text(
                    'ITEM DETAILS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'QUANTITY',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'RATE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                SizedBox(width: 48),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (ctx, idx) {
              final row = rows[idx];
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: FormDropdown<String>(
                        value: row.itemId.isEmpty ? null : row.itemId,
                        items: productList.map((p) => p.id!).toList(),
                        displayStringForValue: (id) => productList
                            .firstWhere((p) => p.id == id)
                            .productName,
                        onChanged: (v) => setState(() => row.itemId = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: CustomTextField(
                        controller: row.quantityCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: CustomTextField(
                        controller: row.rateCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2),
                      onPressed: () =>
                          setState(() => rows.removeAt(idx).dispose()),
                    ),
                  ],
                ),
              );
            },
          ),
          TextButton.icon(
            onPressed: _addItemRow,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Add Row'),
          ),
        ],
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
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
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
          onPressed: _saveRecurringInvoice,
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

  void _saveRecurringInvoice() async {
    if (selectedCustomerId == null) return;
    final items = rows
        .where((r) => r.itemId.isNotEmpty)
        .map(
          (r) => SalesOrderItem(
            itemId: r.itemId,
            quantity: double.tryParse(r.quantityCtrl.text) ?? 0,
            rate: double.tryParse(r.rateCtrl.text) ?? 0,
          ),
        )
        .toList();

    final order = SalesOrder(
      id: '',
      customerId: selectedCustomerId!,
      saleNumber: profileNameCtrl.text, // Simplified for now
      saleDate: startDate,
      status: 'confirmed',
      documentType: 'recurring_invoice',
      items: items,
      customerNotes: notesCtrl.text,
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
