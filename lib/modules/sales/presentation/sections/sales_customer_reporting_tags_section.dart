part of '../sales_customer_create.dart';

extension _ReportingTagsSection on _SalesCustomerCreateScreenState {
  Widget _buildReportingTags() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: _buildFormRow(
        label: 'schedule',
        tooltip: 'Tag this customer for reporting grouping.',
        child: FormDropdown<String>(
          height: _inputHeight,
          value: reportingTag,
          items: const ['Select', 'Monthly', 'Quarterly'],
          onChanged: (v) => _state(() => reportingTag = v ?? reportingTag),
        ),
      ),
    );
  }
}
