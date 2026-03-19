import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import '../controllers/sales_order_controller.dart';
import '../models/sales_customer_model.dart';
import '../models/sales_order_model.dart';
import '../models/sales_order_item_model.dart';
import 'widgets/sales_order_item_row.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/unsaved_changes_dialog.dart';

class SalesChallanCreateScreen extends ConsumerStatefulWidget {
  const SalesChallanCreateScreen({super.key});

  @override
  ConsumerState<SalesChallanCreateScreen> createState() =>
      _SalesChallanCreateScreenState();
}

class _SalesChallanCreateScreenState
    extends ConsumerState<SalesChallanCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;

  String? selectedCustomerId;
  late final TextEditingController challanNumberCtrl;
  late final TextEditingController referenceCtrl;
  late final TextEditingController notesCtrl;

  DateTime challanDate = DateTime.now();
  String challanType = 'Job Work';

  List<SalesOrderItemRow> rows = [];

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
            'If you leave, your unsaved delivery challan changes will be discarded.',
      );
      if (!mounted || !shouldDiscard) return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.salesDeliveryChallans);
    }
  }

  @override
  void initState() {
    super.initState();
    challanNumberCtrl = TextEditingController(
      text: 'DC-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}',
    );
    referenceCtrl = TextEditingController();
    notesCtrl = TextEditingController();
    _addItemRow();
  }

  @override
  void dispose() {
    challanNumberCtrl.dispose();
    referenceCtrl.dispose();
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
      pageTitle: 'New Delivery Challan',
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
            _buildHeader(customersAsync),
            const SizedBox(height: 24),
            _buildItemsTable(itemsState.items),
            const SizedBox(height: 24),
            CustomTextField(
              controller: notesCtrl,
              maxLines: 3,
              label: 'Customer Notes',
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
                    onChanged: (val) =>
                        setState(() => selectedCustomerId = val),
                  ),
                ),
              ]),
              loading: () => const Skeleton(height: 44),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: 20),
            _row([
              _labeledField(
                'Challan#',
                CustomTextField(controller: challanNumberCtrl),
              ),
              _labeledField(
                'Challan Date',
                _datePicker(
                  challanDate,
                  (d) => setState(() => challanDate = d),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _row([
              _labeledField(
                'Challan Type',
                FormDropdown<String>(
                  value: challanType,
                  items: const ['Job Work', 'Supply on Approval', 'Others'],
                  onChanged: (v) => setState(() => challanType = v!),
                ),
              ),
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

  Widget _buildItemsTable(List<Item> productList) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.bgLight,
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
        ElevatedButton(onPressed: _saveChallan, child: const Text('Save')),
        const SizedBox(width: 12),
        OutlinedButton(onPressed: _handleCancel, child: const Text('Cancel')),
      ],
    ),
  );

  void _saveChallan() async {
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
      saleNumber: challanNumberCtrl.text,
      reference: referenceCtrl.text,
      saleDate: challanDate,
      status: 'confirmed',
      documentType: 'challan',
      items: items,
      customerNotes: notesCtrl.text,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
