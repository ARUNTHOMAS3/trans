part of '../sales_customer_create.dart';

extension _CustomFieldsSection on _SalesCustomerCreateScreenState {
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
}
