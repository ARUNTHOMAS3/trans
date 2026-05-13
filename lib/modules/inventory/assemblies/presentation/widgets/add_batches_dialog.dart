import 'package:flutter/material.dart';

import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class AddBatchesDialog extends StatefulWidget {
  final String productName;
  final String warehouseName;
  final double totalQuantity;
  final List<String> existingBatches;

  const AddBatchesDialog({
    super.key,
    required this.productName,
    required this.warehouseName,
    required this.totalQuantity,
    this.existingBatches = const [],
  });

  @override
  State<AddBatchesDialog> createState() => _AddBatchesDialogState();
}

class _AddBatchesDialogState extends State<AddBatchesDialog> {
  bool _overwriteLineItem = false;
  double _quantityToBeAdded = 0;

  final List<BatchRowControllers> _batchRows = [];

  @override
  void initState() {
    super.initState();
    _addNewBatch();
  }

  @override
  void dispose() {
    for (var row in _batchRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addNewBatch({bool isExisting = false}) {
    setState(() {
      final controllers = BatchRowControllers(isExistingBatch: isExisting);
      controllers.quantity.addListener(_calculateTotalAdded);
      _batchRows.add(controllers);
      _calculateTotalAdded();
    });
  }

  void _removeBatch(int index) {
    if (_batchRows.length > 1) {
      setState(() {
        final controllers = _batchRows.removeAt(index);
        controllers.dispose();
        _calculateTotalAdded();
      });
    }
  }

  void _calculateTotalAdded() {
    double total = 0;
    for (var row in _batchRows) {
      total += double.tryParse(row.quantity.text) ?? 0;
    }
    setState(() {
      _quantityToBeAdded = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 1000,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSubHeader(),
                    const SizedBox(height: 20),
                    _buildProductInfoRow(),
                    const SizedBox(height: 16),
                    _buildOverwriteToggle(),
                    const SizedBox(height: 24),
                    _buildBatchTable(),
                    const SizedBox(height: 16),
                    _buildBatchActions(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Add Batches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader() {
    return Row(
      children: [
        const Icon(
          Icons.warehouse_outlined,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          'Warehouse : ',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Text(
          widget.warehouseName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildProductInfoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.bgDisabled)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.productName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Row(
            children: [
              _infoItem('Total Quantity', '${widget.totalQuantity.toInt()}'),
              const SizedBox(width: 24),
              _infoItem(
                'Quantity to be added',
                '${_quantityToBeAdded.toInt()}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Row(
      children: [
        Text(
          '$label : ',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildOverwriteToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Checkbox(
          value: _overwriteLineItem,
          onChanged: (val) => setState(() => _overwriteLineItem = val ?? false),
          activeColor: AppTheme.primaryBlueDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Text(
          'Overwrite the line item with ${widget.totalQuantity.toInt()} quantities',
          style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.help_outline, size: 14, color: AppTheme.textMuted),
      ],
    );
  }

  Widget _buildBatchTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: AppTheme.bgLight,
            child: Row(
              children: [
                _headerCell('BATCH REFERENCE*', flex: 3, isRequired: true),
                _headerCell('MANUFACTURER BATCH#', flex: 3),
                _headerCell('MANUFACTURED DATE', flex: 3),
                _headerCell('EXPIRY DATE', flex: 3),
                _headerCell('QUANTITY IN*', flex: 2, isRequired: true),
                const SizedBox(width: 30),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _batchRows.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => _buildBatchRow(index),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 1, bool isRequired = false}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: RichText(
          text: TextSpan(
            text: label.replaceAll('*', ''),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.errorRed,
              letterSpacing: 0.5,
            ),
            children: isRequired
                ? [
                    const TextSpan(
                      text: '*',
                      style: TextStyle(color: AppTheme.errorRed),
                    ),
                  ]
                : [],
          ),
        ),
      ),
    );
  }

  Widget _buildBatchRow(int index) {
    final row = _batchRows[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          // Batch Reference - Toggle between TextField and Dropdown
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                height: 36,
                child: row.isExistingBatch
                    ? FormDropdown<String>(
                        value: row.reference.text.isEmpty
                            ? null
                            : row.reference.text,
                        items: widget.existingBatches,
                        hint: widget.existingBatches.isEmpty
                            ? 'No existing batches'
                            : 'Select Batch',
                        height: 36,
                        onChanged: (val) {
                          setState(() {
                            row.reference.text = val ?? '';
                          });
                        },
                      )
                    : TextField(
                        controller: row.reference,
                        style: const TextStyle(fontSize: 13),
                        decoration: _inputDecoration('Enter Batch#'),
                      ),
              ),
            ),
          ),
          _inputCell(row.mfrBatch, 'Enter MFR Batch#', flex: 3),
          _inputCell(row.mfrDate, 'dd-MM-yyyy', flex: 3, isDate: true),
          _inputCell(row.expiryDate, 'dd-MM-yyyy', flex: 3, isDate: true),
          _inputCell(row.quantity, '1', flex: 2, isNumber: true),
          InkWell(
            onTap: () => _removeBatch(index),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.cancel, size: 22, color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputCell(
    TextEditingController controller,
    String hint, {
    int flex = 1,
    bool isDate = false,
    bool isNumber = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          height: 36,
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(fontSize: 13),
            decoration: _inputDecoration(hint),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.primaryBlueDark),
      ),
    );
  }

  Widget _buildBatchActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _actionLink('+ New Batch', () => _addNewBatch(isExisting: false)),
            const SizedBox(width: 16),
            _actionLink(
              '+ Existing Batch',
              () => _addNewBatch(isExisting: true),
            ),
          ],
        ),
        Text(
          'Batches added: ${_batchRows.length}/100',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _actionLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.primaryBlueDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
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

class BatchRowControllers {
  final bool isExistingBatch;
  final reference = TextEditingController();
  final mfrBatch = TextEditingController();
  final mfrDate = TextEditingController();
  final expiryDate = TextEditingController();
  final quantity = TextEditingController(text: '1');

  BatchRowControllers({this.isExistingBatch = false});

  void dispose() {
    reference.dispose();
    mfrBatch.dispose();
    mfrDate.dispose();
    expiryDate.dispose();
    quantity.dispose();
  }
}
