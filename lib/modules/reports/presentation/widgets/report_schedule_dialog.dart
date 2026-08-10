import 'package:flutter/material.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/responsive/responsive_dialog.dart';

class ReportScheduleDialog extends StatefulWidget {
  final String reportName;

  const ReportScheduleDialog({
    super.key,
    required this.reportName,
  });

  static Future<void> show(BuildContext context, {required String reportName}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ReportScheduleDialog(reportName: reportName),
    );
  }

  @override
  State<ReportScheduleDialog> createState() => _ReportScheduleDialogState();
}

class _ReportScheduleDialogState extends State<ReportScheduleDialog> {
  static const _frequencies = ['Weekly', 'Daily', 'Monthly'];
  static const _hours = [
    '00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11',
    '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23',
  ];
  static const _minutes = ['00', '15', '30', '45'];
  static const _attachOptions = [
    'PDF',
    'CSV (Comma Separated Value)',
    'XLS (Microsoft Excel 1997-2004 Compatible)',
  ];

  late final TextEditingController _additionalRecipientsController;
  late DateTime _startDate;
  String _frequency = _frequencies.first;
  String _selectedHour = '11';
  String _selectedMinute = '30';
  String _selectedAttachOption = _attachOptions.first;
  final List<String> _emailRecipients = ['zabnixprivatelimited'];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(2026, 7, 10);
    _additionalRecipientsController = TextEditingController();
  }

  @override
  void dispose() {
    _additionalRecipientsController.dispose();
    super.dispose();
  }

  String get _frequencyDescription {
    switch (_frequency) {
      case 'Daily':
        return 'Report will be generated and sent on a daily basis.';
      case 'Monthly':
        return 'Report will be generated and sent on a monthly basis.';
      case 'Weekly':
      default:
        return 'Report will be generated and sent on a weekly basis.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveDialog.wrap(
      context,
      Material(
        color: AppTheme.backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space20,
                    AppTheme.space16,
                    AppTheme.space20,
                    AppTheme.space20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopSection(),
                      const SizedBox(height: AppTheme.space24),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      const SizedBox(height: AppTheme.space20),
                      Text('Recipient Details', style: AppTheme.sectionHeader),
                      const SizedBox(height: AppTheme.space20),
                      _buildRecipientSection(),
                      const SizedBox(height: AppTheme.space24),
                      _buildNoteBox(),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space16,
        AppTheme.space20,
        AppTheme.space16,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Schedule Report', style: AppTheme.pageTitle),
                const SizedBox(height: AppTheme.space8),
                RichText(
                  text: TextSpan(
                    style: AppTheme.bodyText,
                    children: [
                      TextSpan(
                        text: 'Report Name : ',
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: widget.reportName,
                        style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(AppTheme.space4),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: Icon(
                LucideIcons.x,
                size: AppTheme.space18,
                color: AppTheme.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormRow(
          label: 'Frequency*',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSelectField(
                width: AppTheme.space64 * 1.7,
                value: _frequency,
                options: _frequencies,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _frequency = value);
                  }
                },
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppTheme.space12),
                  child: Text(
                    _frequencyDescription,
                    style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space16),
        _buildFormRow(
          label: 'Start Date & Time*',
          child: Wrap(
            spacing: AppTheme.space12,
            runSpacing: AppTheme.space12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildDateField(),
              _buildSelectField(
                width: AppTheme.space64 * 1.35,
                value: _selectedHour,
                options: _hours,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedHour = value);
                  }
                },
                helperText: 'Hours',
              ),
              _buildSelectField(
                width: AppTheme.space64 * 1.35,
                value: _selectedMinute,
                options: _minutes,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMinute = value);
                  }
                },
                helperText: 'Minutes',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormRow(
          label: 'Email Recipients*',
          child: _buildRecipientsField(),
        ),
        const SizedBox(height: AppTheme.space16),
        _buildFormRow(
          label: 'Additional Recipients',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _additionalRecipientsController,
                maxLines: 3,
                style: AppTheme.bodyText,
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                'Use comma(,) to separate more than one email address.',
                style: AppTheme.metaHelper.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space16),
        _buildFormRow(
          label: 'Attach Report As*',
          child: RadioGroup<String>(
            groupValue: _selectedAttachOption,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedAttachOption = value);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _attachOptions
                  .map(
                    (option) => InkWell(
                      onTap: () => setState(() => _selectedAttachOption = option),
                      borderRadius: BorderRadius.circular(AppTheme.space4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: option,
                              activeColor: AppTheme.primaryBlue,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Flexible(
                              child: Text(option, style: AppTheme.bodyText),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.infoBg,
        borderRadius: BorderRadius.circular(AppTheme.space8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.info, size: AppTheme.space14, color: AppTheme.primaryBlue),
              const SizedBox(width: AppTheme.space8),
              Text(
                'Note:',
                style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          _buildNoteLine(
            'The scheduled report will include data based on the access permissions of the user who schedules it.',
          ),
          const SizedBox(height: AppTheme.space8),
          _buildNoteLine(
            'The generated report will contain only a maximum of 25,000 records.',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space16,
        AppTheme.space20,
        AppTheme.space16,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: AppTheme.buttonHeight,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: AppTheme.backgroundColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.space4),
                ),
                textStyle: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
              ),
              child: const Text('Save'),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow({required String label, required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 680;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(label),
              const SizedBox(height: AppTheme.space8),
              child,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: AppTheme.space64 * 2.25,
              child: Padding(
                padding: const EdgeInsets.only(top: AppTheme.space12),
                child: _buildLabel(label),
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: AppTheme.bodyText.copyWith(
        color: AppTheme.errorRed,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDateField() {
    return SizedBox(
      width: AppTheme.space64 * 2.8,
      child: TextField(
        readOnly: true,
        style: AppTheme.bodyText,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            LucideIcons.calendar,
            size: AppTheme.space16,
            color: AppTheme.textPrimary,
          ),
          hintText: ReportFormatterCache.date('dd-MM-yyyy').format(_startDate),
        ),
      ),
    );
  }

  Widget _buildSelectField({
    required double width,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    String? helperText,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            style: AppTheme.bodyText.copyWith(color: AppTheme.textPrimary),
            icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
            decoration: const InputDecoration(),
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  ),
                )
                .toList(growable: false),
            onChanged: onChanged,
          ),
          if (helperText != null) ...[
            const SizedBox(height: AppTheme.space6),
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.space2),
              child: Text(
                helperText,
                style: AppTheme.metaHelper.copyWith(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipientsField() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.space8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space8,
              children: _emailRecipients
                  .map(
                    (recipient) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space10,
                        vertical: AppTheme.space6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.selectionActiveBg,
                        borderRadius: BorderRadius.circular(AppTheme.space6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            recipient,
                            style: AppTheme.metaHelper.copyWith(color: AppTheme.textPrimary),
                          ),
                          const SizedBox(width: AppTheme.space6),
                          const Icon(
                            LucideIcons.x,
                            size: AppTheme.space12,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildNoteLine(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppTheme.space6),
          child: Container(
            width: AppTheme.space4,
            height: AppTheme.space4,
            decoration: const BoxDecoration(
              color: AppTheme.textPrimary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space10),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
