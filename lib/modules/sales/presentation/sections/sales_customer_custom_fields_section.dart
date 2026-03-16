part of '../sales_customer_create.dart';

extension _CustomFieldsSection on _SalesCustomerCreateScreenState {
  Widget _buildCustomFields() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormRow(
            label: 'demo field',
            child: CustomTextField(
              height: _inputHeight,
              controller: demoFieldCtrl,
              forceUppercase: false,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Manage Custom Fields'),
          ),
        ],
      ),
    );
  }
}
