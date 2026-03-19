part of '../sales_customer_create.dart';

extension _CustomFieldsSection on _SalesCustomerCreateScreenState {
  Widget _buildCustomFields() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No custom fields configured',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Custom customer fields will appear here after they are configured from the backend settings.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
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
