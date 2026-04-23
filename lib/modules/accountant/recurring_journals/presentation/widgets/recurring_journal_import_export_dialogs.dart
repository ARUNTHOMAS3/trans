import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class RecurringJournalImportDialog extends StatelessWidget {
  final VoidCallback onImport;

  const RecurringJournalImportDialog({super.key, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, 'Import Recurring Journals'),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload a .CSV, .TSV or .XLS file to import recurring journals.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildUploadBox(),
                  const SizedBox(height: 24),
                  const Text(
                    'Note: Ensure your file follows the format of the sample file.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Download Sample File'),
                  ),
                ],
              ),
            ),
            _buildFooter(context, 'Continue', onImport),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        border: Border.all(
          color: AppTheme.borderColor,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.uploadCloud,
            size: 32,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 12),
          const Text(
            'Drag and drop your file here, or browse',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    String actionLabel,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: Text(actionLabel),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(color: AppTheme.borderColor),
              foregroundColor: AppTheme.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class RecurringJournalExportDialog extends StatefulWidget {
  final VoidCallback onExport;

  const RecurringJournalExportDialog({super.key, required this.onExport});

  @override
  State<RecurringJournalExportDialog> createState() =>
      _RecurringJournalExportDialogState();
}

class _RecurringJournalExportDialogState
    extends State<RecurringJournalExportDialog> {
  String _fileFormat = 'CSV';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, 'Export Recurring Journals'),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select the format in which you want to export your data.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  RadioGroup<String>(
                    groupValue: _fileFormat,
                    onChanged: (v) {
                      if (v != null) setState(() => _fileFormat = v);
                    },
                    child: Column(
                      children: [
                        _buildFormatOption('CSV', 'Comma Separated Values'),
                        _buildFormatOption('XLS', 'Microsoft Excel 1997-2004'),
                        _buildFormatOption('XLSX', 'Microsoft Excel'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildFooter(context, 'Export', widget.onExport),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption(String value, String label) {
    return RadioListTile<String>(
      title: Text(value),
      subtitle: Text(label, style: const TextStyle(fontSize: 11)),
      value: value,
      activeColor: AppTheme.primaryBlue,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildFooter(
    BuildContext context,
    String actionLabel,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
