import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/shared/widgets/inputs/radio_group.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/api/dio_client.dart';

import '../../../../shared/widgets/shortcut_handler.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/utils/error_handler.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/widgets/manual_journal_template_card.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/modules/accountant/models/accountant_lookup_models.dart'
    as lookup;
import 'package:zerpai_erp/modules/accountant/models/accountant_chart_of_accounts_account_model.dart'
    as coa;
import 'package:zerpai_erp/shared/widgets/inputs/account_tree_dropdown.dart'
    as dropdown;
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart' as di;
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/shared/models/account_node.dart' as shared;
import 'package:zerpai_erp/modules/accountant/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/providers/manual_journal_provider.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/providers/manual_journal_template_provider.dart';
import 'package:zerpai_erp/modules/accountant/repositories/accountant_repository.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';

import '../models/manual_journal_model.dart';
import '../../../../shared/services/draft_storage_service.dart';

class ManualJournalRow {
  String? accountId;
  String? accountName;
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController debitCtrl = TextEditingController(text: '');
  final TextEditingController creditCtrl = TextEditingController(text: '');
  final FocusNode accountFocusNode = FocusNode();
  String? contactId;
  String? contactType;
  String? contactName;
  double rowHeight = 48;

  bool isExpanded = false;
  String? projectId;
  String? reportingTags;

  void dispose() {
    descriptionCtrl.dispose();
    debitCtrl.dispose();
    creditCtrl.dispose();
    accountFocusNode.dispose();
  }
}

class _PendingAttachment {
  final String name;
  final Uint8List bytes;
  final String mimeType;

  const _PendingAttachment({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  int get size => bytes.length;
}

class ManualJournalCreateScreen extends ConsumerStatefulWidget {
  final ManualJournal? initialJournal;
  final ManualJournalTemplate? template;
  final bool showTemplates;

  const ManualJournalCreateScreen({
    super.key,
    this.initialJournal,
    this.template,
    this.showTemplates = false,
  });

  @override
  ConsumerState<ManualJournalCreateScreen> createState() =>
      _ManualJournalCreateScreenState();
}

class _ManualJournalCreateScreenState
    extends ConsumerState<ManualJournalCreateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _journalDateKey = GlobalKey();

  late final TextEditingController journalNumberCtrl;
  late final TextEditingController referenceCtrl;
  late final TextEditingController notesCtrl;
  DateTime journalDate = DateTime.now();

  List<ManualJournalRow> rows = [];

  String? fiscalYearId;
  bool is13thMonthAdjustment = false;
  String reportingMethod = 'accrual_and_cash';
  late lookup.Currency selectedCurrency = const lookup.Currency(
    id: 'default',
    code: 'INR',
    name: 'Indian Rupee',
    symbol: '₹',
  );

  double totalDebit = 0.0;
  double totalCredit = 0.0;
  double difference = 0.0;
  bool isJournalNumberReadOnly = true;
  bool _isLoading = false;
  bool _showTemplateSidebar = false;
  bool _isDirty = false;
  // Ghost Draft
  static const _draftKey = 'manual_journal_create';
  Timer? _draftTimer;
  bool _hasDraft = false;
  final List<_PendingAttachment> _pendingAttachments = [];
  final List<String> _validationErrors = [];
  final LayerLink _attachmentsLink = LayerLink();
  OverlayEntry? _attachmentsOverlayEntry;
  static const int _maxAttachmentFiles = 10;
  static const int _maxAttachmentFileSizeBytes = 10 * 1024 * 1024;
  bool get isEditMode => widget.initialJournal != null;

  @override
  void initState() {
    super.initState();
    journalNumberCtrl = TextEditingController();
    referenceCtrl = TextEditingController();
    notesCtrl = TextEditingController();

    if (isEditMode) {
      _hydrateFromJournal(widget.initialJournal!);
    } else if (widget.template != null) {
      _hydrateFromTemplate(widget.template!);
      Future.microtask(_prefillJournalNumberFromSettings);
    } else {
      if (widget.showTemplates) {
        _showTemplateSidebar = true;
        Future.microtask(
          () =>
              ref.read(manualJournalTemplateProvider.notifier).fetchTemplates(),
        );
      }
      _addRow();
      _addRow();
      Future.microtask(_prefillJournalNumberFromSettings);
    }

    // Ghost Draft: start auto-save timer and check for existing draft (create only).
    if (!isEditMode) {
      if (widget.template == null) {
        _hasDraft = DraftStorageService.hasDraft(_draftKey);
      }
      _draftTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _saveDraft(),
      );
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    journalNumberCtrl.dispose();
    referenceCtrl.dispose();
    notesCtrl.dispose();
    for (final row in rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _prefillJournalNumberFromSettings() async {
    try {
      final scope = ref.read(journalSettingsScopeProvider);
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '/accountant/journal-number-settings/next',
        queryParameters: {
          'orgId': scope['orgId'],
          if (scope['outletId'] != null) 'outletId': scope['outletId'],
          if (scope['userId'] != null) 'userId': scope['userId'],
        },
      );
      final raw = response.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(response.data as Map<String, dynamic>)
          : <String, dynamic>{};
      final settings = raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : raw;
      final bool autoGen = settings['auto_generate'] == true;
      final bool overrideAllowed =
          settings['is_manual_override_allowed'] == true;
      final prefix = _stringValue(settings, 'prefix', 'MJ');
      final nextNum = _intValue(settings, 'next_number', 1);
      final generatedNumber = _stringValue(
        settings,
        'journal_number',
        '$prefix-$nextNum',
      );

      if (!mounted) return;

      setState(() {
        isJournalNumberReadOnly = autoGen && !overrideAllowed;
      });

      if (autoGen) {
        journalNumberCtrl.text = generatedNumber;
      } else {
        final current = journalNumberCtrl.text.trim();
        if (current.isEmpty || current.startsWith('MJ-')) {
          journalNumberCtrl.text = '$prefix-$nextNum';
        }
      }
    } catch (_) {
      try {
        final settings = await ref.refresh(journalSettingsProvider.future);
        final bool autoGen = settings['auto_generate'] == true;
        final bool overrideAllowed =
            settings['is_manual_override_allowed'] == true;
        final prefix = _stringValue(settings, 'prefix', 'MJ');
        final nextNum = _intValue(settings, 'next_number', 1);

        if (!mounted) return;

        setState(() {
          isJournalNumberReadOnly = autoGen && !overrideAllowed;
        });
        journalNumberCtrl.text = '$prefix-$nextNum';
      } catch (_) {
        journalNumberCtrl.text =
            'MJ-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}';
      }
    }
  }

  String _buildManualJournalNumber({
    required String prefix,
    required String input,
  }) {
    final cleanPrefix = prefix.trim().replaceAll(RegExp(r'-+$'), '');
    final value = input.trim();

    if (cleanPrefix.isEmpty) return value;
    if (value.isEmpty) return '$cleanPrefix-1';

    final lp = cleanPrefix.toLowerCase();
    final lv = value.toLowerCase();
    if (lv == lp || lv.startsWith('$lp-')) return value;

    return '$cleanPrefix-$value';
  }

  String _extractManualNumberPart({
    required String fullNumber,
    required String prefix,
    required String fallback,
  }) {
    final value = fullNumber.trim();
    final cleanPrefix = prefix.trim().replaceAll(RegExp(r'-+$'), '');
    if (value.isEmpty) return fallback;

    if (cleanPrefix.isNotEmpty) {
      final marker = '$cleanPrefix-';
      if (value.toLowerCase().startsWith(marker.toLowerCase())) {
        final suffix = value.substring(marker.length).trim();
        return suffix.isEmpty ? fallback : suffix;
      }
    }

    final firstDash = value.indexOf('-');
    if (firstDash > 0 && firstDash < value.length - 1) {
      return value.substring(firstDash + 1).trim();
    }

    return value;
  }

  void _hydrateFromJournal(ManualJournal journal) {
    journalDate = journal.journalDate;
    fiscalYearId = journal.fiscalYearId;
    is13thMonthAdjustment = journal.is13thMonthAdjustment;
    reportingMethod = journal.reportingMethod;
    final option = defaultCurrencyOptions.firstWhere(
      (c) => c.code == journal.currency,
      orElse: () => defaultCurrencyOptions.first,
    );
    selectedCurrency = lookup.Currency(
      id: 'default-${option.code}',
      code: option.code,
      name: option.name,
      symbol: option.symbol,
      decimals: option.decimals,
      format: option.format,
    );

    journalNumberCtrl.text = journal.journalNumber;
    referenceCtrl.text = journal.referenceNumber ?? '';
    notesCtrl.text = journal.notes ?? '';
    isJournalNumberReadOnly = false;

    for (final item in journal.items) {
      _addRow(item: item, notify: false);
    }

    if (rows.length < 2) {
      _addRow(notify: false);
      _addRow(notify: false);
    }

    _calculateTotals();
  }

  void _hydrateFromTemplate(ManualJournalTemplate template) {
    setState(() {
      for (final row in rows) {
        row.dispose();
      }
      rows.clear();

      reportingMethod = template.reportingMethod;
      final option = defaultCurrencyOptions.firstWhere(
        (c) => c.code == template.currency,
        orElse: () => defaultCurrencyOptions.first,
      );
      selectedCurrency = lookup.Currency(
        id: 'default-${option.code}',
        code: option.code,
        name: option.name,
        symbol: option.symbol,
        decimals: option.decimals,
        format: option.format,
      );
      referenceCtrl.text = template.referenceNumber ?? '';
      notesCtrl.text = template.notes ?? '';

      for (final item in template.items) {
        final row = ManualJournalRow();
        row.accountId = item.accountId;
        row.accountName = item.accountName;
        row.descriptionCtrl.text = item.description ?? '';
        row.contactId = item.contactId;
        row.contactType = item.contactType;
        row.contactName = item.contactName;
        row.debitCtrl.text = item.debit.toString();
        row.creditCtrl.text = item.credit.toString();
        row.projectId = item.projectId;
        row.reportingTags = item.reportingTags;
        if (row.projectId != null || row.reportingTags != null) {
          row.isExpanded = true;
        }
        rows.add(row);
      }

      if (rows.length < 2) {
        _addRow(notify: false);
        _addRow(notify: false);
      }

      _calculateTotals();
    });
  }

  String _stringValue(Map<String, dynamic> map, String key, String fallback) {
    final value = map[key];
    if (value == null) return fallback;
    final parsed = value.toString().trim();
    return parsed.isEmpty ? fallback : parsed;
  }

  int _intValue(Map<String, dynamic> map, String key, int fallback) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? "");
    return parsed ?? fallback;
  }

  Future<void> _openJournalNumberPreferencesDialog() async {
    Map<String, dynamic> settings;
    try {
      settings = await ref.read(journalSettingsProvider.future);
    } catch (_) {
      settings = const {
        'auto_generate': true,
        'prefix': 'MJ',
        'next_number': 1,
        'is_manual_override_allowed': false,
      };
    }

    if (!mounted) return;

    final defaultAutoGenerate = settings['auto_generate'] == true;
    final defaultPrefix = _stringValue(settings, 'prefix', 'MJ');
    final defaultNextNumber = _intValue(settings, 'next_number', 1);

    final prefixCtrl = TextEditingController(text: defaultPrefix);
    final nextNumberCtrl = TextEditingController(
      text: defaultNextNumber.toString(),
    );
    final manualJournalCtrl = TextEditingController(
      text: _extractManualNumberPart(
        fullNumber: journalNumberCtrl.text,
        prefix: defaultPrefix,
        fallback: defaultNextNumber.toString(),
      ),
    );
    var prefixDraft = defaultPrefix;

    bool autoGenerate = defaultAutoGenerate;
    bool isSaving = false;
    String? inlineError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              alignment: Alignment.topCenter,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              insetPadding: const EdgeInsets.only(
                top: 0,
                left: 24,
                right: 24,
                bottom: 20,
              ),
              child: SizedBox(
                width: 640,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Configure Journal Number Preferences',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              icon: const Icon(
                                LucideIcons.x,
                                size: 18,
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Auto-generating journal numbers can save your time. '
                              'Would you like to change your current setting?',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            RadioScope<bool>(
                              value: autoGenerate,
                              onChanged: (value) {
                                setDialogState(() {
                                  autoGenerate = value;
                                  inlineError = null;
                                });
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const RadioGroupItem<bool>(
                                    value: true,
                                    label: 'Auto-generate journal numbers',
                                    activeColor: AppTheme.primaryBlue,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  if (autoGenerate)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 18,
                                        top: 6,
                                        bottom: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 104,
                                            child: _dialogInputField(
                                              label: 'Prefix',
                                              controller: prefixCtrl,
                                              enabled: !isSaving,
                                              onChanged: (value) =>
                                                  prefixDraft = value,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          SizedBox(
                                            width: 240,
                                            child: _dialogInputField(
                                              label: 'Next Number',
                                              controller: nextNumberCtrl,
                                              enabled: !isSaving,
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  const RadioGroupItem<bool>(
                                    value: false,
                                    label:
                                        'Manually enter journal numbers for each entry',
                                    activeColor: AppTheme.primaryBlue,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  if (!autoGenerate)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 18,
                                        top: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 104,
                                            child: _dialogInputField(
                                              label: 'Prefix',
                                              controller: prefixCtrl,
                                              enabled: !isSaving,
                                              onChanged: (value) =>
                                                  prefixDraft = value,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          SizedBox(
                                            width: 240,
                                            child: _dialogInputField(
                                              label: 'Journal Number',
                                              controller: manualJournalCtrl,
                                              enabled: !isSaving,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (inlineError != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                inlineError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.errorRed,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      FocusScope.of(dialogContext).unfocus();
                                      await Future<void>.delayed(Duration.zero);

                                      final livePrefix =
                                          prefixCtrl.text.trim().isNotEmpty
                                          ? prefixCtrl.text.trim()
                                          : prefixDraft.trim();
                                      final normalizedPrefix =
                                          livePrefix.isEmpty
                                          ? 'MJ'
                                          : livePrefix;
                                      final parsedNext = int.tryParse(
                                        nextNumberCtrl.text.trim(),
                                      );
                                      final effectiveNextNumber =
                                          parsedNext ?? defaultNextNumber;
                                      final manualValue = manualJournalCtrl.text
                                          .trim();

                                      if (autoGenerate &&
                                          (parsedNext == null ||
                                              parsedNext < 1)) {
                                        setDialogState(() {
                                          inlineError =
                                              'Next Number must be 1 or greater.';
                                        });
                                        return;
                                      }

                                      if (!autoGenerate &&
                                          manualValue.isEmpty) {
                                        setDialogState(() {
                                          inlineError =
                                              'Journal Number is required for manual mode.';
                                        });
                                        return;
                                      }

                                      setDialogState(() {
                                        isSaving = true;
                                        inlineError = null;
                                      });

                                      var dialogClosed = false;
                                      try {
                                        final dio = ref.read(dioProvider);
                                        final scope = ref.read(
                                          journalSettingsScopeProvider,
                                        );
                                        await dio.post(
                                          '/accountant/journal-number-settings',
                                          data: {
                                            'autoGenerate': autoGenerate,
                                            'prefix': normalizedPrefix,
                                            'nextNumber': autoGenerate
                                                ? parsedNext
                                                : effectiveNextNumber,
                                            'isManualOverrideAllowed':
                                                !autoGenerate,
                                            'orgId': scope['orgId'],
                                            'outletId': scope['outletId'],
                                            'userId': scope['userId'],
                                          },
                                        );

                                        if (mounted) {
                                          ref.invalidate(
                                            journalSettingsProvider,
                                          );
                                          if (autoGenerate) {
                                            final latest = await ref.refresh(
                                              journalSettingsProvider.future,
                                            );
                                            final latestPrefix = _stringValue(
                                              latest,
                                              'prefix',
                                              normalizedPrefix,
                                            );
                                            final latestNext = _intValue(
                                              latest,
                                              'next_number',
                                              parsedNext ?? 1,
                                            );

                                            setState(() {
                                              isJournalNumberReadOnly = true;
                                              journalNumberCtrl.text =
                                                  '$latestPrefix-$latestNext';
                                            });
                                          } else {
                                            setState(() {
                                              isJournalNumberReadOnly = false;
                                              final composedManualNumber =
                                                  _buildManualJournalNumber(
                                                    prefix: normalizedPrefix,
                                                    input: manualValue,
                                                  );
                                              journalNumberCtrl.text =
                                                  composedManualNumber;
                                            });
                                          }
                                        }

                                        if (dialogContext.mounted) {
                                          dialogClosed = true;
                                          Navigator.of(dialogContext).pop();
                                        }
                                      } on DioException catch (e) {
                                        if (dialogContext.mounted) {
                                          setDialogState(() {
                                            inlineError =
                                                e.response?.data is Map
                                                ? ((e.response?.data['message']
                                                          ?.toString()) ??
                                                      'Failed to save journal number settings.')
                                                : 'Failed to save journal number settings.';
                                          });
                                        }
                                      } catch (_) {
                                        if (dialogContext.mounted) {
                                          setDialogState(() {
                                            inlineError =
                                                'Failed to save journal number settings.';
                                          });
                                        }
                                      } finally {
                                        if (!dialogClosed &&
                                            dialogContext.mounted) {
                                          setDialogState(() {
                                            isSaving = false;
                                          });
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                              ),
                              child: Text(isSaving ? 'Saving...' : 'Save'),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dialogInputField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: CustomTextField(
            controller: controller,
            height: 40,
            keyboardType: keyboardType,
            enabled: enabled,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }


  void _addRow({ManualJournalItem? item, bool notify = true}) {
    final row = ManualJournalRow();
    if (item != null) {
      row.accountId = item.accountId;
      row.accountName = item.accountName;
      row.descriptionCtrl.text = item.description ?? '';
      row.debitCtrl.text = item.debit.toStringAsFixed(2);
      row.creditCtrl.text = item.credit.toStringAsFixed(2);
      row.contactId = item.contactId;
      row.contactType = item.contactType;
      row.contactName = item.contactName;
      row.projectId = item.projectId;
      row.reportingTags = item.reportingTags;
      if (row.projectId != null || row.reportingTags != null) {
        row.isExpanded = true;
      }
    }
    row.debitCtrl.addListener(_calculateTotals);
    row.creditCtrl.addListener(_calculateTotals);

    if (notify) {
      setState(() => rows.add(row));
    } else {
      rows.add(row);
    }
  }

  void _calculateTotals() {
    double debit = 0;
    double credit = 0;
    for (var row in rows) {
      debit += double.tryParse(row.debitCtrl.text) ?? 0;
      credit += double.tryParse(row.creditCtrl.text) ?? 0;
    }
    setState(() {
      totalDebit = debit;
      totalCredit = credit;
      difference = (totalDebit - totalCredit).abs();
    });
  }

  // ── Ghost Draft ───────────────────────────────────────────────────────────

  void _saveDraft() {
    if (!mounted || isEditMode) return;
    final hasContent = referenceCtrl.text.isNotEmpty ||
        notesCtrl.text.isNotEmpty ||
        rows.any(
          (r) =>
              r.accountId != null ||
              r.debitCtrl.text.isNotEmpty ||
              r.creditCtrl.text.isNotEmpty,
        );
    if (!hasContent) return;

    DraftStorageService.save(_draftKey, {
      'reference': referenceCtrl.text,
      'notes': notesCtrl.text,
      'journalDate': journalDate.toIso8601String(),
      'fiscalYearId': fiscalYearId,
      'is13thMonthAdjustment': is13thMonthAdjustment,
      'reportingMethod': reportingMethod,
      'currencyCode': selectedCurrency.code,
      'rows': rows
          .map(
            (r) => {
              'accountId': r.accountId,
              'accountName': r.accountName,
              'description': r.descriptionCtrl.text,
              'debit': r.debitCtrl.text,
              'credit': r.creditCtrl.text,
              'contactId': r.contactId,
              'contactName': r.contactName,
              'contactType': r.contactType,
            },
          )
          .toList(),
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  void _restoreDraft() {
    final data = DraftStorageService.load(_draftKey);
    if (data == null) return;

    for (final row in rows) {
      row.debitCtrl.removeListener(_calculateTotals);
      row.creditCtrl.removeListener(_calculateTotals);
      row.dispose();
    }
    rows.clear();

    setState(() {
      referenceCtrl.text = data['reference'] as String? ?? '';
      notesCtrl.text = data['notes'] as String? ?? '';
      if (data['journalDate'] != null) {
        journalDate =
            DateTime.tryParse(data['journalDate'] as String) ?? DateTime.now();
      }
      fiscalYearId = data['fiscalYearId'] as String?;
      is13thMonthAdjustment = data['is13thMonthAdjustment'] as bool? ?? false;
      reportingMethod =
          data['reportingMethod'] as String? ?? 'accrual_and_cash';

      final currencyCode = data['currencyCode'] as String? ?? 'INR';
      final option = defaultCurrencyOptions.firstWhere(
        (c) => c.code == currencyCode,
        orElse: () => defaultCurrencyOptions.first,
      );
      selectedCurrency = lookup.Currency(
        id: 'default-${option.code}',
        code: option.code,
        name: option.name,
        symbol: option.symbol,
        decimals: option.decimals,
        format: option.format,
      );

      final rawRows = data['rows'] as List? ?? [];
      for (final r in rawRows) {
        final rowMap = Map<String, dynamic>.from(r as Map);
        final row = ManualJournalRow();
        row.accountId = rowMap['accountId'] as String?;
        row.accountName = rowMap['accountName'] as String?;
        row.descriptionCtrl.text = rowMap['description'] as String? ?? '';
        row.debitCtrl.text = rowMap['debit'] as String? ?? '';
        row.creditCtrl.text = rowMap['credit'] as String? ?? '';
        row.contactId = rowMap['contactId'] as String?;
        row.contactName = rowMap['contactName'] as String?;
        row.contactType = rowMap['contactType'] as String?;
        row.debitCtrl.addListener(_calculateTotals);
        row.creditCtrl.addListener(_calculateTotals);
        rows.add(row);
      }
      while (rows.length < 2) {
        _addRow(notify: false);
      }
      _hasDraft = false;
    });

    _calculateTotals();
    DraftStorageService.clear(_draftKey);
    ZerpaiToast.success(context, 'Draft restored successfully.');
  }

  Widget _buildDraftBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFFFCC02)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Color(0xFFF59E0B), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'We found an unsaved draft. Would you like to restore it?',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _restoreDraft,
            child: const Text(
              'Restore',
              style: TextStyle(
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              DraftStorageService.clear(_draftKey);
              setState(() => _hasDraft = false);
            },
            child: const Text(
              'Discard',
              style: TextStyle(color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  List<shared.AccountNode> _mapNodes(List<coa.AccountNode> roots) {
    final groupOrder = [
      'Assets',
      'Liabilities',
      'Equity',
      'Income',
      'Expenses',
    ];

    String displayNameFor(coa.AccountNode account) {
      final user = account.userAccountName.trim();
      final system = account.systemAccountName.trim();
      return user.isNotEmpty
          ? user
          : (system.isNotEmpty ? system : account.name.trim());
    }

    String toTitleCase(String text) {
      if (text.isEmpty) return text;
      return text
          .toLowerCase()
          .split(' ')
          .map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1);
          })
          .join(' ');
    }

    shared.AccountNode mapNode(coa.AccountNode account, int level) {
      final prefix = level > 0 ? '• ' : '';

      final activeChildren =
          account.children.where((c) => c.isActive && !c.isDeleted).toList()
            ..sort(
              (a, b) => displayNameFor(
                a,
              ).toLowerCase().compareTo(displayNameFor(b).toLowerCase()),
            );

      return shared.AccountNode(
        id: account.id,
        name: '$prefix${displayNameFor(account)}',
        selectable: true,
        children: activeChildren.map((c) => mapNode(c, level + 1)).toList(),
      );
    }

    final grouped = <String, Map<String, List<shared.AccountNode>>>{};
    final activeRoots = roots.where((n) => n.isActive && !n.isDeleted).toList();

    for (final root in activeRoots) {
      final group = root.accountGroup.trim();
      final finalGroup = toTitleCase(group.isEmpty ? 'Other' : group);

      final type = root.accountType.trim();
      final finalType = toTitleCase(type.isEmpty ? 'Other' : type);

      grouped.putIfAbsent(finalGroup, () => {});
      grouped[finalGroup]!
          .putIfAbsent(finalType, () => [])
          .add(mapNode(root, 0));
    }

    final sortedGroups = grouped.keys.toList()
      ..sort((a, b) {
        final idxA = groupOrder.indexWhere(
          (e) => e.toLowerCase() == a.toLowerCase(),
        );
        final idxB = groupOrder.indexWhere(
          (e) => e.toLowerCase() == b.toLowerCase(),
        );
        if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
        if (idxA != -1) return -1;
        if (idxB != -1) return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    return sortedGroups.map((group) {
      final groupMap = grouped[group]!;
      final sortedTypes = groupMap.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      final typeNodes = sortedTypes.map((type) {
        final accountNodes = groupMap[type]!;
        accountNodes.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        return shared.AccountNode(
          id: '__account_type__${group}_$type',
          name: type,
          selectable: false,
          children: accountNodes,
        );
      }).toList();

      return shared.AccountNode(
        id: '__account_group__$group',
        name: group,
        selectable: false,
        children: typeNodes,
      );
    }).toList();
  }

  String? _findName(List<shared.AccountNode> nodes, String? id) {
    if (id == null) return null;
    for (final node in nodes) {
      if (node.id == id) return node.name;
      final found = _findName(node.children, id);
      if (found != null) return found;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(chartOfAccountsProvider);

    return ShortcutHandler(
      onSave: () => _save(ManualJournalStatus.draft),
      onPublish: () => _save(ManualJournalStatus.posted),
      onCancel: () => context.go(AppRoutes.accountantManualJournals),
      isDirty: _isDirty,
      child: Stack(
        children: [
          ZerpaiLayout(
            pageTitle: isEditMode ? 'Edit Journal' : 'New Journal',
            enableBodyScroll: true,
            actions: [
              if (!isEditMode)
                TextButton(
                  onPressed: () {
                    setState(() => _showTemplateSidebar = true);
                    ref
                        .read(manualJournalTemplateProvider.notifier)
                        .fetchTemplates();
                  },
                  child: const Text('Choose Template'),
                ),
            ],
            footer: _buildFooter(),
            child: Form(
              key: _formKey,
              onChanged: () => setState(() => _isDirty = true),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_hasDraft) _buildDraftBanner(),
                      if (_validationErrors.isNotEmpty)
                        _buildValidationBanner(),
                      _buildHeaderSection(),
                      const SizedBox(height: 18),
                      _buildItemsTable(accountsState.roots),
                      const SizedBox(height: 16),
                      _buildTotalsCard(),
                      const SizedBox(height: 18),
                      _buildAttachmentsSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_showTemplateSidebar) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showTemplateSidebar = false),
                child: Container(color: Colors.black26),
              ),
            ),
            _buildTemplateSidebar(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    final bool compact = MediaQuery.of(context).size.width < 1050;
    final bool showDateField = !is13thMonthAdjustment;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormRow(
              label: 'Period End Adjustment',
              compact: compact,
              child: Row(
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: is13thMonthAdjustment,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (v) => setState(() {
                        is13thMonthAdjustment = v ?? false;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Mark this journal as a 13th month adjustment',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(width: 6),
                  const ZTooltip(
                    message:
                        '13th month adjustments are typically used for period-end closing entries.',
                    child: Icon(
                      LucideIcons.info,
                      size: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            _buildFormRow(
              label: showDateField ? 'Date' : 'Fiscal Year',
              required: true,
              compact: compact,
              tooltip:
                  'The posting date or fiscal period of the journal entry.',
              child: showDateField
                  ? _datePicker(
                      journalDate,
                      (d) => setState(() => journalDate = d),
                    )
                  : ref
                        .watch(fiscalYearsProvider)
                        .when(
                          data: (years) =>
                              di.FormDropdown<Map<String, dynamic>>(
                                value: years
                                    .where((y) => y['id'] == fiscalYearId)
                                    .firstOrNull,
                                hint: 'Select Fiscal Year',
                                showSearch: true,
                                items: years
                                    .map((y) => Map<String, dynamic>.from(y))
                                    .toList(),
                                displayStringForValue: (y) =>
                                    y['name'] as String,
                                onChanged: (v) =>
                                    setState(() => fiscalYearId = v?['id']),
                              ),
                          loading: () => const Skeleton(height: 40),
                          error: (_, __) =>
                              di.FormDropdown<Map<String, dynamic>>(
                                value: null,
                                items: const [],
                                hint: 'Select Fiscal Year',
                                onChanged: _noopContactChange,
                                enabled: true,
                              ),
                        ),
            ),
            _buildFormRow(
              label: 'Journal#',
              required: true,
              compact: compact,
              tooltip: 'Unique system-generated identifier for this journal.',
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: journalNumberCtrl,
                      readOnly: isJournalNumberReadOnly,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _openJournalNumberPreferencesDialog,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.settings,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: _saveAsTemplate,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.copy,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildFormRow(
              label: 'Reference#',
              compact: compact,
              tooltip:
                  'External reference number (e.g. receipt or invoice number).',
              child: CustomTextField(controller: referenceCtrl),
            ),
            _buildFormRow(
              label: 'Notes',
              required: true,
              compact: compact,
              tooltip: 'Detailed explanation for this journal entry.',
              child: CustomTextField(
                controller: notesCtrl,
                maxLines: 6,
                height: 100,
                hintText: 'Max. 500 characters',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                resizable: true,
              ),
            ),
            _buildFormRow(
              label: 'Reporting Method',
              required: true,
              compact: compact,
              tooltip:
                  'Choose whether you want this journal entry to appear in reports generated on cash basis, accrual basis, or both.',
              child: ZerpaiRadioGroup<String>(
                options: const [
                  'accrual_and_cash',
                  'accrual_only',
                  'cash_only',
                ],
                current: reportingMethod,
                labelBuilder: (value) {
                  switch (value) {
                    case 'accrual_and_cash':
                      return 'Accrual and Cash';
                    case 'accrual_only':
                      return 'Accrual Only';
                    case 'cash_only':
                      return 'Cash Only';
                    default:
                      return value;
                  }
                },
                onChanged: (value) {
                  setState(() => reportingMethod = value);
                },
              ),
            ),
            _buildFormRow(
              label: 'Currency',
              compact: compact,
              child: ref
                  .watch(currenciesProvider)
                  .when(
                    data: (dbCurrencies) {
                      final currencyList = dbCurrencies.isEmpty
                          ? defaultCurrencyOptions
                                .map(
                                  (o) => lookup.Currency(
                                    id: 'default-${o.code}',
                                    code: o.code,
                                    name: o.name,
                                    symbol: o.symbol,
                                    decimals: o.decimals,
                                    format: o.format,
                                  ),
                                )
                                .toList()
                          : dbCurrencies;

                      final currentCurrency =
                          currencyList
                              .where((c) => c.code == selectedCurrency.code)
                              .firstOrNull ??
                          currencyList.first;

                      return di.FormDropdown<lookup.Currency>(
                        value: currentCurrency,
                        items: currencyList,
                        showSearch: true,
                        displayStringForValue: (c) => c.label,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedCurrency = val);
                          }
                        },
                      );
                    },
                    loading: () => const Skeleton(height: 40),
                    error: (_, __) => di.FormDropdown<lookup.Currency>(
                      value: null,
                      items: const [],
                      hint: 'Error loading currencies',
                      onChanged: (lookup.Currency? _) {},
                      enabled: false,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormRow({
    required String label,
    required Widget child,
    bool required = false,
    bool compact = false,
    String? tooltip,
  }) {
    final labelWidget = RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: required ? AppTheme.errorRed : AppTheme.textPrimary,
        ),
        children: required
            ? const [
                TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            : const [],
      ),
    );

    final labelWithTooltip = tooltip == null
        ? labelWidget
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              labelWidget,
              const SizedBox(width: 6),
              ZTooltip(
                message: tooltip,
                child: const Icon(
                  LucideIcons.info,
                  size: 13,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [labelWithTooltip, const SizedBox(height: 6), child],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 150, child: labelWithTooltip),
          const SizedBox(width: 12),
          SizedBox(width: 540, child: child),
        ],
      ),
    );
  }

  Widget _datePicker(DateTime value, ValueChanged<DateTime> onPicked) {
    return InkWell(
      key: _journalDateKey,
      onTap: () async {
        final picked = await ZerpaiDatePicker.show(
          context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          targetKey: _journalDateKey,
        );

        if (picked != null) onPicked(picked);
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColorDark),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(value),
              style: const TextStyle(fontSize: 13),
            ),
            const Icon(
              LucideIcons.calendar,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell({
    int? flex,
    double? width,
    required Widget child,
    bool isLast = false,
  }) {
    final Widget content = Container(
      decoration: BoxDecoration(
        border: Border(
          right: isLast
              ? BorderSide.none
              : const BorderSide(color: AppTheme.borderColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: child,
    );

    if (width != null) return SizedBox(width: width, child: content);
    return Expanded(flex: flex!, child: content);
  }

  Widget _headerText(
    String text, {
    TextAlign textAlign = TextAlign.left,
    bool required = false,
  }) {
    return Container(
      width: double.infinity,
      alignment: textAlign == TextAlign.right
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
          children: required
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: AppTheme.errorRed,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              : const [],
        ),
      ),
    );
  }

  Widget _buildItemsTable(List<coa.AccountNode> roots) {
    final mappedNodes = _mapNodes(roots);
    final bool enableRowScroll = rows.length > 8;

    final String contactHeader =
        'CONTACT (${selectedCurrency.symbol ?? selectedCurrency.code})';
    final String debitHeader = 'DEBITS';
    final String creditHeader = 'CREDITS';

    final Widget rowsList = ReorderableListView.builder(
      buildDefaultDragHandles: false,
      shrinkWrap: !enableRowScroll,
      physics: enableRowScroll
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = rows.removeAt(oldIndex);
          rows.insert(newIndex, item);
        });
      },
      itemBuilder: (ctx, idx) {
        final row = rows[idx];
        return Container(
          key: ObjectKey(row),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: row.rowHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cell(
                      width: 32,
                      child: ReorderableDragStartListener(
                        index: idx,
                        child: const MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: Icon(
                            LucideIcons.gripVertical,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                    _cell(
                      flex: 4,
                      child: dropdown.AccountTreeDropdown(
                        focusNode: row.accountFocusNode,
                        value: row.accountId,
                        nodes: mappedNodes,
                        height: row.rowHeight - 2,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: Colors.transparent),
                        onSearch: (q) async {
                          final results = await ref
                              .read(accountantRepositoryProvider)
                              .searchAccounts(q);
                          return results
                              .map(
                                (e) => shared.AccountNode(
                                  id: e.id,
                                  name: e.name,
                                  children: e.children
                                      .map(
                                        (c) => shared.AccountNode(
                                          id: c.id,
                                          name: c.name,
                                        ),
                                      )
                                      .toList(),
                                ),
                              )
                              .toList();
                        },
                        onChanged: (v) {
                          setState(() {
                            row.accountId = v;
                            row.accountName = _findName(mappedNodes, v);
                          });
                        },
                        hint: 'Select an account',
                      ),
                    ),
                    _cell(
                      flex: 4,
                      child: CustomTextField(
                        controller: row.descriptionCtrl,
                        hintText: 'Description',
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: Colors.transparent),
                        maxLines: null,
                        resizable: true,
                        height: row.rowHeight - 2,
                        minHeight: 40,
                        onHeightChanged: (h) =>
                            setState(() => row.rowHeight = h + 2),
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      ),
                    ),
                    _cell(
                      flex: 3,
                      child: ref
                          .watch(manualJournalContactsProvider)
                          .when(
                            data: (contacts) =>
                                di.FormDropdown<Map<String, dynamic>>(
                                  value:
                                      contacts
                                          .where(
                                            (c) =>
                                                c['id'] == row.contactId &&
                                                (row.contactType == null ||
                                                    (c['contact_type'] ??
                                                                c['type'])
                                                            ?.toString()
                                                            .toLowerCase() ==
                                                        row.contactType!
                                                            .toString()
                                                            .toLowerCase()),
                                          )
                                          .firstOrNull ??
                                      contacts
                                          .where(
                                            (c) => c['id'] == row.contactId,
                                          )
                                          .firstOrNull,
                                  hint: 'Select Contact',
                                  showSearch: true,
                                  borderRadius: BorderRadius.zero,
                                  border: Border.all(color: Colors.transparent),
                                  height: row.rowHeight - 2,
                                  items: contacts
                                      .map((c) => Map<String, dynamic>.from(c))
                                      .toList(),
                                  displayStringForValue: (c) =>
                                      (c['displayName'] ??
                                              c['display_name'] ??
                                              '')
                                          .toString(),
                                  onSearch: (q) async {
                                    return await ref.read(
                                      searchContactsProvider(q).future,
                                    );
                                  },
                                  onChanged: (v) {
                                    setState(() {
                                      row.contactId = v?['id'];
                                      final typeValue =
                                          v?['contact_type'] ?? v?['type'];
                                      row.contactType = typeValue?.toString();
                                      row.contactName =
                                          (v?['displayName'] ??
                                                  v?['display_name'] ??
                                                  '')
                                              .toString();
                                    });
                                  },
                                ),
                            loading: () => const Skeleton(height: 40),
                            error: (e, _) =>
                                di.FormDropdown<Map<String, dynamic>>(
                                  value: null,
                                  items: const [],
                                  hint: 'Select Contact',
                                  onChanged: _noopContactChange,
                                ),
                          ),
                    ),
                    _cell(
                      flex: 2,
                      child: CustomTextField(
                        controller: row.debitCtrl,
                        textAlign: TextAlign.right,
                        height: row.rowHeight - 2,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: Colors.transparent),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        hintText: '0',
                        onTap: () {
                          row.debitCtrl.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: row.debitCtrl.text.length,
                          );
                        },
                        onChanged: (value) {
                          final debit = double.tryParse(value) ?? 0;
                          final credit =
                              double.tryParse(row.creditCtrl.text) ?? 0;
                          if (debit > 0 && credit > 0) {
                            row.creditCtrl.text = '';
                          }
                        },
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    _cell(
                      flex: 2,
                      child: CustomTextField(
                        controller: row.creditCtrl,
                        textAlign: TextAlign.right,
                        height: row.rowHeight - 2,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: Colors.transparent),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        hintText: '0',
                        onTap: () {
                          row.creditCtrl.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: row.creditCtrl.text.length,
                          );
                        },
                        onChanged: (value) {
                          final credit = double.tryParse(value) ?? 0;
                          final debit =
                              double.tryParse(row.debitCtrl.text) ?? 0;
                          if (credit > 0 && debit > 0) {
                            row.debitCtrl.text = '';
                          }
                        },
                        onSubmitted: (_) {
                          if (idx == rows.length - 1) {
                            _addRow();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && rows.isNotEmpty) {
                                rows.last.accountFocusNode.requestFocus();
                              }
                            });
                          } else {
                            FocusScope.of(context).nextFocus();
                          }
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    _cell(
                      width: 80,
                      isLast: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                row.isExpanded = !row.isExpanded;
                              });
                            },
                            icon: const Icon(
                              LucideIcons.moreVertical,
                              size: 16,
                              color: AppTheme.textMuted,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              if (rows.length > 2) {
                                setState(() => rows.removeAt(idx).dispose());
                                _calculateTotals();
                              }
                            },
                            icon: const Icon(
                              LucideIcons.x,
                              size: 16,
                              color: AppTheme.errorRed,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (row.isExpanded)
                Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    border: Border(
                      top: BorderSide(color: AppTheme.borderColor),
                      bottom: BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      _cell(width: 32, child: const SizedBox()),
                      _cell(
                        flex: 4,
                        child: InkWell(
                          onTap: () {},
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.briefcase,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                row.projectId ?? 'Select a project',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF3B82F6),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _cell(
                        flex: 4,
                        child: InkWell(
                          onTap: () {},
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.tag,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                row.reportingTags ?? 'Reporting Tags',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _cell(flex: 7, child: const SizedBox()),
                      _cell(width: 80, child: const SizedBox(), isLast: true),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );

    final tableContainer = Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.zero, // Padding handled by cells
            color: AppTheme.bgLight,
            height: 40,
            child: Row(
              children: [
                _cell(width: 32, child: const SizedBox()),
                _cell(flex: 4, child: _headerText('ACCOUNT', required: true)),
                _cell(
                  flex: 4,
                  child: _headerText('DESCRIPTION'),
                ), // Increased flex to 4
                _cell(
                  flex: 3,
                  child: _headerText(contactHeader),
                ), // Increased flex to 3
                _cell(
                  flex: 2,
                  child: _headerText(debitHeader, textAlign: TextAlign.right),
                ),
                _cell(
                  flex: 2,
                  child: _headerText(creditHeader, textAlign: TextAlign.right),
                ),
                _cell(
                  width: 80,
                  child: Center(
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        LucideIcons.moreVertical,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        setState(() {
                          final expand = value == 'show';
                          for (var row in rows) {
                            row.isExpanded = expand;
                          }
                        });
                      },
                      itemBuilder: (context) {
                        final allExpanded =
                            rows.isNotEmpty && rows.every((r) => r.isExpanded);
                        return [
                          PopupMenuItem<String>(
                            value: allExpanded ? 'hide' : 'show',
                            child: Text(
                              allExpanded
                                  ? 'Hide All Additional Information'
                                  : 'Show All Additional Information',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                  isLast: true,
                ),
              ],
            ),
          ),
          if (enableRowScroll)
            SizedBox(height: 440, child: rowsList)
          else
            rowsList,
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tableContainer,
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addRow,
            icon: const Icon(LucideIcons.plusCircle, size: 16),
            label: const Text('Add New Row'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: AppTheme.primaryBlue),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  static void _noopContactChange(Map<String, dynamic>? _) {}

  Widget _buildTotalsCard() {
    final card = Container(
      width: 760,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.bgLight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _summaryLine(
            'Sub Total',
            leftText: totalDebit.toStringAsFixed(2),
            rightText: totalCredit.toStringAsFixed(2),
            textColor: AppTheme.textSecondary,
          ),
          const SizedBox(height: 12),
          _summaryLine(
            'Total (${selectedCurrency.symbol ?? selectedCurrency.code})',
            leftText: totalDebit.toStringAsFixed(2),
            rightText: totalCredit.toStringAsFixed(2),
            bold: true,
          ),
          const SizedBox(height: 12),
          _summaryLine(
            'Difference',
            leftText: '',
            rightText: difference.toStringAsFixed(2),
            textColor: difference.abs() >= 0.01
                ? AppTheme.errorRed
                : AppTheme.textPrimary,
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return card;
        }

        return Row(children: [const Spacer(), card]);
      },
    );
  }

  Future<void> _pickAttachments() async {
    if (_pendingAttachments.length >= _maxAttachmentFiles) {
      if (mounted) {
        ZerpaiToast.error(context, 'You can upload a maximum of 5 files.');
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'gif'],
    );

    if (result == null || result.files.isEmpty) return;

    final nextAttachments = <_PendingAttachment>[..._pendingAttachments];
    final skippedReasons = <String>[];

    for (final file in result.files) {
      if (nextAttachments.length >= _maxAttachmentFiles) break;

      final bytes = file.bytes;
      final fileName = file.name.trim();
      if (bytes == null || fileName.isEmpty) {
        skippedReasons.add('Some files were skipped because data was empty.');
        continue;
      }

      if (bytes.length > _maxAttachmentFileSizeBytes) {
        skippedReasons.add('$fileName exceeds 10MB and was skipped.');
        continue;
      }

      final alreadyAdded = nextAttachments.any(
        (x) => x.name == fileName && x.size == bytes.length,
      );
      if (alreadyAdded) {
        continue;
      }

      nextAttachments.add(
        _PendingAttachment(
          name: fileName,
          bytes: bytes,
          mimeType: _mimeTypeForFileName(fileName),
        ),
      );
    }

    setState(() {
      _pendingAttachments
        ..clear()
        ..addAll(nextAttachments);
    });

    if (skippedReasons.isNotEmpty && mounted) {
      ZerpaiToast.error(context, skippedReasons.first);
    }
  }

  void _toggleAttachmentsOverlay() {
    if (_attachmentsOverlayEntry != null) {
      _removeAttachmentsOverlay();
    } else {
      _showAttachmentsOverlay();
    }
  }

  void _showAttachmentsOverlay() {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    _attachmentsOverlayEntry = OverlayEntry(
      builder: (context) => _buildAttachmentsOverlay(),
    );
    overlay.insert(_attachmentsOverlayEntry!);
  }

  void _removeAttachmentsOverlay() {
    _attachmentsOverlayEntry?.remove();
    _attachmentsOverlayEntry = null;
  }

  Widget _buildAttachmentsOverlay() {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _removeAttachmentsOverlay,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        CompositedTransformFollower(
          link: _attachmentsLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 42),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _pendingAttachments.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final file = entry.value;
                    return _MJFileItemWidget(
                      file: file,
                      onDelete: () {
                        setState(() {
                          _pendingAttachments.removeAt(idx);
                          if (_pendingAttachments.isEmpty) {
                            _removeAttachmentsOverlay();
                          } else {
                            _attachmentsOverlayEntry?.markNeedsBuild();
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<int> _uploadPendingAttachments(String manualJournalId) async {
    if (_pendingAttachments.isEmpty) return 0;

    final dio = ref.read(dioProvider);
    final payload = _pendingAttachments
        .map(
          (file) => {
            'fileName': file.name,
            'fileData':
                'data:${file.mimeType};base64,${base64Encode(file.bytes)}',
            'mimeType': file.mimeType,
            'fileSize': file.size,
          },
        )
        .toList();

    final response = await dio.post(
      '/accountant/manual-journals/$manualJournalId/attachments',
      data: {'attachments': payload},
    );

    final data = response.data;
    final uploaded = data is List
        ? data.length
        : (data is Map && data['data'] is List
              ? (data['data'] as List).length
              : 0);
    return uploaded;
  }

  String _mimeTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'application/octet-stream';
  }

  Widget _buildAttachmentsSection() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              text: 'Documents',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              children: [
                WidgetSpan(child: SizedBox(width: 4)),
                WidgetSpan(
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              DottedBorder(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                strokeWidth: 1,
                dashPattern: const [4, 2],
                borderType: BorderType.RRect,
                radius: const Radius.circular(4),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: _isLoading ? null : _pickAttachments,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.upload,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Upload File',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: const Color(0xFFE5E7EB),
                      ),
                      InkWell(
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_pendingAttachments.isNotEmpty) ...[
                const SizedBox(width: 12),
                CompositedTransformTarget(
                  link: _attachmentsLink,
                  child: Material(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(4),
                    child: InkWell(
                      onTap: _toggleAttachmentsOverlay,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.paperclip,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_pendingAttachments.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'You can upload a maximum of 10 files, 10MB each',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(
    String label, {
    required String leftText,
    required String rightText,
    bool bold = false,
    Color textColor = AppTheme.textPrimary,
  }) {
    final valueStyle = TextStyle(
      fontSize: bold ? 16 : 13,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: textColor,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: textColor,
          ),
        ),
        Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(
                leftText,
                textAlign: TextAlign.right,
                style: valueStyle,
              ),
            ),
            const SizedBox(width: 28),
            SizedBox(
              width: 140,
              child: Text(
                rightText,
                textAlign: TextAlign.right,
                style: valueStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final primaryLabel = isEditMode ? 'Update and Post' : 'Save and Publish';
    final draftLabel = isEditMode ? 'Update Draft' : 'Save as Draft';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                Tooltip(
                  message: 'Save and Publish (Ctrl+Enter)',
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _save(ManualJournalStatus.posted),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(primaryLabel),
                  ),
                ),
                Tooltip(
                  message: 'Save as Draft (Ctrl+S)',
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _save(ManualJournalStatus.draft),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppTheme.bgDisabled,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                    child: Text(draftLabel),
                  ),
                ),
                Tooltip(
                  message: 'Cancel (Esc)',
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            DraftStorageService.clear(_draftKey);
                            context.go(AppRoutes.accountantManualJournals);
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      textStyle: const TextStyle(decoration: TextDecoration.none),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              final journal = _buildJournalFromForm(ManualJournalStatus.draft);
              context.go(
                AppRoutes.accountantRecurringJournalsCreate,
                extra: journal,
              );
            },
            icon: const Icon(LucideIcons.refreshCw, size: 14),
            label: const Text('Make Recurring'),
          ),
        ],
      ),
    );
  }

  ManualJournal _buildJournalFromForm(ManualJournalStatus status) {
    final validRows = rows
        .where(
          (r) =>
              r.accountId != null &&
              (double.tryParse(r.debitCtrl.text) ?? 0) +
                      (double.tryParse(r.creditCtrl.text) ?? 0) >
                  0,
        )
        .toList();

    final manualItems = validRows.asMap().entries.map((entry) {
      final idx = entry.key;
      final r = entry.value;
      return ManualJournalItem(
        id: '',
        accountId: r.accountId!,
        accountName: r.accountName ?? '',
        description: r.descriptionCtrl.text,
        debit: double.tryParse(r.debitCtrl.text) ?? 0,
        credit: double.tryParse(r.creditCtrl.text) ?? 0,
        contactId: r.contactId,
        contactType: r.contactType,
        contactName: r.contactName,
        projectId: r.projectId,
        reportingTags: r.reportingTags,
        sortOrder: idx + 1,
      );
    }).toList();

    final now = DateTime.now();
    final scope = ref.read(journalSettingsScopeProvider);
    return ManualJournal(
      id: isEditMode ? widget.initialJournal!.id : '',
      orgId: scope['orgId'] as String?,
      outletId: scope['outletId'] as String?,
      userId: scope['userId'] as String?,
      journalDate: is13thMonthAdjustment ? now : journalDate,
      journalNumber: journalNumberCtrl.text,
      referenceNumber: referenceCtrl.text,
      notes: notesCtrl.text,
      reportingMethod: reportingMethod,
      is13thMonthAdjustment: is13thMonthAdjustment,
      fiscalYearId: fiscalYearId,
      currency: selectedCurrency.code,
      status: isEditMode ? ManualJournalStatus.draft : status,
      items: manualItems,
      createdAt: isEditMode ? widget.initialJournal!.createdAt : now,
      updatedAt: now,
    );
  }

  Future<void> _saveAsTemplate() async {
    // 1. Minimum validation: Needs at least one row with an account
    final validRows = rows.where((r) => r.accountId != null).toList();
    if (validRows.isEmpty) {
      ZerpaiToast.error(
        context,
        'Please add at least one row with an account to save as template.',
      );
      return;
    }

    // 2. Ask for template name
    String templateName = 'Template ${journalNumberCtrl.text}';
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController(text: templateName);
        return AlertDialog(
          title: const Text('Save as Template'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Template Name',
              hintText: 'Enter template name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final template = ManualJournalTemplate(
        id: '',
        templateName: name,
        referenceNumber: referenceCtrl.text.trim().isEmpty
            ? null
            : referenceCtrl.text.trim(),
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        reportingMethod: reportingMethod,
        currency: selectedCurrency.code,
        items: validRows
            .map(
              (r) => ManualJournalTemplateItem(
                accountId: r.accountId!,
                accountName: r.accountName ?? '',
                description: r.descriptionCtrl.text,
                debit: double.tryParse(r.debitCtrl.text) ?? 0,
                credit: double.tryParse(r.creditCtrl.text) ?? 0,
                contactId: r.contactId,
                contactType: r.contactType,
                projectId: r.projectId,
                reportingTags: r.reportingTags,
              ),
            )
            .toList(),
      );

      await ref
          .read(manualJournalTemplateProvider.notifier)
          .createTemplate(template);
      if (mounted) {
        ZerpaiToast.success(context, 'Template "$name" saved successfully.');
      }
    } catch (e) {
      if (mounted) {
        final message = ErrorHandler.getFriendlyMessage(e);
        ZerpaiToast.error(context, 'Error saving template: $message');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save(ManualJournalStatus status) async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? true)) return;

    final isDraftAction = status == ManualJournalStatus.draft;

    List<String> errors = [];

    if (!isDraftAction && notesCtrl.text.trim().isEmpty) {
      errors.add('Notes field cannot be left empty.');
    }

    final validRows = rows
        .where(
          (r) =>
              r.accountId != null &&
              (double.tryParse(r.debitCtrl.text) ?? 0) +
                      (double.tryParse(r.creditCtrl.text) ?? 0) >
                  0,
        )
        .toList();

    if (!isDraftAction && validRows.length < 2) {
      errors.add(
        'Please select the Accounts, enter the Debits, and the equivalent credits.',
      );
    }

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final d = double.tryParse(row.debitCtrl.text) ?? 0;
      final c = double.tryParse(row.creditCtrl.text) ?? 0;

      if (!isDraftAction && (d > 0 || c > 0) && row.accountId == null) {
        errors.add('Please select an account for row ${i + 1}');
      }
      if (d > 0 && c > 0) {
        errors.add('Row ${i + 1} cannot have both Debit and Credit values.');
      }
    }

    if (!isDraftAction && difference.abs() >= 0.01) {
      errors.add('Please ensure that the Debits and Credits are equal.');
    }

    final fiscalYears = ref.read(fiscalYearsProvider).asData?.value ?? [];
    bool isDateValid = false;

    if (!isDraftAction && is13thMonthAdjustment) {
      if (fiscalYearId == null) {
        errors.add('Fiscal Year is required for adjustments.');
      }
      isDateValid = true;
    } else if (!isDraftAction) {
      for (var fy in fiscalYears) {
        if (fy['is_active'] == true) {
          final start = DateTime.parse(fy['start_date']);
          final end = DateTime.parse(fy['end_date']);
          if (journalDate.isAfter(start.subtract(const Duration(days: 1))) &&
              journalDate.isBefore(end.add(const Duration(days: 1)))) {
            isDateValid = true;
            break;
          }
        }
      }
      if (!isDateValid && fiscalYears.isNotEmpty) {
        errors.add('Journal date must fall within an active fiscal year range');
      }
    }

    if (errors.isNotEmpty) {
      setState(() {
        _validationErrors.clear();
        _validationErrors.addAll(errors);
      });
      return;
    }

    setState(() {
      _validationErrors.clear();
      _isLoading = true;
    });

    try {
      final journal = _buildJournalFromForm(status);

      final notifier = ref.read(manualJournalProvider.notifier);
      ManualJournal savedJournal;
      if (isEditMode) {
        savedJournal = await notifier.updateJournal(journal);
        if (status == ManualJournalStatus.posted) {
          savedJournal = await notifier.updateStatus(
            savedJournal.id,
            ManualJournalStatus.posted,
          );
        }
      } else {
        savedJournal = await notifier.createJournal(journal);
      }

      int uploadedCount = 0;
      if (_pendingAttachments.isNotEmpty) {
        try {
          uploadedCount = await _uploadPendingAttachments(savedJournal.id);
        } catch (uploadError) {
          if (mounted) {
            final message = ErrorHandler.getFriendlyMessage(uploadError);
            ZerpaiToast.error(
              context,
              'Journal saved, but attachment upload failed: $message',
            );
          }
        }
      }

      if (mounted) {
        final statusLabel = savedJournal.status == ManualJournalStatus.posted
            ? 'posted'
            : savedJournal.status == ManualJournalStatus.cancelled
            ? 'cancelled'
            : 'saved';

        final message = uploadedCount > 0
            ? 'Journal $statusLabel successfully. $uploadedCount attachment(s) uploaded.'
            : 'Journal $statusLabel successfully';

        DraftStorageService.clear(_draftKey);
        ZerpaiToast.success(context, message);
        if (context.canPop()) {
          context.pop(savedJournal);
        } else {
          context.go(AppRoutes.accountantManualJournals);
        }
      }
    } catch (e) {
      if (mounted) {
        final message = ErrorHandler.getFriendlyMessage(e);
        ZerpaiToast.error(context, message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTemplateSidebar() {
    final templateState = ref.watch(manualJournalTemplateProvider);

    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 16,
        child: Container(
          width: 400,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Choose Journal Template',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () =>
                          setState(() => _showTemplateSidebar = false),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Body
              if (templateState.isLoading)
                const Expanded(child: ListSkeleton())
              else if (templateState.error != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Error: ${templateState.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.errorRed),
                      ),
                    ),
                  ),
                )
              else if (templateState.templates.isEmpty)
                _buildSidebarEmptyState()
              else
                _buildSidebarTemplatesList(templateState.templates),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarEmptyState() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.15,
              child: Icon(
                LucideIcons.fileText,
                size: 100,
                color: AppTheme.accentGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "You don't have any templates yet!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  context.push(AppRoutes.accountantJournalTemplateCreation),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
              child: const Text('New Template'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarTemplatesList(List<ManualJournalTemplate> templates) {
    return Expanded(
      child: _PaginatedSidebarList(
        templates: templates,
        onSelect: (template) {
          setState(() => _showTemplateSidebar = false);
          _hydrateFromTemplate(template);
        },
      ),
    );
  }

  Widget _buildValidationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBEAEA),
        border: Border.all(
          color: AppTheme.errorRed.withValues(alpha: 0.5),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _validationErrors.map((error) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 8),
                        child: CircleAvatar(
                          radius: 2,
                          backgroundColor: AppTheme.textPrimary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          error,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _validationErrors.clear()),
            child: const Icon(
              LucideIcons.x,
              size: 16,
              color: AppTheme.errorRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginatedSidebarList extends StatefulWidget {
  final List<ManualJournalTemplate> templates;
  final ValueChanged<ManualJournalTemplate> onSelect;

  const _PaginatedSidebarList({
    required this.templates,
    required this.onSelect,
  });

  @override
  State<_PaginatedSidebarList> createState() => _PaginatedSidebarListState();
}

class _PaginatedSidebarListState extends State<_PaginatedSidebarList> {
  static const int _pageSize = 20;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final startIndex = _currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize < widget.templates.length)
        ? startIndex + _pageSize
        : widget.templates.length;

    // Safety check just in case templates changed and currentPage is out of bounds
    if (startIndex >= widget.templates.length && widget.templates.isNotEmpty) {
      // Reset to first page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentPage = 0);
      });
    }

    final currentItems = (startIndex < widget.templates.length)
        ? widget.templates.sublist(startIndex, endIndex)
        : <ManualJournalTemplate>[];

    final totalPages = (widget.templates.length / _pageSize).ceil();
    // Ensure at least 1 page
    final displayTotalPages = totalPages == 0 ? 1 : totalPages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: currentItems.length,
            padding: const EdgeInsets.all(16),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final template = currentItems[index];
              return ManualJournalTemplateCard(
                template: template,
                onSelect: () => widget.onSelect(template),
              );
            },
          ),
        ),
        if (displayTotalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, size: 16),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                Text(
                  '${_currentPage + 1} / $displayTotalPages',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight, size: 16),
                  onPressed: _currentPage < displayTotalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: OutlinedButton.icon(
            onPressed: () =>
                context.push(AppRoutes.accountantJournalTemplateCreation),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('New Template'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentGreen,
              side: const BorderSide(color: AppTheme.accentGreen),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MJFileItemWidget extends StatefulWidget {
  final _PendingAttachment file;
  final VoidCallback onDelete;

  const _MJFileItemWidget({required this.file, required this.onDelete});

  @override
  State<_MJFileItemWidget> createState() => _MJFileItemWidgetState();
}

class _MJFileItemWidgetState extends State<_MJFileItemWidget> {
  bool _isHovered = false;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = widget.file.mimeType == 'application/pdf';
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: _isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
        child: Row(
          children: [
            Icon(
              isPdf ? LucideIcons.fileText : LucideIcons.image,
              size: 20,
              color: _isHovered ? Colors.white : const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _isHovered
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'File Size: ${_formatSize(widget.file.size)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isHovered
                          ? Colors.white70
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (_isHovered)
              IconButton(
                icon: const Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: widget.onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
