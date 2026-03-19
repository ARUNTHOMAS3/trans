import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import '../controllers/sales_order_controller.dart';
import '../models/sales_eway_bill_model.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class SalesEWayBillCreateScreen extends ConsumerStatefulWidget {
  const SalesEWayBillCreateScreen({super.key});

  @override
  ConsumerState<SalesEWayBillCreateScreen> createState() =>
      _SalesEWayBillCreateScreenState();
}

class _SalesEWayBillCreateScreenState
    extends ConsumerState<SalesEWayBillCreateScreen> {
  final documentNumberCtrl = TextEditingController();
  final transIdCtrl = TextEditingController();
  final vehicleNoCtrl = TextEditingController();
  DateTime documentDate = DateTime.now();
  String supplyType = 'Outward';
  String subType = 'Supply';

  @override
  void dispose() {
    documentNumberCtrl.dispose();
    transIdCtrl.dispose();
    vehicleNoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'New e-Way Bill',
      enableBodyScroll: true,
      footer: _buildFooter(),
      child: Column(
        children: [
          _buildCard('Transaction Details', [
            _row([
              _labeledField(
                'Supply Type',
                _radioGroup(
                  ['Outward', 'Inward'],
                  supplyType,
                  (v) => setState(() => supplyType = v),
                ),
              ),
              _labeledField(
                'Sub Type',
                _radioGroup(
                  ['Supply', 'Import', 'Export', 'Job Work'],
                  subType,
                  (v) => setState(() => subType = v),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            _row([
              _labeledField(
                'Document#',
                CustomTextField(controller: documentNumberCtrl),
              ),
              _labeledField(
                'Document Date',
                _datePicker(
                  documentDate,
                  (d) => setState(() => documentDate = d),
                ),
              ),
            ]),
          ]),
          const SizedBox(height: 24),
          _buildCard('Transporter Details', [
            _row([
              _labeledField(
                'Transporter ID',
                CustomTextField(controller: transIdCtrl),
              ),
              _labeledField(
                'Vehicle Number',
                CustomTextField(controller: vehicleNoCtrl),
              ),
            ]),
          ]),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.textBody,
              ),
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _radioGroup(
    List<String> options,
    String current,
    ValueChanged<String> onChanged,
  ) {
    return ZerpaiRadioGroup<String>(
      options: options,
      current: current,
      onChanged: onChanged,
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
  Widget _labeledField(String label, Widget child) =>
      SharedFieldLayout(label: label, child: child);
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
        ElevatedButton(onPressed: _saveEWayBill, child: const Text('Save')),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );

  void _saveEWayBill() async {
    final bill = SalesEWayBill(
      billNumber: documentNumberCtrl.text,
      billDate: documentDate,
      supplyType: supplyType,
      subType: subType,
      transporterId: transIdCtrl.text,
      vehicleNumber: vehicleNoCtrl.text,
    );

    try {
      await ref.read(salesOrderApiServiceProvider).createEWayBill(bill);
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
