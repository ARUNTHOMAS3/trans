import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'widgets/add_batches_dialog.dart';

class AssemblyCreateScreen extends StatefulWidget {
  const AssemblyCreateScreen({super.key});

  @override
  State<AssemblyCreateScreen> createState() => _AssemblyCreateScreenState();
}

class _AssemblyCreateScreenState extends State<AssemblyCreateScreen> {
  final _assemblyNumCtrl = TextEditingController(text: 'BUN-00010');
  final _descriptionCtrl = TextEditingController();
  final _assembledDateCtrl = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );
  final _quantityCtrl = TextEditingController(text: '1');
  final GlobalKey _assembledDateFieldKey = GlobalKey();

  String? _selectedCompositeItem;
  String? _selectedWarehouse = 'ZABNIX PRIVATE LIMITED';

  // Associated Items table data
  final List<Map<String, dynamic>> _associatedItems = [
    {
      'details': '',
      'qtyRequired': 1.0,
      'totalQtyRequired': 1.0,
      'qtyAvailable': 0.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'New Assembly',
      // icon: Icons.inventory_2_outlined, // Removed
      // enableBodyScroll: true, // Removed
      footer: _buildFooter(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildForm(),
            if (_selectedCompositeItem != null) ...[
              const SizedBox(height: 32),
              _buildAssociatedItemsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            SharedFieldLayout(
              label: 'Composite Item*',
              labelColor: const Color(0xFFB91C1C),
              labelWidth: 180,
              child: FormDropdown<String>(
                value: _selectedCompositeItem,
                hint: 'Select a Composite Item',
                allowClear: true,
                items: const ['aaaaaaaaaaaaaaa', 'Item B', 'Item C'],
                onChanged: (val) =>
                    setState(() => _selectedCompositeItem = val),
              ),
            ),
            if (_selectedCompositeItem != null) ...[
              const SizedBox(height: 16),
              SharedFieldLayout(
                label: 'Assembly#*',
                labelColor: const Color(0xFFB91C1C),
                labelWidth: 180,
                child: CustomTextField(
                  controller: _assemblyNumCtrl,
                  prefixIcon: Icons
                      .settings_outlined, // Fallback to prefix since suffix not supported
                ),
              ),
              const SizedBox(height: 16),
              SharedFieldLayout(
                label: 'Description',
                labelWidth: 180,
                child: CustomTextField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 16),
              SharedFieldLayout(
                label: 'Assembled Date*',
                labelColor: const Color(0xFFB91C1C),
                labelWidth: 180,
                child: InkWell(
                  key: _assembledDateFieldKey,
                  onTap: () async {
                    final date = await ZerpaiDatePicker.show(
                      context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      targetKey: _assembledDateFieldKey,
                    );
                    if (date != null) {
                      setState(() {
                        _assembledDateCtrl.text = DateFormat(
                          'dd-MM-yyyy',
                        ).format(date);
                      });
                    }
                  },
                  child: IgnorePointer(
                    child: CustomTextField(
                      controller: _assembledDateCtrl,
                      prefixIcon: Icons.calendar_today_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SharedFieldLayout(
                label: 'Quantity to Assemble*',
                labelColor: const Color(0xFFB91C1C),
                labelWidth: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _quantityCtrl,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'You can Assemble 0 unit from the available stock.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddBatchesDialog(
                            productName: _selectedCompositeItem ?? 'N/A',
                            warehouseName: _selectedWarehouse ?? 'N/A',
                            totalQuantity:
                                double.tryParse(_quantityCtrl.text) ?? 1.0,
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.report_problem_rounded,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Add Batches',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SharedFieldLayout(
                label: 'Warehouse Name*',
                labelColor: const Color(0xFFB91C1C),
                labelWidth: 180,
                child: FormDropdown<String>(
                  value: _selectedWarehouse,
                  items: const ['ZABNIX PRIVATE LIMITED', 'Warehouse B'],
                  onChanged: (val) => setState(() => _selectedWarehouse = val),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssociatedItemsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: const Text(
            'Associated Items*',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB91C1C),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoBox(),
              const SizedBox(height: 16),
              _buildItemsTable(),
              const SizedBox(height: 16),
              _buildTableActions(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "If you've incurred an addition cost while assembling this item such as rent, labour, or scrap; you can add it as a service item to associate that cost to the item.",
              style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: const Color(0xFFF9FAFB),
            child: Row(
              children: [
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Item Details',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                  ),
                ),
                Container(width: 1, height: 16, color: const Color(0xFFE5E7EB)),
                const Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Text(
                      'Quantity Required',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                Container(width: 1, height: 16, color: const Color(0xFFE5E7EB)),
                const Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Text(
                      'Total Qty required',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                Container(width: 1, height: 16, color: const Color(0xFFE5E7EB)),
                const Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Text(
                      'Quantity Available',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table Body
          ..._associatedItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.image_outlined,
                                size: 16,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Type or click to select an item.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 1), // match divider
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            '${item['qtyRequired']}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                      const SizedBox(width: 1), // match divider
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item['totalQtyRequired']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'x ${_quantityCtrl.text} assemblies',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 1), // match divider
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            '${item['qtyAvailable']}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.more_vert,
                              size: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_associatedItems.length > 1) {
                                  setState(
                                    () => _associatedItems.removeAt(index),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.close,
                                size: 14,
                                color: Color(0xFFEF4444),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < _associatedItems.length - 1)
                  const Divider(height: 1),
              ],
            );
          }),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.sell_outlined,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Cost Price : -',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableActions() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () {
            setState(() {
              _associatedItems.add({
                'details': '',
                'qtyRequired': 1.0,
                'totalQtyRequired': 1.0,
                'qtyAvailable': 0.0,
              });
            });
          },
          icon: const Icon(
            Icons.add_circle_outline,
            size: 16,
            color: Color(0xFF2563EB),
          ),
          label: const Text(
            'Add New Row',
            style: TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
          ),
        ),
        const SizedBox(width: 16),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(
            Icons.add_circle_outline,
            size: 16,
            color: Color(0xFF2563EB),
          ),
          label: const Text(
            'Add Services',
            style: TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          ZButton.secondary(label: 'Save as Draft', onPressed: () {}),
          const SizedBox(width: 12),
          // Split Assemble Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                  ),
                  child: const Text(
                    'Assemble',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Container(
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          ZButton.secondary(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
