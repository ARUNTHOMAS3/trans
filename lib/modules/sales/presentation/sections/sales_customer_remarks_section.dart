part of '../sales_customer_create.dart';

extension _RemarksSection on _SalesCustomerCreateScreenState {
  Widget _buildRemarks() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Remarks',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(For Internal Use)',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF6B7280).withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: remarksCtrl,
            hintText: 'Add a note for internal use...',
            maxLines: 5,
            height: 120,
          ),
        ],
      ),
    );
  }
}
