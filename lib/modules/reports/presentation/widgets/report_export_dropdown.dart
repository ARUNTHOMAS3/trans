import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_export_menu_item.dart';

class ReportExportDropdown extends StatelessWidget {
  final double width;
  final VoidCallback? onPdf;
  final VoidCallback? onXlsx;
  final VoidCallback? onXls;
  final VoidCallback? onCsv;
  final VoidCallback? onZohoSheet;
  final VoidCallback? onPrint;
  final VoidCallback? onPrintPreference;
  final VoidCallback onCloseMenu;

  static const double estimatedHeight = 356;

  const ReportExportDropdown({
    super.key,
    required this.width,
    this.onPdf,
    this.onXlsx,
    this.onXls,
    this.onCsv,
    this.onZohoSheet,
    this.onPrint,
    this.onPrintPreference,
    required this.onCloseMenu,
  });

  void _handleTap(VoidCallback? callback) {
    callback?.call();
    onCloseMenu();
  }

  @override
  Widget build(BuildContext context) {
    final popupRadius = BorderRadius.circular(6);

    return Container(
      width: width,
      constraints: const BoxConstraints(maxWidth: AppTheme.space64 * 4.5),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: popupRadius,
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: popupRadius,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ReportExportSectionHeader(label: 'EXPORT AS'),
              ReportExportMenuItem(
                label: 'PDF',
                indent: AppTheme.space12,
                onTap: () => _handleTap(onPdf),
              ),
              ReportExportMenuItem(
                label: 'XLSX (Microsoft Excel)',
                indent: AppTheme.space12,
                onTap: () => _handleTap(onXlsx),
              ),
              ReportExportMenuItem(
                label: 'XLS (Microsoft Excel 1997-2004 Compatible)',
                indent: AppTheme.space12,
                onTap: () => _handleTap(onXls),
              ),
              ReportExportMenuItem(
                label: 'CSV (Comma Separated Value)',
                indent: AppTheme.space12,
                onTap: () => _handleTap(onCsv),
              ),
              ReportExportMenuItem(
                label: 'Export to Zoho Sheet',
                indent: AppTheme.space12,
                onTap: () => _handleTap(onZohoSheet),
              ),
              const SizedBox(height: AppTheme.space4),
              const ReportExportSectionHeader(label: 'PRINT'),
              ReportExportMenuItem(
                label: 'Print',
                indent: AppTheme.space12,
                onTap: () => _handleTap(onPrint),
              ),
              ReportExportMenuItem(
                label: 'Print Preference',
                indent: AppTheme.space12,
                onTap: () => _handleTap(onPrintPreference),
              ),
              const SizedBox(height: AppTheme.space4),
            ],
          ),
        ),
      ),
    );
  }
}
