part of '../sales_customer_create.dart';

extension _ReportingTagsSection on _SalesCustomerCreateScreenState {
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
}
