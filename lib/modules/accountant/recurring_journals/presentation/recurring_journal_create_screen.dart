import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart' as di;
import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/manual_journal_create_screen.dart';
import '../models/recurring_journal_model.dart';
import '../../manual_journals/models/manual_journal_model.dart';
import '../providers/recurring_journal_provider.dart';
import '../../manual_journals/providers/manual_journal_provider.dart';
import 'package:zerpai_erp/shared/widgets/inputs/account_tree_dropdown.dart'
    as dropdown;
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/modules/accountant/models/accountant_chart_of_accounts_account_model.dart'
    as coa;
import 'package:zerpai_erp/shared/models/account_node.dart' as shared;
import 'package:zerpai_erp/modules/accountant/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/accountant/repositories/accountant_repository.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class RecurringJournalCreateScreen extends ConsumerStatefulWidget {
  final RecurringJournal? initialJournal;
  final ManualJournal? initialManualJournal;

  const RecurringJournalCreateScreen({
    super.key,
    this.initialJournal,
    this.initialManualJournal,
  });

  @override
  ConsumerState<RecurringJournalCreateScreen> createState() =>
      _RecurringJournalCreateScreenState();
}

class _RecurringJournalCreateScreenState
    extends ConsumerState<RecurringJournalCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startDateKey = GlobalKey();
  final _endDateKey = GlobalKey();

  late final TextEditingController profileNameCtrl;
  late final TextEditingController referenceCtrl;
  late final TextEditingController notesCtrl;
  late final TextEditingController startDateCtrl;
  late final TextEditingController endDateCtrl;
  DateTime startDate = DateTime.now();
  DateTime? endDate;
  bool neverExpires = true;
  String repeatEvery = 'Week';
  int interval = 1;
  String reportingMethod = 'accrual_and_cash';
  String selectedCurrency = 'INR';
  String customFrequencyUnit = 'Week(s)';
  late final TextEditingController intervalCtrl;

  List<ManualJournalRow> rows = [];
  double totalDebit = 0.0;
  double totalCredit = 0.0;
  bool _isSaving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    profileNameCtrl = TextEditingController();
    referenceCtrl = TextEditingController();
    notesCtrl = TextEditingController();
    startDateCtrl = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(startDate),
    );
    endDateCtrl = TextEditingController(text: 'dd/MM/yyyy');
    intervalCtrl = TextEditingController(text: interval.toString());
    intervalCtrl.addListener(() {
      setState(() {
        interval = int.tryParse(intervalCtrl.text) ?? 1;
      });
    });

    if (widget.initialJournal != null) {
      _hydrateFromJournal(widget.initialJournal!);
    } else if (widget.initialManualJournal != null) {
      _hydrateFromManualJournal(widget.initialManualJournal!);
    } else {
      _addRow();
      _addRow();
    }
  }

  void _hydrateFromJournal(RecurringJournal journal) {
    profileNameCtrl.text = journal.profileName;
    referenceCtrl.text = journal.referenceNumber ?? '';
    notesCtrl.text = journal.notes ?? '';
    startDate = journal.startDate;
    endDate = journal.endDate;
    neverExpires = journal.neverExpires;
    repeatEvery = journal.repeatEvery;
    interval = journal.interval;
    reportingMethod = journal.reportingMethod;
    selectedCurrency = journal.currency;

    startDateCtrl.text = DateFormat('dd/MM/yyyy').format(startDate);
    if (endDate != null) {
      endDateCtrl.text = DateFormat('dd/MM/yyyy').format(endDate!);
    }

    // Determine correct dropdown value for repeatEvery
    final mappedValue = _getDropdownValue(
      journal.repeatEvery,
      journal.interval,
    );
    if (mappedValue != null) {
      repeatEvery = mappedValue;
    } else {
      repeatEvery = 'Custom';
      customFrequencyUnit =
          '${journal.repeatEvery[0].toUpperCase()}${journal.repeatEvery.substring(1)}(s)';
      // Ensure unit matches 'Day(s)', etc.
      // e.g. 'week' -> 'Week(s)'
      intervalCtrl.text = journal.interval.toString();
    }

    for (final item in journal.items) {
      _addRow(item: item);
    }
    _calculateTotals();
  }

  String? _getDropdownValue(String unit, int count) {
    final lowerUnit = unit.toLowerCase();
    if (lowerUnit == 'week') {
      if (count == 1) return 'Week';
      if (count == 2) return '2 Weeks';
    } else if (lowerUnit == 'month') {
      if (count == 1) return 'Month';
      if (count == 2) return '2 Months';
      if (count == 3) return '3 Months';
      if (count == 6) return '6 Months';
    } else if (lowerUnit == 'year') {
      if (count == 1) return 'Year';
      if (count == 2) return '2 Years';
      if (count == 3) return '3 Years';
    }
    return null;
  }

  void _hydrateFromManualJournal(ManualJournal journal) {
    profileNameCtrl.text = 'Recurring: ${journal.journalNumber}';
    referenceCtrl.text = journal.referenceNumber ?? '';
    notesCtrl.text = journal.notes ?? '';
    reportingMethod = journal.reportingMethod;
    selectedCurrency = journal.currency;

    // Set start date from journal date
    startDate = journal.journalDate;
    startDateCtrl.text = DateFormat('dd/MM/yyyy').format(startDate);

    for (final item in journal.items) {
      final row = ManualJournalRow();
      row.accountId = item.accountId;
      row.accountName = item.accountName;
      row.descriptionCtrl.text = item.description ?? '';
      row.debitCtrl.text = item.debit.toString();
      row.creditCtrl.text = item.credit.toString();
      row.contactId = item.contactId;
      row.contactType = item.contactType;
      row.projectId = item.projectId;
      row.reportingTags = item.reportingTags;
      row.rowHeight = _isGstAccount(row.accountName) ? 75.0 : 48.0;

      // Expand row if project or reporting tags are present
      if (row.projectId != null || row.reportingTags != null) {
        row.isExpanded = true;
      }

      row.debitCtrl.addListener(_calculateTotals);
      row.creditCtrl.addListener(_calculateTotals);
      rows.add(row);
    }
    if (journal.items.isEmpty) {
      _addRow();
      _addRow();
    }
    _calculateTotals();
  }

  void _addRow({ManualJournalItem? item}) {
    final row = ManualJournalRow();
    if (item != null) {
      row.accountId = item.accountId;
      row.accountName = item.accountName;
      row.descriptionCtrl.text = item.description ?? '';
      row.debitCtrl.text = item.debit.toString();
      row.creditCtrl.text = item.credit.toString();
      row.contactId = item.contactId;
      row.contactType = item.contactType;
      row.projectId = item.projectId;
      row.reportingTags = item.reportingTags;
      row.rowHeight = _isGstAccount(row.accountName) ? 75.0 : 48.0;

      if (row.projectId != null || row.reportingTags != null) {
        row.isExpanded = true;
      }
    } else {
      row.rowHeight = 48.0;
    }
    row.debitCtrl.addListener(_calculateTotals);
    row.creditCtrl.addListener(_calculateTotals);
    setState(() => rows.add(row));
  }

  void _removeRow(int index) {
    if (rows.length <= 2) return;
    setState(() {
      rows[index].dispose();
      rows.removeAt(index);
      _calculateTotals();
    });
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
    });
  }

  @override
  void dispose() {
    profileNameCtrl.dispose();
    referenceCtrl.dispose();
    notesCtrl.dispose();
    startDateCtrl.dispose();
    endDateCtrl.dispose();
    intervalCtrl.dispose();
    for (var row in rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime firstDateValue = isStart ? DateTime(2000) : startDate;

    final DateTime? picked = await ZerpaiDatePicker.show(
      context,
      initialDate: isStart ? startDate : (endDate ?? startDate),
      firstDate: firstDateValue,
      targetKey: isStart ? _startDateKey : _endDateKey,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          startDateCtrl.text = DateFormat('dd/MM/yyyy').format(startDate);
          if (endDate != null && endDate!.isBefore(startDate)) {
            endDate = startDate.add(const Duration(days: 1));
            endDateCtrl.text = DateFormat('dd/MM/yyyy').format(endDate!);
          }
        } else {
          endDate = picked;
          endDateCtrl.text = DateFormat('dd/MM/yyyy').format(endDate!);
          neverExpires = false;
        }
      });
    }
  }

  Future<void> _handleSave({RecurringJournalStatus? status}) async {
    if (!_formKey.currentState!.validate()) {
      ZerpaiToast.error(context, 'Please fill in all mandatory fields.');
      return;
    }
    List<String> errors = [];

    if (totalDebit != totalCredit || totalDebit == 0) {
      errors.add('Total Debits must equal Total Credits and be non-zero');
    }

    final validRows = rows.where((r) => r.accountId != null).toList();
    if (validRows.length < 2) {
      errors.add('At least 2 line items with accounts are required.');
    }

    if (errors.isNotEmpty) {
      // Just show the first error using Toast, or if you prefer you could build a Validation Banner here.
      // For consistency with existing behavior, I'll stick to Toast for recurring journals unless otherwise specified.
      ZerpaiToast.error(context, errors.join('\n'));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final journalItems = rows
          .where((r) => r.accountId != null)
          .map(
            (r) => ManualJournalItem(
              id: '',
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
          .toList();

      // Determine final repeatEvery (unit) and interval based on dropdown
      String finalRepeatEvery;
      int finalInterval;

      if (repeatEvery == 'Custom') {
        // e.g. 'Week(s)' -> 'week'
        finalRepeatEvery = customFrequencyUnit
            .replaceAll('(s)', '')
            .toLowerCase();
        finalInterval = int.tryParse(intervalCtrl.text) ?? 1;
      } else {
        // Parse from dropdown string, e.g. '2 Weeks' -> unit='week', interval=2
        // e.g. 'Month' -> unit='month', interval=1
        final lower = repeatEvery.toLowerCase();
        if (lower.contains('week')) {
          finalRepeatEvery = 'week';
          if (lower.contains('2'))
            finalInterval = 2;
          else
            finalInterval = 1;
        } else if (lower.contains('month')) {
          finalRepeatEvery = 'month';
          if (lower.contains('2'))
            finalInterval = 2;
          else if (lower.contains('3'))
            finalInterval = 3;
          else if (lower.contains('6'))
            finalInterval = 6;
          else
            finalInterval = 1;
        } else if (lower.contains('year')) {
          finalRepeatEvery = 'year';
          if (lower.contains('2'))
            finalInterval = 2;
          else if (lower.contains('3'))
            finalInterval = 3;
          else
            finalInterval = 1;
        } else {
          // Default fallback
          finalRepeatEvery = 'week';
          finalInterval = 1;
        }
      }

      final journal = RecurringJournal(
        id: widget.initialJournal?.id ?? '',
        profileName: profileNameCtrl.text,
        repeatEvery: finalRepeatEvery,
        interval: finalInterval,
        startDate: startDate,
        endDate: neverExpires ? null : endDate,
        neverExpires: neverExpires,
        referenceNumber: referenceCtrl.text,
        notes: notesCtrl.text,
        currency: selectedCurrency,
        reportingMethod: reportingMethod,
        items: journalItems,
        status: status ?? (widget.initialJournal?.status ?? RecurringJournalStatus.active),
        createdAt: widget.initialJournal?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.initialJournal != null) {
        await ref
            .read(recurringJournalProvider.notifier)
            .updateJournal(journal);
      } else {
        await ref
            .read(recurringJournalProvider.notifier)
            .createJournal(journal);
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          // Fallback if no history
          context.go(AppRoutes.accountantRecurringJournals);
        }
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: widget.initialJournal == null
          ? 'New Recurring Journal'
          : 'Edit Recurring Journal',
      isDirty: _isDirty,
      enableBodyScroll: true,
      footer: _buildActionButtons(),
      child: Form(
        key: _formKey,
        onChanged: () {
          if (!_isDirty) setState(() => _isDirty = true);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormFields(),
              const SizedBox(height: 32),
              _buildJournalTable(),
              const SizedBox(height: 24),
              _buildAddRowButton(),
              const SizedBox(height: 24),
              _buildTotalsSection(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRowField(
          label: 'Profile Name*',
          isRequired: true,
          tooltip:
              'The unique title to identify this specific recurring journal template',
          child: SizedBox(
            width: 540,
            child: CustomTextField(
              controller: profileNameCtrl,
              hintText: 'Enter profile name',
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
          ),
        ),
        _buildRowField(
          label: 'Repeat Every*',
          isRequired: true,
          tooltip:
              'The frequency interval at which new journal entries will be automatically created',
          child: Row(
            children: [
              SizedBox(
                width: 540,
                child: di.FormDropdown<String>(
                  value: repeatEvery,
                  items: const [
                    'Week',
                    '2 Weeks',
                    'Month',
                    '2 Months',
                    '3 Months',
                    '6 Months',
                    'Year',
                    '2 Years',
                    '3 Years',
                    'Custom',
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      repeatEvery = v;
                      if (v != 'Custom') {
                        // syncing state so if user switches to Custom, it's pre-filled
                        final lower = v.toLowerCase();
                        int newInterval = 1;
                        String newUnit = 'Week(s)';

                        if (lower.contains('week')) {
                          newUnit = 'Week(s)';
                          if (lower.contains('2')) newInterval = 2;
                        } else if (lower.contains('month')) {
                          newUnit = 'Month(s)';
                          if (lower.contains('2'))
                            newInterval = 2;
                          else if (lower.contains('3'))
                            newInterval = 3;
                          else if (lower.contains('6'))
                            newInterval = 6;
                        } else if (lower.contains('year')) {
                          newUnit = 'Year(s)';
                          if (lower.contains('2'))
                            newInterval = 2;
                          else if (lower.contains('3'))
                            newInterval = 3;
                        }

                        interval = newInterval;
                        intervalCtrl.text = newInterval.toString();
                        customFrequencyUnit = newUnit;
                      }
                    });
                  },
                ),
              ),
              if (repeatEvery == 'Custom') ...[
                const SizedBox(width: 16),
                SizedBox(
                  width: 60,
                  child: CustomTextField(
                    controller: intervalCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  child: di.FormDropdown<String>(
                    value: customFrequencyUnit,
                    items: const ['Day(s)', 'Week(s)', 'Month(s)', 'Year(s)'],
                    onChanged: (v) => setState(() => customFrequencyUnit = v!),
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildRowField(
          label: 'Starts On',
          tooltip:
              'The initial date the first recurring journal will be triggered',
          child: Row(
            children: [
              SizedBox(
                width: 150,
                child: InkWell(
                  key: _startDateKey,
                  onTap: () => _selectDate(context, true),
                  child: CustomTextField(
                    controller: startDateCtrl,
                    enabled: false,
                    fillColor: Colors.white,
                    suffixWidget: const Icon(LucideIcons.calendar, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              if (!neverExpires) ...[
                const Text('Ends On', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 14),
                SizedBox(
                  width: 150,
                  child: InkWell(
                    key: _endDateKey,
                    onTap: () => _selectDate(context, false),
                    child: CustomTextField(
                      controller: endDateCtrl,
                      enabled: false,
                      fillColor: Colors.white,
                      hintText: 'dd/MM/yyyy',
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Checkbox(
                value: neverExpires,
                onChanged: (v) => setState(() {
                  neverExpires = v!;
                  if (v) {
                    endDate = null;
                    endDateCtrl.text = 'dd/MM/yyyy';
                  }
                }),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const Text('Never Expires', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildRowField(
          label: 'Reference#',
          tooltip:
              'Internal tracking or receipt number to associate with generated journals',
          child: SizedBox(
            width: 540,
            child: CustomTextField(
              controller: referenceCtrl,
              hintText: 'Reference#',
            ),
          ),
        ),
        _buildRowField(
          label: 'Notes*',
          isRequired: true,
          tooltip:
              'Any extra details appended directly to each auto-created journal. Keep within 500 characters',
          child: SizedBox(
            width: 540,
            child: CustomTextField(
              controller: notesCtrl,
              maxLines: 6,
              hintText: 'Max. 500 characters',
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
              height: 100,
            ),
          ),
        ),
        _buildRowField(
          label: 'Reporting Method',
          labelWidget: const Icon(
            LucideIcons.helpCircle,
            size: 14,
            color: AppTheme.textSecondary,
          ),
          child: ZerpaiRadioGroup<String>(
            options: const ['accrual_and_cash', 'accrual_only', 'cash_only'],
            current: reportingMethod,
            onChanged: (v) => setState(() => reportingMethod = v),
            labelBuilder: (v) {
              switch (v) {
                case 'accrual_and_cash':
                  return 'Accrual and Cash';
                case 'accrual_only':
                  return 'Accrual Only';
                case 'cash_only':
                  return 'Cash Only';
                default:
                  return v;
              }
            },
          ),
        ),
        _buildRowField(
          label: 'Currency',
          child: Row(
            children: [
              SizedBox(
                width: 540,
                child: di.FormDropdown<String>(
                  value: selectedCurrency,
                  items: const ['INR- Indian Rupee'],
                  onChanged: (v) => setState(() => selectedCurrency = v!),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRowField({
    required String label,
    required Widget child,
    bool isRequired = false,
    Widget? labelWidget,
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isRequired
                          ? AppTheme.errorRed
                          : AppTheme.textPrimary,
                    ),
                  ),
                  if (labelWidget != null) ...[
                    const SizedBox(width: 4),
                    labelWidget,
                  ],
                  if (tooltip != null) ...[
                    const SizedBox(width: 4),
                    ZTooltip(
                      message: tooltip,
                      child: const Icon(
                        LucideIcons.info,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildJournalTable() {
    final accountsState = ref.watch(chartOfAccountsProvider);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            color: AppTheme.bgLight,
            height: 40,
            child: Row(
              children: [
                _cell(width: 32, child: const SizedBox()), // Drag handle space
                _cell(flex: 4, child: _headerText('ACCOUNT')),
                _cell(flex: 4, child: _headerText('DESCRIPTION')),
                _cell(flex: 3, child: _headerText('CONTACT (INR)')),
                _cell(
                  flex: 2,
                  child: _headerText('DEBITS', textAlign: TextAlign.right),
                ),
                _cell(
                  flex: 2,
                  child: _headerText('CREDITS', textAlign: TextAlign.right),
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
          // Rows
          ReorderableListView.builder(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
            itemBuilder: (context, index) =>
                _buildItemRow(index, rows[index], accountsState.roots),
          ),
        ],
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

  Widget _headerText(String text, {TextAlign textAlign = TextAlign.left}) {
    return Container(
      width: double.infinity,
      alignment: textAlign == TextAlign.right
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildItemRow(
    int index,
    ManualJournalRow row,
    List<coa.AccountNode> roots,
  ) {
    final contactsAsync = ref.watch(manualJournalContactsProvider);
    final mappedNodes = _mapNodes(roots);

    return Container(
      key: ObjectKey(row),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _isGstAccount(row.accountName) ? 75.0 : row.rowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cell(
                  width: 32,
                  child: ReorderableDragStartListener(
                    index: index,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      dropdown.AccountTreeDropdown(
                        value: row.accountId,
                        nodes: mappedNodes,
                        height: _isGstAccount(row.accountName) ? 40.0 : row.rowHeight - 2,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: Colors.transparent),
                        onSearch: (q) async {
                          final results = await ref
                              .read(accountantRepositoryProvider)
                              .searchAccounts(q);
                          return results.where((e) {
                            final name = e.name.toLowerCase().trim();
                            final type = e.accountType.toLowerCase().trim();

                            // Always hide Dimension Adjustments
                            if (name == 'dimension adjustments' ||
                                name == 'dimension adjustment') {
                              return false;
                            }

                            // Always hide Stock/Inventory
                            if (name.contains('stock') ||
                                name.contains('inventory') ||
                                type.contains('stock') ||
                                type.contains('inventory')) {
                              return false;
                            }

                            // Hide AP/AR for non-accrual_only
                            if (reportingMethod != 'accrual_only') {
                              if (name == 'accounts payable' ||
                                  name == 'account payable' ||
                                  name == 'accounts receivable' ||
                                  name == 'account receivable') {
                                return false;
                              }
                            }
                            return true;
                          }).map((e) => shared.AccountNode(
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
                        onChanged: (id) {
                          setState(() {
                            row.accountId = id;
                            row.accountName = _findName(mappedNodes, id);
                            row.rowHeight =
                                _isGstAccount(row.accountName) ? 75.0 : 48.0;
                          });
                        },
                        hint: 'Select an account',
                      ),
                      if (_isGstAccount(row.accountName))
                        const _GstWarningWidget(),
                    ],
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
                  child: contactsAsync.when(
                    data: (contacts) => di.FormDropdown<Map<String, dynamic>>(
                      value: contacts
                              .where(
                                (c) =>
                                    c['id'] == row.contactId &&
                                    (row.contactType == null ||
                                        (c['contact_type'] ?? c['type'])
                                                ?.toString()
                                                .toLowerCase() ==
                                            row.contactType!
                                                .toString()
                                                .toLowerCase()),
                              )
                              .firstOrNull ??
                          contacts
                              .where((c) => c['id'] == row.contactId)
                              .firstOrNull,
                      items: contacts
                          .map((c) => Map<String, dynamic>.from(c))
                          .toList(),
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: Colors.transparent),
                      height: 48,
                      displayStringForValue: (c) =>
                          (c['displayName'] ?? c['display_name'] ?? '')
                              .toString(),
                      onChanged: (v) {
                        setState(() {
                          row.contactId = v?['id'];
                          final typeValue = v?['contact_type'] ?? v?['type'];
                          row.contactType = typeValue?.toString();
                        });
                      },
                      onSearch: (q) async {
                        return await ref.read(searchContactsProvider(q).future);
                      },
                      hint: 'Select Contact',
                      showSearch: true,
                    ),
                    loading: () => const SizedBox(height: 20),
                    error: (_, __) => const Text('Error'),
                  ),
                ),
                _cell(
                  flex: 2,
                  child: CustomTextField(
                    controller: row.debitCtrl,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: Colors.transparent),
                    height: 48,
                    hintText: '0',
                    onTap: () {
                      row.debitCtrl.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: row.debitCtrl.text.length,
                      );
                    },
                    onChanged: (value) {
                      final debit = double.tryParse(value) ?? 0;
                      final credit = double.tryParse(row.creditCtrl.text) ?? 0;
                      if (debit > 0 && credit > 0) {
                        row.creditCtrl.text = '';
                      }
                      _calculateTotals();
                    },
                  ),
                ),
                _cell(
                  flex: 2,
                  child: CustomTextField(
                    controller: row.creditCtrl,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: Colors.transparent),
                    height: 48,
                    hintText: '0',
                    onTap: () {
                      row.creditCtrl.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: row.creditCtrl.text.length,
                      );
                    },
                    onChanged: (value) {
                      final credit = double.tryParse(value) ?? 0;
                      final debit = double.tryParse(row.debitCtrl.text) ?? 0;
                      if (credit > 0 && debit > 0) {
                        row.debitCtrl.text = '';
                      }
                      _calculateTotals();
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
                        icon: Icon(
                          row.isExpanded
                              ? LucideIcons.chevronUp
                              : LucideIcons.moreVertical,
                          size: 16,
                          color: AppTheme.textMuted,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Additional Information',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _removeRow(index),
                        icon: const Icon(
                          LucideIcons.trash2,
                          size: 15,
                          color: AppTheme.errorRed,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Remove Line',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (row.isExpanded)
            Container(
              color: AppTheme.bgLight.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 22),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.briefcase,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: di.FormDropdown<String>(
                              value: row.projectId,
                              items: const [],
                              hint: 'Select a project',
                              onChanged: (v) =>
                                  setState(() => row.projectId = v),
                              height: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.tag,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: di.FormDropdown<String>(
                              value: row.reportingTags,
                              items: const [],
                              hint: 'Reporting Tags',
                              onChanged: (v) =>
                                  setState(() => row.reportingTags = v),
                              height: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 7, // filler for Contact/Debit/Credit
                    child: const SizedBox(),
                  ),
                  const SizedBox(width: 80), // filler for actions
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddRowButton() {
    return TextButton.icon(
      onPressed: () => _addRow(),
      icon: const Icon(LucideIcons.plusCircle, size: 16),
      label: const Text('Add New Row'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppTheme.primaryBlue),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.bgLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _buildTotalRow('Sub Total', totalDebit, totalCredit),
            const SizedBox(height: 16),
            _buildTotalRow('Total (₹)', totalDebit, totalCredit, isBold: true),
          ],
        ),
      ),
    );
  }

  bool _isGstAccount(String? name) {
    if (name == null) return false;
    final n = name.toLowerCase();
    return n.contains('gst') ||
        n.contains('cgst') ||
        n.contains('sgst') ||
        n.contains('igst') ||
        n.contains('input tax credit');
  }

  Widget _buildTotalRow(
    String label,
    double debit,
    double credit, {
    bool isBold = false,
  }) {
    final style = TextStyle(
      fontSize: isBold ? 15 : 13,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: AppTheme.textPrimary,
    );
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        SizedBox(
          width: 80,
          child: Text(
            debit.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
        const SizedBox(width: 40),
        SizedBox(
          width: 80,
          child: Text(
            credit.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ZButton.primary(
            label: 'Save',
            onPressed: _isSaving
                ? null
                : () => _handleSave(status: RecurringJournalStatus.active),
            loading: _isSaving,
          ),
          const SizedBox(width: 12),
          ZButton.secondary(
            label: 'Save as Draft',
            onPressed: _isSaving
                ? null
                : () => _handleSave(status: RecurringJournalStatus.draft),
          ),
          const SizedBox(width: 12),
          ZButton.secondary(
            label: 'Cancel',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.accountantRecurringJournals);
              }
            },
          ),
        ],
      ),
    );
  }

  String _getAccountDisplayName(coa.AccountNode account) {
    final user = account.userAccountName.trim();
    final system = account.systemAccountName.trim();
    return user.isNotEmpty
        ? user
        : (system.isNotEmpty ? system : account.name.trim());
  }

  bool _isAccountHidden(coa.AccountNode account) {
    final name = _getAccountDisplayName(account).toLowerCase().trim();
    final type = account.accountType.toLowerCase().trim();

    // 1. Always hide Dimension Adjustments
    if (name == 'dimension adjustments' || name == 'dimension adjustment') {
      return true;
    }

    // 2. Always hide Stock/Inventory related accounts in Journals
    // (This includes stock and its child types)
    if (name.contains('stock') ||
        name.contains('inventory') ||
        type.contains('stock') ||
        type.contains('inventory')) {
      return true;
    }

    // 3. Hide AP/AR for non-accrual_only reporting methods
    if (reportingMethod != 'accrual_only') {
      if (name.contains('accounts payable') ||
          name.contains('account payable') ||
          name.contains('accounts receivable') ||
          name.contains('account receivable') ||
          type.contains('payable') ||
          type.contains('receivable')) {
        return true;
      }
    }
    return false;
  }

  List<shared.AccountNode> _mapNodes(List<coa.AccountNode> roots) {
    final groupOrder = [
      'Assets',
      'Liabilities',
      'Equity',
      'Income',
      'Expenses',
    ];

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

      final activeChildren = account.children
          .where((c) => c.isActive && !c.isDeleted && !_isAccountHidden(c))
          .toList()
        ..sort(
          (a, b) => _getAccountDisplayName(a)
              .toLowerCase()
              .compareTo(_getAccountDisplayName(b).toLowerCase()),
        );

      return shared.AccountNode(
        id: account.id,
        name: '$prefix${_getAccountDisplayName(account)}',
        selectable: true,
        children: activeChildren.map((c) => mapNode(c, level + 1)).toList(),
      );
    }

    // Grouping only by account type now
    final groupedByType = <String, List<shared.AccountNode>>{};
    final typeToGroup =
        <String, String>{}; // To preserve accounting order (Assets types first, etc.)

    final activeRoots = roots
        .where((n) => n.isActive && !n.isDeleted && !_isAccountHidden(n))
        .toList();

    for (final root in activeRoots) {
      final isGroup = groupOrder.any(
        (g) => g.toLowerCase() == _getAccountDisplayName(root).toLowerCase().trim(),
      );

      if (isGroup) {
        // If it's a group (like 'Assets'), skip it but process its direct children
        for (final child in root.children) {
          if (child.isActive && !child.isDeleted && !_isAccountHidden(child)) {
            final type = child.accountType.trim();
            final finalType = toTitleCase(type.isEmpty ? 'Other' : type);

            final group = child.accountGroup.trim();
            final finalGroup = toTitleCase(group.isEmpty ? 'Other' : group);

            groupedByType.putIfAbsent(finalType, () => []);
            groupedByType[finalType]!.add(mapNode(child, 0));
            typeToGroup.putIfAbsent(finalType, () => finalGroup);
          }
        }
      } else {
        // Not a group, add it directly to its type bucket
        final type = root.accountType.trim();
        final finalType = toTitleCase(type.isEmpty ? 'Other' : type);

        final group = root.accountGroup.trim();
        final finalGroup = toTitleCase(group.isEmpty ? 'Other' : group);

        groupedByType.putIfAbsent(finalType, () => []);
        groupedByType[finalType]!.add(mapNode(root, 0));
        typeToGroup.putIfAbsent(finalType, () => finalGroup);
      }
    }

    // Sort the types by their group (Assets first...) and then by name
    final sortedTypes = groupedByType.keys.toList()
      ..sort((a, b) {
        final groupA = typeToGroup[a]!;
        final groupB = typeToGroup[b]!;

        final idxA = groupOrder.indexWhere(
          (e) => e.toLowerCase() == groupA.toLowerCase(),
        );
        final idxB = groupOrder.indexWhere(
          (e) => e.toLowerCase() == groupB.toLowerCase(),
        );

        // First sort by Group Index
        if (idxA != -1 && idxB != -1) {
          if (idxA != idxB) return idxA.compareTo(idxB);
        } else if (idxA != -1) {
          return -1;
        } else if (idxB != -1) {
          return 1;
        }

        // Then sort by Type name alphabetically
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    return sortedTypes.map((type) {
      final accountNodes = groupedByType[type]!;
      accountNodes.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      // Return each type as a non-selectable top-level node (heading)
      return shared.AccountNode(
        id: '__account_type__$type',
        name: type,
        selectable: false,
        children: accountNodes,
      );
    }).toList();
  }

  String? _findName(List<shared.AccountNode> nodes, String? id) {
    for (final n in nodes) {
      if (n.id == id) return n.name;
      final found = _findName(n.children, id);
      if (found != null) return found;
    }
    return null;
  }
}

class _GstWarningWidget extends StatefulWidget {
  const _GstWarningWidget();

  @override
  State<_GstWarningWidget> createState() => _GstWarningWidgetState();
}

class _GstWarningWidgetState extends State<_GstWarningWidget> {
  bool _showPopover = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _togglePopover() {
    if (_showPopover) {
      _hidePopover();
    } else {
      _showPopoverDetails();
    }
  }

  void _showPopoverDetails() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showPopover = true);
  }

  void _hidePopover() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _showPopover = false);
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible barrier to close on tap outside
          GestureDetector(
            onTap: _hidePopover,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            width: 320,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 8),
              child: Material(
                elevation: 8,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppTheme.borderColor, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox.shrink(),
                          GestureDetector(
                            onTap: _hidePopover,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.primaryBlue),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                LucideIcons.x,
                                size: 12,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "If you're not sure about selecting this account, it is recommended that you consult with your accountant before recording this journal. Also, remember that this journal will not reflect in the GST Returns.",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: InkWell(
          onTap: _togglePopover,
          hoverColor: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                size: 14,
                color: Color(0xFFFF5252),
              ),
              const SizedBox(width: 4),
              Text(
                'Warning',
                style: TextStyle(
                  color: const Color(0xFFFF5252),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
