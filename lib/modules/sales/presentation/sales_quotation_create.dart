import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import '../controllers/sales_order_controller.dart';
import '../models/sales_order_model.dart';
import '../models/sales_order_item_model.dart';
import '../models/sales_customer_model.dart';
import '../../items/pricelist/providers/pricelist_provider.dart';
import '../../items/pricelist/models/pricelist_model.dart';
import 'widgets/sales_order_item_row.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/unsaved_changes_dialog.dart';

class SalesQuoteCreateScreen extends ConsumerStatefulWidget {
  const SalesQuoteCreateScreen({super.key});

  @override
  ConsumerState<SalesQuoteCreateScreen> createState() =>
      _SalesQuoteCreateScreenState();
}

class _SalesQuoteCreateScreenState
    extends ConsumerState<SalesQuoteCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;

  String? selectedCustomerId;
  late final TextEditingController quoteNumberCtrl;
  late final TextEditingController referenceCtrl;
  late final TextEditingController notesCtrl;
  late final TextEditingController shippingCtrl;
  late final TextEditingController adjustmentCtrl;

  DateTime quoteDate = DateTime.now();
  DateTime expiryDate = DateTime.now().add(const Duration(days: 30));
  String? salesperson;

  List<SalesOrderItemRow> rows = [];

  double subTotal = 0.0;
  double taxTotal = 0.0;
  double total = 0.0;

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
            'If you leave, your unsaved quotation changes will be discarded.',
      );
      if (!mounted || !shouldDiscard) return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.salesQuotations);
    }
  }

  @override
  void initState() {
    super.initState();
    quoteNumberCtrl = TextEditingController(
      text: 'QT-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}',
    );
    referenceCtrl = TextEditingController();
    notesCtrl = TextEditingController();
    shippingCtrl = TextEditingController(text: '0');
    adjustmentCtrl = TextEditingController(text: '0');

    shippingCtrl.addListener(_calculateTotals);
    adjustmentCtrl.addListener(_calculateTotals);

    _addItemRow();
  }

  @override
  void dispose() {
    quoteNumberCtrl.dispose();
    referenceCtrl.dispose();
    notesCtrl.dispose();
    shippingCtrl.dispose();
    adjustmentCtrl.dispose();
    for (var row in rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addItemRow() {
    setState(() {
      final row = SalesOrderItemRow(
        quantityCtrl: TextEditingController(text: '1'),
        rateCtrl: TextEditingController(text: '0'),
        discountCtrl: TextEditingController(text: '0'),
      );
      row.quantityCtrl.addListener(() {
        final customers = ref.read(salesCustomersProvider).asData?.value ?? [];
        final customer = customers.firstWhere(
          (c) => c.id == selectedCustomerId,
          orElse: () => customers.first,
        );
        final priceLists =
            ref.read(filteredPriceListsProvider).asData?.value ?? [];
        _updateRowRate(row, customer, priceLists);
        _calculateTotals();
      });
      row.rateCtrl.addListener(_calculateTotals);
      row.discountCtrl.addListener(_calculateTotals);
      rows.add(row);
    });
  }

  void _updateRowRate(
    SalesOrderItemRow row,
    SalesCustomer? customer,
    List<PriceList> priceLists,
  ) {
    if (customer == null || row.item == null) return;

    final priceListId = customer.priceList;
    if (priceListId == null || priceListId == 'Select') return;

    final matchingPls = priceLists.where((p) => p.id == priceListId);
    if (matchingPls.isEmpty) return;
    final pl = matchingPls.first;

    final qty = double.tryParse(row.quantityCtrl.text) ?? 1;
    final newRate = pl.calculatePrice(
      row.itemId,
      (row.item!.sellingPrice ?? 0).toDouble(),
      quantity: qty,
    );

    if (row.rateCtrl.text != newRate.toString()) {
      row.rateCtrl.text = newRate.toString();
    }
  }

  void _calculateTotals() {
    double st = 0;
    for (var row in rows) {
      if (row.itemId.isNotEmpty) {
        final q = double.tryParse(row.quantityCtrl.text) ?? 0;
        final r = double.tryParse(row.rateCtrl.text) ?? 0;
        final d = double.tryParse(row.discountCtrl.text) ?? 0;
        st += (q * r) - d;
      }
    }
    final shipping = double.tryParse(shippingCtrl.text) ?? 0;
    final adjustment = double.tryParse(adjustmentCtrl.text) ?? 0;

    setState(() {
      subTotal = st;
      total = subTotal + taxTotal + shipping + adjustment;
    });
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);
    final itemsState = ref.watch(itemsControllerProvider);
    final priceListsAsync = ref.watch(filteredPriceListsProvider);

    return ZerpaiLayout(
      pageTitle: 'New Quote',
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
            _buildHeaderSection(customersAsync, priceListsAsync),
            const SizedBox(height: 24),
            _buildItemsTable(itemsState.items, customersAsync, priceListsAsync),
            const SizedBox(height: 24),
            _buildSummaryAndNotes(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    AsyncValue<List<SalesCustomer>> customersAsync,
    AsyncValue<List<PriceList>> priceListsAsync,
  ) {
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
            customersAsync.when(
              data: (customers) => ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SharedFieldLayout(
                  label: 'Customer Name',
                  child: FormDropdown<String>(
                    value: selectedCustomerId,
                    items: customers.map((c) => c.id).toList(),
                    hint: 'Select or type to add',
                    displayStringForValue: (id) =>
                        customers.firstWhere((c) => c.id == id).displayName,
                    onChanged: (val) {
                      setState(() {
                        selectedCustomerId = val;
                        // When customer changes, refresh rates for all items if they exist
                        final customers = customersAsync.asData?.value ?? [];
                        final customer = customers.firstWhere(
                          (c) => c.id == val,
                          orElse: () => customers.first,
                        );
                        final priceLists = priceListsAsync.asData?.value ?? [];

                        for (var row in rows) {
                          if (row.itemId.isNotEmpty && row.item != null) {
                            _updateRowRate(row, customer, priceLists);
                          }
                        }
                      });
                    },
                  ),
                ),
              ),
              loading: () => const Skeleton(height: 44, width: 400),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            Wrap(
              spacing: 32,
              runSpacing: 24,
              children: [
                _buildFieldCol([
                  _labeledField(
                    'Quote#',
                    CustomTextField(controller: quoteNumberCtrl),
                  ),
                  _labeledField(
                    'Reference#',
                    CustomTextField(controller: referenceCtrl),
                  ),
                ]),
                _buildFieldCol([
                  _labeledField(
                    'Quote Date',
                    _datePicker(
                      quoteDate,
                      (d) => setState(() => quoteDate = d),
                    ),
                  ),
                  _labeledField(
                    'Expiry Date',
                    _datePicker(
                      expiryDate,
                      (d) => setState(() => expiryDate = d),
                    ),
                  ),
                ]),
                _buildFieldCol([
                  _labeledField(
                    'Salesperson',
                    FormDropdown<String>(
                      value: salesperson,
                      items: const ['Self', 'Agent A', 'Agent B'],
                      onChanged: (v) => setState(() => salesperson = v),
                    ),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCol(List<Widget> children) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            children.expand((w) => [w, const SizedBox(height: 16)]).toList()
              ..removeLast(),
      ),
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
          border: Border.all(color: AppTheme.borderColorDark),
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
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable(
    List<Item>? productList,
    AsyncValue<List<SalesCustomer>> customersAsync,
    AsyncValue<List<PriceList>> priceListsAsync,
  ) {
    if (productList == null) return const SizedBox();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.bgLight,
            child: Row(
              children: const [
                Expanded(
                  flex: 4,
                  child: Text('ITEM DETAILS', style: _tableHeaderStyle),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Text('QUANTITY', style: _tableHeaderStyle),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Text('RATE', style: _tableHeaderStyle),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Text('DISCOUNT', style: _tableHeaderStyle),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Text('AMOUNT', style: _tableHeaderStyle),
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
              final q = double.tryParse(row.quantityCtrl.text) ?? 0;
              final r = double.tryParse(row.rateCtrl.text) ?? 0;
              final d = double.tryParse(row.discountCtrl.text) ?? 0;
              final amount = (q * r) - d;
              return Padding(
                padding: const EdgeInsets.all(16.0),
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
                        onChanged: (v) {
                          if (v != null) {
                            final p = productList.firstWhere(
                              (element) => element.id == v,
                            );
                            setState(() {
                              row.itemId = v;
                              row.item = p;

                              final customers =
                                  customersAsync.asData?.value ?? [];
                              final customer = customers.firstWhere(
                                (c) => c.id == selectedCustomerId,
                                orElse: () => customers.first,
                              );
                              final priceLists =
                                  priceListsAsync.asData?.value ?? [];
                              _updateRowRate(row, customer, priceLists);

                              if (row.rateCtrl.text == '0' ||
                                  row.rateCtrl.text.isEmpty) {
                                row.rateCtrl.text = (p.sellingPrice ?? 0)
                                    .toString();
                              }
                            });
                            _calculateTotals();
                          }
                        },
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
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: CustomTextField(
                        controller: row.discountCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Container(
                        alignment: Alignment.centerRight,
                        child: Text('₹${amount.toStringAsFixed(2)}'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.trash2,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        setState(() => rows.removeAt(idx).dispose());
                        _calculateTotals();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: _addItemRow,
              icon: const Icon(LucideIcons.plusCircle),
              label: const Text('Add another line'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryAndNotes() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: CustomTextField(
            controller: notesCtrl,
            maxLines: 4,
            label: 'Customer Notes',
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                _summaryRow('Sub Total', subTotal),
                const SizedBox(height: 12),
                _rowInput('Shipping Charges', shippingCtrl),
                const SizedBox(height: 12),
                _rowInput('Adjustment', adjustmentCtrl),
                const Divider(height: 32),
                _summaryRow('Total (rs)', total, isBold: true, fontSize: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(
    String label,
    double val, {
    bool isBold = false,
    double fontSize = 13,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : null,
          fontSize: fontSize,
        ),
      ),
      Text(
        '₹${val.toStringAsFixed(2)}',
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : null,
          fontSize: fontSize,
        ),
      ),
    ],
  );

  Widget _rowInput(String label, TextEditingController ctrl) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      SizedBox(
        width: 100,
        child: CustomTextField(
          controller: ctrl,
          textAlign: TextAlign.right,
          keyboardType: TextInputType.number,
        ),
      ),
    ],
  );

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
          ElevatedButton(
            onPressed: () => _saveQuote('confirmed'),
            child: const Text('Save'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: _handleCancel, child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _saveQuote(String status) async {
    if (selectedCustomerId == null) return;
    final items = rows
        .where((r) => r.itemId.isNotEmpty)
        .map(
          (r) => SalesOrderItem(
            itemId: r.itemId,
            quantity: double.tryParse(r.quantityCtrl.text) ?? 0,
            rate: double.tryParse(r.rateCtrl.text) ?? 0,
            discount: double.tryParse(r.discountCtrl.text) ?? 0,
          ),
        )
        .toList();

    final order = SalesOrder(
      id: '',
      customerId: selectedCustomerId!,
      saleNumber: quoteNumberCtrl.text,
      reference: referenceCtrl.text,
      saleDate: quoteDate,
      status: status,
      documentType: 'quote',
      items: items,
      subTotal: subTotal,
      total: total,
      customerNotes: notesCtrl.text,
    );
    try {
      await ref
          .read(salesOrderControllerProvider.notifier)
          .createSalesOrder(order);
      if (mounted) {
        setState(() => _isDirty = false);
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.salesQuotations);
        }
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error: $e');
      }
    }
  }

  static const _tableHeaderStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 11,
    color: AppTheme.textSecondary,
  );
}
