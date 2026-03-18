// lib/modules/items/items/presentation/sections/components/items_batch_dialogs.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';

class CreateBatchDialog extends StatefulWidget {
  final BatchData? initialBatch; // If null, it's "Create", else "Edit"

  const CreateBatchDialog({super.key, this.initialBatch});

  @override
  State<CreateBatchDialog> createState() => _CreateBatchDialogState();
}

class _CreateBatchDialogState extends State<CreateBatchDialog> {
  late final TextEditingController batchRefController;
  late final TextEditingController unitPackController;
  late final TextEditingController manufacturerController;
  late final TextEditingController manufacturedDateController;
  late final TextEditingController expiryDateController;
  final GlobalKey _manufacturedDateFieldKey = GlobalKey();
  final GlobalKey _expiryDateFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    batchRefController = TextEditingController(
      text: widget.initialBatch?.batchReference ?? '',
    );
    unitPackController = TextEditingController(
      text: widget.initialBatch?.unitPack.toString() ?? '',
    );
    manufacturerController = TextEditingController(
      text: widget.initialBatch?.manufacturerBatch ?? '',
    );
    manufacturedDateController = TextEditingController(
      text: widget.initialBatch?.manufacturedDate ?? '',
    );
    expiryDateController = TextEditingController(
      text: widget.initialBatch?.expiryDate ?? '',
    );
  }

  @override
  void dispose() {
    batchRefController.dispose();
    unitPackController.dispose();
    manufacturerController.dispose();
    manufacturedDateController.dispose();
    expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    TextEditingController controller,
    GlobalKey targetKey,
  ) async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      targetKey: targetKey,
    );
    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      controller.text = '$day-$month-${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.initialBatch == null
                          ? 'Create Batch'
                          : 'Edit Batch',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 12),
                _buildRow(
                  'Batch Reference#*',
                  _buildTextField(batchRefController, 'Enter Batch#'),
                  labelColor: const Color(0xFFEF4444),
                ),
                const SizedBox(height: 12),
                _buildRow(
                  'Unit Pack',
                  _buildNumberField(unitPackController, hint: '0'),
                ),
                const SizedBox(height: 12),
                _buildRow(
                  'Manufacturer/Patent Batch#',
                  _buildTextField(
                    manufacturerController,
                    'Enter MFR/Patent Batch#',
                  ),
                ),
                const SizedBox(height: 12),
                _buildRow(
                  'Manufactured date',
                  _buildDateField(
                    manufacturedDateController,
                    'dd-MM-yyyy',
                    fieldKey: _manufacturedDateFieldKey,
                    onTap: () => _pickDate(
                      manufacturedDateController,
                      _manufacturedDateFieldKey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildRow(
                  'Expiry Date',
                  _buildDateField(
                    expiryDateController,
                    'dd-MM-yyyy',
                    fieldKey: _expiryDateFieldKey,
                    onTap: () =>
                        _pickDate(expiryDateController, _expiryDateFieldKey),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => context.pop({
                        'batchReference': batchRefController.text,
                        'unitPack': int.tryParse(unitPackController.text) ?? 0,
                        'manufacturerBatch': manufacturerController.text,
                        'manufacturedDate': manufacturedDateController.text,
                        'expiryDate': expiryDateController.text,
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    Widget field, {
    Color labelColor = const Color(0xFF111827),
  }) {
    return Row(
      children: [
        SizedBox(
          width: 170,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: field),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(
    TextEditingController controller, {
    String hint = '',
  }) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(
    TextEditingController controller,
    String hint, {
    GlobalKey? fieldKey,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 36,
      child: TextField(
        key: fieldKey,
        controller: controller,
        readOnly: true,
        onTap: onTap,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
          ),
        ),
      ),
    );
  }
}
