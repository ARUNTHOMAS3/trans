part of '../sales_customer_create.dart';

extension _RemarksSection on _SalesCustomerCreateScreenState {
  Widget _buildRemarks() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: _buildFormRow(
        label: 'Remarks (For Internal Use)',
        child: CustomTextField(
          height: 120,
          controller: remarksCtrl,
          maxLines: 5,
          hintText: 'Add remarks...',
          forceUppercase: false,
        ),
      ),
    );
  }
}
