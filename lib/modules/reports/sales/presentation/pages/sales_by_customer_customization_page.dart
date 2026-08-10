import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customization_scaffold.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customization_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customization_select_field.dart';

class SalesByCustomerCustomizationPage extends StatefulWidget {
  const SalesByCustomerCustomizationPage({super.key});

  @override
  State<SalesByCustomerCustomizationPage> createState() => _SalesByCustomerCustomizationPageState();
}

class _SalesByCustomerCustomizationPageState extends State<SalesByCustomerCustomizationPage> {
  String _selectedNavId = 'general';
  String _selectedDateRange = 'This Year';
  String _selectedCompareWith = 'None';
  String _selectedEntity = 'None';
  final Map<String, bool> _columns = <String, bool>{
    'Name': true,
    'Invoice Count': true,
    'Sales': true,
    'Sales With Tax': true,
    'Customer Type': true,
  };
  final Map<String, bool> _grouping = <String, bool>{
    'Group by Customer': true,
    'Group by Customer Type': false,
  };
  final Map<String, bool> _sorting = <String, bool>{
    'Sort by Sales': true,
    'Sort by Customer Name': false,
  };

  @override
  Widget build(BuildContext context) {
    return ReportCustomizationScaffold(
      title: 'Customize Report',
      navItems: const [
        ('general', 'General'),
        ('columns', 'Show / Hide Columns'),
      ],
      selectedNavId: _selectedNavId,
      onNavChanged: (value) => setState(() => _selectedNavId = value),
      onBack: () => Navigator.of(context).maybePop(),
      onClose: () => Navigator.of(context).maybePop(),
      onPrimaryAction: () => Navigator.of(context).maybePop(),
      onSecondaryAction: () => Navigator.of(context).maybePop(),
      child: _selectedNavId == 'general' ? _buildGeneralTab() : _buildColumnsTab(),
    );
  }

  Widget _buildGeneralTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportCustomizationSection(
          title: 'Date Range',
          showTopDivider: false,
          child: ReportCustomizationSelectField(
            value: _selectedDateRange,
            options: const ['This Year', 'This Month', 'This Quarter'],
            leadingIcon: LucideIcons.calendarDays,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedDateRange = value);
            },
          ),
        ),
        ReportCustomizationSection(
          title: 'Compare With',
          child: ReportCustomizationSelectField(
            value: _selectedCompareWith,
            options: const ['None', 'Previous Period', 'Previous Year'],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedCompareWith = value);
            },
          ),
        ),
        ReportCustomizationSection(
          title: 'Entities :',
          child: ReportCustomizationSelectField(
            value: _selectedEntity,
            options: const ['None', 'All Entities'],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedEntity = value);
            },
          ),
        ),
        ReportCustomizationSection(
          title: 'Advanced Filters',
          helperText: 'Use advanced filters to filter the report based on the fields of Reports, Locations, Contacts.',
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(
              LucideIcons.plusCircle,
              size: AppTheme.space16,
              color: AppTheme.primaryBlue,
            ),
            label: Text(
              'Add Filters',
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportCustomizationSection(
          title: 'Grouping',
          showTopDivider: false,
          child: Column(
            children: _grouping.entries
                .map(
                  (entry) => CheckboxListTile(
                    value: entry.value,
                    onChanged: (value) {
                      setState(() => _grouping[entry.key] = value ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(entry.key, style: AppTheme.bodyText),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        ReportCustomizationSection(
          title: 'Column Customization',
          child: Column(
            children: _columns.entries
                .map(
                  (entry) => CheckboxListTile(
                    value: entry.value,
                    onChanged: (value) {
                      setState(() => _columns[entry.key] = value ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(entry.key, style: AppTheme.bodyText),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        ReportCustomizationSection(
          title: 'Sorting',
          child: Column(
            children: _sorting.entries
                .map(
                  (entry) => CheckboxListTile(
                    value: entry.value,
                    onChanged: (value) {
                      setState(() => _sorting[entry.key] = value ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(entry.key, style: AppTheme.bodyText),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}
