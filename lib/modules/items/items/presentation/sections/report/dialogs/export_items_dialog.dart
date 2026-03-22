import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

Future<void> showExportItemsDialog(BuildContext context) {
  String module = 'items';
  String period = 'all';
  String fileFormat = 'csv';
  bool includePii = false;
  bool batchNumbers = false;
  bool serialNumbers = false;
  final TextEditingController passwordCtrl = TextEditingController();

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Export Items',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, _, __) {
      return SafeArea(
        child: Center(
          child: Material(
            elevation: 18,
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: StatefulBuilder(
                builder: (ctx, setState) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --------------------------------------------------
                        // HEADER
                        // --------------------------------------------------
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppTheme.borderColor),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Export Items',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                        ),

                        // --------------------------------------------------
                        // BODY
                        // --------------------------------------------------
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoBox(),

                              const SizedBox(height: 20),

                              // MODULE
                              const _Label('Module*', required: true),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 40,
                                child: DropdownButtonFormField<String>(
                                  initialValue: module,
                                  decoration: _inputDecoration(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'items',
                                      child: Text('Items'),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => module = v);
                                    }
                                  },
                                ),
                              ),

                              const SizedBox(height: 24),

                              // PERIOD
                              const _Label('Period'),
                              const SizedBox(height: 6),
                              RadioGroup<String>(
                                groupValue: period,
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => period = v);
                                  }
                                },
                                child: Row(
                                  children: const [
                                    _RadioRow(value: 'all', label: 'All items'),
                                    SizedBox(width: 24),
                                    _RadioRow(
                                      value: 'specific',
                                      label: 'Specific Period',
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // EXPORT TEMPLATE
                              const _Label('Export Template'),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 40,
                                child: DropdownButtonFormField<String>(
                                  initialValue: null,
                                  decoration: _inputDecoration(
                                    hint: 'Select an Export Template',
                                  ),
                                  items: const [],
                                  onChanged: (_) {},
                                ),
                              ),

                              const SizedBox(height: 24),

                              // DECIMAL FORMAT
                              const _Label('Decimal Format*', required: true),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 40,
                                child: DropdownButtonFormField<String>(
                                  initialValue: null,
                                  decoration: _inputDecoration(
                                    hint: 'Select Decimal Format',
                                  ),
                                  items: const [],
                                  onChanged: (_) {},
                                ),
                              ),

                              const SizedBox(height: 24),

                              // FILE FORMAT
                              const _Label(
                                'Export File Format*',
                                required: true,
                              ),
                              const SizedBox(height: 8),
                              RadioGroup<String>(
                                groupValue: fileFormat,
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => fileFormat = v);
                                  }
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    _RadioRow(
                                      value: 'csv',
                                      label: 'CSV (Comma Separated Value)',
                                    ),
                                    _RadioRow(
                                      value: 'xls',
                                      label: 'XLS (Microsoft Excel 1997–2004)',
                                    ),
                                    _RadioRow(
                                      value: 'xlsx',
                                      label: 'XLSX (Microsoft Excel)',
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              CheckboxListTile(
                                value: includePii,
                                onChanged: (v) =>
                                    setState(() => includePii = v ?? false),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text(
                                  'Include Sensitive Personally Identifiable Information (PII)',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // PASSWORD
                              const _Label('File Protection Password'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: passwordCtrl,
                                obscureText: true,
                                decoration: _inputDecoration(
                                  suffix: const Icon(
                                    Icons.lock_outline,
                                    size: 18,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),

                              const SizedBox(height: 24),

                              const _Label(
                                'Select the additional fields you want to export',
                              ),
                              CheckboxListTile(
                                value: batchNumbers,
                                onChanged: (v) =>
                                    setState(() => batchNumbers = v ?? false),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text(
                                  'Batch Numbers',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              CheckboxListTile(
                                value: serialNumbers,
                                onChanged: (v) =>
                                    setState(() => serialNumbers = v ?? false),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Text(
                                  'Serial Numbers',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --------------------------------------------------
                        // FOOTER
                        // --------------------------------------------------
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                          child: Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Export started'),
                                    ),
                                  );
                                },
                                child: const Text('Export'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

// ------------------------------------------------------------
// HELPERS
// ------------------------------------------------------------

class _RadioRow extends StatelessWidget {
  final String value;
  final String label;

  const _RadioRow({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<String>(value: value, visualDensity: VisualDensity.compact),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool required;

  const _Label(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: required
            ? const Color.fromARGB(255, 245, 10, 2)
            : AppTheme.textBody,
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F2FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'You can export your data in CSV, XLS or XLSX format.',
        style: TextStyle(fontSize: 12),
      ),
    );
  }
}

InputDecoration _inputDecoration({String? hint, Widget? suffix}) {
  return InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    suffixIcon: suffix,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
  );
}
