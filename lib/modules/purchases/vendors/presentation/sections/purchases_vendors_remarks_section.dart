part of '../purchases_vendors_vendor_create.dart';

extension _MiscSections on _PurchasesVendorsVendorCreateScreenState {
  Widget _buildCustomFields() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48.0),
      child: Center(
        child: Text(
          "You've not created any Custom Fields.",
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }

  Widget _buildReportingTags() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48.0),
      child: Center(
        child: Text(
          "You've not created any Reporting Tags.",
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }

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
            controller: _remarksCtrl,
            hintText: 'Add a note for internal use...',
            maxLines: 5,
            height: 120,
          ),
        ],
      ),
    );
  }
}
